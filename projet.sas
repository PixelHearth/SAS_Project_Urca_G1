/*Création d'une bibliothèque*/
LIBNAME projetM2 "/home/u62535957/projetM2";

PROC IMPORT DATAFILE="/home/u62535957/projetM2/vehicules-2022.csv"
    DBMS = CSV replace
    OUT = projetM2.vehicules;
    delimiter=";";
    GETNAMES= Yes;
    GUESSINGROWS=2790;
RUN;

PROC IMPORT DATAFILE="/home/u62535957/projetM2/usagers-2022.csv"
    DBMS = CSV replace
    OUT = projetM2.usagers;
    delimiter=";";
    GETNAMES= Yes;
    GUESSINGROWS=2790;
RUN;

PROC IMPORT DATAFILE="/home/u62535957/projetM2/lieux-2022.csv"
    DBMS = CSV replace
    OUT = projetM2.lieux;
    delimiter=";";
    GETNAMES= Yes;
    GUESSINGROWS=2790;
RUN;

PROC IMPORT DATAFILE="/home/u62535957/projetM2/carcteristiques-2022.csv"
    DBMS = CSV replace
    OUT = projetM2.caracteristiques;
    delimiter=";";
    GETNAMES= Yes;
    GUESSINGROWS=2790;
RUN;

/* 1) Nombre d'accidents par départemetns*/
proc freq data=work.table ;
	TABLES departement / OUT=table_freq_departement;
RUN;

/* 2) Nb d'accident en marne en decembre /et le 23 decembre*/

proc sql ;
SELECT COUNT(*) AS Nombre_Accidents
FROM projetM2.caracteristiques
WHERE dep = "51" AND mois = "12";
quit;

proc sql ;
SELECT COUNT(*) AS Nombre_Accidents
FROM projetM2.caracteristiques
WHERE dep = "51" AND mois = "12" AND jour = "23";
quit;

/* 3) classez les accidents par luminosite et meteo (pluvieux neigeux sec ...)*/
/*lum
Lumière : conditions d’éclairage dans lesquelles l'accident s'est produit :
1 – Plein jour
2 – Crépuscule ou aube
3 – Nuit sans éclairage public
4 – Nuit avec éclairage public non allumé
5 – Nuit avec éclairage public allumé*/

/*atm
Conditions atmosphériques :
-1 – Non renseigné
1 – Normale
2 – Pluie légère
3 – Pluie forte
4 – Neige - grêle
5 – Brouillard - fumée
6 – Vent fort - tempête
7 – Temps éblouissant
8 – Temps couvert
9 – Autre*/

proc sql ;
SELECT *
FROM projetM2.caracteristiques
WHERE dep = "51" AND mois = "08"
GROUP BY lum,atm;
quit;

%macro accidents(dep_val);
  proc sql;
    SELECT *
    FROM work.caracteristiques
    WHERE dep = "&dep_val" AND mois = "08"
    GROUP BY lum, atm;
  quit;
%mend;

%accidents(51);



/* 4) Meme requete mais en decembre en marne */



/* 5) Nb d'accident mortel des femmes en temps neigeux /
/ variable à utiliser sexe (2,femme) de usagers, temps neigeux (atm 4 caractéristiques), nombre d'accident grav usagers 2 /
*/

proc sql;
select sum(u.grav = "2") as Nbre_accident_mortel_femme
from projetM2.usagers  as u
left join projetM2.caracteristiques as c on u.Num_Acc= c.Accident_id
where u.sexe = "2" and c.atm = "4";
run;
 
/* 6) Accidents ayant lieu dans un parking grouper par genre par age du plus jeune au plus vieux  /
/  variable à utiliser catr 6 – Parc de stationnement ouvert à la circulation publique lieux, sexe usagers, an_nais - today usagers/
*/


proc sql;
select sexe, count(Num_acc) as nombre_accident, year(today()) - input(an_nais,4.) as age
from projetM2.usagers
where sexe ="1" or sexe = "2"
group by sexe,age; / Filtre les enregistrements avec une date de naissance non nulle /
run;


proc freq data=projetm2.usagers;
table an_nais;
run;


/* 7)Nb de personnes de -25ans qui ont eu des accidents entre 23h et 5h */


proc sql;
select count(u.Num_acc) as nombre_accident, year(today()) - input(u.an_nais, 4.) as age
from projetM2.usagers as u 
left join projetM2.caracteristiques as c on u.Num_acc = c.Accident_Id
WHERE input(SUBSTR(c.hrmn, 1, 2), 2.)  OR input(SUBSTR(c.hrmn, 1, 2), 2.)  
group by age
having age ge 20 and age is not null;
quit;


/* 8)Nb de morts qui n'avait pas leur ceinture */
proc sql;

    select count(usa.id_usager)
    from    projetM2.usagers as usa
    left join projetM2.vehicules as veh on usa.id_vehicule = veh.id_vehicule
    where (secu1^='1' and secu2^='1' and secu3^='1') and (grav='2') and (catv = '4' or catv = '10' or catv = '11' or catv = '12' )
    ;
quit;

proc sql;

    select count(usa.id_usager)
    from    projetM2.usagers as usa
    left join projetM2.vehicules as veh on usa.id_vehicule = veh.id_vehicule
    where (secu1='1' and secu2='1' and secu3='1') and (grav='2') and (catv = '4' or catv = '10' or catv = '11' or catv = '12' )
    ;
quit;


/* 9) Nb de morts de velo qui n'avait pas de securite (ceinture) */
proc sql;

    select count(usa.id_usager)
    from    projetM2.usagers as usa
    left join projetM2.vehicules as veh on usa.id_vehicule = veh.id_vehicule
    where (secu1='0'and secu2<='0' and secu3<='0') and (grav='2'or grav = '3') and (catv = '1' )
    ;
quit;

proc sql;

    select count(usa.id_usager)
    from    projetM2.usagers as usa
    left join projetM2.vehicules as veh on usa.id_vehicule = veh.id_vehicule
    where (secu1='2') and (grav='2' or grav = '3') and (catv = '1' )
    ;
quit;

/* 10) Nombre d'accidents genre par genre et les classez par la gravité */
proc sql;
    select u1.sexe, u1.grav
    from    projetM2.usagers as u1
    left join projetM2.usagers as u2 on u1.id_usager = u2.id_usager
    where (u1.sexe=u2.sexe and u1.sexe>'0' and u1.grav>'0' )
    group by u1.sexe,u1.grav;
quit;




/* Test d'independance */

DATA test_indep;
	set projetm2.usagers ;
	keep sexe an_nais grav;
	where sexe = '1' or sexe = '2';
RUN;

proc freq DATA=test_indep;
TABLE an_nais*grav / chisq ;
run;


