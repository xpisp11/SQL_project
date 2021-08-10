SQL projekt

Pøíprava dat pro další analýzu šíøení COVID-19

Zadání projektu

Cílem projektu je pøipravit pro statistika pracujícího na urèení faktorù, které ovlivòují rychlost šíøení koronaviru na úrovni jednotlivých státù, data, která bude dále statisticky zpracovávat. Bude se jednat o tabulku na databázi, ze které se budou dát získat požadovaná data jedním selectem. 

Výsledná data budou panelová, klíèe budou stát (country) a den (date). Statistik bude vyhodnocovat model, který bude vysvìtlovat denní nárùsty nakažených v jednotlivých zemích. Samotné poèty nakažených pro nìj nicménì nejsou dostaèující - je potøeba vzít v úvahu také poèty provedených testù a poèet obyvatel daného státu. Z tìchto tøí promìnných bude potom možné vytvoøit vhodnou vysvìtlovanou promìnnou. Denní poèty nakažených budou vysvìtlována pomocí promìnných nìkolika typù. Každý sloupec v tabulce bude pøedstavovat jednu promìnnou, pøièemž se bude jednat o následující sloupce:

Èasové promìnné
binární promìnná pro víkend / pracovní den
roèní období daného dne (zakódovat jako 0 až 3)

Promìnné specifické pro daný stát
hustota zalidnìní - ve státech s vyšší hustotou zalidnìní se nákaza mùže šíøit rychleji
HDP na obyvatele - použije se jako indikátor ekonomické vyspìlosti státu
GINI koeficient - má majetková nerovnost vliv na šíøení koronaviru?
dìtská úmrtnost - použijeme jako indikátor kvality zdravotnictví
medián vìku obyvatel v roce 2018 - státy se starším obyvatelstvem mohou být postiženy více
podíly jednotlivých náboženství - použijí se jako proxy promìnná pro kulturní specifika, pro každé náboženství v daném státì je potøeba urèit procentní podíl jeho pøíslušníkù na celkovém obyvatelstvu
rozdíl mezi oèekávanou dobou dožití v roce 1965 a v roce 2015 - státy, ve kterých probìhl rychlý rozvoj, mohou reagovat jinak než zemì, které jsou vyspìlé už delší dobu

Poèasí (ovlivòuje chování lidí a také schopnost šíøení viru)
prùmìrná denní (nikoli noèní!) teplota
poèet hodin v daném dni, kdy byly srážky nenulové
maximální síla vìtru v nárazech bìhem dne

Veškerá potøebná data jsou dostupná v relaèní databázi, pøedevším v tabulkách: countries, economies, life_expectancy, religions, covid19_basic_differences, covid19_testing, weather, lookup_table.

###############################

Finálním výstupem projektu je soubor Projekt_final.sql.

Po stisknutí Alt+X vznikne 5 VIEW:

v_joined_eco_co_rel
v_joined_cov_lt_tests_eco_co_rel
v_covid19_tests_new
v_joined_cov_lt_tests_eco_co_rel_w
v_Petra_Rohlickova_projekt_SQL_final
Nakonec se z posledního VIEW vytvoøí požadovaná tabulka:

CREATE TABLE t_Petra_Rohlickova_projekt_SQL_final AS SELECT * FROM v_Petra_Rohlickova_projekt_SQL_final

Souèástí repozitáøe jsou také následující soubory, z nichž klíèové jsou pouze první dva z nich:

Projekt_final_vypis_tabulky.sql - script pro vypsání výsledné tabulky
Projekt_pruvodka.docx - detailní popis postupu v rámci celého projektu
Projekt_priprava.sql - detailnìji popsané pøípravné kroky (èíslování "kapitol" navázáno na kapitoly v dokumentu Projekt_pruvodka.docx)
Projekt_priprava_kontrolni.sql - dotazy pro kontrolu správnosti napojení tabulek apod.
Projekt_pomocne_tabulky.xlsx - tabulky v excelu sloužící pro rychlou kontrolu názvu zemí a mìst v rùzných tabulkách a pro kontrolu výpoètù v rámci tabulky weather
Projekt_pomocne_tabulky.sql - novì vytvoøené tabulky, které byly následnì použity v souboru Projekt_final.sql