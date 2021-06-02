-- 1. Studium všech tabulek, jejich sloupcù, klíèù pro JOINy s jinými tabulkami
 
SELECT * FROM countries;	-- country, population, population density, median age 2018, iso 3 (totožné s ISO z covid19_test)
SELECT * FROM economies; 	-- country, year, GDP, population (2019), gini (rùzné roky), mortality under 5 (2019)
SELECT * FROM life_expectancy;		-- country, iso3, year, life expectancy	
SELECT * FROM religions;	-- year (vzít 2020), country, religion (náboženství v dané zemi), population (pøíslušníci daného náboženství)
SELECT * FROM covid19_basic_differences;  -- denní pøírustky ve všech zemích (country, date)
SELECT * FROM covid19_tests;		-- denní a kumulativní poèty provedených testù ve všech zemích (country, date, ISO)
SELECT * FROM weather;		-- date, time, temp, gust, rain 
SELECT * FROM lookup_table;		-- country, iso3, population


 -- 2. Øešení "issues" v datech èi tabulkách

/* GDP, gini koeficient a mortality under 5:
   Tyto promìnné jsou v rùzných zemích zadávány rùznì (v nìkterých zemích je nejaktuálnìjší hodnota z roku 2018, v jiných tøeba i z 90. let), 
   bude tedy potøeba pro každou zemi vzít hodnotu z jiného roku */
SELECT 		
	country,
	MAX(year),
	gini
FROM economies				
WHERE gini IS NOT NULL		
GROUP BY country;	

/* population:
   V tabulce countries a lookup_table je population statická (nevím, ze kterého roku), v tabulce economies dynamická (vyplnìná do roku 2019, v roce 2020 NULL).
   Musím se rozhodnout, ze které tabulky údaj k population použiju.

Spojím si tabulky dohromady pøes INNER JOIN a z hodnot vidím, že údaje k population z tabulky countries jsou z roku 2018, údaje z tabulky lookup_table 
pravdìpodobnì z roku 2020 (jsou vìtší než údaje z economies z roku 2019). Pro rámcovou kontrolu jsem si ještì doplnila sloupce s meziroèním rùstem populace,
ve kterých vidím, že rùst 2019/2018 a 2020/2019 je v náhodnì vybraných zemích velmi podobný, takže údaje z lookup_table jsou s velkou pravdìpodobností z 2020.
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


/* rùzné názvy státù v rùzných tabulkách:
   Názvy zemí jsou shodné v tabulkách covid_basic a lookup (napø. Czechia, US) a v tabulkách covid_tests, economies a countries (napø. Czech Republic a United States).
   Takže mùžu první dvì a druhé tøi tabulky spojit pøes shodný název zemì a pak výsledné dvì tabulky spojit pøes iso3 (je v lookup a v countries).*/


/* 3. První spojení tabulek: propojení tabulek economies, countries, covid19_basic_diff, lookup, covid19_tests 
 	  
a) Napøed si pøipravím tabulku s aktuálními hodnotami GDP, gini a mortality_under5, kterou pak spojím s countries a religions, èímž získám "stavovou" 
   tabulku se sloupci: country, GDP, gini, mortality_under5, iso3, population_density, median_age_2018, religion, population  
   (uloženo jako v_joined_economies_countries_religions) */

CREATE OR REPLACE VIEW v_joined_economies_countries_religions AS
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
religions AS
( 
	SELECT
		country,
		religion AS "náboženství",
		population AS "poèet_pøíslušníkù"
	FROM religions 
	WHERE 1=1
		AND `year` = '2020' 
		AND country <> 'All Countries'
		AND population > 0
)
-- Pøipojím tabulku religion:
SELECT
	base.*,
	r.náboženství,
	r.poèet_pøíslušníkù
FROM joined_economies_countries base
LEFT JOIN religions r 
	ON base.zemì = r.country
;

SELECT * FROM v_joined_economies_countries_religions


/* b) Spojím tabulky covid19_basic_differences a lookup_table, èímž získám požadované sloupce date, country, confirmed a population (se kterou chci 
      dál poèítat). 
      Na tuto novou tabulku pøes ISO pøipojím ještì tabulku covid19_tests, resp. upravenou tabulku covid19_tests_new, abych získala sloupec s denními testy.
      Nakonec pøipojím pøes iso3 s tabulkou v_joined_economies_countries_religions. Tím získám "vývojovou" tabulku se sloupci datum, zemì, ISO,
      denní nárùst nakažených, denní testy, poèet obyvatel, HDP na obyvatele, gini koeficient, dìtská úmrtnost, hustota zalidnìní, medián vìku v roce 2018,
      náboženství a poèet pøíslušníkù. 
      Tuto výslednou tabulku si opìt uložím do VIEW v_joined_covid_lookup_tests_economies_countries_religions  */

CREATE OR REPLACE VIEW v_joined_covid_lookup_tests_economies_countries_religions AS
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
),
-- Pøipojím covid19_tests
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
-- Spojím dvì novì vytvoøené tabulky dohromady
SELECT 
	base.`date` AS datum,
	base.country AS zemì,
	base.iso3 AS ISO,
	base.confirmed AS "denní_nárust_nakažených",
	base.tests_performed AS "denní_testy",
	base.population AS "poèet_obyvatel",
	v.HDP,
	v.gini_koeficient,
	v.`dìtská_úmrtnost`,
	v.`hustota_zalidnìní`,
	v.`medián_vìku_2018`,
	v.`náboženství`,
	v.`poèet_pøíslušníkù`
FROM joined_covid_lookup_tests base 
LEFT JOIN (SELECT * FROM v_joined_economies_countries_religions) v 
	ON base.iso3 = v.ISO
-- ORDER BY base.country
;
-- Tuto výslednou tabulku si opìt uložím do VIEW v_joined_covid_lookup_tests_economies_countries_religions 


/* Kvùli problémùm se dvìma záznami o testech u jednoho data u nìkterých zemí jsem vytvoøila novou tabulku covid19_tests_new, kterou použiju místo
   tabulky covid19_tests */
CREATE OR REPLACE VIEW v_joined_covid_lookup_tests_economies_countries_religions AS
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
),
-- Pøipojím covid19_tests
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
-- Spojím dvì novì vytvoøené tabulky dohromady
SELECT 
	base.`date` AS datum,
	base.country AS zemì,
	base.iso3 AS ISO,
	base.confirmed AS "denní_nárust_nakažených",
	base.tests_performed AS "denní_testy",
	base.population AS "poèet_obyvatel",
	ROUND(v.HDP/base.population) AS "HDP_na_obyvatele",		-- ve výsledné tabulce jsem ještì místo celkového HDP dopoèítala HDP na obyvatele 
	v.gini_koeficient,
	v.`dìtská_úmrtnost`,
	v.`hustota_zalidnìní`,
	v.`medián_vìku_2018`,
	v.`náboženství`,
	v.`poèet_pøíslušníkù`
FROM joined_covid_lookup_tests base 
LEFT JOIN (SELECT * FROM v_joined_economies_countries_religions) v 
	ON base.iso3 = v.ISO
-- ORDER BY base.country
;
-- Tuto výslednou tabulku si opìt uložím do VIEW v_joined_covid_lookup_tests_economies_countries_religions 

-- zkouška
SELECT * FROM v_joined_covid_lookup_tests_economies_countries_religions WHERE ISO = 'CZE' AND datum = '2020-03-20';


-- 4. spojení tabulek: napojení údajù z tabulky weather

/* a) Udìlám potøebné výpoèty pro požadované údaje z tabulky weather ve sloupcích s teplotou, vìtrem a deštìm.
 	  Pøepíšu si názvy hlavních mìst v tabulce weather (city) tak, aby byly shodné s názvy v tabulce countries (capital_city). 
      Pøes tento sloupec rovnou tabulky weather a countries spojím, abych k údajùm o poèasí získala ISO z tabulky countries a mohla pak údaje o poèasí
      pøipojit k velké výsledné tabulce. Výslednou tabulku uložím do VIEW v_weather_new */  

CREATE OR REPLACE VIEW v_weather_new AS
WITH 
weather_new AS
(
	SELECT		
		CAST(`date` AS date) AS datum,
		CONCAT(ROUND((SUM((CASE WHEN `time` IN ('09:00', '12:00', '15:00', '18:00') THEN 1 ELSE 0 END) * REPLACE(temp,' °c', ''))) / 4), ' °c') AS "prùm._denní_teplota",	
		SUM(CASE WHEN rain = '0.0 mm' THEN 0 ELSE 1 END) * 3 AS "poèet_hod._se_srážkami",
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
JOIN weather_new w		-- Brno a Stornoway nejsou v tabulce countries, takže jejich ISO je NULL a ve výsledné tabulce je nepotøebuju, proto INNER JOIN.
	 ON c.capital_city = w.capital_city
	AND c.iso3 IS NOT NULL 
;

-- kontrola
SELECT * FROM v_weather_new WHERE capital_city = 'Prague';


-- b) Údaje z tabulky v_weather_new pøipojím pøes LEFT JOIN k velké tabulce a uložím do VIEW v_joined_covid_..._weather
CREATE OR REPLACE VIEW v_joined_covid_lookup_tests_economies_countries_weather AS
WITH 
weather_new AS
(
	SELECT		
		CAST(`date` AS date) AS datum,
		CONCAT(ROUND((SUM((CASE WHEN `time` IN ('09:00', '12:00', '15:00', '18:00') THEN 1 ELSE 0 END) * REPLACE(temp,' °c', ''))) / 4), ' °c') AS "prùm._denní_teplota",	
		SUM(CASE WHEN rain = '0.0 mm' THEN 0 ELSE 1 END) * 3 AS "poèet_hod._se_srážkami",
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
	JOIN weather_new w		-- Brno a Stornoway nejsou v tabulce countries, takže jejich ISO je NULL a ve výsledné tabulce je nepotøebuju, proto INNER JOIN.
		 ON c.capital_city = w.capital_city
		AND c.iso3 IS NOT NULL 
)
SELECT
	base.*,
	-- binární promìnná pro víkend / pracovní den
	CASE 
		WHEN WEEKDAY(base.datum) IN (5, 6) THEN 1 
		ELSE 0 
		END AS "víkend",
	-- roèní období
	CASE 
		WHEN base.datum < '2020-03-20' OR (base.datum BETWEEN '2020-12-21' AND '2021-03-19') THEN "zima"
		WHEN base.datum < '2020-06-20' OR (base.datum BETWEEN '2021-03-20' AND '2021-06-20') THEN "jaro"
		WHEN base.datum < '2020-09-22' THEN "léto"
		WHEN base.datum < '2020-12-21' THEN "podzim"
		END AS "roèní období",
	wc.`prùm._denní_teplota`,
 	wc.`poèet_hod._se_srážkami`,
 	wc.`max_vítr_v_nárazech`
FROM v_joined_covid_lookup_tests_economies_countries base 
LEFT JOIN joined_weather_countries wc 
	ON base.ISO = wc.ISO
   AND base.datum = wc.datum
;

-- kontrola
SELECT * FROM v_joined_covid_lookup_tests_economies_countries_weather WHERE zemì = 'Czechia';
