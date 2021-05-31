-- V�po�tu pro tvorbu dal��ch sloupc�

SELECT
	*,
	-- bin�rn� prom�nn� pro v�kend / pracovn� den
	CASE 
		WHEN WEEKDAY(datum) IN (5, 6) THEN 1 
		ELSE 0 
		END AS "V�kend",
	-- ro�n� obdob�
	CASE 
		WHEN datum < '2020-03-20' OR (datum BETWEEN '2020-12-21' AND '2021-03-19') THEN "zima"
		WHEN datum < '2020-06-20' OR (datum BETWEEN '2021-03-20' AND '2021-06-20') THEN "jaro"
		WHEN datum < '2020-09-22' THEN "l�to"
		WHEN datum < '2020-12-21' THEN "podzim"
		END AS "Ro�n� obdob�"
FROM v_joined_covid_lookup_tests_economies_countries
WHERE ISO = 'USA'
;

-- V�po�ty v tabulce weather
-- a) pr�m�rn� denn� (nikoli no�n�!) teplota

SELECT 
	`time`,
	`date`,

-- b) po�et hodin v dan�m dni, kdy byly sr�ky nenulov�
-- c) maxim�ln� s�la v�tru v n�razech b�hem dne


SELECT * FROM weather

SELECT DISTINCT city FROM weather ORDER BY city;
SELECT capital_city FROM countries WHERE capital_city IS NOT NULL ORDER BY capital_city;  -- odtud vz�t capital city a p�es to dohledat v tabulce weather po�as�