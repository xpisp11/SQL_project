-- covid19_tests_new

/* P�iprav�m si nov� tabulky covid19_tests pro "problematick�" zem�, ve kter�ch ur��m jen jednu entitu. Pomoc� UNION tyto tabulky spoj�m spolu navz�jem
   a tak� s tabulkou covid19_tests bez t�chto zem�. T�m z�sk�m novou tabulku covid19_tests_new, kter� u� u t�chto "problematick�ch" zem� nebude m�t
   zdvojen� z�znamy pro ��dn� datum */

CREATE OR REPLACE VIEW v_covid19_tests_new AS
SELECT *
FROM covid19_tests
WHERE country = 'France'
	AND entity = 'tests performed (incl. non-PCR)'
UNION
SELECT *
FROM covid19_tests
WHERE country = 'India'
	AND entity = 'samples tested'
UNION
SELECT *
FROM covid19_tests
WHERE country = 'Italy'
	AND entity = 'tests performed'
UNION 
SELECT *
FROM covid19_tests
WHERE country = 'Japan'
	AND entity = 'people tested (incl. non-PCR)'
UNION 
SELECT *
FROM covid19_tests
WHERE country = 'Poland'
	AND entity = 'samples tested'
UNION 
SELECT *
FROM covid19_tests
WHERE country = 'Singapore'
	AND entity = 'samples tested'
UNION 
SELECT *
FROM covid19_tests
WHERE country = 'United States'
	AND entity = 'tests performed'
UNION	
SELECT *
FROM covid19_tests
WHERE country NOT IN ('France', 'India', 'Italy', 'Japan', 'Poland', 'Singapore', 'United States')
;

SELECT * FROM v_covid19_tests_new; 


-- weather_new

-- P�ep�u si n�zvy hlavn�ch m�st v tabulce weather tak, aby byly shodn� s n�zvy v tabulce countries 
 
SELECT DISTINCT city FROM weather ORDER BY city;
SELECT DISTINCT capital_city FROM countries ORDER BY capital_city;

CREATE OR REPLACE VIEW v_weather_new AS
SELECT
	*,
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
FROM weather;
