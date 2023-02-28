/* Importation des données */
proc import datafile="C:\Users\antoi\OneDrive\Bureau\M2 SEP\SerieTemp\projet\AEP_hourly.csv"
            out=data_energie;
run;

data energie;
   set data_energie;
   Date = datepart(Datetime);
   format Date date9.;
run;

proc sql;
    create table releve_journalier as
    select distinct date, avg(aep_mw) as aep_mw
    from energie
    group by date;
quit;

proc sort data=releve_journalier;
    by date;
run;

proc sgplot data=releve_journalier;
	series x=Date y=AEP_MW / markers
	markerattrs=(color=blue symbol='asterisk')
                               lineattrs=(color=blue)
                               legendlabel="Série originale" ;
    yaxis values=(0 to 5 by 0.1);
	yaxis label="Consommation horaire d'électricité moyenne par jour en MW (relevé American Electric Power)" ;
run;


/*confirmer la saisonnalité*/
proc spectra data=releve_journalier out=spectre_aep p s ;
var aep_mw ;
weight parzen ;
run;


proc sgplot data=spectre_aep;
series x=period y=s_01 / markers markerattrs=(color=black
symbol=circlefilled);/*circlefilled = pointsnoirs*/
yaxis label='Périodogramme';
run;


proc sgplot data=spectre_aep;
series x=freq y=s_01 / markers markerattrs=(color=black
symbol=circlefilled);
yaxis label='Densité Spectrale';
run;/*période de 100 jours environ*/


proc arima data=releve_journalier;
identify var=aep_mw;
run;
quit;

/* On différencie */
proc arima data=releve_journalier;
identify var=aep_mw(1,100) stationarity=(adf=6);
run;
quit; 


/*SARIMA_12(2,1,0)(1,1,0) */
proc arima data=releve_journalier;
identify var=aep_mw (1,12);
estimate q= (1)(12) plot; /*on reprend les parametres du modele */
forecast lead=24 interval=month id=date out=prev_energie;
run;
quit;

/* On fait des prédiction sur les données de la dernière année (2018) */
data prev_1;
set prev_energie;
debut='01JAN2018'd; /*date où on fait démarrer les prev*/
fin='03AUG2018'd ; /*date où on fait arreter les prev*/
if date lt debut or date gt fin then do;
forecast=.;
l95=.;
u95=.;
end;
run;

/* série réelle vs prévision */
proc sgplot data=prev_1;
series x=date y=aep_mw / markers
markerattrs=(color=black )
lineattrs=(color=black)
legendlabel="Série originale" ;
series x=date y=forecast / markers
markerattrs=(color=red )
lineattrs=(color=red)
legendlabel="Prévision" ;
yaxis label= "Consomation d'energie horaire en MW";
run;


/* Prévision avec région de confiance */
data prev_2;
set prev_energie;
debut='01jan2018'd; /*date où on fait démarrer les previsions*/
if date lt debut then do;
forecast=.;
l95=.;
u95=.;
end;
run;


proc sgplot data=prev_2;
series x=date y=aep_mw / markers
markerattrs=(color=black )
lineattrs=(color=black)
legendlabel="Série originale" ;
series x=date y=forecast / markers
markerattrs=(color=blue )
lineattrs=(color=blue)
legendlabel="Prévision" ;
series x=date y=l95 / markers
markerattrs=(color=green )
lineattrs=(color=green)
legendlabel="borne inf " ;
series x=date y=u95 / markers
markerattrs=(color=red )
lineattrs=(color=red)
legendlabel="borne sup" ;
yaxis label= "Consommation d'energie horaire en MW";
run;
