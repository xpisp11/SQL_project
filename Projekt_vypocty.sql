-- Výpoètu pro tvorbu dalších sloupcù

SELECT
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
WHERE ISO = 'USA'
;

-- Výpoèty v tabulce weather
-- a) prùmìrná denní (nikoli noèní!) teplota

SELECT 
	`time`,
	`date`,

-- b) poèet hodin v daném dni, kdy byly srážky nenulové
-- c) maximální síla vìtru v nárazech bìhem dne


SELECT * FROM weather

SELECT DISTINCT city FROM weather ORDER BY city;
SELECT capital_city FROM countries WHERE capital_city IS NOT NULL ORDER BY capital_city;  -- odtud vzít capital city a pøes to dohledat v tabulce weather poèasí