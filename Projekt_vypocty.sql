-- Výpoèty pro tvorbu dalších sloupcù

SELECT		-- pøidám do SELECTu pro výpis výsledné tabulky
	*,
	-- binární promìnná pro víkend / pracovní den
	CASE 
		WHEN WEEKDAY(datum) IN (5, 6) THEN 1 
		ELSE 0 
		END AS "Víkend",
	-- roèní období
	CASE 
		WHEN datum < '2020-03-20' OR (datum BETWEEN '2020-12-21' AND '2021-03-19') THEN "zima"
		WHEN datum < '2020-06-20' OR (datum BETWEEN '2021-03-20' AND '2021-06-20') THEN "jaro"
		WHEN datum < '2020-09-22' THEN "léto"
		WHEN datum < '2020-12-21' THEN "podzim"
		END AS "Roèní období"
FROM v_joined_covid_lookup_tests_economies_countries
-- WHERE ISO = 'USA'
;

-- Výpoèty v tabulce weather

SELECT DISTINCT city FROM weather ORDER BY city;
SELECT DISTINCT capital_city FROM countries ORDER BY capital_city;

-- - Pøepíšu si názvy hlavních mìst v tabulce weather (city) tak, aby byly shodné s názvy v tabulce countries (capital_city).
-- -- Udìlám výpoèty ve sloupcích s teplotou, vìtrem a deštìm 
 
SELECT		-- použiju ve WITH jako weather_new
	CAST(`date`AS date) AS datum,
	-- prùmìrná denní (nikoli noèní!) teplota
	-- odstranila jsem " °c", vypoèítala prùmìr pouze z teplot pro èasy z daného intervalu a zase pøipojila " °c"
	CONCAT(ROUND((SUM((CASE WHEN `time` IN ('09:00', '12:00', '15:00', '18:00') THEN 1 ELSE 0 END) * REPLACE(temp,' °c', ''))) / 4), ' °c') AS "prùm._denní_teplota",	
	-- poèet hodin v daném dni, kdy byly srážky nenulové
	SUM(CASE WHEN rain = '0.0 mm' THEN 0 ELSE 1 END) * 3 AS "poèet_hod._se_srážkami",
	-- maximální síla vìtru v nárazech bìhem dne
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
;

-- kontrola
SELECT `date`, `time`, temp, gust, rain FROM weather WHERE city = 'Prague';