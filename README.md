# my-github-repo

Finálním výstupem projektu je soubor Projekt_final.sql.

Po stisknutí Alt+X vznikne 5 VIEW:

1) v_joined_eco_co_rel
2) v_joined_cov_lt_tests_eco_co_rel
3) v_covid19_tests_new
4) v_joined_cov_lt_tests_eco_co_rel_w 
5) v_Petra_Rohlickova_projekt_SQL_final

Nakonec se z posledního VIEW vytvoøí požadovaná tabulka:

CREATE TABLE t_Petra_Rohlickova_projekt_SQL_final AS
SELECT *
FROM v_Petra_Rohlickova_projekt_SQL_final 
 

Souèástí repozitáøe jsou také následující soubory, z nichž klíèové jsou pouze první dva z nich:

 - Projekt_final_vypis_tabulky.sql - script pro vypsání výsledné tabulky
 - Projekt_pruvodka.docx - detailní popis postupu v rámci celého projektu
 - Projekt_pomocne_tabulky.xlsx - tabulky v excelu sloužící pro rychlou kontrolu názvu zemí a mìst v rùzných tabulkách a pro kontrolu výpoètù v rámci tabulky weather
 - Projekt_pomocne_tabulky.sql - novì vytvoøené tabulky, které byly následnì použity v souboru Projekt_final.sql
 - Projekt_priprava.sql - detailnìji popsané pøípravné kroky (èíslování "kapitol" navázáno na kapitoly v dokumentu Projekt_pruvodka.docx)
 - Projekt_priprava_kontrolni.sql - dotazy pro kontrolu správnosti napojení tabulek apod.

