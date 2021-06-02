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
 	  
a) Propojen� tabulek economies, countries, religions, 
   Nap�ed si p�iprav�m tabulku s aktu�ln�mi hodnotami GDP, gini a mortality_under5, kterou pak spoj�m s countries a pivoted_religions,
   ��m� z�sk�m "stavovou" tabulku se sloupci: country, GDP, gini, mortality_under5, iso3, population_density, median_age_2018 a 
   sloupci pro po�et p��slu�n�k� jednotliv�ch n�bo�enstv�  
   (ulo�eno jako v_joined_eco_co_rel) */

CREATE OR REPLACE VIEW v_joined_eco_co_rel AS
WITH
-- Nap�ed p�iprav�m 3 tabulky s aktu�ln�mi hodnotami GDP, gini a mortality_under5: 
GDP_actual AS 
(
	SELECT 		
		country,
		MAX(`year`),
 		GDP
	FROM economies				
	WHERE GDP IS NOT NULL		
	GROUP BY country
),
gini_actual AS
(
	SELECT 		
		country,
		MAX(`year`),
		gini
	FROM economies				
	WHERE gini IS NOT NULL		
	GROUP BY country
),
mortality_actual AS 	
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
),
-- Spoj�m tabulky economies_actual a countries:
joined_economies_countries AS
(
	SELECT
		e.*,
		c.iso3 AS ISO,
		c.population_density AS "hustota_zalidn�n�",
		c.median_age_2018 AS "medi�n_v�ku_2018"
	FROM economies_actual e
	LEFT JOIN countries c 
		ON e.zem� = c.country
	ORDER BY e.zem�
),
pivoted_religions AS
( 
	SELECT 
   		country,
  		MAX(CASE WHEN religion = 'Christianity' THEN population END) AS "k�es�anstv�",
		MAX(CASE WHEN religion = 'Islam' THEN population END) AS "isl�m",
   		MAX(CASE WHEN religion = 'Hinduism' THEN population END) AS "hinduismus",
   		MAX(CASE WHEN religion = 'Buddhism' THEN population END) AS "budhismus",
  		MAX(CASE WHEN religion = 'Judaism' THEN population END) AS "judaismus",
   		MAX(CASE WHEN religion = 'Unaffiliated Religions' THEN population END) AS "nep�idru�en�_n�bo�enstv�",
 		MAX(CASE WHEN religion = 'Folk Religions' THEN population END) AS "lidov�_n�bo�enstv�",
		MAX(CASE WHEN religion = 'Other Religions' THEN population END) AS "jin� n�bo�enstv�"
	FROM religions
	WHERE 1=1
		AND `year` = '2020' 
		AND country <> 'All Countries'
	GROUP BY country
)
-- P�ipoj�m tabulku pivoted_religions:
SELECT
	base.*,
	r.*
FROM joined_economies_countries base
LEFT JOIN pivoted_religions r 
	ON base.zem� = r.country
;

-- kontrola
SELECT * FROM v_joined_eco_co_rel;


/* b) Propojen� covid19_basic_diff s lookup a covid19_tests
      Spoj�m tabulky covid19_basic_differences a lookup_table, ��m� z�sk�m po�adovan� sloupce date, country, confirmed a population 
      (se kterou chci d�l po��tat). 
      Na tuto novou tabulku p�es ISO p�ipoj�m je�t� tabulku covid19_tests, resp. upravenou tabulku covid19_tests_new, abych z�skala 
      sloupec s denn�mi testy.
      Nakonec spoj�m p�es iso3 s tabulkou v_joined_eco_co_rel. T�m z�sk�m "v�vojovou" tabulku se sloupci datum, zem�, ISO,
      denn� n�r�st naka�en�ch, denn� testy, po�et obyvatel, HDP na obyvatele, gini koeficient, d�tsk� �mrtnost, hustota zalidn�n�, 
      medi�n v�ku v roce 2018 a sloupce s pod�ly jednotliv�ch n�bo�enstv� na populaci. 
      Tuto v�slednou tabulku si op�t ulo��m do VIEW v_joined_cov_lt_tests_eco_co_rel  */

/* Kv�li probl�m�m se dv�ma z�znami o testech u jednoho data u n�kter�ch zem� (viz. Projekt_priprava_kontrolni.sql) jsem vytvo�ila novou tabulku 
   covid19_tests_new (viz. Projekt_upravene_tabulky.sql), kterou pou�iju m�sto tabulky covid19_tests */

CREATE OR REPLACE VIEW v_joined_cov_lt_tests_eco_co_rel AS
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
),
-- P�ipoj�m covid19_tests_new
joined_covid_lookup_tests AS 
(
	SELECT
		jcl.*,
		vct.tests_performed
	FROM joined_covid_lookup jcl 
	LEFT JOIN v_covid19_tests_new vct
		ON jcl.`date` = vct.`date`
	   AND jcl.iso3 = vct.ISO
)
-- Spoj�m dv� nov� vytvo�en� tabulky dohromady
SELECT 
	base.`date` AS datum,
	base.country AS zem�,
	base.iso3 AS ISO,
	base.confirmed AS "denn�_n�rust_naka�en�ch",
	base.tests_performed AS "denn�_testy",
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
FROM joined_covid_lookup_tests base 
LEFT JOIN (SELECT * FROM v_joined_eco_co_rel) v 
	ON base.iso3 = v.ISO
;

-- zkou�ka
SELECT * FROM v_joined_cov_lt_tests_eco_co_rel WHERE ISO = 'USA' AND datum BETWEEN '2020-09-20' AND '2020-12-20';



-- 5. Spojen� tabulek: napojen� �daj� z tabulky weather

/* a) Ud�l�m pot�ebn� v�po�ty pro po�adovan� �daje z tabulky weather ve sloupc�ch s teplotou, v�trem a de�t�m.
 	  P�ep�u si n�zvy hlavn�ch m�st v tabulce weather (city) tak, aby byly shodn� s n�zvy v tabulce countries (capital_city). 
      P�es tento sloupec rovnou tabulky weather a countries spoj�m, abych k �daj�m o po�as� z�skala ISO z tabulky countries a mohla pak �daje o po�as�
      p�ipojit k velk� v�sledn� tabulce. V�slednou tabulku ulo��m do VIEW v_weather_new */  

CREATE OR REPLACE VIEW v_weather_new AS
WITH 
weather_new AS
(
	SELECT		
		CAST(`date` AS date) AS datum,
		CONCAT(ROUND((SUM((CASE WHEN `time` IN ('09:00', '12:00', '15:00', '18:00') THEN 1 ELSE 0 END) * REPLACE(temp,' �c', ''))) / 4), ' �c') AS "pr�m._denn�_teplota",	
		SUM(CASE WHEN rain = '0.0 mm' THEN 0 ELSE 1 END) * 3 AS "po�et_hod._se_sr�kami",
		MAX(gust) AS "max_v�tr_v_n�razech",
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
)
SELECT 
	c.iso3 AS ISO,
	w.*
FROM countries c 
JOIN weather_new w		-- Brno a Stornoway nejsou v tabulce countries, tak�e jejich ISO je NULL a ve v�sledn� tabulce je nepot�ebuju, proto INNER JOIN.
	 ON c.capital_city = w.capital_city
	AND c.iso3 IS NOT NULL 
;

-- kontrola
SELECT * FROM v_weather_new WHERE capital_city = 'Prague';


-- b) �daje z tabulky v_weather_new p�ipoj�m p�es LEFT JOIN k velk� tabulce a ulo��m do VIEW v_joined_cov_lt_tests_eco_co_rel_w
CREATE OR REPLACE VIEW v_joined_cov_lt_tests_eco_co_rel_w AS
WITH 
weather_new AS
(
	SELECT		
		CAST(`date` AS date) AS datum,
		CONCAT(ROUND((SUM((CASE WHEN `time` IN ('09:00', '12:00', '15:00', '18:00') THEN 1 ELSE 0 END) * REPLACE(temp,' �c', ''))) / 4), ' �c') AS "pr�m._denn�_teplota",	
		SUM(CASE WHEN rain = '0.0 mm' THEN 0 ELSE 1 END) * 3 AS "po�et_hod._se_sr�kami",
		MAX(gust) AS "max_v�tr_v_n�razech",
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
),
joined_weather_countries AS
(
	SELECT 
		c.iso3 AS ISO,
		w.*
	FROM countries c 
	JOIN weather_new w		-- Brno a Stornoway nejsou v tabulce countries, tak�e jejich ISO je NULL a ve v�sledn� tabulce je nepot�ebuju, proto INNER JOIN.
		 ON c.capital_city = w.capital_city
		AND c.iso3 IS NOT NULL 
)
SELECT
	base.*,
	wc.`pr�m._denn�_teplota`,
 	wc.`po�et_hod._se_sr�kami`,
 	wc.`max_v�tr_v_n�razech`
FROM v_joined_cov_lt_tests_eco_co_rel base 
LEFT JOIN joined_weather_countries wc 
	ON base.ISO = wc.ISO
   AND base.datum = wc.datum
;

-- zkou�ka
SELECT * 
FROM v_joined_cov_lt_tests_eco_co_rel_w 
WHERE zem� IN ('US', 'Czechia') AND datum BETWEEN '2020-09-20' AND '2020-12-20' 
ORDER BY datum;



-- 6. Pivotov�n� a v�po�ty v tabulce life_expectancy

CREATE OR REPLACE VIEW v_Petra_Rohlickova_projekt_SQL_final AS
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
;


-- zkou�ka
SELECT * 
FROM v_Petra_Rohlickova_projekt_SQL_final 
WHERE zem� IN ('US', 'Czechia') AND datum BETWEEN '2020-09-20' AND '2020-12-20';