  /***********************/
 /*  covid19_tests_new  */ 
/***********************/
  
/* Pøipravím si nové tabulky covid19_tests pro "problematické" zemì, ve kterých urèím jen jednu entitu. Pomocí UNION tyto tabulky spojím spolu navzájem
   a také s tabulkou covid19_tests bez tìchto zemí. Tím získám novou tabulku covid19_tests_new, která už u tìchto "problematických" zemí nebude mít
   zdvojené záznamy pro žádné datum */

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

SELECT * FROM v_covid19_tests_new WHERE country = 'Afghanistan'; 

  /*********************/
 /*  life_expectancy  */
/*********************/

-- Podívám se, jak tabulka vypadá.
SELECT * FROM life_expectancy;

/*Tabulka má sloupec iso3, pøes který mùžu pomocí LEFT JOIN tabulku pøipojit k velké výsledné tabulce. Napøed ale musím øádky s rokem 1965 a 2015 
  transponovat do sloupcù, abych od sebe mohla hodnoty snadno odeèíst */

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
-- pøipojení tabulky k velké výsledné tabulce
SELECT
    base.*,
    ROUND(le.life_expectancy_2015 - le.life_expectancy_1965,1) AS "rozdíl_dožití_2015_1965"
FROM v_joined_cov_lt_tests_eco_co_rel_w base
LEFT JOIN pivoted_life_expectancy le
  ON base.ISO = le.iso3
WHERE base.ISO = 'CZE'


  /**************/
 /*  religion  */
/**************/
-- Podívám se, jak tabulka vypadá. Zajímají mì jen údaje z roku 2020 a to pro jednotlivé zemì (ne All Countries) 
SELECT * FROM religions WHERE `year` = '2020' AND country <> 'All Countries';

/* Abych mohla stanovit podíly pøíslušníkù jednotlivých náboženství v zemi na celkovém obyvatelstvu, musím napøed spojit tabulku religion s tabulkou
   obsahující informaci o celkové populaci zemì (nejlépe lookup_table, kterou jsem si na zaèátku urèila jako výchozí pro hodnoty poètu obyvatel státù). 
   Zjistím, jaké názvy mají zemì v tabulce (napø. jestli ÈR je Czech Republic jako v tabulce economies a countries nebo Czechia jako v tabulce 
   lookuup_table a covid19_basic_differences) */

SELECT DISTINCT country FROM religions WHERE country <> 'All Countries' ORDER BY country;

/* Názvy jsou stejné jako v tabulká economies a countries, takže tabulku religion nejprve pøipojím k v_joined_economies_countries
   a vytvoøím nové VIEW v_joined_eco_co_rel, se kterým dále pracuju */

WITH
religion AS
( 
	SELECT
		country,
		religion,
		population
	FROM religions 
	WHERE 1=1
		AND `year` = '2020' 
		AND country <> 'All Countries'
		AND population > 0
)
SELECT
	r.*,
	base.*
FROM v_joined_economies_countries base
LEFT JOIN religion r 
ON base.zemì = r.country
;

SELECT * FROM v_joined_economies_countries 
