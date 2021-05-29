-- bin�rn� prom�nn� pro v�kend / pracovn� den
SELECT
	*,
	CASE 
		WHEN WEEKDAY(`date`) IN (5, 6) THEN 1 
		ELSE 0 
		END AS "V�kend",
	CASE 
		WHEN `date` < '2020-03-20' OR (`date` BETWEEN '2020-12-21' AND '2021-03-19') THEN "zima"
		WHEN `date` < '2020-06-20' OR (`date` BETWEEN '2021-03-20' AND '2021-06-20') THEN "jaro"
		WHEN `date` < '2020-09-22' THEN "l�to"
		WHEN `date` < '2020-12-21' THEN "podzim"
		END AS "Ro�n� obdob�"
FROM v_joined_covid_lookup_economies_countries
WHERE country = 'Afghanistan';


SELECT * FROM weather GROUP BY city;
SELECT * FROM countries;  -- odtud vz�t capital city a p�es to dohledat v tabulce weather po�as�