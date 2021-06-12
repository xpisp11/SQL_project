-- Zobrazení celé tabulky
SELECT * 
FROM t_petra_rohlickova_projekt_sql_final;


-- Návrh zobrazení "výøezu" tabulky v návaznosti na dostupnost dat
SELECT * 
FROM t_petra_rohlickova_projekt_sql_final
WHERE 1=1
	AND datum <= '2020-11-24'		-- informace o testování jsou dostupné pouze do 24. 11. 2020, takže pokud jsou tyto informace pro analýzu zásadní, dává smysl tabulku omezit 
ORDER BY datum DESC;	-- øazení vhodné pro porovnání vývoje mezi rùznými zemìmi


SELECT * 
FROM t_petra_rohlickova_projekt_sql_final
WHERE 1=1
	AND datum <= '2020-11-24'		-- informace o testování jsou dostupné pouze do 24. 11. 2020, takže pokud jsou tyto informace pro analýzu zásadní, dává smysl tabulku omezit 
ORDER BY zemì;	-- øazení vhodné pro analýzu vývoje v èase v jednotlivých zemí
