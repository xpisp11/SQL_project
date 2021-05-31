-- covid19_tests_new

/* Pøipravím si nové tabulky covid19_tests pro "problematické" zemì, ve kterých urèím jen jednu entitu. Pomocí UNION tyto tabulky spojím spolu navzájem
   a také s tabulkou covid19_tests bez tìchto zemí. Tím získám novou tabulku covid19_tests_new, která už u tìchto "problematických" zemí nebude mít
   zdvojené záznamy pro žádné datum */

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

-- Pøepíšu si názvy hlavních mìst v tabulce weather tak, aby byly shodné s názvy v tabulce countries 
 
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
