-- Zobrazen� cel� tabulky
SELECT * 
FROM t_petra_rohlickova_projekt_sql_final;


-- N�vrh zobrazen� "v��ezu" tabulky v n�vaznosti na dostupnost dat
SELECT * 
FROM t_petra_rohlickova_projekt_sql_final
WHERE 1=1
	AND datum <= '2020-11-24'		-- informace o testov�n� jsou dostupn� pouze do 24. 11. 2020, tak�e pokud jsou tyto informace pro anal�zu z�sadn�, d�v� smysl tabulku omezit 
ORDER BY datum DESC;	-- �azen� vhodn� pro porovn�n� v�voje mezi r�zn�mi zem�mi


SELECT * 
FROM t_petra_rohlickova_projekt_sql_final
WHERE 1=1
	AND datum <= '2020-11-24'		-- informace o testov�n� jsou dostupn� pouze do 24. 11. 2020, tak�e pokud jsou tyto informace pro anal�zu z�sadn�, d�v� smysl tabulku omezit 
ORDER BY zem�;	-- �azen� vhodn� pro anal�zu v�voje v �ase v jednotliv�ch zem�
