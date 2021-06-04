-- mezikrok: spojení covid19_basic_diff s lookup a pak s economies a countries (bez covid19_tests)

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
-- Spojím covid_Australia_Canada_China (tj. rozšíøenou tabulku covid19_basic_differences) s lookup_table, tím získám k datùm o confirmed také iso3
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
-- Spojím dvì novì vytvoøené tabulky dohromady
SELECT 
	base.`date` AS datum,
	base.country AS zemì,
	base.iso3 AS ISO,
	base.confirmed AS "denní_nárust_nakažených",
	base.population AS "poèet_obyvatel",
	-- 4. Pøidání nových sloupcù: binární promìnná pro víkend / pracovní den
	CASE 
		WHEN WEEKDAY(base.`date`) IN (5, 6) THEN 1 
		ELSE 0 
		END AS "víkend",
	-- 4. Pøidání nových sloupcù: roèní období
	CASE 
		WHEN base.`date` < '2020-03-20' OR (base.`date` BETWEEN '2020-12-21' AND '2021-03-19') THEN "zima"
		WHEN base.`date` < '2020-06-20' OR (base.`date` BETWEEN '2021-03-20' AND '2021-06-20') THEN "jaro"
		WHEN base.`date` < '2020-09-22' THEN "léto"
		WHEN base.`date` < '2020-12-21' THEN "podzim"
		END AS "roèní období",
	-- ve výsledné tabulce jsem ještì místo celkového HDP dopoèítala HDP na obyvatele 
	ROUND(v.HDP/base.population) AS "HDP_na_obyvatele",		
	v.gini_koeficient,
	v.`dìtská_úmrtnost`,
	v.`hustota_zalidnìní`,
	v.`medián_vìku_2018`,
	-- ve výsledné tabulce jsem ještì dopoèítala podíl pøíslušníkù jednotlivých náboženství na celkové populaci zemì
	CONCAT(ROUND(v.`køesanství`/base.population * 100,1), ' %') AS "podíl_køesanù",
	CONCAT(ROUND(v.`islám`/base.population * 100,1), ' %') AS "podíl_pøíslušníkù_islámu",
	CONCAT(ROUND(v.`hinduismus`/base.population * 100,1), ' %') AS "podíl_hinduistù",
	CONCAT(ROUND(v.`budhismus`/base.population * 100,1), ' %') AS "podíl_budhistù",
	CONCAT(ROUND(v.`judaismus`/base.population * 100,1), ' %') AS "podíl_židù",
	CONCAT(ROUND(v.`nepøidružená_náboženství`/base.population * 100,1), ' %') AS "podíl_pøíslušníkù_nepøidruž._náb.",
	CONCAT(ROUND(v.`lidová_náboženství`/base.population * 100,1), ' %') AS "podíl_pøíslušníkù_lid._náb.",
	CONCAT(ROUND(v.`jiná náboženství`/base.population * 100,1), ' %') AS "podíl_pøíslušníkù_jiných_náb."	
FROM joined_covid_lookup base 
LEFT JOIN (SELECT * FROM v_joined_eco_co_rel) v 
	ON base.iso3 = v.ISO
;



-- kontrola velikosti tabulky v_joined_cov_lt_eco_co_rel (tím ovìøím spojení pomocí LEFT JOIN)  	- OK (pùvodnì 88 452, po pøidání Austrálie, Èíny a Kanady 89 798)
SELECT 
	"covid19_basic_differences" AS "Tabulka",
	COUNT(*) AS "Poèet_øádkù"
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
	COUNT (*) AS "Poèet_øádkù"
FROM v_joined_cov_lt_eco_co_rel;



-- kontrola velikosti tabulky v_joined_co_lt_tests_eco_co_rel (tím ovìøím spojení pomocí LEFT JOIN)  	- pùvodnì vyšlo 89 874 místo 88 452 (bez Austrálie, Èíny a Kanady)
-- - po pøipojení covid19_tests došlo k navýšení poètu øádkù
SELECT 
	"covid19_basic_differences" AS "Tabulka",
	COUNT(*) AS "Poèet_øádkù"
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
	COUNT (*) AS "Poèet_øádkù"
FROM v_joined_cov_lt_tests_eco_co_rel;



-- kontrola potenciálnì problematických zemí - problém ve sloupci entity v tabulce covid19_tests
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


-- kontrola velikosti tabulky v_joined_cov_lt_tests_eco_co_rel 			OK (pùvodnì 88 452, novì po pøidání Austrálie, Èíny a Kanady 89 798)
SELECT 
	"covid19_basic_differences" AS "Tabulka",
	COUNT(*) AS "Poèet_øádkù"
FROM covid19_basic_differences
UNION
SELECT 
	"joined_table" AS "Tabulka",
	COUNT (*) AS "Poèet_øádkù"
FROM v_joined_cov_lt_tests_eco_co_rel;	


-- kontrola velikosti tabulky v_joined_cov_lt_tests_eco_co_rel_w		OK (pùvodnì 88 452, novì po pøidání Austrálie, Èíny a Kanady 89 798)
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



