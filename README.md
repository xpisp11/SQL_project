SQL projekt

P��prava dat pro dal�� anal�zu ���en� COVID-19

Zad�n� projektu

C�lem projektu je p�ipravit pro statistika pracuj�c�ho na ur�en� faktor�, kter� ovliv�uj� rychlost ���en� koronaviru na �rovni jednotliv�ch st�t�, data, kter� bude d�le statisticky zpracov�vat. Bude se jednat o tabulku na datab�zi, ze kter� se budou d�t z�skat po�adovan� data jedn�m selectem. 

V�sledn� data budou panelov�, kl��e budou st�t (country) a den (date). Statistik bude vyhodnocovat model, kter� bude vysv�tlovat denn� n�r�sty naka�en�ch v jednotliv�ch zem�ch. Samotn� po�ty naka�en�ch pro n�j nicm�n� nejsou dosta�uj�c� - je pot�eba vz�t v �vahu tak� po�ty proveden�ch test� a po�et obyvatel dan�ho st�tu. Z t�chto t�� prom�nn�ch bude potom mo�n� vytvo�it vhodnou vysv�tlovanou prom�nnou. Denn� po�ty naka�en�ch budou vysv�tlov�na pomoc� prom�nn�ch n�kolika typ�. Ka�d� sloupec v tabulce bude p�edstavovat jednu prom�nnou, p�i�em� se bude jednat o n�sleduj�c� sloupce:

�asov� prom�nn�
bin�rn� prom�nn� pro v�kend / pracovn� den
ro�n� obdob� dan�ho dne (zak�dovat jako 0 a� 3)

Prom�nn� specifick� pro dan� st�t
hustota zalidn�n� - ve st�tech s vy��� hustotou zalidn�n� se n�kaza m��e ���it rychleji
HDP na obyvatele - pou�ije se jako indik�tor ekonomick� vysp�losti st�tu
GINI koeficient - m� majetkov� nerovnost vliv na ���en� koronaviru?
d�tsk� �mrtnost - pou�ijeme jako indik�tor kvality zdravotnictv�
medi�n v�ku obyvatel v roce 2018 - st�ty se star��m obyvatelstvem mohou b�t posti�eny v�ce
pod�ly jednotliv�ch n�bo�enstv� - pou�ij� se jako proxy prom�nn� pro kulturn� specifika, pro ka�d� n�bo�enstv� v dan�m st�t� je pot�eba ur�it procentn� pod�l jeho p��slu�n�k� na celkov�m obyvatelstvu
rozd�l mezi o�ek�vanou dobou do�it� v roce 1965 a v roce 2015 - st�ty, ve kter�ch prob�hl rychl� rozvoj, mohou reagovat jinak ne� zem�, kter� jsou vysp�l� u� del�� dobu

Po�as� (ovliv�uje chov�n� lid� a tak� schopnost ���en� viru)
pr�m�rn� denn� (nikoli no�n�!) teplota
po�et hodin v dan�m dni, kdy byly sr�ky nenulov�
maxim�ln� s�la v�tru v n�razech b�hem dne

Ve�ker� pot�ebn� data jsou dostupn� v rela�n� datab�zi, p�edev��m v tabulk�ch: countries, economies, life_expectancy, religions, covid19_basic_differences, covid19_testing, weather, lookup_table.

###############################

Fin�ln�m v�stupem projektu je soubor Projekt_final.sql.

Po stisknut� Alt+X vznikne 5 VIEW:

v_joined_eco_co_rel
v_joined_cov_lt_tests_eco_co_rel
v_covid19_tests_new
v_joined_cov_lt_tests_eco_co_rel_w
v_Petra_Rohlickova_projekt_SQL_final
Nakonec se z posledn�ho VIEW vytvo�� po�adovan� tabulka:

CREATE TABLE t_Petra_Rohlickova_projekt_SQL_final AS SELECT * FROM v_Petra_Rohlickova_projekt_SQL_final

Sou��st� repozit��e jsou tak� n�sleduj�c� soubory, z nich� kl��ov� jsou pouze prvn� dva z nich:

Projekt_final_vypis_tabulky.sql - script pro vyps�n� v�sledn� tabulky
Projekt_pruvodka.docx - detailn� popis postupu v r�mci cel�ho projektu
Projekt_priprava.sql - detailn�ji popsan� p��pravn� kroky (��slov�n� "kapitol" nav�z�no na kapitoly v dokumentu Projekt_pruvodka.docx)
Projekt_priprava_kontrolni.sql - dotazy pro kontrolu spr�vnosti napojen� tabulek apod.
Projekt_pomocne_tabulky.xlsx - tabulky v excelu slou��c� pro rychlou kontrolu n�zvu zem� a m�st v r�zn�ch tabulk�ch a pro kontrolu v�po�t� v r�mci tabulky weather
Projekt_pomocne_tabulky.sql - nov� vytvo�en� tabulky, kter� byly n�sledn� pou�ity v souboru Projekt_final.sql