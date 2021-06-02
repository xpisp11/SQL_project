-- 1. Studium všech tabulek, jejich sloupcù, klíèù pro JOINy s jinımi tabulkami
 
SELECT * FROM countries;	-- country, population, population density, median age 2018, iso 3 (totoné s ISO z covid19_test)
SELECT * FROM economies; 	-- country, year, GDP, population (2019), gini (rùzné roky), mortality under 5 (2019)
SELECT * FROM life_expectancy;		-- country, iso3, year, life expectancy	
SELECT * FROM religions;	-- year (vzít 2020), country, religion (náboenství v dané zemi), population (pøíslušníci daného náboenství)
SELECT * FROM covid19_basic_differences;  -- denní pøírustky ve všech zemích (country, date)
SELECT * FROM covid19_tests;		-- denní a kumulativní poèty provedenıch testù ve všech zemích (country, date, ISO)
SELECT * FROM weather;		-- date, time, temp, gust, rain 
SELECT * FROM lookup_table;		-- country, iso3, population


 -- 2. Øešení "issues" v datech èi tabulkách

/* GDP, gini koeficient a mortality under 5:
   Tyto promìnné jsou v rùznıch zemích zadávány rùznì (v nìkterıch zemích je nejaktuálnìjší hodnota z roku 2018, v jinıch tøeba i z 90. let), 
   bude tedy potøeba pro kadou zemi vzít hodnotu z jiného roku */
SELECT 		
	country,
	MAX(year),
	gini
FROM economies				
WHERE gini IS NOT NULL		
GROUP BY country;	

/* population:
   V tabulce countries a lookup_table je population statická (nevím, ze kterého roku), v tabulce economies dynamická (vyplnìná do roku 2019, v roce 2020 NULL).
   Musím se rozhodnout, ze které tabulky údaj k population pouiju.

Spojím si tabulky dohromady pøes INNER JOIN a z hodnot vidím, e údaje k population z tabulky countries jsou z roku 2018, údaje z tabulky lookup_table 
pravdìpodobnì z roku 2020 (jsou vìtší ne údaje z economies z roku 2019). Pro rámcovou kontrolu jsem si ještì doplnila sloupce s meziroèním rùstem populace,
ve kterıch vidím, e rùst 2019/2018 a 2020/2019 je v náhodnì vybranıch zemích velmi podobnı, take údaje z lookup_table jsou s velkou pravdìpodobností z 2020.
Údaj k celkové populaci tedy vezmu z tabulky lookup_table. */

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


/* rùzné názvy státù v rùznıch tabulkách:
   Názvy zemí jsou shodné v tabulkách covid_basic a lookup (napø. Czechia, US) a v tabulkách covid_tests, economies a countries (napø. Czech Republic a United States).
   Take mùu první dvì a druhé tøi tabulky spojit pøes shodnı název zemì a pak vısledné dvì tabulky spojit pøes iso3 (je v lookup a v countries).*/


/* 3. První spojení tabulek 
 	  
a) Propojení tabulek economies, countries, religions, 
   Napøed si pøipravím tabulku s aktuálními hodnotami GDP, gini a mortality_under5, kterou pak spojím s countries a pivoted_religions,
   èím získám "stavovou" tabulku se sloupci: country, GDP, gini, mortality_under5, iso3, population_density, median_age_2018 a 
   sloupci pro poèet pøíslušníkù jednotlivıch náboenství  
   (uloeno jako v_joined_eco_co_rel) */

CREATE OR REPLACE VIEW v_joined_eco_co_rel AS
WITH
-- Napøed pøipravím 3 tabulky s aktuálními hodnotami GDP, gini a mortality_under5: 
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
-- Tyto 3 tabulky spojím do jedné tabulky:
economies_actual AS 
(
	 SELECT
		gdp.country AS "zemì",
		gdp.GDP AS HDP,
		g.gini AS "gini_koeficient",
 		m.mortaliy_under5 "dìtská_úmrtnost"
     FROM GDP_actual gdp
LEFT JOIN gini_actual g
	   ON gdp.country = g.country
LEFT JOIN mortality_actual m
 	   ON gdp.country = m.country
 ORDER BY gdp.country
),
-- Spojím tabulky economies_actual a countries:
joined_economies_countries AS
(
	SELECT
		e.*,
		c.iso3 AS ISO,
		c.population_density AS "hustota_zalidnìní",
		c.median_age_2018 AS "medián_vìku_2018"
	FROM economies_actual e
	LEFT JOIN countries c 
		ON e.zemì = c.country
	ORDER BY e.zemì
),
pivoted_religions AS
( 
	SELECT 
   		country,
  		MAX(CASE WHEN religion = 'Christianity' THEN population END) AS "køesanství",
		MAX(CASE WHEN religion = 'Islam' THEN population END) AS "islám",
   		MAX(CASE WHEN religion = 'Hinduism' THEN population END) AS "hinduismus",
   		MAX(CASE WHEN religion = 'Buddhism' THEN population END) AS "budhismus",
  		MAX(CASE WHEN religion = 'Judaism' THEN population END) AS "judaismus",
   		MAX(CASE WHEN religion = 'Unaffiliated Religions' THEN population END) AS "nepøidruená_náboenství",
 		MAX(CASE WHEN religion = 'Folk Religions' THEN population END) AS "lidová_náboenství",
		MAX(CASE WHEN religion = 'Other Religions' THEN population END) AS "jiná náboenství"
	FROM religions
	WHERE 1=1
		AND `year` = '2020' 
		AND country <> 'All Countries'
	GROUP BY country
)
-- Pøipojím tabulku pivoted_religions:
SELECT
	base.*,
	r.*
FROM joined_economies_countries base
LEFT JOIN pivoted_religions r 
	ON base.zemì = r.country
;

-- kontrola
SELECT * FROM v_joined_eco_co_rel;


/* b) Propojení covid19_basic_diff s lookup a covid19_tests
      Spojím tabulky covid19_basic_differences a lookup_table, èím získám poadované sloupce date, country, confirmed a population 
      (se kterou chci dál poèítat). 
      Na tuto novou tabulku pøes ISO pøipojím ještì tabulku covid19_tests, resp. upravenou tabulku covid19_tests_new, abych získala 
      sloupec s denními testy.
      Nakonec spojím pøes iso3 s tabulkou v_joined_eco_co_rel. Tím získám "vıvojovou" tabulku se sloupci datum, zemì, ISO,
      denní nárùst nakaenıch, denní testy, poèet obyvatel, HDP na obyvatele, gini koeficient, dìtská úmrtnost, hustota zalidnìní, 
      medián vìku v roce 2018 a sloupce s podíly jednotlivıch náboenství na populaci. 
      Tuto vıslednou tabulku si opìt uloím do VIEW v_joined_cov_lt_tests_eco_co_rel  */

/* Kvùli problémùm se dvìma záznami o testech u jednoho data u nìkterıch zemí (viz. Projekt_priprava_kontrolni.sql) jsem vytvoøila novou tabulku 
   covid19_tests_new (viz. Projekt_upravene_tabulky.sql), kterou pouiju místo tabulky covid19_tests */

CREATE OR REPLACE VIEW v_joined_cov_lt_tests_eco_co_rel AS
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
),
-- Pøipojím covid19_tests_new
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
-- Spojím dvì novì vytvoøené tabulky dohromady
SELECT 
	base.`date` AS datum,
	base.country AS zemì,
	base.iso3 AS ISO,
	base.confirmed AS "denní_nárust_nakaenıch",
	base.tests_performed AS "denní_testy",
	base.population AS "poèet_obyvatel",
	-- 4. Pøidání novıch sloupcù: binární promìnná pro víkend / pracovní den
	CASE 
		WHEN WEEKDAY(base.`date`) IN (5, 6) THEN 1 
		ELSE 0 
		END AS "víkend",
	-- 4. Pøidání novıch sloupcù: roèní období
	CASE 
		WHEN base.`date` < '2020-03-20' OR (base.`date` BETWEEN '2020-12-21' AND '2021-03-19') THEN "zima"
		WHEN base.`date` < '2020-06-20' OR (base.`date` BETWEEN '2021-03-20' AND '2021-06-20') THEN "jaro"
		WHEN base.`date` < '2020-09-22' THEN "léto"
		WHEN base.`date` < '2020-12-21' THEN "podzim"
		END AS "roèní období",
	-- ve vısledné tabulce jsem ještì místo celkového HDP dopoèítala HDP na obyvatele 
	ROUND(v.HDP/base.population) AS "HDP_na_obyvatele",		
	v.gini_koeficient,
	v.`dìtská_úmrtnost`,
	v.`hustota_zalidnìní`,
	v.`medián_vìku_2018`,
	-- ve vısledné tabulce jsem ještì dopoèítala podíl pøíslušníkù jednotlivıch náboenství na celkové populaci zemì
	CONCAT(ROUND(v.`køesanství`/base.population * 100,1), ' %') AS "podíl_køesanù",
	CONCAT(ROUND(v.`islám`/base.population * 100,1), ' %') AS "podíl_pøíslušníkù_islámu",
	CONCAT(ROUND(v.`hinduismus`/base.population * 100,1), ' %') AS "podíl_hinduistù",
	CONCAT(ROUND(v.`budhismus`/base.population * 100,1), ' %') AS "podíl_budhistù",
	CONCAT(ROUND(v.`judaismus`/base.population * 100,1), ' %') AS "podíl_idù",
	CONCAT(ROUND(v.`nepøidruená_náboenství`/base.population * 100,1), ' %') AS "podíl_pøíslušníkù_nepøidru._náb.",
	CONCAT(ROUND(v.`lidová_náboenství`/base.population * 100,1), ' %') AS "podíl_pøíslušníkù_lid._náb.",
	CONCAT(ROUND(v.`jiná náboenství`/base.population * 100,1), ' %') AS "podíl_pøíslušníkù_jinıch_náb."	
FROM joined_covid_lookup_tests base 
LEFT JOIN (SELECT * FROM v_joined_eco_co_rel) v 
	ON base.iso3 = v.ISO
;

-- zkouška
SELECT * FROM v_joined_cov_lt_tests_eco_co_rel WHERE ISO = 'USA' AND datum BETWEEN '2020-09-20' AND '2020-12-20';



-- 5. Spojení tabulek: napojení údajù z tabulky weather

/* a) Udìlám potøebné vıpoèty pro poadované údaje z tabulky weather ve sloupcích s teplotou, vìtrem a deštìm.
 	  Pøepíšu si názvy hlavních mìst v tabulce weather (city) tak, aby byly shodné s názvy v tabulce countries (capital_city). 
      Pøes tento sloupec rovnou tabulky weather a countries spojím, abych k údajùm o poèasí získala ISO z tabulky countries a mohla pak údaje o poèasí
      pøipojit k velké vısledné tabulce. Vıslednou tabulku uloím do VIEW v_weather_new */  

CREATE OR REPLACE VIEW v_weather_new AS
WITH 
weather_new AS
(
	SELECT		
		CAST(`date` AS date) AS datum,
		CONCAT(ROUND((SUM((CASE WHEN `time` IN ('09:00', '12:00', '15:00', '18:00') THEN 1 ELSE 0 END) * REPLACE(temp,' °c', ''))) / 4), ' °c') AS "prùm._denní_teplota",	
		SUM(CASE WHEN rain = '0.0 mm' THEN 0 ELSE 1 END) * 3 AS "poèet_hod._se_srákami",
		MAX(gust) AS "max_vítr_v_nárazech",
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
JOIN weather_new w		-- Brno a Stornoway nejsou v tabulce countries, take jejich ISO je NULL a ve vısledné tabulce je nepotøebuju, proto INNER JOIN.
	 ON c.capital_city = w.capital_city
	AND c.iso3 IS NOT NULL 
;

-- kontrola
SELECT * FROM v_weather_new WHERE capital_city = 'Prague';


-- b) Údaje z tabulky v_weather_new pøipojím pøes LEFT JOIN k velké tabulce a uloím do VIEW v_joined_cov_lt_tests_eco_co_rel_w
CREATE OR REPLACE VIEW v_joined_cov_lt_tests_eco_co_rel_w AS
WITH 
weather_new AS
(
	SELECT		
		CAST(`date` AS date) AS datum,
		CONCAT(ROUND((SUM((CASE WHEN `time` IN ('09:00', '12:00', '15:00', '18:00') THEN 1 ELSE 0 END) * REPLACE(temp,' °c', ''))) / 4), ' °c') AS "prùm._denní_teplota",	
		SUM(CASE WHEN rain = '0.0 mm' THEN 0 ELSE 1 END) * 3 AS "poèet_hod._se_srákami",
		MAX(gust) AS "max_vítr_v_nárazech",
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
	JOIN weather_new w		-- Brno a Stornoway nejsou v tabulce countries, take jejich ISO je NULL a ve vısledné tabulce je nepotøebuju, proto INNER JOIN.
		 ON c.capital_city = w.capital_city
		AND c.iso3 IS NOT NULL 
)
SELECT
	base.*,
	wc.`prùm._denní_teplota`,
 	wc.`poèet_hod._se_srákami`,
 	wc.`max_vítr_v_nárazech`
FROM v_joined_cov_lt_tests_eco_co_rel base 
LEFT JOIN joined_weather_countries wc 
	ON base.ISO = wc.ISO
   AND base.datum = wc.datum
;

-- zkouška
SELECT * 
FROM v_joined_cov_lt_tests_eco_co_rel_w 
WHERE zemì IN ('US', 'Czechia') AND datum BETWEEN '2020-09-20' AND '2020-12-20' 
ORDER BY datum;



-- 6. Pivotování a vıpoèty v tabulce life_expectancy

CREATE OR REPLACE VIEW v_Petra_Rohlickova_projekt_SQL_final AS
WITH
-- transponování
pivoted_life_expectancy AS
(
	SELECT 
        iso3,
        MAX(CASE WHEN year = 1965 THEN life_expectancy END) AS life_expectancy_1965,
        MAX(CASE WHEN year = 2015 THEN life_expectancy END) AS life_expectancy_2015
    FROM life_expectancy
    GROUP BY iso3
)
-- pøipojení tabulky k velké vısledné tabulce
SELECT
    base.*,
    ROUND(le.life_expectancy_2015 - le.life_expectancy_1965,1) AS "rozdíl_doití_2015_1965"
FROM v_joined_cov_lt_tests_eco_co_rel_w base
LEFT JOIN pivoted_life_expectancy le
  ON base.ISO = le.iso3
;


-- zkouška
SELECT * 
FROM v_Petra_Rohlickova_projekt_SQL_final 
WHERE zemì IN ('US', 'Czechia') AND datum BETWEEN '2020-09-20' AND '2020-12-20';