  /*****************************/ 
 /*  Austrálie, Èína, Kanada  */ 
/*****************************/
  
 /* Údaje pro tyto zemì z tabulky covid19_detail_global_differences pøipojím pøes UNION k tabulce covid19_basic_differences. Nejprve ale musím v tabulce
    covid19_detail_global_differences pouít GROUP BY, abych hodnoty za jednotlivé provincie spojila do jednoho celkového souètu pro kadé datum. */

SELECT		-- pouiju ve WITH jako covid_Australia_Canada_China
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
FROM covid19_basic_differences;



/***********************/
 /*  covid19_tests_new  */ 
/***********************/
  
/* Pøipravím si nové tabulky covid19_tests pro "problematické" zemì, ve kterıch urèím jen jednu entitu. Pomocí UNION tyto tabulky spojím spolu navzájem
   a také s tabulkou covid19_tests bez tìchto zemí. Tím získám novou tabulku covid19_tests_new, která u u tìchto "problematickıch" zemí nebude mít
   zdvojené záznamy pro ádné datum */

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
 /*  Vıpoèty pro tvorbu dalších sloupcù  */
/****************************************/
  
SELECT		-- pøidám do SELECTu pro vıpis vısledné tabulky
	*,
	-- binární promìnná pro víkend / pracovní den
	CASE 
		WHEN WEEKDAY(datum) IN (5, 6) THEN 1 
		ELSE 0 
		END AS "Víkend",
	-- roèní období
	CASE 
		WHEN datum < '2020-03-20' OR (datum BETWEEN '2020-12-21' AND '2021-03-19') THEN "zima"
		WHEN datum < '2020-06-20' OR (datum BETWEEN '2021-03-20' AND '2021-06-20') THEN "jaro"
		WHEN datum < '2020-09-22' THEN "léto"
		WHEN datum < '2020-12-21' THEN "podzim"
		END AS "Roèní období"
FROM v_joined_covid_lookup_tests_economies_countries
-- WHERE ISO = 'USA'
;



  /**************/
 /*  religion  */
/**************/

-- Podívám se, jak tabulka vypadá. Zajímají mì jen údaje z roku 2020 a to pro jednotlivé zemì (ne All Countries) 
SELECT * FROM religions WHERE `year` = '2020' AND country <> 'All Countries';


-- Chyba v datech u Afghanistánu (v roce 2020 má bıt Other Religions 30,000)
SELECT * FROM religions WHERE country = 'Afghanistan' AND religion IN ('Folk Religions', 'Other Religions');
-- Opravím pøímo v tabulce:
UPDATE religions 
SET religion = 'Other Religions'
WHERE 1=1
	AND `year` = 2020
	AND country = 'Afghanistan'
	AND population = 30000;


-- Protoe chci údaje ke kadé zemi mít pouze na jednom øádku, pøetransponuju si øádky s jednotlivımi náboenstvími na sloupce.
SELECT DISTINCT religion FROM religions;

SELECT 		-- pouiju ve WITH jako pivoted_religions pro pøipojení k tabulce joined_economies_countries	
   country,
   MAX(CASE WHEN religion = 'Christianity' THEN population END) AS "køesanství",
   MAX(CASE WHEN religion = 'Islam' THEN population END) AS "islám",
   MAX(CASE WHEN religion = 'Hinduism' THEN population END) AS "hinduismus",
   MAX(CASE WHEN religion = 'Buddhism' THEN population END) AS "budhismus",
   MAX(CASE WHEN religion = 'Judaism' THEN population END) AS "judaismus",
   MAX(CASE WHEN religion = 'Unaffiliated Religions' THEN population END) AS "nepøidruená_náboenství",
   MAX(CASE WHEN religion = 'Folk Religions' THEN population END) AS "lidová_náboenství",
   MAX(CASE WHEN religion = 'Other Religions' THEN population END) AS "jiná_náboenství"
FROM religions
WHERE 1=1
	AND `year` = '2020' 
	AND country <> 'All Countries'
GROUP BY country;


/* Abych mohla stanovit podíly pøíslušníkù jednotlivıch náboenství v zemi na celkovém obyvatelstvu, musím napøed spojit tabulku 
   pivoted_religions s tabulkou obsahující informaci o celkové populaci zemì (nejlépe lookup_table, kterou jsem si na zaèátku urèila 
   jako vıchozí pro hodnoty poètu obyvatel státù). 
   Nejprve ale musím zjistit, jaké názvy mají zemì v tabulce religions (napø. jestli ÈR je Czech Republic jako v tabulce economies a 
   countries nebo Czechia jako v tabulce lookuup_table a covid19_basic_differences) */

SELECT DISTINCT country FROM religions WHERE country <> 'All Countries' ORDER BY country;


/* Názvy jsou stejné jako v tabulká economies a countries, take tabulku religion nejprve spojím s joined_economies_countries
   a vytvoøím nové VIEW v_joined_eco_co_rel, se kterım dále pracuju (viz. Projekt_final.sql) */




  /*******************************/
 /*  Vıpoèty v tabulce weather  */
/*******************************/

SELECT DISTINCT city FROM weather ORDER BY city;
SELECT DISTINCT capital_city FROM countries ORDER BY capital_city;

-- - Pøepíšu si názvy hlavních mìst v tabulce weather (city) tak, aby byly shodné s názvy v tabulce countries (capital_city).
-- -- Udìlám vıpoèty ve sloupcích s teplotou, vìtrem a deštìm 
 
SELECT		-- pouiju ve WITH jako weather_new
	CAST(`date`AS date) AS datum,
	-- prùmìrná denní (nikoli noèní!) teplota
	-- odstranila jsem " °c", vypoèítala prùmìr pouze z teplot pro èasy z daného intervalu a zase pøipojila " °c"
	CONCAT(ROUND((SUM((CASE WHEN `time` IN ('09:00', '12:00', '15:00', '18:00') THEN 1 ELSE 0 END) * REPLACE(temp,' °c', ''))) / 4), ' °c') AS "prùm._denní_teplota",	
	-- poèet hodin v daném dni, kdy byly sráky nenulové
	SUM(CASE WHEN rain = '0.0 mm' THEN 0 ELSE 1 END) * 3 AS "poèet_hod._se_srákami",
	-- maximální síla vìtru v nárazech bìhem dne
	CONCAT(MAX(CAST(REPLACE(gust,' km/h', '') AS INT)), ' km/h') AS "max_vítr_v_nárazech",
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
 /*  Pivotování life_expectancy  */
/********************************/

-- Podívám se, jak tabulka vypadá.
SELECT * FROM life_expectancy;

/*Tabulka má sloupec iso3, pøes kterı mùu pomocí LEFT JOIN tabulku pøipojit k velké vısledné tabulce. Napøed ale musím øádky s rokem 1965 a 2015 
  transponovat do sloupcù, abych od sebe mohla hodnoty snadno odeèíst */

WITH 
-- transponování
pivoted_life_expectancy AS 	-- pouiju ve WITH pro pøipojení k tabulce v_joined_cov_lt_tests_eco_co_rel_w
(
	SELECT 
        iso3,
        MAX(CASE WHEN year = 1965 THEN life_expectancy END) AS life_expectancy_1965,
        MAX(CASE WHEN year = 2015 THEN life_expectancy END) AS life_expectancy_2015
    FROM life_expectancy
    GROUP BY iso3
)
-- pøipojení tabulky k velké vısledné tabulce
SELECT
    base.*,
    ROUND(le.life_expectancy_2015 - le.life_expectancy_1965,1) AS "rozdíl_doití_2015_1965"
FROM v_joined_cov_lt_tests_eco_co_rel_w base
LEFT JOIN pivoted_life_expectancy le
  ON base.ISO = le.iso3


