/* Propojen� tabulek economies, countries, religions - ulo�eno jako v_joined_eco_co_rel */

-- Oprava chybn�ch dat v tabulce religions u Afgh�nist�nu:
UPDATE religions 
SET religion = 'Other Religions'
WHERE 1=1
	AND `year` = 2020
	AND country = 'Afghanistan'
	AND population = 30000;


-- Postupn� spojen� v�ech 3 tabulek:
CREATE OR REPLACE VIEW v_joined_eco_co_rel AS
WITH
-- P��prava 3 tabulek s aktu�ln�mi hodnotami GDP, gini a mortality_under5: 
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
-- Spojen� 3 tabulek do jedn� tabulky:
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
-- Spojen� tabulek economies_actual a countries:
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
-- P��prava sloupc� s po�tem p��slu�n�k� jednotliv�ch n�bo�enstv�:
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
		MAX(CASE WHEN religion = 'Other Religions' THEN population END) AS "jin�_n�bo�enstv�"
	FROM religions
	WHERE 1=1
		AND `year` = '2020' 
		AND country <> 'All Countries'
	GROUP BY country
)
-- P�ipojen� tabulky pivoted_religions:
SELECT
	base.*,
	r.*
FROM joined_economies_countries base
LEFT JOIN pivoted_religions r 
	ON base.zem� = r.country
;





/* Propojen� covid19_basic_differences s lookup_table a covid19_tests - ulo�eno jako v_joined_cov_lt_tests_eco_co_rel  */

-- Vytvo�en� tabulky covid19_test_new ulo�en� ve VIEW:
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



-- Spojen� tabulek covid19_basic_differences s lookup_table a covid19_tests_new a n�sledn� spojen� s v_joined_eco_co_rel
CREATE OR REPLACE VIEW v_joined_cov_lt_tests_eco_co_rel AS
WITH 
-- Vytvo�en� nov� tabulky pro ��nu z covid19_detail_global_differences
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
-- P�ipojen� z�znam� pro Austr�lii a Kanadu z covid19_detail_global_differences k nov� tabulce pro ��nu a k tabulce covid19_basic_differences: 
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
-- Spojen� covid_Australia_Canada_China (tj. roz���en� tabulky covid19_basic_differences) s lookup_table (tj. z�sk�n� sloupce s iso3):
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
-- P�ipojen� covid19_tests_new
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
-- Spojen� dvou nov� vytvo�en�ch tabulek (v_joined_eco_co_rel a joined_covid_lookup_tests) dohromady, p�ejmenov�n� sloupc� a v�po�ty:
SELECT 
	base.`date` AS datum,
	base.country AS zem�,
	base.iso3 AS ISO,
	base.confirmed AS "denn�_n�rust_naka�en�ch",
	base.tests_performed AS "denn�_testy",
	base.population AS "po�et_obyvatel",
	-- 4. P�id�n� nov�ho sloupce: bin�rn� prom�nn� pro v�kend / pracovn� den:
	CASE 
		WHEN WEEKDAY(base.`date`) IN (5, 6) THEN 1 
		ELSE 0 
		END AS "v�kend",
	-- 4. P�id�n� nov�ho sloupce: ro�n� obdob�:
	CASE 
		WHEN base.`date` < '2020-03-20' OR (base.`date` BETWEEN '2020-12-21' AND '2021-03-19') THEN "3"		-- zima
		WHEN base.`date` < '2020-06-20' OR (base.`date` BETWEEN '2021-03-20' AND '2021-06-20') THEN "0"		-- jaro
		WHEN base.`date` < '2020-09-22' THEN "1"		-- l�to
		WHEN base.`date` < '2020-12-21' THEN "2"		-- podzim
		END AS "ro�n�_obdob�",
	-- Dopo��t�n� HDP na obyvatele: 
	ROUND(v.HDP/base.population) AS "HDP_na_obyvatele",		
	v.gini_koeficient,
	v.`d�tsk�_�mrtnost`,
	v.`hustota_zalidn�n�`,
	v.`medi�n_v�ku_2018`,
	-- Dopo��t�n� pod�lu p��slu�n�k� jednotliv�ch n�bo�enstv� na celkov� populaci zem�:
	CONCAT(ROUND(v.`k�es�anstv�`/base.population * 100,1), ' %') AS "pod�l_k�es�an�",
	CONCAT(ROUND(v.`isl�m`/base.population * 100,1), ' %') AS "pod�l_p��slu�n�k�_isl�mu",
	CONCAT(ROUND(v.`hinduismus`/base.population * 100,1), ' %') AS "pod�l_hinduist�",
	CONCAT(ROUND(v.`budhismus`/base.population * 100,1), ' %') AS "pod�l_budhist�",
	CONCAT(ROUND(v.`judaismus`/base.population * 100,1), ' %') AS "pod�l_�id�",
	CONCAT(ROUND(v.`nep�idru�en�_n�bo�enstv�`/base.population * 100,1), ' %') AS "pod�l_p��slu�n�k�_nep�idru�._n�b.",
	CONCAT(ROUND(v.`lidov�_n�bo�enstv�`/base.population * 100,1), ' %') AS "pod�l_p��slu�n�k�_lid._n�b.",
	CONCAT(ROUND(v.`jin�_n�bo�enstv�`/base.population * 100,1), ' %') AS "pod�l_p��slu�n�k�_jin�ch_n�b."	
FROM joined_covid_lookup_tests base 
LEFT JOIN (SELECT * FROM v_joined_eco_co_rel) v 
	ON base.iso3 = v.ISO
;




/*  Napojen� �daj� z tabulky weather k v�sledn� tabulce  - ulo�eno jako v_joined_cov_lt_tests_eco_co_rel_w  */

CREATE OR REPLACE VIEW v_joined_cov_lt_tests_eco_co_rel_w AS
WITH 
weather_new AS		-- vytvo�en� nov� tabulky se zm�n�n�mi n�zvy m�st a proveden�mi v�po�ty
(
	SELECT		
		CAST(`date` AS date) AS datum,
		-- V�po�ty pro po�adovan� �daje z tabulky weather ve sloupc�ch s teplotou, v�trem a de�t�m:
		CONCAT(ROUND((SUM((CASE WHEN `time` IN ('09:00', '12:00', '15:00', '18:00') THEN 1 ELSE 0 END) * REPLACE(temp,' �c', ''))) / 4), ' �c') AS "pr�m._denn�_teplota",	
		SUM(CASE WHEN rain = '0.0 mm' THEN 0 ELSE 1 END) * 3 AS "po�et_hod._se_sr�kami",
		CONCAT(MAX(CAST(REPLACE(gust,' km/h', '') AS INT)), ' km/h') AS "max_v�tr_v_n�razech",
		-- P�epis n�zv� hlavn�ch m�st v tabulce weather (city) tak, aby byly shodn� s n�zvy v tabulce countries (capital_city):
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
    INNER JOIN weather_new w		-- Brno a Stornoway nejsou v tabulce countries, tak�e jejich ISO je NULL a ve v�sledn� tabulce nejsou t�eba, proto INNER JOIN.
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




/* Napojen� �daj� k life_expectancy  - ulo�eno jako v_Petra_Rohlickova_projekt_SQL_final*/

CREATE OR REPLACE VIEW v_Petra_Rohlickova_projekt_SQL_final AS
WITH
-- Transponov�n� ��dk� do sloupc�:
pivoted_life_expectancy AS
(
	SELECT 
        iso3,
        MAX(CASE WHEN year = 1965 THEN life_expectancy END) AS life_expectancy_1965,
        MAX(CASE WHEN year = 2015 THEN life_expectancy END) AS life_expectancy_2015
    FROM life_expectancy
    GROUP BY iso3
)
-- P�ipojen� tabulky k velk� v�sledn� tabulce a uspo��d�n� sloupc� podle zad�n�:
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




/*  Vytvo�en� fin�ln� tabulky  */

CREATE TABLE t_Petra_Rohlickova_projekt_SQL_final AS	-- trvalo to 160 minut!!!
SELECT *
FROM v_Petra_Rohlickova_projekt_SQL_final;
