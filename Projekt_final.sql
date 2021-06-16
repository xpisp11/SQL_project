/* PropojenÌ tabulek economies, countries, religions - uloûeno jako v_joined_eco_co_rel */

-- Oprava chybn˝ch dat v tabulce religions u Afgh·nist·nu:
UPDATE religions 
SET religion = 'Other Religions'
WHERE 1=1
	AND `year` = 2020
	AND country = 'Afghanistan'
	AND population = 30000;


-- PostupnÈ spojenÌ vöech 3 tabulek:
CREATE OR REPLACE VIEW v_joined_eco_co_rel AS
WITH
-- P¯Ìprava 3 tabulek s aktu·lnÌmi hodnotami GDP, gini a mortality_under5: 
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
-- SpojenÌ 3 tabulek do jednÈ tabulky:
economies_actual AS 
(
	 SELECT
		gdp.country AS "zemÏ",
		gdp.GDP AS HDP,
		g.gini AS "gini_koeficient",
 		m.mortaliy_under5 "dÏtsk·_˙mrtnost"
     FROM GDP_actual gdp
LEFT JOIN gini_actual g
	   ON gdp.country = g.country
LEFT JOIN mortality_actual m
 	   ON gdp.country = m.country
 ORDER BY gdp.country
),
-- SpojenÌ tabulek economies_actual a countries:
joined_economies_countries AS
(
	SELECT
		e.*,
		c.iso3 AS ISO,
		c.population_density AS "hustota_zalidnÏnÌ",
		c.median_age_2018 AS "medi·n_vÏku_2018"
	FROM economies_actual e
	LEFT JOIN countries c 
		ON e.zemÏ = c.country
	ORDER BY e.zemÏ
),
-- P¯Ìprava sloupc˘ s poËtem p¯ÌsluönÌk˘ jednotliv˝ch n·boûenstvÌ:
pivoted_religions AS
( 
	SELECT 
   		country,
  		MAX(CASE WHEN religion = 'Christianity' THEN population END) AS "k¯esùanstvÌ",
		MAX(CASE WHEN religion = 'Islam' THEN population END) AS "isl·m",
   		MAX(CASE WHEN religion = 'Hinduism' THEN population END) AS "hinduismus",
   		MAX(CASE WHEN religion = 'Buddhism' THEN population END) AS "budhismus",
  		MAX(CASE WHEN religion = 'Judaism' THEN population END) AS "judaismus",
   		MAX(CASE WHEN religion = 'Unaffiliated Religions' THEN population END) AS "nep¯idruûen·_n·boûenstvÌ",
 		MAX(CASE WHEN religion = 'Folk Religions' THEN population END) AS "lidov·_n·boûenstvÌ",
		MAX(CASE WHEN religion = 'Other Religions' THEN population END) AS "jin·_n·boûenstvÌ"
	FROM religions
	WHERE 1=1
		AND `year` = '2020' 
		AND country <> 'All Countries'
	GROUP BY country
)
-- P¯ipojenÌ tabulky pivoted_religions:
SELECT
	base.*,
	r.*
FROM joined_economies_countries base
LEFT JOIN pivoted_religions r 
	ON base.zemÏ = r.country
;





/* PropojenÌ covid19_basic_differences s lookup_table a covid19_tests - uloûeno jako v_joined_cov_lt_tests_eco_co_rel  */

-- Vytvo¯enÌ tabulky covid19_test_new uloûenÈ ve VIEW:
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



-- SpojenÌ tabulek covid19_basic_differences s lookup_table a covid19_tests_new a n·slednÈ spojenÌ s v_joined_eco_co_rel
CREATE OR REPLACE VIEW v_joined_cov_lt_tests_eco_co_rel AS
WITH 
-- Vytvo¯enÌ novÈ tabulky pro »Ìnu z covid19_detail_global_differences
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
-- P¯ipojenÌ z·znam˘ pro Austr·lii a Kanadu z covid19_detail_global_differences k novÈ tabulce pro »Ìnu a k tabulce covid19_basic_differences: 
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
-- SpojenÌ covid_Australia_Canada_China (tj. rozöÌ¯enÈ tabulky covid19_basic_differences) s lookup_table (tj. zÌsk·nÌ sloupce s iso3):
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
-- P¯ipojenÌ covid19_tests_new
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
-- SpojenÌ dvou novÏ vytvo¯en˝ch tabulek (v_joined_eco_co_rel a joined_covid_lookup_tests) dohromady, p¯ejmenov·nÌ sloupc˘ a v˝poËty:
SELECT 
	base.`date` AS datum,
	base.country AS zemÏ,
	base.iso3 AS ISO,
	base.confirmed AS "dennÌ_n·rust_nakaûen˝ch",
	base.tests_performed AS "dennÌ_testy",
	base.population AS "poËet_obyvatel",
	-- 4. P¯id·nÌ novÈho sloupce: bin·rnÌ promÏnn· pro vÌkend / pracovnÌ den:
	CASE 
		WHEN WEEKDAY(base.`date`) IN (5, 6) THEN 1 
		ELSE 0 
		END AS "vÌkend",
	-- 4. P¯id·nÌ novÈho sloupce: roËnÌ obdobÌ:
	CASE 
		WHEN base.`date` < '2020-03-20' OR (base.`date` BETWEEN '2020-12-21' AND '2021-03-19') THEN "3"		-- zima
		WHEN base.`date` < '2020-06-20' OR (base.`date` BETWEEN '2021-03-20' AND '2021-06-20') THEN "0"		-- jaro
		WHEN base.`date` < '2020-09-22' THEN "1"		-- lÈto
		WHEN base.`date` < '2020-12-21' THEN "2"		-- podzim
		END AS "roËnÌ_obdobÌ",
	-- DopoËÌt·nÌ HDP na obyvatele: 
	ROUND(v.HDP/base.population) AS "HDP_na_obyvatele",		
	v.gini_koeficient,
	v.`dÏtsk·_˙mrtnost`,
	v.`hustota_zalidnÏnÌ`,
	v.`medi·n_vÏku_2018`,
	-- DopoËÌt·nÌ podÌlu p¯ÌsluönÌk˘ jednotliv˝ch n·boûenstvÌ na celkovÈ populaci zemÏ:
	CONCAT(ROUND(v.`k¯esùanstvÌ`/base.population * 100,1), ' %') AS "podÌl_k¯esùan˘",
	CONCAT(ROUND(v.`isl·m`/base.population * 100,1), ' %') AS "podÌl_p¯ÌsluönÌk˘_isl·mu",
	CONCAT(ROUND(v.`hinduismus`/base.population * 100,1), ' %') AS "podÌl_hinduist˘",
	CONCAT(ROUND(v.`budhismus`/base.population * 100,1), ' %') AS "podÌl_budhist˘",
	CONCAT(ROUND(v.`judaismus`/base.population * 100,1), ' %') AS "podÌl_ûid˘",
	CONCAT(ROUND(v.`nep¯idruûen·_n·boûenstvÌ`/base.population * 100,1), ' %') AS "podÌl_p¯ÌsluönÌk˘_nep¯idruû._n·b.",
	CONCAT(ROUND(v.`lidov·_n·boûenstvÌ`/base.population * 100,1), ' %') AS "podÌl_p¯ÌsluönÌk˘_lid._n·b.",
	CONCAT(ROUND(v.`jin·_n·boûenstvÌ`/base.population * 100,1), ' %') AS "podÌl_p¯ÌsluönÌk˘_jin˝ch_n·b."	
FROM joined_covid_lookup_tests base 
LEFT JOIN (SELECT * FROM v_joined_eco_co_rel) v 
	ON base.iso3 = v.ISO
;




/*  NapojenÌ ˙daj˘ z tabulky weather k v˝slednÈ tabulce  - uloûeno jako v_joined_cov_lt_tests_eco_co_rel_w  */

CREATE OR REPLACE VIEW v_joined_cov_lt_tests_eco_co_rel_w AS
WITH 
weather_new AS		-- vytvo¯enÌ novÈ tabulky se zmÏnÏn˝mi n·zvy mÏst a proveden˝mi v˝poËty
(
	SELECT		
		CAST(`date` AS date) AS datum,
		-- V˝poËty pro poûadovanÈ ˙daje z tabulky weather ve sloupcÌch s teplotou, vÏtrem a deötÏm:
		CONCAT(ROUND((SUM((CASE WHEN `time` IN ('09:00', '12:00', '15:00', '18:00') THEN 1 ELSE 0 END) * REPLACE(temp,' ∞c', ''))) / 4), ' ∞c') AS "pr˘m._dennÌ_teplota",	
		SUM(CASE WHEN rain = '0.0 mm' THEN 0 ELSE 1 END) * 3 AS "poËet_hod._se_sr·ûkami",
		CONCAT(MAX(CAST(REPLACE(gust,' km/h', '') AS INT)), ' km/h') AS "max_vÌtr_v_n·razech",
		-- P¯epis n·zv˘ hlavnÌch mÏst v tabulce weather (city) tak, aby byly shodnÈ s n·zvy v tabulce countries (capital_city):
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
    INNER JOIN weather_new w		-- Brno a Stornoway nejsou v tabulce countries, takûe jejich ISO je NULL a ve v˝slednÈ tabulce nejsou t¯eba, proto INNER JOIN.
		ON c.capital_city = w.capital_city
		AND c.iso3 IS NOT NULL 
)
SELECT
	base.*,
	wc.`pr˘m._dennÌ_teplota`,
 	wc.`poËet_hod._se_sr·ûkami`,
 	wc.`max_vÌtr_v_n·razech`
FROM v_joined_cov_lt_tests_eco_co_rel base 
LEFT JOIN joined_weather_countries wc 
	ON base.ISO = wc.ISO
   AND base.datum = wc.datum
;




/* NapojenÌ ˙daj˘ k life_expectancy  - uloûeno jako v_Petra_Rohlickova_projekt_SQL_final*/

CREATE OR REPLACE VIEW v_Petra_Rohlickova_projekt_SQL_final AS
WITH
-- Transponov·nÌ ¯·dk˘ do sloupc˘:
pivoted_life_expectancy AS
(
	SELECT 
        iso3,
        MAX(CASE WHEN year = 1965 THEN life_expectancy END) AS life_expectancy_1965,
        MAX(CASE WHEN year = 2015 THEN life_expectancy END) AS life_expectancy_2015
    FROM life_expectancy
    GROUP BY iso3
)
-- P¯ipojenÌ tabulky k velkÈ v˝slednÈ tabulce a uspo¯·d·nÌ sloupc˘ podle zad·nÌ:
SELECT
    base.datum,
	base.zemÏ,
-- 	base.ISO,
	base.`dennÌ_n·rust_nakaûen˝ch`,
	base.`dennÌ_testy`,
	base.`poËet_obyvatel`,
	base.vÌkend,
	base.`roËnÌ_obdobÌ`,
	base.`hustota_zalidnÏnÌ`,
	base.`HDP_na_obyvatele`,		
	base.gini_koeficient,
	base.`dÏtsk·_˙mrtnost`,
	base.`medi·n_vÏku_2018`,
	base.`podÌl_k¯esùan˘`,
	base.`podÌl_p¯ÌsluönÌk˘_isl·mu`,
	base.`podÌl_hinduist˘`,
	base.`podÌl_budhist˘`,
	base.`podÌl_ûid˘`,
	base.`podÌl_p¯ÌsluönÌk˘_nep¯idruû._n·b.`,
	base.`podÌl_p¯ÌsluönÌk˘_lid._n·b.`,
	base.`podÌl_p¯ÌsluönÌk˘_jin˝ch_n·b.`,	
    ROUND(le.life_expectancy_2015 - le.life_expectancy_1965,1) AS "rozdÌl_doûitÌ_2015_1965",
	base.`pr˘m._dennÌ_teplota`,	
	base.`poËet_hod._se_sr·ûkami`,
	base.`max_vÌtr_v_n·razech`
FROM v_joined_cov_lt_tests_eco_co_rel_w base
LEFT JOIN pivoted_life_expectancy le
  ON base.ISO = le.iso3
;




/*  Vytvo¯enÌ fin·lnÌ tabulky  */

CREATE TABLE t_Petra_Rohlickova_projekt_SQL_final AS	-- trvalo to 160 minut!!!
SELECT *
FROM v_Petra_Rohlickova_projekt_SQL_final;
