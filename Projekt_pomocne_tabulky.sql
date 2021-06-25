  /*****************************/ 
 /*  Australie, Cina, Kanada  */ 
/*****************************/
  
 /* Udaje pro tyto zeme z tabulky covid19_detail_global_differences pripojim pres UNION k tabulce covid19_basic_differences. 
  	V tabulce covid19_detail_global_differences musim pouzit GROUP BY, abych hodnoty za jednotlive provincie spojila do jednoho celkoveho souctu pro kazde datum.
	Napred si pripravim tabulku pro Cinu (musim secist hodnoty pro Mainland China a China), tu pak pres UNION spojim s novou tabulkou pro Australii a Kanadu */

-- Cina zobrazeni hodnot pro China a Mainland China
SELECT
	`date`,
	country,
	SUM(confirmed) AS confirmed,
	SUM(deaths) AS deaths,
	SUM(recovered) AS recovered
FROM covid19_detail_global_differences 
WHERE country LIKE '%China%' 
GROUP BY country, `date`
ORDER BY `date`;


-- Vytvorení nove tabulky pro Cinu, ktera pujde pres UNION pripojit ke covid19_basic_differences  
WITH		-- pouziju ve WITH pro tvorbu tabulky China_final
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
)
SELECT
	`date`,
	'China' AS country,
	(Mainland_China_confirmed + China_confirmed) AS confirmed,
	(Mainland_China_deaths + China_deaths) AS deaths,
	(Mainland_China_recovered + China_recovered) AS recovered
FROM China_joined; 
  

-- Vytvoreni nove tabulky pro Australii a Kanadu, ktera pujde pripojit ke covid19_basic_differences
SELECT		-- pouziju ve WITH v covid_Australia_Canada_China
	`date`,
	country,
	SUM(confirmed) AS confirmed,
	SUM(deaths) AS deaths,
	SUM(recovered) AS recovered 
FROM covid19_detail_global_differences 
WHERE country IN ('Australia', 'Canada') 
GROUP BY country, `date`;



  /***********************/
 /*  covid19_tests_new  */ 
/***********************/
  
/* Pripravim si nove tabulky covid19_tests pro "problematicke" zeme, ve kterych urcim jen jednu entitu. Pomoci UNION tyto tabulky spojim spolu navzajem
   a take s tabulkou covid19_tests bez techto zemi. Tim ziskam novou tabulku covid19_tests_new, ktera uz u techto "problematickych" zemi nebude mit
   zdvojene zaznamy pro zadne datum */

CREATE OR REPLACE VIEW v_covid19_tests_new AS
SELECT *
FROM covid19_tests
WHERE country = 'France'
	AND entity = 'tests performed (incl. non-PCR)'
UNION
SELECT *
FROM covid19_tests
WHERE country = 'India'
	AND entity = 'samples tested'
UNION
SELECT *
FROM covid19_tests
WHERE country = 'Italy'
	AND entity = 'tests performed'
UNION 
SELECT *
FROM covid19_tests
WHERE country = 'Japan'
	AND entity = 'people tested (incl. non-PCR)'
UNION 
SELECT *
FROM covid19_tests
WHERE country = 'Poland'
	AND entity = 'samples tested'
UNION 
SELECT *
FROM covid19_tests
WHERE country = 'Singapore'
	AND entity = 'samples tested'
UNION 
SELECT *
FROM covid19_tests
WHERE country = 'United States'
	AND entity = 'tests performed'
UNION	
SELECT *
FROM covid19_tests
WHERE country NOT IN ('France', 'India', 'Italy', 'Japan', 'Poland', 'Singapore', 'United States')
;

-- kontrola
SELECT * FROM v_covid19_tests_new WHERE country = 'United States';


  
  /****************************************/
 /*  Vypocty pro tvorbu dalsich sloupcu  */
/****************************************/
  
SELECT		-- pridam do SELECTu pro vypis vysledne tabulky
	*,
	-- binarni promenna pro vikend / pracovni den
	CASE 
		WHEN WEEKDAY(datum) IN (5, 6) THEN 1 
		ELSE 0 
		END AS "vikend",
	-- roèní období
	CASE 
		WHEN datum < '2020-03-20' OR (datum BETWEEN '2020-12-21' AND '2021-03-19') THEN "zima"
		WHEN datum < '2020-06-20' OR (datum BETWEEN '2021-03-20' AND '2021-06-20') THEN "jaro"
		WHEN datum < '2020-09-22' THEN "leto"
		WHEN datum < '2020-12-21' THEN "podzim"
		END AS "rocni obdobi"
FROM v_joined_covid_lookup_tests_economies_countries
-- WHERE ISO = 'USA'
;



  /**************/
 /*  religion  */
/**************/

-- Podivam se, jak tabulka vypada. Zajimaji me jen udaje z roku 2020 a to pro jednotlive zeme (ne All Countries) 
SELECT * FROM religions WHERE `year` = '2020' AND country <> 'All Countries';


-- Chyba v datech u Afghanistanu (v roce 2020 ma byt Other Religions 30,000)
SELECT * FROM religions WHERE country = 'Afghanistan' AND religion IN ('Folk Religions', 'Other Religions');
-- Opravim primo v tabulce:
UPDATE religions 
SET religion = 'Other Religions'
WHERE 1=1
	AND `year` = 2020
	AND country = 'Afghanistan'
	AND population = 30000;


-- Protoze chci udaje ke kazde zemi mit pouze na jednom radku, pretransponuju si radky s jednotlivymi nabozenstvimi na sloupce.
SELECT DISTINCT religion FROM religions;

SELECT 		-- pouziju ve WITH jako pivoted_religions pro pripojeni k tabulce joined_economies_countries	
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
GROUP BY country;


/* Abych mohla stanovit podily prislusniku jednotlivych nabozenstvi v zemi na celkovem obyvatelstvu, musim napred spojit tabulku 
   pivoted_religions s tabulkou obsahujici informaci o celkove populaci zeme (nejlepe lookup_table, kterou jsem si na zacatku urcila 
   jako vychozi pro hodnoty poctu obyvatel statu). 
   Nejprve ale musim zjistit, jake nazvy maji zeme v tabulce religions (napr. jestli CR je Czech Republic jako v tabulce economies a 
   countries nebo Czechia jako v tabulce lookuup_table a covid19_basic_differences) */

SELECT DISTINCT country FROM religions WHERE country <> 'All Countries' ORDER BY country;


/* Nazvy jsou stejne jako v tabulkach economies a countries, takze tabulku religion nejprve spojim s joined_economies_countries
   a vytvorim nove VIEW v_joined_eco_co_rel, se kterym dale pracuju (viz. Projekt_final.sql) */




  /*******************************/
 /*  Vypocty v tabulce weather  */
/*******************************/

SELECT DISTINCT city FROM weather ORDER BY city;
SELECT DISTINCT capital_city FROM countries ORDER BY capital_city;

-- - Prepisu si nazvy hlavnich mest v tabulce weather (city) tak, aby byly shodne s nazvy v tabulce countries (capital_city).
-- -- Udelam vypocty ve sloupcich s teplotou, vetrem a destem 
 
SELECT		-- pouziju ve WITH jako weather_new
	CAST(`date`AS date) AS datum,
	-- prumerna denni (nikoli nocni!) teplota
	-- odstranila jsem " °c", vypocitala prumer pouze z teplot pro casy z daneho intervalu a zase pripojila " °c"
	CONCAT(ROUND((SUM((CASE WHEN `time` IN ('09:00', '12:00', '15:00', '18:00') THEN 1 ELSE 0 END) * REPLACE(temp,' °c', ''))) / 4), ' °c') AS "prum_denni_teplota",	
	-- pocet hodin v danem dni, kdy byly srazky nenulove
	SUM(CASE WHEN rain = '0.0 mm' THEN 0 ELSE 1 END) * 3 AS "pocet_hod_se_srazkami",
	-- maximalni sila vetru v narazech behem dne
	CONCAT(MAX(CAST(REPLACE(gust,' km/h', '') AS INT)), ' km/h') AS "max_vitr_v_narazech",
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
;

-- kontrola
SELECT `date`, `time`, temp, gust, rain FROM weather WHERE city = 'Prague';




  /********************************/
 /*  Pivotovani life_expectancy  */
/********************************/

-- Podivam se, jak tabulka vypada.
SELECT * FROM life_expectancy;

/*Tabulka ma sloupec iso3, pres ktery muzu pomoci LEFT JOIN tabulku pripojit k velke vysledne tabulce. Napred ale musim radky s rokem 1965 a 2015 
  transponovat do sloupcu, abych od sebe mohla hodnoty snadno odecist */

WITH 
-- transponovani
pivoted_life_expectancy AS 	-- pouziju ve WITH pro pripojeni k tabulce v_joined_cov_lt_tests_eco_co_rel_w
(
	SELECT 
        iso3,
        MAX(CASE WHEN year = 1965 THEN life_expectancy END) AS life_expectancy_1965,
        MAX(CASE WHEN year = 2015 THEN life_expectancy END) AS life_expectancy_2015
    FROM life_expectancy
    GROUP BY iso3
)
-- pripojeni tabulky k velke vysledne tabulce
SELECT
    base.*,
    ROUND(le.life_expectancy_2015 - le.life_expectancy_1965,1) AS "rozdil_doziti_2015_1965"
FROM v_joined_cov_lt_tests_eco_co_rel_w base
LEFT JOIN pivoted_life_expectancy le
  ON base.ISO = le.iso3