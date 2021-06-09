  /******************************/
 /*  3. Prvn� spojen� tabulek  */
/******************************/ 	  

-- a) Propojen� tabulek economies, countries, religions - ulo�eno jako v_joined_eco_co_rel  
CREATE OR REPLACE VIEW v_joined_eco_co_rel AS
WITH
-- Nap�ed p�iprav�m 3 tabulky s aktu�ln�mi hodnotami GDP, gini a mortality_under5: 
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
-- Tyto 3 tabulky spoj�m do jedn� tabulky:
economies_actual AS 
(
	 SELECT
		gdp.country AS "zem�",
		gdp.GDP AS HDP,
		g.gini AS "gini_koeficient",
 		m.mortaliy_under5 "d�tsk�_�mrtnost"
     FROM GDP_actual gdp
LEFT JOIN gini_actual g
	   ON gdp.country = g.country
LEFT JOIN mortality_actual m
 	   ON gdp.country = m.country
 ORDER BY gdp.country
),
-- Spoj�m tabulky economies_actual a countries:
joined_economies_countries AS
(
	SELECT
		e.*,
		c.iso3 AS ISO,
		c.population_density AS "hustota_zalidn�n�",
		c.median_age_2018 AS "medi�n_v�ku_2018"
	FROM economies_actual e
	LEFT JOIN countries c 
		ON e.zem� = c.country
	ORDER BY e.zem�
),
-- P�iprav�m si sloupce s po�tem p��slu�n�k� jednotliv�ch n�bo�enstv�
pivoted_religions AS
( 
	SELECT 
   		country,
  		MAX(CASE WHEN religion = 'Christianity' THEN population END) AS "k�es�anstv�",
		MAX(CASE WHEN religion = 'Islam' THEN population END) AS "isl�m",
   		MAX(CASE WHEN religion = 'Hinduism' THEN population END) AS "hinduismus",
   		MAX(CASE WHEN religion = 'Buddhism' THEN population END) AS "budhismus",
  		MAX(CASE WHEN religion = 'Judaism' THEN population END) AS "judaismus",
   		MAX(CASE WHEN religion = 'Unaffiliated Religions' THEN population END) AS "nep�idru�en�_n�bo�enstv�",
 		MAX(CASE WHEN religion = 'Folk Religions' THEN population END) AS "lidov�_n�bo�enstv�",
		MAX(CASE WHEN religion = 'Other Religions' THEN population END) AS "jin� n�bo�enstv�"
	FROM religions
	WHERE 1=1
		AND `year` = '2020' 
		AND country <> 'All Countries'
	GROUP BY country
)
-- P�ipoj�m tabulku pivoted_religions:
SELECT
	base.*,
	r.*
FROM joined_economies_countries base
LEFT JOIN pivoted_religions r 
	ON base.zem� = r.country
;



-- b) Propojen� covid19_basic_diff s lookup a covid19_tests - ulo�eno jako v_joined_cov_lt_tests_eco_co_rel  
-- - nejprve vytvo�en� tabulky covid19_test_new ulo�en� ve VIEW:
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
-- Spoj�m p�es UNION z�znamy pro Austr�lii, ��nu a Kanadu z covid19_detail_global_differences a covid19_basic_differences 
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
-- Spoj�m covid_Australia_Canada_China (tj. roz���enou tabulku covid19_basic_differences) s lookup_table, t�m z�sk�m k dat�m o confirmed tak� iso3
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
-- P�ipoj�m covid19_tests_new
/* Kv�li probl�m�m se dv�ma z�znami o testech u jednoho data u n�kter�ch zem� (viz. Projekt_priprava_kontrolni.sql) jsem vytvo�ila novou tabulku 
   covid19_tests_new (viz. Projekt_upravene_tabulky.sql), kterou pou�iju m�sto tabulky covid19_tests */
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
-- Spoj�m dv� nov� vytvo�en� tabulky dohromady
SELECT 
	base.`date` AS datum,
	base.country AS zem�,
	base.iso3 AS ISO,
	base.confirmed AS "denn�_n�rust_naka�en�ch",
	base.tests_performed AS "denn�_testy",
	base.population AS "po�et_obyvatel",
	-- 4. P�id�m nov� sloupec: bin�rn� prom�nn� pro v�kend / pracovn� den
	CASE 
		WHEN WEEKDAY(base.`date`) IN (5, 6) THEN 1 
		ELSE 0 
		END AS "v�kend",
	-- 4. P�id�m nov� sloupec: ro�n� obdob�
	CASE 
		WHEN base.`date` < '2020-03-20' OR (base.`date` BETWEEN '2020-12-21' AND '2021-03-19') THEN "3"		-- zima
		WHEN base.`date` < '2020-06-20' OR (base.`date` BETWEEN '2021-03-20' AND '2021-06-20') THEN "0"		-- jaro
		WHEN base.`date` < '2020-09-22' THEN "1"		-- l�to
		WHEN base.`date` < '2020-12-21' THEN "2"		-- podzim
		END AS "ro�n�_obdob�",
	-- Dopo��t�n� HDP na obyvatele 
	ROUND(v.HDP/base.population) AS "HDP_na_obyvatele",		
	v.gini_koeficient,
	v.`d�tsk�_�mrtnost`,
	v.`hustota_zalidn�n�`,
	v.`medi�n_v�ku_2018`,
	-- Dopo��t�n� pod�lu p��slu�n�k� jednotliv�ch n�bo�enstv� na celkov� populaci zem�
	CONCAT(ROUND(v.`k�es�anstv�`/base.population * 100,1), ' %') AS "pod�l_k�es�an�",
	CONCAT(ROUND(v.`isl�m`/base.population * 100,1), ' %') AS "pod�l_p��slu�n�k�_isl�mu",
	CONCAT(ROUND(v.`hinduismus`/base.population * 100,1), ' %') AS "pod�l_hinduist�",
	CONCAT(ROUND(v.`budhismus`/base.population * 100,1), ' %') AS "pod�l_budhist�",
	CONCAT(ROUND(v.`judaismus`/base.population * 100,1), ' %') AS "pod�l_�id�",
	CONCAT(ROUND(v.`nep�idru�en�_n�bo�enstv�`/base.population * 100,1), ' %') AS "pod�l_p��slu�n�k�_nep�idru�._n�b.",
	CONCAT(ROUND(v.`lidov�_n�bo�enstv�`/base.population * 100,1), ' %') AS "pod�l_p��slu�n�k�_lid._n�b.",
	CONCAT(ROUND(v.`jin� n�bo�enstv�`/base.population * 100,1), ' %') AS "pod�l_p��slu�n�k�_jin�ch_n�b."	
FROM joined_covid_lookup_tests base 
LEFT JOIN (SELECT * FROM v_joined_eco_co_rel) v 
	ON base.iso3 = v.ISO
;



  /************************/
 /*  5. Tabulka weather  */
/************************/
-- Napojen� �daj� z tabulky weather k v�sledn� tabulce  - ulo�eno jako v_joined_cov_lt_tests_eco_co_rel_w
CREATE OR REPLACE VIEW v_joined_cov_lt_tests_eco_co_rel_w AS
WITH 
weather_new AS
(
	SELECT		
		CAST(`date` AS date) AS datum,
		-- Ud�l�m pot�ebn� v�po�ty pro po�adovan� �daje z tabulky weather ve sloupc�ch s teplotou, v�trem a de�t�m.
		CONCAT(ROUND((SUM((CASE WHEN `time` IN ('09:00', '12:00', '15:00', '18:00') THEN 1 ELSE 0 END) * REPLACE(temp,' �c', ''))) / 4), ' �c') AS "pr�m._denn�_teplota",	
		SUM(CASE WHEN rain = '0.0 mm' THEN 0 ELSE 1 END) * 3 AS "po�et_hod._se_sr�kami",
		CONCAT(MAX(CAST(REPLACE(gust,' km/h', '') AS INT)), ' km/h') AS "max_v�tr_v_n�razech",
		-- P�ep�u si n�zvy hlavn�ch m�st v tabulce weather (city) tak, aby byly shodn� s n�zvy v tabulce countries (capital_city).
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
	JOIN weather_new w		-- Brno a Stornoway nejsou v tabulce countries, tak�e jejich ISO je NULL a ve v�sledn� tabulce je nepot�ebuju, proto INNER JOIN.
		 ON c.capital_city = w.capital_city
		AND c.iso3 IS NOT NULL 
)
SELECT
	base.*,
	wc.`pr�m._denn�_teplota`,
 	wc.`po�et_hod._se_sr�kami`,
 	wc.`max_v�tr_v_n�razech`
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
-- transponov�n�
pivoted_life_expectancy AS
(
	SELECT 
        iso3,
        MAX(CASE WHEN year = 1965 THEN life_expectancy END) AS life_expectancy_1965,
        MAX(CASE WHEN year = 2015 THEN life_expectancy END) AS life_expectancy_2015
    FROM life_expectancy
    GROUP BY iso3
)
-- p�ipojen� tabulky k velk� v�sledn� tabulce a uspo��d�n� sloupc� podle zad�n�
SELECT
    base.datum,
	base.zem�,
-- 	base.ISO,
	base.`denn�_n�rust_naka�en�ch`,
	base.`denn�_testy`,
	base.`po�et_obyvatel`,
	base.v�kend,
	base.`ro�n�_obdob�`,
	base.`hustota_zalidn�n�`,
	base.`HDP_na_obyvatele`,		
	base.gini_koeficient,
	base.`d�tsk�_�mrtnost`,
	base.`medi�n_v�ku_2018`,
	base.`pod�l_k�es�an�`,
	base.`pod�l_p��slu�n�k�_isl�mu`,
	base.`pod�l_hinduist�`,
	base.`pod�l_budhist�`,
	base.`pod�l_�id�`,
	base.`pod�l_p��slu�n�k�_nep�idru�._n�b.`,
	base.`pod�l_p��slu�n�k�_lid._n�b.`,
	base.`pod�l_p��slu�n�k�_jin�ch_n�b.`,	
    ROUND(le.life_expectancy_2015 - le.life_expectancy_1965,1) AS "rozd�l_do�it�_2015_1965",
	base.`pr�m._denn�_teplota`,	
	base.`po�et_hod._se_sr�kami`,
	base.`max_v�tr_v_n�razech`
FROM v_joined_cov_lt_tests_eco_co_rel_w base
LEFT JOIN pivoted_life_expectancy le
  ON base.ISO = le.iso3
;




  /*************************/
 /*  7. Fin�ln� tabulka   */
/*************************/ 

-- Vytvo�en� fin�ln� v�sledn� tabulky (trvalo to 160 minut!!!)
CREATE TABLE t_Petra_Rohlickova_projekt_SQL_final AS
SELECT *
FROM v_Petra_Rohlickova_projekt_SQL_final;


-- Zobrazen� cel� tabulky
SELECT * 
FROM t_petra_rohlickova_projekt_sql_final;


-- N�vrh zobrazen� "v��ezu" tabulky v n�vaznosti na dostupnost dat
SELECT * 
FROM t_petra_rohlickova_projekt_sql_final
WHERE 1=1
	AND datum <= '2020-11-24'		-- informace o testov�n� jsou dostupn� pouze do tohoto data, tak�e pokud jsou tyto informace pro anal�zu z�sadn�, d�v� smysl tabulku omezit 
ORDER BY datum DESC, 
		 denn�_n�rust_naka�en�ch DESC;


