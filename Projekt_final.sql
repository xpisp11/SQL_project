/* Propojeni tabulek economies, countries, religions - ulozeno jako v_joined_eco_co_rel */

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
-- Priprava 3 tabulek s aktualnimi hodnotami GDP, gini a mortality_under5: 
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
-- Spojeni 3 tabulek do jedne tabulky:
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
-- Spojeni tabulek economies_actual a countries:
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
-- Priprava sloupcu s poctem prislusniku jednotlivych nabozenstvi:
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
-- Pripojeni tabulky pivoted_religions:
SELECT
	base.*,
	r.*
FROM joined_economies_countries base
LEFT JOIN pivoted_religions r 
	ON base.zeme = r.country
;





/* Propojeni covid19_basic_differences s lookup_table a covid19_tests - ulozeno jako v_joined_cov_lt_tests_eco_co_rel  */

-- Vytvoreni tabulky covid19_test_new ulozene ve VIEW:
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



-- Spojeni tabulek covid19_basic_differences s lookup_table a covid19_tests_new a nasledne spojeni s v_joined_eco_co_rel
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
-- Spojeni covid_Australia_Canada_China (tj. rozsirene tabulky covid19_basic_differences) s lookup_table (tj. ziskani sloupce s iso3):
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
-- Pripojeni covid19_tests_new
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
-- Spojeni dvou nove vytvorených tabulek (v_joined_eco_co_rel a joined_covid_lookup_tests) dohromady, prejmenovani sloupcu a vypocty:
SELECT 
	base.`date` AS datum,
	base.country AS zeme,
	base.iso3 AS ISO,
	base.confirmed AS "denni_narust_nakazenych",
	base.tests_performed AS "denni_testy",
	base.population AS "pocet_obyvatel",
	-- 4. Pridani noveho sloupce: binarni promenna pro vikend / pracovni den:
	CASE 
		WHEN WEEKDAY(base.`date`) IN (5, 6) THEN 1 
		ELSE 0 
		END AS "vikend",
	-- 4. Pridani noveho sloupce: rocni obdobi:
	CASE 
		WHEN base.`date` < '2020-03-20' OR (base.`date` BETWEEN '2020-12-21' AND '2021-03-19') THEN "3"		-- zima
		WHEN base.`date` < '2020-06-20' OR (base.`date` BETWEEN '2021-03-20' AND '2021-06-20') THEN "0"		-- jaro
		WHEN base.`date` < '2020-09-22' THEN "1"		-- leto
		WHEN base.`date` < '2020-12-21' THEN "2"		-- podzim
		END AS "rocni_obdobi",
	-- Dopocitani HDP na obyvatele: 
	ROUND(v.HDP/base.population) AS "HDP_na_obyvatele",		
	v.gini_koeficient,
	v.`detska_umrtnost`,
	v.`hustota_zalidneni`,
	v.`median_veku_2018`,
	-- Dopocitani podilu prislusniku jednotlivych nabozenstvi na celkove populaci zeme:
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




/*  Napojeni udaju z tabulky weather k vysledne tabulce  - ulozeno jako v_joined_cov_lt_tests_eco_co_rel_w  */

CREATE OR REPLACE VIEW v_joined_cov_lt_tests_eco_co_rel_w AS
WITH 
weather_new AS		-- vytvoreni nove tabulky se zmenenymi nazvy mest a provedenymi vypocty
(
	SELECT		
		CAST(`date` AS date) AS datum,
		-- Vypocty pro pozadovane udaje z tabulky weather ve sloupcich s teplotou, vetrem a destem:
		CONCAT(ROUND((SUM((CASE WHEN `time` IN ('09:00', '12:00', '15:00', '18:00') THEN 1 ELSE 0 END) * REPLACE(temp,' °c', ''))) / 4), ' °c') AS "prum_denni_teplota",	
		SUM(CASE WHEN rain = '0.0 mm' THEN 0 ELSE 1 END) * 3 AS "pocet_hod_se_srazkami",
		CONCAT(MAX(CAST(REPLACE(gust,' km/h', '') AS INT)), ' km/h') AS "max_vitr_v_narazech",
		-- Prepis nazvu hlavnich mest v tabulce weather (city) tak, aby byly shodne s nazvy v tabulce countries (capital_city):
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
    INNER JOIN weather_new w		-- Brno a Stornoway nejsou v tabulce countries, takze jejich ISO je NULL a ve vysledne tabulce nejsou treba, proto INNER JOIN.
		ON c.capital_city = w.capital_city
		AND c.iso3 IS NOT NULL 
)
SELECT
	base.*,
	wc.`prum_denni_teplota`,
 	wc.`pocet_hod_se_srazkami`,
 	wc.`max_vitr_v_narazech`
FROM v_joined_cov_lt_tests_eco_co_rel base 
LEFT JOIN joined_weather_countries wc 
	ON base.ISO = wc.ISO
   AND base.datum = wc.datum
;


SELECT distinct capital_city FROM weather

/* Napojeni udaju k life_expectancy  - ulozeno jako v_Petra_Rohlickova_projekt_SQL_final*/

CREATE OR REPLACE VIEW v_Petra_Rohlickova_projekt_SQL_final AS
WITH
-- Transponovani radku do sloupcu:
pivoted_life_expectancy AS
(
	SELECT 
        iso3,
        MAX(CASE WHEN year = 1965 THEN life_expectancy END) AS life_expectancy_1965,
        MAX(CASE WHEN year = 2015 THEN life_expectancy END) AS life_expectancy_2015
    FROM life_expectancy
    GROUP BY iso3
)
-- Pripojeni tabulky k velke vysledne tabulce a usporadani sloupcu podle zadani:
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




/*  Vytvoreni finalni tabulky  */

CREATE TABLE t_Petra_Rohlickova_projekt_SQL_final AS	-- trvalo to 160 minut!!!
SELECT *
FROM v_Petra_Rohlickova_projekt_SQL_final;
