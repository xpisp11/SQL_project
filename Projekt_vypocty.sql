-- V�po�ty pro tvorbu dal��ch sloupc�

SELECT		-- p�id�m do SELECTu pro v�pis v�sledn� tabulky
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
-- WHERE ISO = 'USA'
;

-- V�po�ty v tabulce weather

SELECT DISTINCT city FROM weather ORDER BY city;
SELECT DISTINCT capital_city FROM countries ORDER BY capital_city;

-- - P�ep�u si n�zvy hlavn�ch m�st v tabulce weather (city) tak, aby byly shodn� s n�zvy v tabulce countries (capital_city).
-- -- Ud�l�m v�po�ty ve sloupc�ch s teplotou, v�trem a de�t�m 
 
SELECT		-- pou�iju ve WITH jako weather_new
	CAST(`date`AS date) AS datum,
	-- pr�m�rn� denn� (nikoli no�n�!) teplota
	-- odstranila jsem " �c", vypo��tala pr�m�r pouze z teplot pro �asy z dan�ho intervalu a zase p�ipojila " �c"
	CONCAT(ROUND((SUM((CASE WHEN `time` IN ('09:00', '12:00', '15:00', '18:00') THEN 1 ELSE 0 END) * REPLACE(temp,' �c', ''))) / 4), ' �c') AS "pr�m._denn�_teplota",	
	-- po�et hodin v dan�m dni, kdy byly sr�ky nenulov�
	SUM(CASE WHEN rain = '0.0 mm' THEN 0 ELSE 1 END) * 3 AS "po�et_hod._se_sr�kami",
	-- maxim�ln� s�la v�tru v n�razech b�hem dne
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
;

-- kontrola
SELECT `date`, `time`, temp, gust, rain FROM weather WHERE city = 'Prague';