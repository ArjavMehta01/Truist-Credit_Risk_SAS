%let id05 = %nrstr(1iDdiHWP7ihEtEh1zED3XQup0ksdNmK_J);
  %let _url = %nrstr(https://docs.google.com/uc?export=download&id=)&&id05;
  filename url_file url "&_url";
  
  data TNFPayrolls ( drop = lagvar1   lagvar12 );
    infile url_file missover dsd;
    input date :$10. Payrolls;
    lagvar1 = lag(Payrolls) ;
    lagvar12 = lag12(Payrolls);
    logP = log(Payrolls); /*Log transformation*/
    MGT = log ( Payrolls / lagvar1 ); /*Monthly Growth Transformation ( ln(Xt / Xt-1) )*/ 
    AGT = log ( Payrolls / lagvar12 ); /*Annual Growth Transformation ( ln(Xt / Xt-12) ) */
    MRT = ( Payrolls / lagvar1 ) ;/* Monthly Return Transformation ( Xt / Xt-1 ) */
    ART = ( Payrolls / lagvar12 ) ;/* Annual Return Transformation (Xt / Xt-12 ) */
    MDT = dif(lag(Payrolls)); /* Monthly Difference Transformation ( Xt - Xt-1 ) */ 
    pctchng = ( ( Payrolls / lag( Payrolls ) ) ** 12 - 1 ) * 100;
    AnnualGrowth = dif12( Payrolls ) / lag12( Payrolls ) * 100; 
    /*compute percent change from the same period in the previous year*/
  run;