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
	"covid19_basic_differences" AS "Tabulka",
	COUNT(*) AS "Po�et_��dk�"
FROM covid19_basic_differences
UNION
SELECT 
	"joined_table" AS "Tabulka",
	COUNT (*) AS "Po�et_��dk�"
FROM v_joined_covid_lookup_economies_countries;


-- kontrola velikosti tabulky v_joined_covid_lookup_tests_economies_countries (t�m ov���m spojen� pomoc� LEFT JOIN)  - NE OK 89 874!!!
-- - po p�ipojen� covid19_tests do�lo k nav��en� po�tu ��dk�
SELECT 
	"covid19_basic_differences" AS "Tabulka",
	COUNT(*) AS "Po�et_��dk�"
FROM covid19_basic_differences
UNION
SELECT 
	"joined_table" AS "Tabulka",
	COUNT (*) AS "Po�et_��dk�"
FROM v_joined_covid_lookup_tests_economies_countries;


-- kontrola potenci�ln� problematick� zem� - probl�m ve sloupci entity v tabulce covid19_tests
SELECT 
	"v�echna" AS "Data",
	COUNT(`date`) AS Row_count 
FROM covid19_tests 
WHERE country = 'United States'   	-- v�c ��dk� (kv�li 2 entit�m testu)
UNION
SELECT 
	"unik�tn�" AS "Data",
	COUNT(DISTINCT(`date`)) AS Row_count
FROM covid19_tests 
WHERE country = 'United States';



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


-- v�b�r entity pro zahrnut� do nov� tabulky
SELECT * FROM covid19_tests WHERE country = 'France';	-- tests performed
SELECT * FROM covid19_tests WHERE country = 'India'; 	-- samples tested
SELECT * FROM covid19_tests WHERE country = 'Italy'; 	-- tests performed
SELECT * FROM covid19_tests WHERE country = 'Japan';	-- people tested
SELECT * FROM covid19_tests WHERE country = 'Poland'; 	-- samples tested
SELECT * FROM covid19_tests WHERE country = 'Singapore';	-- samples tested
SELECT * FROM covid19_tests WHERE country = 'Sweden'; 	-- nepou��v� ob� entity sou�asn�, tak�e nen� probl�m se zdvojen�mi ��dky
SELECT * FROM covid19_tests WHERE country = 'United States'; 	-- tests performed


-- kontrola vy�e�en� probl�mu:	-- OK
SELECT 
	"v�echna" AS "Data",
	COUNT(`date`) AS "Po�et_��dk�" 
FROM v_covid19_tests_new 
WHERE country = 'Singapore' 
UNION
SELECT 
	"unik�tn�" AS "Data",
	COUNT(DISTINCT(`date`)) AS "Po�et_��dk�"
FROM v_covid19_tests_new 
WHERE country = 'Singapore';


-- kontrola velikosti tabulky v_joined_covid_lookup_tests_economies_countries 	
SELECT 
	"covid19_basic_differences" AS "Tabulka",
	COUNT(*) AS "Po�et_��dk�"
FROM covid19_basic_differences
UNION
SELECT 
	"joined_table" AS "Tabulka",
	COUNT (*) AS "Po�et_��dk�"
FROM v_joined_covid_lookup_tests_economies_countries;	-- OK 88 452
