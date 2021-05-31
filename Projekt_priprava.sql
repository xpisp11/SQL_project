-- 1. Studium v�ech tabulek, jejich sloupc�, kl��� pro JOINy s jin�mi tabulkami
 
SELECT * FROM countries;	-- country, population, population density, median age 2018, iso 3 (toto�n� s ISO z covid19_test)
SELECT * FROM economies; 	-- country, year, GDP, population (2019), gini (r�zn� roky), mortality under 5 (2019)
SELECT * FROM life_expectancy;		-- country, iso3, year, life expectancy	
SELECT * FROM religions;	-- year (vz�t 2020), country, religion (n�bo�enstv� v dan� zemi), population (p��slu�n�ci dan�ho n�bo�enstv�)
SELECT * FROM covid19_basic_differences;  -- denn� p��rustky ve v�ech zem�ch (country, date)
SELECT * FROM covid19_tests;		-- denn� a kumulativn� po�ty proveden�ch test� ve v�ech zem�ch (country, date, ISO)
SELECT * FROM weather;		-- date, time, temp, gust, rain 
SELECT * FROM lookup_table;		-- country, iso3, population


 -- 2. �e�en� "issues" v datech �i tabulk�ch

/* GDP, gini koeficient a mortality under 5:
   Tyto prom�nn� jsou v r�zn�ch zem�ch zad�v�ny r�zn� (v n�kter�ch zem�ch je nejaktu�ln�j�� hodnota z roku 2018, v jin�ch t�eba i z 90. let), 
   bude tedy pot�eba pro ka�dou zemi vz�t hodnotu z jin�ho roku */
SELECT 		
	country,
	MAX(year),
	gini
FROM economies				
WHERE gini IS NOT NULL		
GROUP BY country;	

/* population:
   V tabulce countries a lookup_table je population statick� (nev�m, ze kter�ho roku), v tabulce economies dynamick� (vypln�n� do roku 2019, v roce 2020 NULL).
   Mus�m se rozhodnout, ze kter� tabulky �daj k population pou�iju.

Spoj�m si tabulky dohromady p�es INNER JOIN a z hodnot vid�m, �e �daje k population z tabulky countries jsou z roku 2018, �daje z tabulky lookup_table 
pravd�podobn� z roku 2020 (jsou v�t�� ne� �daje z economies z roku 2019). Pro r�mcovou kontrolu jsem si je�t� doplnila sloupce s meziro�n�m r�stem populace,
ve kter�ch vid�m, �e r�st 2019/2018 a 2020/2019 je v n�hodn� vybran�ch zem�ch velmi podobn�, tak�e �daje z lookup_table jsou s velkou pravd�podobnost� z 2020.
�daj k celkov� populaci tedy vezmu z tabulky lookup_table. */

SELECT 
	e.country,
	e.`year`,
	c.population AS population_countries,
	e.population AS population_economies,
	ROUND((e.population/c.population-1) * 100,2) AS "2019/2018_%_growth",
	lt.population AS population_lookup_table,
	ROUND((lt.population/e.population-1) * 100,2) AS "2020/2019_%_growth"
FROM economies e 
JOIN countries c 
  ON e.country = c.country
JOIN lookup_table lt 
  ON e.country = lt.country
GROUP BY country, `year`
ORDER BY country, `year` DESC;


/* r�zn� n�zvy st�t� v r�zn�ch tabulk�ch:
   N�zvy zem� jsou shodn� v tabulk�ch covid_basic a lookup (nap�. Czechia, US) a v tabulk�ch covid_tests, economies a countries (nap�. Czech Republic a United States).
   Tak�e m��u prvn� dv� a druh� t�i tabulky spojit p�es shodn� n�zev zem� a pak v�sledn� dv� tabulky spojit p�es iso3 (je v lookup a v countries).*/


/* 3. Prvn� spojen� tabulek 
 	  
 	  a) Nap�ed si p�iprav�m tabulku s aktu�ln�mi hodnotami GDP, gini a mortality_under5, kterou pak spoj�m s countries, ��m� z�sk�m "stavovou" tabulku
         se sloupci: country, GDP, gini, mortality_under5, iso3, population_density, median_age_2018  (ulo�eno jako v_joined_economies_countries) */

CREATE OR REPLACE VIEW v_joined_economies_countries AS
WITH
-- Nap�ed p�iprav�m 3 tabulky s aktu�ln�mi hodnotami GDP, gini a mortality_under5: 
GDP_actual AS 	-- 252 zem�
(
	SELECT 		
		country,
		MAX(`year`),
 		GDP
	FROM economies				
	WHERE GDP IS NOT NULL		
	GROUP BY country
),
gini_actual AS		-- 165 zem�
(
	SELECT 		
		country,
		MAX(`year`),
		gini
	FROM economies				
	WHERE gini IS NOT NULL		
	GROUP BY country
),
mortality_actual AS 	-- 239 zem�
(
	SELECT 		
		country,
		MAX(`year`),
		mortaliy_under5
	FROM economies				
	WHERE mortaliy_under5 IS NOT NULL		
	GROUP BY country
),
-- Tyto 3 tabulky spoj�m do jedn� tabulky:
economies_actual AS 
(
	 SELECT
		gdp.country AS "zem�",
		gdp.GDP AS HDP,
		g.gini AS "gini_koeficient",
 		m.mortaliy_under5 "d�tsk�_�mrtnost"
     FROM GDP_actual gdp
LEFT JOIN gini_actual g
	   ON gdp.country = g.country
LEFT JOIN mortality_actual m
 	   ON gdp.country = m.country
 ORDER BY gdp.country
)
-- Spoj�m tabulky economies_actual a countries:
SELECT
	e.*,
	c.iso3 AS ISO,
	c.population_density AS "hustota_zalidn�n�",
	c.median_age_2018 AS "medi�n_v�ku_2018"
FROM economies_actual e
LEFT JOIN countries c 
	ON e.zem� = c.country
ORDER BY e.zem�
;

SELECT * FROM v_joined_economies_countries


/*     b) Spoj�m tabulky covid19_basic_differences a lookup_table, ��m� z�sk�m po�adovan� sloupce date, country, confirmed a population (se kterou chci 
          d�l po��tat). 
          Na tuto novou tabulku p�es ISO p�ipoj�m je�t� tabulku covid19_tests, resp. upravenou tabulku covid19_tests_new, abych z�skala sloupec 
          s denn�mi testy.
          Nakonec p�ipoj�m p�es iso3 s tabulkou v_joined_economies_countries. T�m z�sk�m "v�vojovou" tabulku se sloupci date, country, iso3, 
          confirmed, test, population, gdp, gini, mortality_under5, population_density_median_age_2018. 
          Tuto v�slednou tabulku si op�t ulo��m do VIEW v_joined_covid_lookup_tests_economies_countries  */

CREATE OR REPLACE VIEW v_joined_covid_lookup_tests_economies_countries AS
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
),
-- P�ipoj�m covid19_tests
joined_covid_lookup_tests AS 
(
	SELECT
		jcl.*,
		ct.tests_performed
	FROM joined_covid_lookup jcl 
	LEFT JOIN covid19_tests ct
		ON jcl.`date` = ct.`date`
	   AND jcl.iso3 = ct.ISO
-- 	ORDER BY jcl.`date`
)
-- Spoj�m dv� nov� vytvo�en� tabulky dohromady
SELECT 
	base.`date` AS datum,
	base.country AS zem�,
	base.iso3 AS ISO,
	base.confirmed AS "denn�_n�rust_naka�en�ch",
	base.tests_performed AS "denn�_testy",
	base.population AS "po�et_obyvatel",
	v.HDP,
	v.gini_koeficient,
	v.d�tsk�_�mrtnost,
	v.hustota_zalidn�n�,
	v.medi�n_v�ku_2018
FROM joined_covid_lookup_tests base 
LEFT JOIN (SELECT * FROM v_joined_economies_countries) v 
	ON base.iso3 = v.ISO
-- ORDER BY base.country
;
-- Tuto v�slednou tabulku si op�t ulo��m do VIEW v_joined_covid_lookup_tests_economies_countries 


/* Kv�li probl�m�m se dv�ma z�znami o testech u jednoho data u n�kter�ch zem� jsem vytvo�ila novou tabulku covid19_tests_new a ve v��e uveden�m VIEW
   touto tabulkou nahrad�m p�vodn� tabulku covid19_tests */
CREATE OR REPLACE VIEW v_joined_covid_lookup_tests_economies_countries AS
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
),
-- P�ipoj�m covid19_tests
joined_covid_lookup_tests AS 
(
	SELECT
		jcl.*,
		vct.tests_performed
	FROM joined_covid_lookup jcl 
	LEFT JOIN v_covid19_tests_new vct
		ON jcl.`date` = vct.`date`
	   AND jcl.iso3 = vct.ISO
-- 	ORDER BY jcl.`date`
)
-- Spoj�m dv� nov� vytvo�en� tabulky dohromady
SELECT 
	base.`date` AS datum,
	base.country AS zem�,
	base.iso3 AS ISO,
	base.confirmed AS "denn�_n�rust_naka�en�ch",
	base.tests_performed AS "denn�_testy",
	base.population AS "po�et_obyvatel",
	ROUND(v.HDP/base.population) AS "HDP_na_obyvatele",		-- ve v�sledn� tabulce jsem je�t� m�sto celkov�ho HDP dopo��tala HDP na obyvatele 
	v.gini_koeficient,
	v.d�tsk�_�mrtnost,
	v.hustota_zalidn�n�,
	v.medi�n_v�ku_2018
FROM joined_covid_lookup_tests base 
LEFT JOIN (SELECT * FROM v_joined_economies_countries) v 
	ON base.iso3 = v.ISO
-- ORDER BY base.country
;

-- zkou�ka
SELECT * FROM v_joined_covid_lookup_tests_economies_countries WHERE ISO = 'USA';
