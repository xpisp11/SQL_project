-- kontrola velikosti tabulky 
SELECT 
	"covid19_basic_differences" AS "Table",
	COUNT(*) AS Row_count
FROM covid19_basic_differences
UNION
SELECT 
	"joined_table" AS "Table",
	COUNT (*) AS Row_count
FROM v_joined_covid_lookup_economies_countries;
