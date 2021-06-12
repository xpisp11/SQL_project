# my-github-repo

Fin�ln�m v�stupem projektu je soubor Projekt_final.sql.

Po stisknut� Alt+X vznikne 5 VIEW:

1) v_joined_eco_co_rel
2) v_joined_cov_lt_tests_eco_co_rel
3) v_covid19_tests_new
4) v_joined_cov_lt_tests_eco_co_rel_w 
5) v_Petra_Rohlickova_projekt_SQL_final

Nakonec se z posledn�ho VIEW vytvo�� po�adovan� tabulka:

CREATE TABLE t_Petra_Rohlickova_projekt_SQL_final AS
SELECT *
FROM v_Petra_Rohlickova_projekt_SQL_final 
 

Sou��st� repozit��e jsou tak� n�sleduj�c� soubory, z nich� kl��ov� jsou pouze prvn� dva z nich:

 - Projekt_final_vypis_tabulky.sql - script pro vyps�n� v�sledn� tabulky
 - Projekt_pruvodka.docx - detailn� popis postupu v r�mci cel�ho projektu
 - Projekt_pomocne_tabulky.xlsx - tabulky v excelu slou��c� pro rychlou kontrolu n�zvu zem� a m�st v r�zn�ch tabulk�ch a pro kontrolu v�po�t� v r�mci tabulky weather
 - Projekt_pomocne_tabulky.sql - nov� vytvo�en� tabulky, kter� byly n�sledn� pou�ity v souboru Projekt_final.sql
 - Projekt_priprava.sql - detailn�ji popsan� p��pravn� kroky (��slov�n� "kapitol" nav�z�no na kapitoly v dokumentu Projekt_pruvodka.docx)
 - Projekt_priprava_kontrolni.sql - dotazy pro kontrolu spr�vnosti napojen� tabulek apod.

