-- Vytvoreni VIEW pro pripojeni Australie, Ciny a Kanady ke covid19_basic_differences (pouze pro kontrolu, v projektu neni)

CREATE OR REPLACE VIEW v_covid_Australia_Canada_China AS
WITH 
-- Vytvoreni nove tabulky pro Cinu z covid19_detail_global_differences
China_confirmed AS
(	
	SELECT 
		`date`,
		country, 
		sum(confirmed) AS confirmed
	FROM covid19_detail_global_differences
	WHERE country LIKE '%China%' 
	GROUP BY `date`
	ORDER BY `date`
),
China_deaths AS
(
	SELECT 
		`date`,
		country, 
		sum(deaths) AS deaths
	FROM covid19_detail_global_differences
	WHERE country LIKE '%China%' 
	GROUP BY `date`
	ORDER BY `date`
),
China_recovered AS
(
	SELECT 
		`date`,
		country, 
		sum(recovered) AS recovered
	FROM covid19_detail_global_differences
	WHERE country LIKE '%China%' 
	GROUP BY `date`
	ORDER BY `date`
),
China_joined AS
(	
	SELECT
		c.`date`,
		c.country,
		COALESCE(SUM(CASE WHEN c.country = 'Mainland China' THEN c.confirmed END), 0) AS Mainland_China_confirmed,
		COALESCE(SUM(CASE WHEN c.country = 'China' THEN c.confirmed END), 0) AS China_confirmed,
		COALESCE(SUM(CASE WHEN c.country = 'Mainland China' THEN d.deaths END), 0) AS Mainland_China_deaths,
		COALESCE(SUM(CASE WHEN c.country = 'China' THEN d.deaths END), 0) AS China_deaths,
		COALESCE(SUM(CASE WHEN c.country = 'Mainland China' THEN r.recovered END), 0) AS Mainland_China_recovered,
		COALESCE(SUM(CASE WHEN c.country = 'China' THEN r.recovered END), 0) AS China_recovered
	FROM China_confirmed c
	LEFT JOIN China_deaths d
		 ON c.`date` = d.`date`
		AND c.country = d.country
	LEFT JOIN China_recovered r 
		 ON d.`date` = r.`date`
		AND d.country = r.country
	GROUP BY c.`date`, c.country
),
China_final AS
(
	SELECT
		`date`,
		'China' AS country,
		(Mainland_China_confirmed + China_confirmed) AS confirmed,
		(Mainland_China_deaths + China_deaths) AS deaths,
		(Mainland_China_recovered + China_recovered) AS recovered
	FROM China_joined
)
SELECT		
	`date`,
	country,
	SUM(confirmed) AS confirmed,
	SUM(deaths) AS deaths,
	SUM(recovered) AS recovered 
FROM covid19_detail_global_differences 
WHERE country IN ('Australia', 'Canada') 
GROUP BY country, `date`
UNION 
SELECT *
FROM China_final
UNION
SELECT 
	*
FROM covid19_basic_differences;
	
	


	
-- mezikrok: spojeni covid19_basic_diff s lookup a pak s economies a countries (bez covid19_tests)

CREATE OR REPLACE VIEW v_joined_cov_lt_eco_co_rel AS
WITH 
-- Vytvoreni nove tabulky pro Cinu z covid19_detail_global_differences
covid_Australia_Canada_China AS
(
	SELECT		
		*
	FROM v_covid_australia_canada_china
),
-- Spojim covid_Australia_Canada_China (tj. rozsirenou tabulku covid19_basic_differences) s lookup_table, tim ziskam k datum o confirmed take iso3
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
-- Spojim dve nove vytvorene tabulky dohromady
SELECT 
	base.`date` AS datum,
	base.country AS zemì,
	base.iso3 AS ISO,
	base.confirmed AS "denni_narust_nakazenych",
	base.population AS "pocet_obyvatel",
	-- 4. Pridani novych sloupcu: binarni promenna pro vikend / pracovni den
	CASE 
		WHEN WEEKDAY(base.`date`) IN (5, 6) THEN 1 
		ELSE 0 
		END AS "vikend",
	-- 4. Pridani novych sloupcu: rocni obdobi
	CASE 
		WHEN base.`date` < '2020-03-20' OR (base.`date` BETWEEN '2020-12-21' AND '2021-03-19') THEN "3"		-- zima
		WHEN base.`date` < '2020-06-20' OR (base.`date` BETWEEN '2021-03-20' AND '2021-06-20') THEN "0"		-- jaro
		WHEN base.`date` < '2020-09-22' THEN "1"		-- leto
		WHEN base.`date` < '2020-12-21' THEN "2"		-- podzim
		END AS "rocni_obdobi",
	-- ve vysledne tabulce jsem jeste misto celkoveho HDP dopocitala HDP na obyvatele 
	ROUND(v.HDP/base.population) AS "HDP_na_obyvatele",		
	v.gini_koeficient,
	v.`detska_umrtnost`,
	v.`hustota_zalidneni`,
	v.`median_veku_2018`,
	-- ve vysledne tabulce jsem jeste dopocitala podil prislusniku jednotlivych nabozenstvi na celkove populaci zeme
	CONCAT(ROUND(v.`krestanstvi`/base.population * 100,1), ' %') AS "podil_krestanu",
	CONCAT(ROUND(v.`islam`/base.population * 100,1), ' %') AS "podil_prislusniku_islamu",
	CONCAT(ROUND(v.`hinduismus`/base.population * 100,1), ' %') AS "podil_hinduistu",
	CONCAT(ROUND(v.`budhismus`/base.population * 100,1), ' %') AS "podil_budhistu",
	CONCAT(ROUND(v.`judaismus`/base.population * 100,1), ' %') AS "podil_zidu",
	CONCAT(ROUND(v.`nepridruzena_nabozenstvi`/base.population * 100,1), ' %') AS "podil_prislusniku_nepridruz_nab",
	CONCAT(ROUND(v.`lidova_nabozenstvi`/base.population * 100,1), ' %') AS "podil_prislusniku_lid_nab",
	CONCAT(ROUND(v.`jina_nabozenstvi`/base.population * 100,1), ' %') AS "podil_prislusniku_jinych_nab"	
FROM joined_covid_lookup base 
LEFT JOIN (SELECT * FROM v_joined_eco_co_rel) v 
	ON base.iso3 = v.ISO
;



-- kontrola velikosti tabulky v_joined_cov_lt_eco_co_rel (tim overim spojeni pomocí LEFT JOIN)  	- OK (puvodne 88 452, po pridani Australie, Ciny a Kanady 89 847)
SELECT 
	"covid19_basic_differences" AS "Tabulka",
	COUNT(*) AS "Pocet_radku"
FROM v_covid_australia_canada_china  -- tabulka covid19_basic_differences rozsirena o Australii, Cinu a Kanadu
UNION
SELECT 
	"joined_table" AS "Tabulka",
	COUNT (*) AS "Pocet_radku"
FROM v_joined_cov_lt_eco_co_rel;



-- kontrola velikosti tabulky v_joined_co_lt_tests_eco_co_rel (tim overim spojeni pomocí LEFT JOIN)  	- puvodne vyslo 89 874 misto 88 452 (bez Australie, Ciny a Kanady)
-- - po pripojeni covid19_tests doslo k navyseni poctu radku
SELECT 
	"covid19_basic_differences" AS "Tabulka",
	COUNT(*) AS "Pocet_radku"
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
	COUNT (*) AS "Pocet_radku"
FROM v_joined_cov_lt_tests_eco_co_rel;



-- kontrola potencialne problematickych zemi - problem ve sloupci entity v tabulce covid19_tests
SELECT 
	"vsechna" AS "Data",
	COUNT(`date`) AS Row_count 
FROM covid19_tests 
WHERE country = 'United States'   	-- vic radku (kvuli 2 entitam testu)
UNION
SELECT 
	"unikatni" AS "Data",
	COUNT(DISTINCT(`date`)) AS Row_count
FROM covid19_tests 
WHERE country = 'United States';



-- pocet statu, ktere maji vice nez 1 entitu v tabulce covid19_tests (tedy vice nez 1 radek pro 1 datum)
SELECT 
	country,
	COUNT(DISTINCT(entity)) 
FROM covid19_tests 
GROUP BY country 
HAVING COUNT(DISTINCT(entity)) > 1;	

-- prehled "problematickych" statu vcetne entit
SELECT 
	country,
	entity 
FROM covid19_tests
WHERE country IN ('France', 'India', 'Italy', 'Japan', 'Poland', 'Singapore', 'Sweden', 'USA')
GROUP BY country, entity 


-- vyber entity pro zahrnuti do nove tabulky
SELECT * FROM covid19_tests WHERE country = 'France';	-- tests performed
SELECT * FROM covid19_tests WHERE country = 'India'; 	-- samples tested
SELECT * FROM covid19_tests WHERE country = 'Italy'; 	-- tests performed
SELECT * FROM covid19_tests WHERE country = 'Japan';	-- people tested
SELECT * FROM covid19_tests WHERE country = 'Poland'; 	-- samples tested
SELECT * FROM covid19_tests WHERE country = 'Singapore';	-- samples tested
SELECT * FROM covid19_tests WHERE country = 'Sweden'; 	-- nepouziva obe entity soucasne, takze neni problem se zdvojenymi radky
SELECT * FROM covid19_tests WHERE country = 'United States'; 	-- tests performed


-- kontrola vyreseni problemu:	-- OK
SELECT 
	"vsechna" AS "Data",
	COUNT(`date`) AS "Pocet_radku" 
FROM v_covid19_tests_new 
WHERE country = 'Singapore' 
UNION
SELECT 
	"unikatni" AS "Data",
	COUNT(DISTINCT(`date`)) AS "Pocet_radku"
FROM v_covid19_tests_new 
WHERE country = 'Singapore';


-- kontrola velikosti tabulky v_joined_cov_lt_tests_eco_co_rel 			OK (puvodne 88 452, nove po pridani Australie, Ciny a Kanady 89 847)
SELECT 
	"covid19_basic_differences" AS "Tabulka",
	COUNT(*) AS "Pocet_radku"
FROM v_covid_australia_canada_china  -- tabulka covid19_basic_differences rozsirena o Australii, Cinu a Kanadu
UNION
SELECT 
	"joined_table" AS "Tabulka",
	COUNT (*) AS "Pocet_radku"
FROM v_joined_cov_lt_tests_eco_co_rel;	


-- kontrola velikosti tabulky v_joined_cov_lt_tests_eco_co_rel_w		OK (puvodne 88 452, nove po pridani Australie, Ciny a Kanady 89 847)
SELECT COUNT(*) FROM v_joined_cov_lt_tests_eco_co_rel_w;			


-- kontrola poctu radku po pridani Australie, Ciny, Kanady
SELECT			-- OK (1 395 + 88 452 = 89 847) 
	COUNT(*)
FROM (
	WITH 
	China_confirmed AS
	(	
		SELECT 
			`date`,
			country, 
			sum(confirmed) AS confirmed
		FROM covid19_detail_global_differences
		WHERE country LIKE '%China%' 
		GROUP BY `date`
		ORDER BY `date`
	),
	China_deaths AS
	(
		SELECT 
			`date`,
			country, 
			sum(deaths) AS deaths
		FROM covid19_detail_global_differences
		WHERE country LIKE '%China%' 
		GROUP BY `date`
		ORDER BY `date`
	),
	China_recovered AS
	(
		SELECT 
			`date`,
			country, 
			sum(recovered) AS recovered
		FROM covid19_detail_global_differences
		WHERE country LIKE '%China%' 
		GROUP BY `date`
		ORDER BY `date`
	),
	China_joined AS
	(	
		SELECT
			c.`date`,
			c.country,
			COALESCE(SUM(CASE WHEN c.country = 'Mainland China' THEN c.confirmed END), 0) AS Mainland_China_confirmed,
			COALESCE(SUM(CASE WHEN c.country = 'China' THEN c.confirmed END), 0) AS China_confirmed,
			COALESCE(SUM(CASE WHEN c.country = 'Mainland China' THEN d.deaths END), 0) AS Mainland_China_deaths,
			COALESCE(SUM(CASE WHEN c.country = 'China' THEN d.deaths END), 0) AS China_deaths,
			COALESCE(SUM(CASE WHEN c.country = 'Mainland China' THEN r.recovered END), 0) AS Mainland_China_recovered,
			COALESCE(SUM(CASE WHEN c.country = 'China' THEN r.recovered END), 0) AS China_recovered
		FROM China_confirmed c
		LEFT JOIN China_deaths d
			 ON c.`date` = d.`date`
			AND c.country = d.country
		LEFT JOIN China_recovered r 
			 ON d.`date` = r.`date`
			AND d.country = r.country
		GROUP BY c.`date`, c.country
	),
	China_final AS
	(
		SELECT
			`date`,
			'China' AS country,
			(Mainland_China_confirmed + China_confirmed) AS confirmed,
			(Mainland_China_deaths + China_deaths) AS deaths,
			(Mainland_China_recovered + China_recovered) AS recovered
		FROM China_joined
	)
	SELECT		
		`date`,
		country,
		SUM(confirmed) AS confirmed,
		SUM(deaths) AS deaths,
		SUM(recovered) AS recovered 
	FROM covid19_detail_global_differences 
	WHERE country IN ('Australia', 'Canada') 
	GROUP BY country, `date`
	UNION 
	SELECT *
	FROM China_final) tabulka;
