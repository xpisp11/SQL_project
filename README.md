# SQL projekt

## Příprava dat pro další analýzu šíření COVID-19

**Zadání projektu**

Cílem projektu je připravit pro statistika pracujícího na určení faktorů, které ovlivňují rychlost šíření koronaviru na úrovni jednotlivých států, data, která bude dále statisticky zpracovávat. Bude se jednat o tabulku na databázi, ze které se budou dát získat požadovaná data jedním selectem. 

Výsledná data budou panelová, klíče budou stát (country) a den (date). Statistik bude vyhodnocovat model, který bude vysvětlovat denní nárůsty nakažených v jednotlivých zemích. Samotné počty nakažených pro něj nicméně nejsou dostačující - je potřeba vzít v úvahu také počty provedených testů a počet obyvatel daného státu. Z těchto tří proměnných bude potom možné vytvořit vhodnou vysvětlovanou proměnnou. Denní počty nakažených budou vysvětlována pomocí proměnných několika typů. Každý sloupec v tabulce bude představovat jednu proměnnou, přičemž se bude jednat o následující sloupce:

Časové proměnné
- binární proměnná pro víkend / pracovní den
- roční období daného dne (zakódovat jako 0 až 3)

Proměnné specifické pro daný stát
- hustota zalidnění - ve státech s vyšší hustotou zalidnění se nákaza může šířit rychleji
- HDP na obyvatele - použije se jako indikátor ekonomické vyspělosti státu
- GINI koeficient - má majetková nerovnost vliv na šíření koronaviru?
- dětská úmrtnost - použijeme jako indikátor kvality zdravotnictví
- medián věku obyvatel v roce 2018 - státy se starším obyvatelstvem mohou být postiženy více
- podíly jednotlivých náboženství - použijí se jako proxy proměnná pro kulturní specifika, pro každé náboženství v daném státě je potřeba určit procentní podíl jeho příslušníků na celkovém obyvatelstvu
- rozdíl mezi očekávanou dobou dožití v roce 1965 a v roce 2015 - státy, ve kterých proběhl rychlý rozvoj, mohou reagovat jinak než země, které jsou vyspělé už delší dobu

Počasí (ovlivňuje chování lidí a také schopnost šíření viru)
- průměrná denní (nikoli noční!) teplota
- počet hodin v daném dni, kdy byly srážky nenulové
- maximální síla větru v nárazech během dne

Veškerá potřebná data jsou dostupná v relační databázi, především v tabulkách: countries, economies, life_expectancy, religions, covid19_basic_differences, covid19_testing, weather, lookup_table.



**Výstup projektu**

Finálním výstupem projektu je soubor Projekt_final.sql.

Po stisknutí Alt+X vznikne 5 VIEW:

v_joined_eco_co_rel
v_joined_cov_lt_tests_eco_co_rel
v_covid19_tests_new
v_joined_cov_lt_tests_eco_co_rel_w
v_Petra_Rohlickova_projekt_SQL_final
Nakonec se z posledního VIEW vytvoří požadovaná tabulka:

CREATE TABLE t_Petra_Rohlickova_projekt_SQL_final AS SELECT * FROM v_Petra_Rohlickova_projekt_SQL_final

Součástí repozitáře jsou také následující soubory, z nichž klíčové jsou pouze první dva z nich:

Projekt_final_vypis_tabulky.sql - script pro vypsání výsledné tabulky
Projekt_pruvodka.docx - detailní popis postupu v rámci celého projektu
Projekt_priprava.sql - detailněji popsané přípravné kroky (číslování "kapitol" navázáno na kapitoly v dokumentu Projekt_pruvodka.docx)
Projekt_priprava_kontrolni.sql - dotazy pro kontrolu správnosti napojení tabulek apod.
Projekt_pomocne_tabulky.xlsx - tabulky v excelu sloužící pro rychlou kontrolu názvu zemí a měst v různých tabulkách a pro kontrolu výpočtů v rámci tabulky weather
Projekt_pomocne_tabulky.sql - nově vytvořené tabulky, které byly následně použity v souboru Projekt_final.sql
