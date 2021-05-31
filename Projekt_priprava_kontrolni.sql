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
	"covid19_basic_differences" AS "Tabulka",
	COUNT(*) AS "Poèet_øádkù"
FROM covid19_basic_differences
UNION
SELECT 
	"joined_table" AS "Tabulka",
	COUNT (*) AS "Poèet_øádkù"
FROM v_joined_covid_lookup_economies_countries;


-- kontrola velikosti tabulky v_joined_covid_lookup_tests_economies_countries (tím ovìøím spojení pomocí LEFT JOIN)  - NE OK 89 874!!!
-- - po pøipojení covid19_tests došlo k navýšení poètu øádkù
SELECT 
	"covid19_basic_differences" AS "Tabulka",
	COUNT(*) AS "Poèet_øádkù"
FROM covid19_basic_differences
UNION
SELECT 
	"joined_table" AS "Tabulka",
	COUNT (*) AS "Poèet_øádkù"
FROM v_joined_covid_lookup_tests_economies_countries;


-- kontrola potenciálnì problematický zemí - problém ve sloupci entity v tabulce covid19_tests
SELECT 
	"všechna" AS "Data",
	COUNT(`date`) AS Row_count 
FROM covid19_tests 
WHERE country = 'United States'   	-- víc øádkù (kvùli 2 entitám testu)
UNION
SELECT 
	"unikátní" AS "Data",
	COUNT(DISTINCT(`date`)) AS Row_count
FROM covid19_tests 
WHERE country = 'United States';



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


-- výbìr entity pro zahrnutí do nové tabulky
SELECT * FROM covid19_tests WHERE country = 'France';	-- tests performed
SELECT * FROM covid19_tests WHERE country = 'India'; 	-- samples tested
SELECT * FROM covid19_tests WHERE country = 'Italy'; 	-- tests performed
SELECT * FROM covid19_tests WHERE country = 'Japan';	-- people tested
SELECT * FROM covid19_tests WHERE country = 'Poland'; 	-- samples tested
SELECT * FROM covid19_tests WHERE country = 'Singapore';	-- samples tested
SELECT * FROM covid19_tests WHERE country = 'Sweden'; 	-- nepoužívá obì entity souèasnì, takže není problém se zdvojenými øádky
SELECT * FROM covid19_tests WHERE country = 'United States'; 	-- tests performed


-- kontrola vyøešení problému:	-- OK
SELECT 
	"všechna" AS "Data",
	COUNT(`date`) AS "Poèet_øádkù" 
FROM v_covid19_tests_new 
WHERE country = 'Singapore' 
UNION
SELECT 
	"unikátní" AS "Data",
	COUNT(DISTINCT(`date`)) AS "Poèet_øádkù"
FROM v_covid19_tests_new 
WHERE country = 'Singapore';


-- kontrola velikosti tabulky v_joined_covid_lookup_tests_economies_countries 	
SELECT 
	"covid19_basic_differences" AS "Tabulka",
	COUNT(*) AS "Poèet_øádkù"
FROM covid19_basic_differences
UNION
SELECT 
	"joined_table" AS "Tabulka",
	COUNT (*) AS "Poèet_øádkù"
FROM v_joined_covid_lookup_tests_economies_countries;	-- OK 88 452
