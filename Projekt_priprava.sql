  /********************************/
 /*   1. Studium vsech tabulek   */
/********************************/ 
   
SELECT * FROM countries;	-- country, population, population density, median age 2018, iso 3 (totozne s ISO z covid19_test)
SELECT * FROM economies; 	-- country, year, GDP, population (2019), gini (ruzne roky), mortality under 5 (2019)
SELECT * FROM life_expectancy;		-- country, iso3, year, life expectancy	
SELECT * FROM religions;	-- year (vzit 2020), country, religion (nabozenstvi v dane zemi), population (prislusnici daneho nabozenstvi)
SELECT * FROM covid19_basic_differences;  -- denni prirustky ve vsech zemich (country, date)
SELECT * FROM covid19_tests;		-- denni a kumulativni pocty provedenych testu ve vsech zemich (country, date, ISO)
SELECT * FROM weather;		-- date, time, temp, gust, rain 
SELECT * FROM lookup_table;		-- country, iso3, population



  /***********************************************/
 /*  2. Reseni "issues" v datech ci tabulkach   */
/***********************************************/

/* GDP, gini koeficient a mortality under 5:
   Hodnoty ukazatelu jsem vzala v kazde zemi nejaktualnejsi, ktere jsou k dispozici, tj. nasla jsem posledni rok (MAX(year)), ve kterem byly tyto ukazatele NOT NULL */
SELECT 		
	country,
	MAX(year),
	gini
FROM economies				
WHERE gini IS NOT NULL		
GROUP BY country;	


-- population:
-- - spojeni tabulek a kontrolni sloupce s mezirocnim rustem populace
SELECT 
	e.country,
	e.`year`,
	c.population AS population_countries,
	e.population AS population_economies,
	ROUND((e.population/c.population-1) * 100,2) AS "2019/2018_%_growth",
	lt.population AS population_lookup_table,
	ROUND((lt.population/e.population-1) * 100,2) AS "2020/2019_%_growth"
FROM economies e 
JOIN countries c 
  ON e.country = c.country
JOIN lookup_table lt 
  ON e.country = lt.country
GROUP BY country, `year`
ORDER BY country, `year` DESC;


-- ruzne nazvy statu v ruznych tabulkach
-- - kontrola nazvu statu v tabulkach   
SELECT DISTINCT country FROM economies;
SELECT DISTINCT country FROM countries;
SELECT DISTINCT country FROM lookup_table;
SELECT DISTINCT country FROM covid19_basic_differences;
SELECT DISTINCT country FROM covid19_tests;
SELECT DISTINCT country FROM religions;



  /******************************/
 /*  3. Prvni spojeni tabulek  */
/******************************/ 	  

-- a) Propojeni tabulek economies, countries, religions - ulozeno jako v_joined_eco_co_rel  

-- Oprava chybnych dat v tabulce religions u Afghanistanu:
UPDATE religions 
SET religion = 'Other Religions'
WHERE 1=1
	AND `year` = 2020
	AND country = 'Afghanistan'
	AND population = 30000;


-- Postupne spojeni vsech 3 tabulek:
CREATE OR REPLACE VIEW v_joined_eco_co_rel AS
WITH
-- Napred pripravim 3 tabulky s aktualnimi hodnotami GDP, gini a mortality_under5: 
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
-- Tyto 3 tabulky spojim do jedne tabulky:
economies_actual AS 
(
	 SELECT
		gdp.country AS "zeme",
		gdp.GDP AS HDP,
		g.gini AS "gini_koeficient",
 		m.mortaliy_under5 "detska_umrtnost"
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
		c.population_density AS "hustota_zalidneni",
		c.median_age_2018 AS "median_veku_2018"
	FROM economies_actual e
	LEFT JOIN countries c 
		ON e.zeme = c.country
	ORDER BY e.zeme
),
-- Pripravim si sloupce s poctem prislusniku jednotlivych nabozenstvi
pivoted_religions AS
( 
	SELECT 
   		country,
  		MAX(CASE WHEN religion = 'Christianity' THEN population END) AS "krestanstvi",
		MAX(CASE WHEN religion = 'Islam' THEN population END) AS "islam",
   		MAX(CASE WHEN religion = 'Hinduism' THEN population END) AS "hinduismus",
   		MAX(CASE WHEN religion = 'Buddhism' THEN population END) AS "budhismus",
  		MAX(CASE WHEN religion = 'Judaism' THEN population END) AS "judaismus",
   		MAX(CASE WHEN religion = 'Unaffiliated Religions' THEN population END) AS "nepridruzena_nabozenstvi",
 		MAX(CASE WHEN religion = 'Folk Religions' THEN population END) AS "lidova_nabozenstvi",
		MAX(CASE WHEN religion = 'Other Religions' THEN population END) AS "jina_nabozenstvi"
	FROM religions
	WHERE 1=1
		AND `year` = '2020' 
		AND country <> 'All Countries'
	GROUP BY country
)
-- Pripojim tabulku pivoted_religions:
SELECT
	base.*,
	r.*
FROM joined_economies_countries base
LEFT JOIN pivoted_religions r 
	ON base.zeme = r.country
;

-- zkouska
SELECT * FROM v_joined_eco_co_rel;


-- b) Propojeni covid19_basic_diff s lookup a covid19_tests - ulozeno jako v_joined_cov_lt_tests_eco_co_rel  
CREATE OR REPLACE VIEW v_joined_cov_lt_tests_eco_co_rel AS
WITH 
-- Vytvoreni nove tabulky pro Cinu z covid19_detail_global_differences
China_confirmed AS
(	
	SELECT 
		`date`,
		country, 
		sum(confirmed) AS confirmed
	FROM covid19_detail_global_differences
	WHERE country LIKE '%China%' 
	GROUP BY `date`
	ORDER BY `date`
),
China_deaths AS
(
	SELECT 
		`date`,
		country, 
		sum(deaths) AS deaths
	FROM covid19_detail_global_differences
	WHERE country LIKE '%China%' 
	GROUP BY `date`
	ORDER BY `date`
),
China_recovered AS
(
	SELECT 
		`date`,
		country, 
		sum(recovered) AS recovered
	FROM covid19_detail_global_differences
	WHERE country LIKE '%China%' 
	GROUP BY `date`
	ORDER BY `date`
),
China_joined AS
(	
	SELECT
		c.`date`,
		c.country,
		COALESCE(SUM(CASE WHEN c.country = 'Mainland China' THEN c.confirmed END), 0) AS Mainland_China_confirmed,
		COALESCE(SUM(CASE WHEN c.country = 'China' THEN c.confirmed END), 0) AS China_confirmed,
		COALESCE(SUM(CASE WHEN c.country = 'Mainland China' THEN d.deaths END), 0) AS Mainland_China_deaths,
		COALESCE(SUM(CASE WHEN c.country = 'China' THEN d.deaths END), 0) AS China_deaths,
		COALESCE(SUM(CASE WHEN c.country = 'Mainland China' THEN r.recovered END), 0) AS Mainland_China_recovered,
		COALESCE(SUM(CASE WHEN c.country = 'China' THEN r.recovered END), 0) AS China_recovered
	FROM China_confirmed c
	LEFT JOIN China_deaths d
		 ON c.`date` = d.`date`
		AND c.country = d.country
	LEFT JOIN China_recovered r 
		 ON d.`date` = r.`date`
		AND d.country = r.country
	GROUP BY c.`date`, c.country
),
China_final AS
(
	SELECT
		`date`,
		'China' AS country,
		(Mainland_China_confirmed + China_confirmed) AS confirmed,
		(Mainland_China_deaths + China_deaths) AS deaths,
		(Mainland_China_recovered + China_recovered) AS recovered
	FROM China_joined
),
-- Pripojeni zaznamu pro Australii a Kanadu z covid19_detail_global_differences k nove tabulce pro Cinu a k tabulce covid19_basic_differences: 
covid_Australia_Canada_China AS
(
	SELECT		
		`date`,
		country,
		SUM(confirmed) AS confirmed,
		SUM(deaths) AS deaths,
		SUM(recovered) AS recovered 
	FROM covid19_detail_global_differences 
	WHERE country IN ('Australia', 'Canada') 
	GROUP BY country, `date`
	UNION 
	SELECT *
	FROM China_final
	UNION
	SELECT 
		*
	FROM covid19_basic_differences
),
-- Spojim covid_Australia_Canada_China (tj. rozsirenou tabulku covid19_basic_differences) s lookup_table, tim ziskam k datum o confirmed také iso3
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
-- Pripojim covid19_tests_new
/* Kvuli problemum se dvema zaznami o testech u jednoho data u nekterych zemi (viz. Projekt_priprava_kontrolni.sql) jsem vytvorila novou tabulku 
   covid19_tests_new (viz. Projekt_pomocne_tabulky.sql), kterou pouziju misto tabulky covid19_tests */
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
-- Spojim dve nove vytvorene tabulky dohromady
SELECT 
	base.`date` AS datum,
	base.country AS zeme,
	base.iso3 AS ISO,
	base.confirmed AS "denni_narust_nakazenych",
	base.tests_performed AS "denni_testy",
	base.population AS "pocet_obyvatel",
	-- 4. Pridam novy sloupec: binarni promenna pro vikend / pracovni den
	CASE 
		WHEN WEEKDAY(base.`date`) IN (5, 6) THEN 1 
		ELSE 0 
		END AS "vikend",
	-- 4. Pridam novy sloupec: rocni obdobi
	CASE 
		WHEN base.`date` < '2020-03-20' OR (base.`date` BETWEEN '2020-12-21' AND '2021-03-19') THEN "3"		-- zima
		WHEN base.`date` < '2020-06-20' OR (base.`date` BETWEEN '2021-03-20' AND '2021-06-20') THEN "0"		-- jaro
		WHEN base.`date` < '2020-09-22' THEN "1"		-- leto
		WHEN base.`date` < '2020-12-21' THEN "2"		-- podzim
		END AS "rocni_obdobi",
	-- Dopocitani HDP na obyvatele 
	ROUND(v.HDP/base.population) AS "HDP_na_obyvatele",		
	v.gini_koeficient,
	v.`detska_umrtnost`,
	v.`hustota_zalidneni`,
	v.`median_veku_2018`,
	-- Dopocitani podilu prislusniku jednotlivych nabozenstvi na celkove populaci zeme
	CONCAT(ROUND(v.`krestanstvi`/base.population * 100,1), ' %') AS "podil_krestanu",
	CONCAT(ROUND(v.`islam`/base.population * 100,1), ' %') AS "podil_prislusniku_islamu",
	CONCAT(ROUND(v.`hinduismus`/base.population * 100,1), ' %') AS "podil_hinduistu",
	CONCAT(ROUND(v.`budhismus`/base.population * 100,1), ' %') AS "podil_budhistu",
	CONCAT(ROUND(v.`judaismus`/base.population * 100,1), ' %') AS "podil_zidu",
	CONCAT(ROUND(v.`nepridruzena_nabozenstvi`/base.population * 100,1), ' %') AS "podil_prislusniku_nepridruz_nab",
	CONCAT(ROUND(v.`lidova_nabozenstvi`/base.population * 100,1), ' %') AS "podil_prislusniku_lid_nab",
	CONCAT(ROUND(v.`jina_nabozenstvi`/base.population * 100,1), ' %') AS "podil_prislusniku_jinych_nab"
FROM joined_covid_lookup_tests base 
LEFT JOIN (SELECT * FROM v_joined_eco_co_rel) v 
	ON base.iso3 = v.ISO
;

-- zkouska
SELECT * FROM v_joined_cov_lt_tests_eco_co_rel WHERE zeme IN ('Australia', 'Canada', 'China') AND datum BETWEEN '2020-09-20' AND '2020-12-20';

SELECT * FROM v_joined_cov_lt_tests_eco_co_rel WHERE zeme = 'Afghanistan';

-- oprava chybnych dat v tabulce religions u Afghanistanu:
UPDATE religions 
SET religion = 'Other Religions'
WHERE 1=1
	AND `year` = 2020
	AND country = 'Afghanistan'
	AND population = 30000;


  /************************/
 /*  5. Tabulka weather  */
/************************/
-- a) napojeni udaju z tabulky weather  - ulozeno jako v_weather_new 
    
CREATE OR REPLACE VIEW v_weather_new AS
WITH 
weather_new AS
(
	SELECT		
		CAST(`date` AS date) AS datum,
		-- Udelam potrebne vypocty pro pozadovane udaje z tabulky weather ve sloupcich s teplotou, vetrem a destem.
		CONCAT(ROUND((SUM((CASE WHEN `time` IN ('09:00', '12:00', '15:00', '18:00') THEN 1 ELSE 0 END) * REPLACE(temp,' °c', ''))) / 4), ' °c') AS "prum_denni_teplota",	
		SUM(CASE WHEN rain = '0.0 mm' THEN 0 ELSE 1 END) * 3 AS "pocet_hod_se_srazkami",
		CONCAT(MAX(CAST(REPLACE(gust,' km/h', '') AS INT)), ' km/h') AS "max_vitr_v_narazech",
		-- Prepisu si nazvy hlavnich mest v tabulce weather (city) tak, aby byly shodne s nazvy v tabulce countries (capital_city).
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
)
-- Spojim tabulky weather_new a countries, tak k udajum o pocasi ziskam ISO z tabulky countries.   
SELECT 
	c.iso3 AS ISO,
	w.*
FROM countries c 
JOIN weather_new w		-- Brno a Stornoway nejsou v tabulce countries, takze jejich ISO je NULL a ve vysledne tabulce je nepotrebuju, proto INNER JOIN.
	 ON c.capital_city = w.capital_city
	AND c.iso3 IS NOT NULL 
;

-- zkouska
SELECT * FROM v_weather_new WHERE capital_city = 'Roma';

-- b) Pripojeni tabulky v_weather_new k vysledne tabulce  - ulozeno jako v_joined_cov_lt_tests_eco_co_rel_w
CREATE OR REPLACE VIEW v_joined_cov_lt_tests_eco_co_rel_w AS
SELECT
	base.*,
	wn.`prum_denni_teplota`,
 	wn.`pocet_hod_se_srazkami`,
 	wn.`max_vitr_v_narazech`
FROM v_joined_cov_lt_tests_eco_co_rel base 
LEFT JOIN v_weather_new wn 
	ON base.ISO = wn.ISO
   AND base.datum = wn.datum
;

-- zkouska
SELECT * 
FROM v_joined_cov_lt_tests_eco_co_rel_w 
WHERE zeme IN ('US', 'Czechia') AND datum BETWEEN '2020-09-20' AND '2020-12-20' 
ORDER BY datum;



  /*********************************/
 /*  6. Tabulka life_expectancy   */ 
/*********************************/

CREATE OR REPLACE VIEW v_Petra_Rohlickova_projekt_SQL_final AS
WITH
-- transponovani
pivoted_life_expectancy AS
(
	SELECT 
        iso3,
        MAX(CASE WHEN year = 1965 THEN life_expectancy END) AS life_expectancy_1965,
        MAX(CASE WHEN year = 2015 THEN life_expectancy END) AS life_expectancy_2015
    FROM life_expectancy
    GROUP BY iso3
)
-- pripojeni tabulky k velke vysledne tabulce a usporadani sloupcu podle zadani
SELECT
    base.datum,
	base.zeme,
-- 	base.ISO,
	base.`denni_narust_nakazenych`,
	base.`denni_testy`,
	base.`pocet_obyvatel`,
	base.vikend,
	base.`rocni_obdobi`,
	base.`hustota_zalidneni`,
	base.`HDP_na_obyvatele`,		
	base.gini_koeficient,
	base.`detska_umrtnost`,
	base.`median_veku_2018`,
	base.`podil_krestanu`,
	base.`podil_prislusniku_islamu`,
	base.`podil_hinduistu`,
	base.`podil_budhistu`,
	base.`podil_zidu`,
	base.`podil_prislusniku_nepridruz_nab`,
	base.`podil_prislusniku_lid_nab`,
	base.`podil_prislusniku_jinych_nab`,	
    ROUND(le.life_expectancy_2015 - le.life_expectancy_1965,1) AS "rozdil_doziti_2015_1965",
	base.`prum_denni_teplota`,	
	base.`pocet_hod_se_srazkami`,
	base.`max_vitr_v_narazech`
FROM v_joined_cov_lt_tests_eco_co_rel_w base
LEFT JOIN pivoted_life_expectancy le
  ON base.ISO = le.iso3
;


-- zkouska 
SELECT * FROM v_petra_rohlickova_projekt_sql_final WHERE zeme IN ('Australia', 'Czechia', 'US') ORDER BY zeme, datum;

SELECT * FROM v_petra_rohlickova_projekt_sql_final WHERE zeme = 'Afghanistan';



  /*************************/
 /*  7. Finalni tabulka   */
/*************************/ 

-- Vytvoreni finalni vysledne tabulky (trvalo to 135 minut, resp. podruhe 282 minut !!!)

CREATE TABLE t_Petra_Rohlickova_projekt_SQL_final AS
SELECT *
FROM v_Petra_Rohlickova_projekt_SQL_final
ORDER BY zeme, datum DESC;


SELECT * FROM t_petra_rohlickova_projekt_sql_final ORDER BY datum;

