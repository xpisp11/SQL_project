-- mezikrok: spojen� covid19_basic_diff s lookup a pak s economies a countries (bez covid19_tests)

CREATE OR REPLACE VIEW v_joined_covid_lookup_economies_countries AS
WITH 
-- Spoj�m coivd19_basic s lookup_table, t�m z�sk�m k dat�m z covid19_basic iso3
joined_covid_lookup AS	
(
	SELECT
		cbd.`date`,
		cbd.country,
		lt.iso3,
		cbd.confirmed,
		lt.population
	FROM covid19_basic_differences cbd
LEFT JOIN lookup_table lt 
  	  ON cbd.country = lt.country
  	 AND lt.province IS NULL
-- 	ORDER BY cbd.`date`
)
-- Spoj�m dv� nov� vytvo�en� tabulky dohromady
SELECT 
	base.`date` AS datum,
	base.country AS zem�,
	base.iso3 AS ISO,
	base.confirmed AS "denn�_n�rust_naka�en�ch",
	base.population AS "po�et_obyvatel",
	v.HDP,
	v.gini_koeficient,
	v.d�tsk�_�mrtnost,
	v.hustota_zalidn�n�,
	v.medi�n_v�ku_2018
FROM joined_covid_lookup base 
LEFT JOIN (SELECT * FROM v_joined_economies_countries) v 
	ON base.iso3 = v.ISO
-- ORDER BY base.country
;

-- kontrola velikosti tabulky v_joined_covid_lookup_economies_countries (t�m ov���m spojen� pomoc� LEFT JOIN)  - OK (88 452)
SELECT 
	"covid19_basic_differences" AS "Table",
	COUNT(*) AS Row_count
FROM covid19_basic_differences
UNION
SELECT 
	"joined_table" AS "Table",
	COUNT (*) AS Row_count
FROM v_joined_covid_lookup_economies_countries;


-- kontrola velikosti tabulky v_joined_covid_lookup_tests_economies_countries (t�m ov���m spojen� pomoc� LEFT JOIN)  - NE OK 89 874!!!
-- - po p�ipojen� covid19_tests do�lo k nav��en� po�tu ��dk�
SELECT 
	"covid19_basic_differences" AS "Table",
	COUNT(*) AS Row_count
FROM covid19_basic_differences
UNION
SELECT 
	"joined_table" AS "Table",
	COUNT (*) AS Row_count
FROM v_joined_covid_lookup_tests_economies_countries;


-- kontrola velikosti tabulky joined_covid_lookup	- OK (88 452)
SELECT COUNT (*)
FROM (
	SELECT
		cbd.`date`,
		cbd.country,
		lt.iso3,
		cbd.confirmed,
		lt.population
	FROM covid19_basic_differences cbd
LEFT JOIN lookup_table lt 
  	  ON cbd.country = lt.country
  	 AND lt.province IS NULL) tabulka;

  	
-- kontrola velikosti tabulky joined_covid_lookup_tests (t�m ov���m spojen� pomoc� LEFT JOIN) 	- NOT OK - vy�lo to 89 874!!!
SELECT COUNT (*)  
FROM (
	WITH 
	joined_covid_lookup AS	
	(
		SELECT
			cbd.`date`,
			cbd.country,
			lt.iso3,
			cbd.confirmed,
			lt.population
		FROM covid19_basic_differences cbd
	LEFT JOIN lookup_table lt 
  		  ON cbd.country = lt.country
  	 	 AND lt.province IS NULL
	)
		SELECT
			jcl.*,
			ct.tests_performed
		FROM joined_covid_lookup jcl 
		LEFT JOIN covid19_tests ct
			ON jcl.`date` = ct.`date`
	   	   AND jcl.iso3 = ct.ISO) tabulka
;


SELECT * FROM covid19_tests WHERE country = 'United States';   	-- 571 ��dk� (kv�li 2 entit�m testu)

SELECT * FROM covid19_basic_differences WHERE country = 'US';	 -- 468 ��dk�


-- po�et st�t�, kter� maj� v�ce ne� 1 entitu v tabulce covid19_tests (tedy v�ce ne� 1 ��dek pro 1 datum)
SELECT 
	country,
	COUNT(DISTINCT(entity)) 
FROM covid19_tests 
GROUP BY country 
HAVING COUNT(DISTINCT(entity)) > 1;	

-- p�ehled "problematick�ch" st�t� v�etn� entit
SELECT 
	country,
	entity 
FROM covid19_tests
WHERE country IN ('France', 'India', 'Italy', 'Japan', 'Poland', 'Singapore', 'Sweden', 'USA')
GROUP BY country, entity 


-- kontrola velikosti tabulky bez "problematick�ch" st�t� se 2 entitami		-- 85 441
SELECT COUNT (*)  
FROM (
	WITH 
	joined_covid_lookup AS	
	(
		SELECT
			cbd.`date`,
			cbd.country,
			lt.iso3,
			cbd.confirmed,
			lt.population
		FROM covid19_basic_differences cbd
	LEFT JOIN lookup_table lt 
  		  ON cbd.country = lt.country
  	 	 AND lt.province IS NULL
	)
		SELECT
			jcl.*,
			ct.tests_performed
		FROM joined_covid_lookup jcl 
		LEFT JOIN covid19_tests ct
			ON jcl.`date` = ct.`date`
	   	   AND jcl.iso3 = ct.ISO) tabulka	
WHERE country NOT IN ('France', 'India', 'Italy', 'Japan', 'Poland', 'Singapore', 'Sweden', 'USA')  -- tady by �el ud�lat vno�en� SELECT, ale trvalo by to pak je�t� d�l
-- ORDER BY `date`;


-- Po�et ��dk� "problematick�ch" zem�  - dohromady 3 481
SELECT 
	"France" AS "Zem�",
	COUNT(*) AS "Po�et ��dk�"
FROM covid19_tests
WHERE country = 'France'
UNION
SELECT 
	"India" AS "Zem�",
	COUNT(*) AS "Po�et ��dk�"
FROM covid19_tests
WHERE country = 'India'
UNION 
SELECT 
	"Italy" AS "Zem�",
	COUNT(*) AS "Po�et ��dk�"
FROM covid19_tests
WHERE country = 'Italy'
UNION 
SELECT 
	"Japan" AS "Zem�",
	COUNT(*) AS "Po�et ��dk�"
FROM covid19_tests
WHERE country = 'Japan'
UNION 
SELECT 
	"Poland" AS "Zem�",
	COUNT(*) AS "Po�et ��dk�"
FROM covid19_tests
WHERE country = 'Poland'
UNION 
SELECT 
	"Singapore" AS "Zem�",
	COUNT(*) AS "Po�et ��dk�"
FROM covid19_tests
WHERE country = 'Singapore'
UNION 
SELECT 
	"Sweden" AS "Zem�",
	COUNT(*) AS "Po�et ��dk�"
FROM covid19_tests
WHERE country = 'Sweden'
UNION 
SELECT 
	"United States" AS "Zem�",
	COUNT(*) AS "Po�et ��dk�"
FROM covid19_tests
WHERE country = 'United States'
;

SELECT * FROM covid19_tests WHERE country = 'France'; 
SELECT * FROM covid19_tests WHERE country = 'India'; 
SELECT * FROM covid19_tests WHERE country = 'Italy'; 
SELECT * FROM covid19_tests WHERE country = 'Japan';
SELECT * FROM covid19_tests WHERE country = 'Poland'; 
SELECT * FROM covid19_tests WHERE country = 'Singapore';	-- m� jen kumulativn� hodnoty
SELECT * FROM covid19_tests WHERE country = 'Sweden'; 	-- nepou��v� ob� entity sou�asn�, tak�e nen� probl�m se zdvojen�mi ��dky
SELECT * FROM covid19_tests WHERE country = 'United States'; 






