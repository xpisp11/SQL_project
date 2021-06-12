  /*****************************/ 
 /*  Austr�lie, ��na, Kanada  */ 
/*****************************/
  
 /* �daje pro tyto zem� z tabulky covid19_detail_global_differences p�ipoj�m p�es UNION k tabulce covid19_basic_differences. Nejprve ale mus�m v tabulce
    covid19_detail_global_differences pou��t GROUP BY, abych hodnoty za jednotliv� provincie spojila do jednoho celkov�ho sou�tu pro ka�d� datum. */

SELECT		-- pou�iju ve WITH jako covid_Australia_Canada_China
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
  
/* P�iprav�m si nov� tabulky covid19_tests pro "problematick�" zem�, ve kter�ch ur��m jen jednu entitu. Pomoc� UNION tyto tabulky spoj�m spolu navz�jem
   a tak� s tabulkou covid19_tests bez t�chto zem�. T�m z�sk�m novou tabulku covid19_tests_new, kter� u� u t�chto "problematick�ch" zem� nebude m�t
   zdvojen� z�znamy pro ��dn� datum */

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
 /*  V�po�ty pro tvorbu dal��ch sloupc�  */
/****************************************/
  
SELECT		-- p�id�m do SELECTu pro v�pis v�sledn� tabulky
	*,
	-- bin�rn� prom�nn� pro v�kend / pracovn� den
	CASE 
		WHEN WEEKDAY(datum) IN (5, 6) THEN 1 
		ELSE 0 
		END AS "V�kend",
	-- ro�n� obdob�
	CASE 
		WHEN datum < '2020-03-20' OR (datum BETWEEN '2020-12-21' AND '2021-03-19') THEN "zima"
		WHEN datum < '2020-06-20' OR (datum BETWEEN '2021-03-20' AND '2021-06-20') THEN "jaro"
		WHEN datum < '2020-09-22' THEN "l�to"
		WHEN datum < '2020-12-21' THEN "podzim"
		END AS "Ro�n� obdob�"
FROM v_joined_covid_lookup_tests_economies_countries
-- WHERE ISO = 'USA'
;



  /**************/
 /*  religion  */
/**************/

-- Pod�v�m se, jak tabulka vypad�. Zaj�maj� m� jen �daje z roku 2020 a to pro jednotliv� zem� (ne All Countries) 
SELECT * FROM religions WHERE `year` = '2020' AND country <> 'All Countries';


-- Chyba v datech u Afghanist�nu (v roce 2020 m� b�t Other Religions 30,000)
SELECT * FROM religions WHERE country = 'Afghanistan' AND religion IN ('Folk Religions', 'Other Religions');
-- Oprav�m p��mo v tabulce:
UPDATE religions 
SET religion = 'Other Religions'
WHERE 1=1
	AND `year` = 2020
	AND country = 'Afghanistan'
	AND population = 30000;


-- Proto�e chci �daje ke ka�d� zemi m�t pouze na jednom ��dku, p�etransponuju si ��dky s jednotliv�mi n�bo�enstv�mi na sloupce.
SELECT DISTINCT religion FROM religions;

SELECT 		-- pou�iju ve WITH jako pivoted_religions pro p�ipojen� k tabulce joined_economies_countries	
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
GROUP BY country;


/* Abych mohla stanovit pod�ly p��slu�n�k� jednotliv�ch n�bo�enstv� v zemi na celkov�m obyvatelstvu, mus�m nap�ed spojit tabulku 
   pivoted_religions s tabulkou obsahuj�c� informaci o celkov� populaci zem� (nejl�pe lookup_table, kterou jsem si na za��tku ur�ila 
   jako v�choz� pro hodnoty po�tu obyvatel st�t�). 
   Nejprve ale mus�m zjistit, jak� n�zvy maj� zem� v tabulce religions (nap�. jestli �R je Czech Republic jako v tabulce economies a 
   countries nebo Czechia jako v tabulce lookuup_table a covid19_basic_differences) */

SELECT DISTINCT country FROM religions WHERE country <> 'All Countries' ORDER BY country;


/* N�zvy jsou stejn� jako v tabulk� economies a countries, tak�e tabulku religion nejprve spoj�m s joined_economies_countries
   a vytvo��m nov� VIEW v_joined_eco_co_rel, se kter�m d�le pracuju (viz. Projekt_final.sql) */




  /*******************************/
 /*  V�po�ty v tabulce weather  */
/*******************************/

SELECT DISTINCT city FROM weather ORDER BY city;
SELECT DISTINCT capital_city FROM countries ORDER BY capital_city;

-- - P�ep�u si n�zvy hlavn�ch m�st v tabulce weather (city) tak, aby byly shodn� s n�zvy v tabulce countries (capital_city).
-- -- Ud�l�m v�po�ty ve sloupc�ch s teplotou, v�trem a de�t�m 
 
SELECT		-- pou�iju ve WITH jako weather_new
	CAST(`date`AS date) AS datum,
	-- pr�m�rn� denn� (nikoli no�n�!) teplota
	-- odstranila jsem " �c", vypo��tala pr�m�r pouze z teplot pro �asy z dan�ho intervalu a zase p�ipojila " �c"
	CONCAT(ROUND((SUM((CASE WHEN `time` IN ('09:00', '12:00', '15:00', '18:00') THEN 1 ELSE 0 END) * REPLACE(temp,' �c', ''))) / 4), ' �c') AS "pr�m._denn�_teplota",	
	-- po�et hodin v dan�m dni, kdy byly sr�ky nenulov�
	SUM(CASE WHEN rain = '0.0 mm' THEN 0 ELSE 1 END) * 3 AS "po�et_hod._se_sr�kami",
	-- maxim�ln� s�la v�tru v n�razech b�hem dne
	CONCAT(MAX(CAST(REPLACE(gust,' km/h', '') AS INT)), ' km/h') AS "max_v�tr_v_n�razech",
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
 /*  Pivotov�n� life_expectancy  */
/********************************/

-- Pod�v�m se, jak tabulka vypad�.
SELECT * FROM life_expectancy;

/*Tabulka m� sloupec iso3, p�es kter� m��u pomoc� LEFT JOIN tabulku p�ipojit k velk� v�sledn� tabulce. Nap�ed ale mus�m ��dky s rokem 1965 a 2015 
  transponovat do sloupc�, abych od sebe mohla hodnoty snadno ode��st */

WITH 
-- transponov�n�
pivoted_life_expectancy AS 	-- pou�iju ve WITH pro p�ipojen� k tabulce v_joined_cov_lt_tests_eco_co_rel_w
(
	SELECT 
        iso3,
        MAX(CASE WHEN year = 1965 THEN life_expectancy END) AS life_expectancy_1965,
        MAX(CASE WHEN year = 2015 THEN life_expectancy END) AS life_expectancy_2015
    FROM life_expectancy
    GROUP BY iso3
)
-- p�ipojen� tabulky k velk� v�sledn� tabulce
SELECT
    base.*,
    ROUND(le.life_expectancy_2015 - le.life_expectancy_1965,1) AS "rozd�l_do�it�_2015_1965"
FROM v_joined_cov_lt_tests_eco_co_rel_w base
LEFT JOIN pivoted_life_expectancy le
  ON base.ISO = le.iso3


