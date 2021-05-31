-- mezikrok: spojení covid19_basic_diff s lookup a pak s economies a countries (bez covid19_tests)

CREATE OR REPLACE VIEW v_joined_covid_lookup_economies_countries AS
WITH 
-- Spojím coivd19_basic s lookup_table, tím získám k datùm z covid19_basic iso3
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
-- Spojím dvì novì vytvoøené tabulky dohromady
SELECT 
	base.`date` AS datum,
	base.country AS zemì,
	base.iso3 AS ISO,
	base.confirmed AS "denní_nárust_nakažených",
	base.population AS "poèet_obyvatel",
	v.HDP,
	v.gini_koeficient,
	v.dìtská_úmrtnost,
	v.hustota_zalidnìní,
	v.medián_vìku_2018
FROM joined_covid_lookup base 
LEFT JOIN (SELECT * FROM v_joined_economies_countries) v 
	ON base.iso3 = v.ISO
-- ORDER BY base.country
;

-- kontrola velikosti tabulky v_joined_covid_lookup_economies_countries (tím ovìøím spojení pomocí LEFT JOIN)  - OK (88 452)
SELECT 
	"covid19_basic_differences" AS "Table",
	COUNT(*) AS Row_count
FROM covid19_basic_differences
UNION
SELECT 
	"joined_table" AS "Table",
	COUNT (*) AS Row_count
FROM v_joined_covid_lookup_economies_countries;


-- kontrola velikosti tabulky v_joined_covid_lookup_tests_economies_countries (tím ovìøím spojení pomocí LEFT JOIN)  - NE OK 89 874!!!
-- - po pøipojení covid19_tests došlo k navýšení poètu øádkù
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

  	
-- kontrola velikosti tabulky joined_covid_lookup_tests (tím ovìøím spojení pomocí LEFT JOIN) 	- NOT OK - vyšlo to 89 874!!!
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


SELECT * FROM covid19_tests WHERE country = 'United States';   	-- 571 øádkù (kvùli 2 entitám testu)

SELECT * FROM covid19_basic_differences WHERE country = 'US';	 -- 468 øádkù


-- poèet státù, které mají více než 1 entitu v tabulce covid19_tests (tedy více než 1 øádek pro 1 datum)
SELECT 
	country,
	COUNT(DISTINCT(entity)) 
FROM covid19_tests 
GROUP BY country 
HAVING COUNT(DISTINCT(entity)) > 1;	

-- pøehled "problematických" státù vèetnì entit
SELECT 
	country,
	entity 
FROM covid19_tests
WHERE country IN ('France', 'India', 'Italy', 'Japan', 'Poland', 'Singapore', 'Sweden', 'USA')
GROUP BY country, entity 


-- kontrola velikosti tabulky bez "problematických" státù se 2 entitami		-- 85 441
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
WHERE country NOT IN ('France', 'India', 'Italy', 'Japan', 'Poland', 'Singapore', 'Sweden', 'USA')  -- tady by šel udìlat vnoøený SELECT, ale trvalo by to pak ještì dýl
-- ORDER BY `date`;


-- Poèet øádkù "problematických" zemí  - dohromady 3 481
SELECT 
	"France" AS "Zemì",
	COUNT(*) AS "Poèet øádkù"
FROM covid19_tests
WHERE country = 'France'
UNION
SELECT 
	"India" AS "Zemì",
	COUNT(*) AS "Poèet øádkù"
FROM covid19_tests
WHERE country = 'India'
UNION 
SELECT 
	"Italy" AS "Zemì",
	COUNT(*) AS "Poèet øádkù"
FROM covid19_tests
WHERE country = 'Italy'
UNION 
SELECT 
	"Japan" AS "Zemì",
	COUNT(*) AS "Poèet øádkù"
FROM covid19_tests
WHERE country = 'Japan'
UNION 
SELECT 
	"Poland" AS "Zemì",
	COUNT(*) AS "Poèet øádkù"
FROM covid19_tests
WHERE country = 'Poland'
UNION 
SELECT 
	"Singapore" AS "Zemì",
	COUNT(*) AS "Poèet øádkù"
FROM covid19_tests
WHERE country = 'Singapore'
UNION 
SELECT 
	"Sweden" AS "Zemì",
	COUNT(*) AS "Poèet øádkù"
FROM covid19_tests
WHERE country = 'Sweden'
UNION 
SELECT 
	"United States" AS "Zemì",
	COUNT(*) AS "Poèet øádkù"
FROM covid19_tests
WHERE country = 'United States'
;

SELECT * FROM covid19_tests WHERE country = 'France'; 
SELECT * FROM covid19_tests WHERE country = 'India'; 
SELECT * FROM covid19_tests WHERE country = 'Italy'; 
SELECT * FROM covid19_tests WHERE country = 'Japan';
SELECT * FROM covid19_tests WHERE country = 'Poland'; 
SELECT * FROM covid19_tests WHERE country = 'Singapore';	-- má jen kumulativní hodnoty
SELECT * FROM covid19_tests WHERE country = 'Sweden'; 	-- nepoužívá obì entity souèasnì, takže není problém se zdvojenými øádky
SELECT * FROM covid19_tests WHERE country = 'United States'; 






