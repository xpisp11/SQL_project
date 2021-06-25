-- Zobrazeni cele tabulky
SELECT * 
FROM t_petra_rohlickova_projekt_sql_final;


-- Navrh zobrazeni "vyrezu" tabulky v navaznosti na dostupnost dat
SELECT * 
FROM t_petra_rohlickova_projekt_sql_final
WHERE 1=1
	AND datum <= '2020-11-24'		-- informace o testovani jsou dostupne pouze do 24. 11. 2020, takze pokud jsou tyto informace pro analyzu zasadni, dava smysl tabulku omezit 
ORDER BY datum DESC;	-- razeni vhodne pro porovnani vyvoje mezi ruznymi zememi


SELECT * 
FROM t_petra_rohlickova_projekt_sql_final
WHERE 1=1
	AND datum <= '2020-11-24'		-- informace o testovani jsou dostupne pouze do 24. 11. 2020, takze pokud jsou tyto informace pro analyzu zasadni, dava smysl tabulku omezit 
ORDER BY zeme;	-- razeni vhodne pro analyzu vyvoje v case v jednotlivych zemi
