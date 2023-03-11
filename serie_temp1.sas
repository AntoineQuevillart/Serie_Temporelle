/* série originale */
proc sgplot data=sashelp.retail;
	series x=date y=sales / markers
	markerattrs=(color=blue symbol='point')
                               lineattrs=(color=blue)
                               legendlabel="Série originale" ;
    yaxis values=(0 to 5 by 0.1);
	yaxis label="Evolution des ventes quadrimestrielles entre 1980 et 1994" ;
run;

/*confirmer la saisonnalité*/
proc spectra data=sashelp.retail out=spectre_sales p s ;
	var sales ;
	weight parzen ;
run;

/* périodigramme */
proc sgplot data=spectre_sales;
	series x=period y=s_01 / markers markerattrs=(color=black
	symbol=circlefilled);/*circlefilled = pointsnoirs*/
	yaxis label='Périodogramme';
run;

proc x11 data=sashelp.retail noprint;
	quarterly date=date;
	var sales;
	output out=retail_out b1=sales d11=adjusted;
run;

/* comparaison originale et corrigée */
proc sgplot data=retail_out;
	series x=date y=sales / markers
	markerattrs=(color=red symbol='asterisk')
	lineattrs=(color=red)
	legendlabel="original" ;
	series x=date y=adjusted / markers
	markerattrs=(color=blue symbol='circle')
	lineattrs=(color=blue)
	legendlabel="adjusted" ;
	yaxis label='Série originale et série ajustée';
run;

/* série corrigée seule */
proc sgplot data=retail_out;
	series x=date y=adjusted / markers
	markerattrs=(color=blue symbol='point')
                               lineattrs=(color=blue)
                               legendlabel="Série ajustée" ;
    yaxis values=(0 to 5 by 0.1);
	yaxis label="Evolution des ventes trimestrielles entre 1980 et 1994" ;
run;

/* modèle ARIMA */
proc arima data=work.retail_out plots
     (only)=(series(corr crosscorr) residual(corr normal) 
		forecast(forecast forecastonly) );
	identify var=adjusted(1);
	estimate p=(1 2 3) q=(1) method=ML;
	forecast lead=0 back=10 alpha=0.05 id=date interval=qtr;
	outlier;
	run;
quit;
