-- mezikrok: spojen� covid19_basic_diff s lookup a pak s economies a countries (bez covid19_tests)

CREATE OR REPLACE VIEW v_joined_cov_lt_eco_co_rel AS
WITH 
covid_Australia_Canada_China AS
(
	SELECT		
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
	FROM covid19_basic_differences
),
-- Spoj�m covid_Australia_Canada_China (tj. roz���enou tabulku covid19_basic_differences) s lookup_table, t�m z�sk�m k dat�m o confirmed tak� iso3
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
)
-- Spoj�m dv� nov� vytvo�en� tabulky dohromady
SELECT 
	base.`date` AS datum,
	base.country AS zem�,
	base.iso3 AS ISO,
	base.confirmed AS "denn�_n�rust_naka�en�ch",
	base.population AS "po�et_obyvatel",
	-- 4. P�id�n� nov�ch sloupc�: bin�rn� prom�nn� pro v�kend / pracovn� den
	CASE 
		WHEN WEEKDAY(base.`date`) IN (5, 6) THEN 1 
		ELSE 0 
		END AS "v�kend",
	-- 4. P�id�n� nov�ch sloupc�: ro�n� obdob�
	CASE 
		WHEN base.`date` < '2020-03-20' OR (base.`date` BETWEEN '2020-12-21' AND '2021-03-19') THEN "zima"
		WHEN base.`date` < '2020-06-20' OR (base.`date` BETWEEN '2021-03-20' AND '2021-06-20') THEN "jaro"
		WHEN base.`date` < '2020-09-22' THEN "l�to"
		WHEN base.`date` < '2020-12-21' THEN "podzim"
		END AS "ro�n� obdob�",
	-- ve v�sledn� tabulce jsem je�t� m�sto celkov�ho HDP dopo��tala HDP na obyvatele 
	ROUND(v.HDP/base.population) AS "HDP_na_obyvatele",		
	v.gini_koeficient,
	v.`d�tsk�_�mrtnost`,
	v.`hustota_zalidn�n�`,
	v.`medi�n_v�ku_2018`,
	-- ve v�sledn� tabulce jsem je�t� dopo��tala pod�l p��slu�n�k� jednotliv�ch n�bo�enstv� na celkov� populaci zem�
	CONCAT(ROUND(v.`k�es�anstv�`/base.population * 100,1), ' %') AS "pod�l_k�es�an�",
	CONCAT(ROUND(v.`isl�m`/base.population * 100,1), ' %') AS "pod�l_p��slu�n�k�_isl�mu",
	CONCAT(ROUND(v.`hinduismus`/base.population * 100,1), ' %') AS "pod�l_hinduist�",
	CONCAT(ROUND(v.`budhismus`/base.population * 100,1), ' %') AS "pod�l_budhist�",
	CONCAT(ROUND(v.`judaismus`/base.population * 100,1), ' %') AS "pod�l_�id�",
	CONCAT(ROUND(v.`nep�idru�en�_n�bo�enstv�`/base.population * 100,1), ' %') AS "pod�l_p��slu�n�k�_nep�idru�._n�b.",
	CONCAT(ROUND(v.`lidov�_n�bo�enstv�`/base.population * 100,1), ' %') AS "pod�l_p��slu�n�k�_lid._n�b.",
	CONCAT(ROUND(v.`jin� n�bo�enstv�`/base.population * 100,1), ' %') AS "pod�l_p��slu�n�k�_jin�ch_n�b."	
FROM joined_covid_lookup base 
LEFT JOIN (SELECT * FROM v_joined_eco_co_rel) v 
	ON base.iso3 = v.ISO
;



-- kontrola velikosti tabulky v_joined_cov_lt_eco_co_rel (t�m ov���m spojen� pomoc� LEFT JOIN)  	- OK (p�vodn� 88 452, po p�id�n� Austr�lie, ��ny a Kanady 89 798)
SELECT 
	"covid19_basic_differences" AS "Tabulka",
	COUNT(*) AS "Po�et_��dk�"
FROM (
SELECT		
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
	FROM covid19_basic_differences) tabulka
UNION
SELECT 
	"joined_table" AS "Tabulka",
	COUNT (*) AS "Po�et_��dk�"
FROM v_joined_cov_lt_eco_co_rel;



-- kontrola velikosti tabulky v_joined_co_lt_tests_eco_co_rel (t�m ov���m spojen� pomoc� LEFT JOIN)  	- p�vodn� vy�lo 89 874 m�sto 88 452 (bez Austr�lie, ��ny a Kanady)
-- - po p�ipojen� covid19_tests do�lo k nav��en� po�tu ��dk�
SELECT 
	"covid19_basic_differences" AS "Tabulka",
	COUNT(*) AS "Po�et_��dk�"
FROM (
	SELECT		
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
		FROM covid19_basic_differences) tabulka
UNION
SELECT 
	"joined_table" AS "Tabulka",
	COUNT (*) AS "Po�et_��dk�"
FROM v_joined_cov_lt_tests_eco_co_rel;



-- kontrola potenci�ln� problematick�ch zem� - probl�m ve sloupci entity v tabulce covid19_tests
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


-- kontrola velikosti tabulky v_joined_cov_lt_tests_eco_co_rel 			OK (p�vodn� 88 452, nov� po p�id�n� Austr�lie, ��ny a Kanady 89 798)
SELECT 
	"covid19_basic_differences" AS "Tabulka",
	COUNT(*) AS "Po�et_��dk�"
FROM covid19_basic_differences
UNION
SELECT 
	"joined_table" AS "Tabulka",
	COUNT (*) AS "Po�et_��dk�"
FROM v_joined_cov_lt_tests_eco_co_rel;	


-- kontrola velikosti tabulky v_joined_cov_lt_tests_eco_co_rel_w		OK (p�vodn� 88 452, nov� po p�id�n� Austr�lie, ��ny a Kanady 89 798)
SELECT COUNT(*) FROM v_joined_cov_lt_tests_eco_co_rel_w;			


SELECT 
	COUNT(*)
FROM (
	SELECT
		`date`,
		country,
		SUM(confirmed) AS confirmed,
		SUM(deaths) AS deaths,
		SUM(recovered) AS recovered 
	FROM covid19_detail_global_differences 
	WHERE country IN ('Australia', 'Canada', 'China') 
	GROUP BY country, `date`) tabulka;



