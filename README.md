# my-github-repo

Finálním výstupem projektu je soubor Projekt_final.sql

Požadovaná tabulka vznikne postupným vytváøením VIEW obsažených v tomto souboru, tj.:

1) v_joined_eco_co_rel
2) v_joined_cov_lt_tests_eco_co_rel
3) v_covid19_tests_new
4) v_joined_cov_lt_tests_eco_co_rel_w 
5) v_Petra_Rohlickova_projekt_SQL_final

Nakonec se z posledního VIEW vytvoøí požadovaná tabulka:

CREATE TABLE t_Petra_Rohlickova_projekt_SQL_final AS
SELECT *
FROM v_Petra_Rohlickova_projekt_SQL_final 
 

Souèástí repozitáøe jsou také následující soubory:
Projekt_pruvodka.docx - detailní popis postupu v rámci celého projektu
Projekt_pomocne_tabulky.xlsx - tabulky v excelu sloužící pro rychlou kontrolu názvu zemí a mìst v rùzných tabulkách a pro kontrolu výpoètù v rámci tabulky weather
Projekt_priprava.sql - detailnìji popsané pøípravné kroky
Projekt_priprava_kontrolni.sql - dotazy pro kontrolu správnosti napojení tabulek apod.
Projekt_pomocne_tabulky.sql - novì vytvoøené tabulky, které byly následnì použity v souboru Projekt_final.sql