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

SELECT * FROM v_covid19_tests_new WHERE country = 'Afghanistan'; 

  /*********************/
 /*  life_expectancy  */
/*********************/

-- Pod�v�m se, jak tabulka vypad�.
SELECT * FROM life_expectancy;

/*Tabulka m� sloupec iso3, p�es kter� m��u pomoc� LEFT JOIN tabulku p�ipojit k velk� v�sledn� tabulce. Nap�ed ale mus�m ��dky s rokem 1965 a 2015 
  transponovat do sloupc�, abych od sebe mohla hodnoty snadno ode��st */

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
-- p�ipojen� tabulky k velk� v�sledn� tabulce
SELECT
    base.*,
    ROUND(le.life_expectancy_2015 - le.life_expectancy_1965,1) AS "rozd�l_do�it�_2015_1965"
FROM v_joined_cov_lt_tests_eco_co_rel_w base
LEFT JOIN pivoted_life_expectancy le
  ON base.ISO = le.iso3
WHERE base.ISO = 'CZE'


  /**************/
 /*  religion  */
/**************/
-- Pod�v�m se, jak tabulka vypad�. Zaj�maj� m� jen �daje z roku 2020 a to pro jednotliv� zem� (ne All Countries) 
SELECT * FROM religions WHERE `year` = '2020' AND country <> 'All Countries';

/* Abych mohla stanovit pod�ly p��slu�n�k� jednotliv�ch n�bo�enstv� v zemi na celkov�m obyvatelstvu, mus�m nap�ed spojit tabulku religion s tabulkou
   obsahuj�c� informaci o celkov� populaci zem� (nejl�pe lookup_table, kterou jsem si na za��tku ur�ila jako v�choz� pro hodnoty po�tu obyvatel st�t�). 
   Zjist�m, jak� n�zvy maj� zem� v tabulce (nap�. jestli �R je Czech Republic jako v tabulce economies a countries nebo Czechia jako v tabulce 
   lookuup_table a covid19_basic_differences) */

SELECT DISTINCT country FROM religions WHERE country <> 'All Countries' ORDER BY country;

/* N�zvy jsou stejn� jako v tabulk� economies a countries, tak�e tabulku religion nejprve p�ipoj�m k v_joined_economies_countries
   a vytvo��m nov� VIEW v_joined_eco_co_rel, se kter�m d�le pracuju */

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
ON base.zem� = r.country
;

SELECT * FROM v_joined_economies_countries 
