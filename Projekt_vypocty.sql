-- binární promìnná pro víkend / pracovní den
SELECT
	*,
	CASE 
		WHEN WEEKDAY(`date`) IN (5, 6) THEN 1 
		ELSE 0 
		END AS "Víkend",
	CASE 
		WHEN `date` < '2020-03-20' OR (`date` BETWEEN '2020-12-21' AND '2021-03-19') THEN "zima"
		WHEN `date` < '2020-06-20' OR (`date` BETWEEN '2021-03-20' AND '2021-06-20') THEN "jaro"
		WHEN `date` < '2020-09-22' THEN "léto"
		WHEN `date` < '2020-12-21' THEN "podzim"
		END AS "Roèní období"
FROM v_joined_covid_lookup_economies_countries
WHERE country = 'Afghanistan';


SELECT * FROM weather GROUP BY city;
SELECT * FROM countries;  -- odtud vzít capital city a pøes to dohledat v tabulce weather poèasí