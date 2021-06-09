  /******************************/
 /*  3. První spojení tabulek  */
/******************************/ 	  

-- a) Propojení tabulek economies, countries, religions - uloeno jako v_joined_eco_co_rel  
CREATE OR REPLACE VIEW v_joined_eco_co_rel AS
WITH
-- Napøed pøipravím 3 tabulky s aktuálními hodnotami GDP, gini a mortality_under5: 
GDP_actual AS 
(
	SELECT 		
		country,
		MAX(`year`),
 		GDP
	FROM economies				
	WHERE GDP IS NOT NULL		
	GROUP BY country
),
gini_actual AS
(
	SELECT 		
		country,
		MAX(`year`),
		gini
	FROM economies				
	WHERE gini IS NOT NULL		
	GROUP BY country
),
mortality_actual AS 	
(
	SELECT 		
		country,
		MAX(`year`),
		mortaliy_under5
	FROM economies				
	WHERE mortaliy_under5 IS NOT NULL		
	GROUP BY country
),
-- Tyto 3 tabulky spojím do jedné tabulky:
economies_actual AS 
(
	 SELECT
		gdp.country AS "zemì",
		gdp.GDP AS HDP,
		g.gini AS "gini_koeficient",
 		m.mortaliy_under5 "dìtská_úmrtnost"
     FROM GDP_actual gdp
LEFT JOIN gini_actual g
	   ON gdp.country = g.country
LEFT JOIN mortality_actual m
 	   ON gdp.country = m.country
 ORDER BY gdp.country
),
-- Spojím tabulky economies_actual a countries:
joined_economies_countries AS
(
	SELECT
		e.*,
		c.iso3 AS ISO,
		c.population_density AS "hustota_zalidnìní",
		c.median_age_2018 AS "medián_vìku_2018"
	FROM economies_actual e
	LEFT JOIN countries c 
		ON e.zemì = c.country
	ORDER BY e.zemì
),
-- Pøipravím si sloupce s poètem pøíslušníkù jednotlivıch náboenství
pivoted_religions AS
( 
	SELECT 
   		country,
  		MAX(CASE WHEN religion = 'Christianity' THEN population END) AS "køesanství",
		MAX(CASE WHEN religion = 'Islam' THEN population END) AS "islám",
   		MAX(CASE WHEN religion = 'Hinduism' THEN population END) AS "hinduismus",
   		MAX(CASE WHEN religion = 'Buddhism' THEN population END) AS "budhismus",
  		MAX(CASE WHEN religion = 'Judaism' THEN population END) AS "judaismus",
   		MAX(CASE WHEN religion = 'Unaffiliated Religions' THEN population END) AS "nepøidruená_náboenství",
 		MAX(CASE WHEN religion = 'Folk Religions' THEN population END) AS "lidová_náboenství",
		MAX(CASE WHEN religion = 'Other Religions' THEN population END) AS "jiná náboenství"
	FROM religions
	WHERE 1=1
		AND `year` = '2020' 
		AND country <> 'All Countries'
	GROUP BY country
)
-- Pøipojím tabulku pivoted_religions:
SELECT
	base.*,
	r.*
FROM joined_economies_countries base
LEFT JOIN pivoted_religions r 
	ON base.zemì = r.country
;



-- b) Propojení covid19_basic_diff s lookup a covid19_tests - uloeno jako v_joined_cov_lt_tests_eco_co_rel  
-- - nejprve vytvoøení tabulky covid19_test_new uloené ve VIEW:
CREATE OR REPLACE VIEW v_covid19_tests_new AS
SELECT *
FROM covid19_tests
WHERE 1=1
	AND country = 'France'
	AND entity = 'tests performed (incl. non-PCR)'
UNION
SELECT *
FROM covid19_tests
WHERE 1=1
	AND country = 'India'
	AND entity = 'samples tested'
UNION
SELECT *
FROM covid19_tests
WHERE 1=1
	AND country = 'Italy'
	AND entity = 'tests performed'
UNION 
SELECT *
FROM covid19_tests
WHERE 1=1
	AND country = 'Japan'
	AND entity = 'people tested (incl. non-PCR)'
UNION 
SELECT *
FROM covid19_tests
WHERE 1=1
	AND country = 'Poland'
	AND entity = 'samples tested'
UNION 
SELECT *
FROM covid19_tests
WHERE 1=1 
	AND country = 'Singapore'
	AND entity = 'samples tested'
UNION 
SELECT *
FROM covid19_tests
WHERE 1=1
	AND country = 'United States'
	AND entity = 'tests performed'
UNION	
SELECT *
FROM covid19_tests
WHERE country NOT IN ('France', 'India', 'Italy', 'Japan', 'Poland', 'Singapore', 'United States')
;



CREATE OR REPLACE VIEW v_joined_cov_lt_tests_eco_co_rel AS
WITH 
-- Spojím pøes UNION záznamy pro Austrálii, Èínu a Kanadu z covid19_detail_global_differences a covid19_basic_differences 
covid_Australia_Canada_China AS
(
	SELECT		
		`date`,
		country,
		SUM(confirmed) AS confirmed,
		SUM(deaths) AS deaths,
		SUM(recovered) AS recovered 
	FROM covid19_detail_global_differences 
	WHERE country IN ('Australia', 'Canada', 'China') 
	GROUP BY country, `date`
	UNION 
	SELECT 
		*
	FROM covid19_basic_differences
),
-- Spojím covid_Australia_Canada_China (tj. rozšíøenou tabulku covid19_basic_differences) s lookup_table, tím získám k datùm o confirmed také iso3
joined_covid_lookup AS	
(
	SELECT
		cacc.`date`,
		cacc.country,
		lt.iso3,
		cacc.confirmed,
		lt.population
	FROM covid_Australia_Canada_China cacc
LEFT JOIN lookup_table lt 
  	  ON cacc.country = lt.country
  	 AND lt.province IS NULL
),
-- Pøipojím covid19_tests_new
/* Kvùli problémùm se dvìma záznami o testech u jednoho data u nìkterıch zemí (viz. Projekt_priprava_kontrolni.sql) jsem vytvoøila novou tabulku 
   covid19_tests_new (viz. Projekt_upravene_tabulky.sql), kterou pouiju místo tabulky covid19_tests */
joined_covid_lookup_tests AS 
(
	SELECT
		jcl.*,
		vct.tests_performed
	FROM joined_covid_lookup jcl 
	LEFT JOIN v_covid19_tests_new vct
		ON jcl.`date` = vct.`date`
	   AND jcl.iso3 = vct.ISO
)
-- Spojím dvì novì vytvoøené tabulky dohromady
SELECT 
	base.`date` AS datum,
	base.country AS zemì,
	base.iso3 AS ISO,
	base.confirmed AS "denní_nárust_nakaenıch",
	base.tests_performed AS "denní_testy",
	base.population AS "poèet_obyvatel",
	-- 4. Pøidám novı sloupec: binární promìnná pro víkend / pracovní den
	CASE 
		WHEN WEEKDAY(base.`date`) IN (5, 6) THEN 1 
		ELSE 0 
		END AS "víkend",
	-- 4. Pøidám novı sloupec: roèní období
	CASE 
		WHEN base.`date` < '2020-03-20' OR (base.`date` BETWEEN '2020-12-21' AND '2021-03-19') THEN "3"		-- zima
		WHEN base.`date` < '2020-06-20' OR (base.`date` BETWEEN '2021-03-20' AND '2021-06-20') THEN "0"		-- jaro
		WHEN base.`date` < '2020-09-22' THEN "1"		-- léto
		WHEN base.`date` < '2020-12-21' THEN "2"		-- podzim
		END AS "roèní_období",
	-- Dopoèítání HDP na obyvatele 
	ROUND(v.HDP/base.population) AS "HDP_na_obyvatele",		
	v.gini_koeficient,
	v.`dìtská_úmrtnost`,
	v.`hustota_zalidnìní`,
	v.`medián_vìku_2018`,
	-- Dopoèítání podílu pøíslušníkù jednotlivıch náboenství na celkové populaci zemì
	CONCAT(ROUND(v.`køesanství`/base.population * 100,1), ' %') AS "podíl_køesanù",
	CONCAT(ROUND(v.`islám`/base.population * 100,1), ' %') AS "podíl_pøíslušníkù_islámu",
	CONCAT(ROUND(v.`hinduismus`/base.population * 100,1), ' %') AS "podíl_hinduistù",
	CONCAT(ROUND(v.`budhismus`/base.population * 100,1), ' %') AS "podíl_budhistù",
	CONCAT(ROUND(v.`judaismus`/base.population * 100,1), ' %') AS "podíl_idù",
	CONCAT(ROUND(v.`nepøidruená_náboenství`/base.population * 100,1), ' %') AS "podíl_pøíslušníkù_nepøidru._náb.",
	CONCAT(ROUND(v.`lidová_náboenství`/base.population * 100,1), ' %') AS "podíl_pøíslušníkù_lid._náb.",
	CONCAT(ROUND(v.`jiná náboenství`/base.population * 100,1), ' %') AS "podíl_pøíslušníkù_jinıch_náb."	
FROM joined_covid_lookup_tests base 
LEFT JOIN (SELECT * FROM v_joined_eco_co_rel) v 
	ON base.iso3 = v.ISO
;



  /************************/
 /*  5. Tabulka weather  */
/************************/
-- Napojení údajù z tabulky weather k vısledné tabulce  - uloeno jako v_joined_cov_lt_tests_eco_co_rel_w
CREATE OR REPLACE VIEW v_joined_cov_lt_tests_eco_co_rel_w AS
WITH 
weather_new AS
(
	SELECT		
		CAST(`date` AS date) AS datum,
		-- Udìlám potøebné vıpoèty pro poadované údaje z tabulky weather ve sloupcích s teplotou, vìtrem a deštìm.
		CONCAT(ROUND((SUM((CASE WHEN `time` IN ('09:00', '12:00', '15:00', '18:00') THEN 1 ELSE 0 END) * REPLACE(temp,' °c', ''))) / 4), ' °c') AS "prùm._denní_teplota",	
		SUM(CASE WHEN rain = '0.0 mm' THEN 0 ELSE 1 END) * 3 AS "poèet_hod._se_srákami",
		CONCAT(MAX(CAST(REPLACE(gust,' km/h', '') AS INT)), ' km/h') AS "max_vítr_v_nárazech",
		-- Pøepíšu si názvy hlavních mìst v tabulce weather (city) tak, aby byly shodné s názvy v tabulce countries (capital_city).
		CASE 
			WHEN city = 'Athens' THEN 'Athenai'
			WHEN city = 'Brussels' THEN 'Bruxelles [Brussel]'
			WHEN city = 'Bucharest' THEN 'Bucuresti'
			WHEN city = 'Helsinki' THEN 'Helsinki [Helsingfors]'
			WHEN city = 'Kiev' THEN 'Kyiv'
			WHEN city = 'Lisbon' THEN 'Lisboa'
			WHEN city = 'Luxembourg' THEN 'Luxembourg [Luxemburg/L'
			WHEN city = 'Rome' THEN 'Roma'
			WHEN city = 'Vienna' THEN 'Wien'
			WHEN city = 'Warsaw' THEN 'Warszawa'
			ELSE city
		END AS "capital_city"
	FROM weather
	GROUP BY capital_city, `date`
),
joined_weather_countries AS
(
	SELECT 
		c.iso3 AS ISO,
		w.*
	FROM countries c 
	JOIN weather_new w		-- Brno a Stornoway nejsou v tabulce countries, take jejich ISO je NULL a ve vısledné tabulce je nepotøebuju, proto INNER JOIN.
		 ON c.capital_city = w.capital_city
		AND c.iso3 IS NOT NULL 
)
SELECT
	base.*,
	wc.`prùm._denní_teplota`,
 	wc.`poèet_hod._se_srákami`,
 	wc.`max_vítr_v_nárazech`
FROM v_joined_cov_lt_tests_eco_co_rel base 
LEFT JOIN joined_weather_countries wc 
	ON base.ISO = wc.ISO
   AND base.datum = wc.datum
;




  /*********************************/
 /*  6. Tabulka life_expectancy   */ 
/*********************************/

CREATE OR REPLACE VIEW v_Petra_Rohlickova_projekt_SQL_final AS
WITH
-- transponování
pivoted_life_expectancy AS
(
	SELECT 
        iso3,
        MAX(CASE WHEN year = 1965 THEN life_expectancy END) AS life_expectancy_1965,
        MAX(CASE WHEN year = 2015 THEN life_expectancy END) AS life_expectancy_2015
    FROM life_expectancy
    GROUP BY iso3
)
-- pøipojení tabulky k velké vısledné tabulce a uspoøádání sloupcù podle zadání
SELECT
    base.datum,
	base.zemì,
-- 	base.ISO,
	base.`denní_nárust_nakaenıch`,
	base.`denní_testy`,
	base.`poèet_obyvatel`,
	base.víkend,
	base.`roèní_období`,
	base.`hustota_zalidnìní`,
	base.`HDP_na_obyvatele`,		
	base.gini_koeficient,
	base.`dìtská_úmrtnost`,
	base.`medián_vìku_2018`,
	base.`podíl_køesanù`,
	base.`podíl_pøíslušníkù_islámu`,
	base.`podíl_hinduistù`,
	base.`podíl_budhistù`,
	base.`podíl_idù`,
	base.`podíl_pøíslušníkù_nepøidru._náb.`,
	base.`podíl_pøíslušníkù_lid._náb.`,
	base.`podíl_pøíslušníkù_jinıch_náb.`,	
    ROUND(le.life_expectancy_2015 - le.life_expectancy_1965,1) AS "rozdíl_doití_2015_1965",
	base.`prùm._denní_teplota`,	
	base.`poèet_hod._se_srákami`,
	base.`max_vítr_v_nárazech`
FROM v_joined_cov_lt_tests_eco_co_rel_w base
LEFT JOIN pivoted_life_expectancy le
  ON base.ISO = le.iso3
;




  /*************************/
 /*  7. Finální tabulka   */
/*************************/ 

-- Vytvoøení finální vısledné tabulky (trvalo to 160 minut!!!)
CREATE TABLE t_Petra_Rohlickova_projekt_SQL_final AS
SELECT *
FROM v_Petra_Rohlickova_projekt_SQL_final;


-- Zobrazení celé tabulky
SELECT * 
FROM t_petra_rohlickova_projekt_sql_final;


-- Návrh zobrazení "vıøezu" tabulky v návaznosti na dostupnost dat
SELECT * 
FROM t_petra_rohlickova_projekt_sql_final
WHERE 1=1
	AND datum <= '2020-11-24'		-- informace o testování jsou dostupné pouze do tohoto data, take pokud jsou tyto informace pro analızu zásadní, dává smysl tabulku omezit 
ORDER BY datum DESC, 
		 denní_nárust_nakaenıch DESC;


