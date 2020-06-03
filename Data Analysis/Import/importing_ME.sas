/* Importing Macroeoconomics Data */



%let datasets = Housing_Starts;



/* Housing Starts (Monthly)  */

  %let id01 = %nrstr(1YqgLuVYbwK8LQGL05yiDLzt-PchZN751);
  %let _url = %nrstr(https://docs.google.com/uc?export=download&id=)&&id01;
  filename url_file url "&_url";
  
  data Housing_Starts;
    infile url_file  missover dsd firstobs=2;
    input date:YYMMDD10. HousingSt_Var;
    label
    HousingSt_Var = "Housing Starts"
    logP = "Log Transformation"
    MGT = "Monthly Growth Transformation"
    AGT = "Annual Growth Transformation"
    MRT = "Monthly Return Transformation"
    ART = "Annual Return Transformation"
    MDT = "Monthly Difference Transformation"
    pctchng = "Percetnage Change"
    AG = "Annual Growth in Percent"
    ;
    format date mmddyy8. logP MGT AGT MRT ART MDT comma10.5 pctchng AG percent10.2;
    lagvar1 = lag(HousingSt_Var) ;
    lagvar12 = lag12(HousingSt_Var);
    logP = log(HousingSt_Var); /*Log transformation*/
    MGT = log ( HousingSt_Var / lagvar1 ); /*Monthly Growth Transformation ( ln(Xt / Xt-1) )*/ 
    AGT = log ( HousingSt_Var / lagvar12 ); /*Annual Growth Transformation ( ln(Xt / Xt-12) ) */
    MRT = ( HousingSt_Var / lagvar1 ) ;/* Monthly Return Transformation ( Xt / Xt-1 ) */
    ART = ( HousingSt_Var / lagvar12 ) ;/* Annual Return Transformation (Xt / Xt-12 ) */
    MDT = dif(lag(HousingSt_Var)); /* Monthly Difference Transformation ( Xt - Xt-1 ) */  
    pctchng = ( ( HousingSt_Var / lag( HousingSt_Var ) ) ** 12 - 1 ) * 100;
    AG = dif12( HousingSt_Var ) / lag12( HousingSt_Var ) * 100; /*computed percent change from the same period in the previous year*/
  run;
  

/* US GDP (Quarterly) */

  %let id02 = %nrstr(1Nolfw8rIW7gFQEbKAR3X-4KaSKUNMZzZ);
  %let _url = %nrstr(https://docs.google.com/uc?export=download&id=)&&id02;
  filename url_file url "&_url";
  
  data GDP (drop = lagvar1 lagvar4 );
    infile url_file missover dsd;
    input date :$10. GDP_Var;
    label 
    GDP_Var = "US GDP"
    logP = "Log Transformation"
    QGT = "Quarterly Growth Transformation"
    AGT = "Annual Growth Transformation"
    QRT = "Quarterly Return Transformation"
    ART = "Annual Return Transformation"
    QDT = "Quarterly Difference Transformation"
    pctchng = "Percetnage Change"
    AG = "Annual Growth in Percent"
    ;
    format logP QGT AGT QRT ART QDT comma10.5 pctchng AG percent10.2;
    lagvar1 = lag(GDP_Var) ;
    lagvar4 = lag4(GDP_Var);
    logP = log(GDP_Var); /*Log transformation*/
    QGT = log ( GDP_Var / lagvar1 ); /*Quarterly Growth Transformation ( ln(Xt / Xt-1) )*/ 
    AGT = log ( GDP_Var / lagvar4 ); /*Annual Growth Transformation ( ln(Xt / Xt-4) ) */
    QRT = ( GDP_Var / lagvar1 ) ;/* Quarterly Return Transformation ( Xt / Xt-1 ) */
    ART = ( GDP_Var / lagvar1 ) ;/* Annual Return Transformation (Xt / Xt-4 ) */
    QDT = dif(lag(GDP_Var)); /* Quarterly Difference Transformation ( Xt - Xt-1 ) */  
    pctchng = ( ( GDP_Var / lag( GDP_Var ) ) ** 12 - 1 ) * 100;
    AG = dif4( GDP_Var ) / lag4( GDP_Var ) * 100; /*computed percent change from the same period in the previous year*/
  run;
  


/* Unemployment (Monthly) */
  
  %let id03 = %nrstr(1QhbI6yakMv9Q-8dwn0nwcJeX6kWQjJ76);
  %let _url = %nrstr(https://docs.google.com/uc?export=download&id=)&&id03;
  filename url_file url "&_url";
  
  data Unemployment ( drop = date);
    infile url_file missover dsd;
    input date :$10. Unemp_Var;
    label
    logP = "Log Transformation"
    MGT = "Monthly Growth Transformation"
    AGT = "Annual Growth Transformation"
    MRT = "Monthly Return Transformation"
    ART = "Annual Return Transformation"
    MDT = "Monthly Difference Transformation"
    pctchng = "Percetnage Change"
    AG = "Annual Growth in Percent"
    ;
    format logP MGT AGT MRT ART MDT comma10.5 pctchng AG percentN10.2 ;
    lagvar1 = lag(Unemp_Var) ;
    lagvar12 = lag12(Unemp_Var);
    logP = log(Unemp_Var); /*Log transformation*/
    MGT = log ( Unemp_Var / lagvar1 ); /*Monthly Growth Transformation ( ln(Xt / Xt-1) )*/ 
    AGT = log ( Unemp_Var / lagvar12 ); /*Annual Growth Transformation ( ln(Xt / Xt-12) ) */
    MRT = ( Unemp_Var / lagvar1 ) ;/* Monthly Return Transformation ( Xt / Xt-1 ) */
    ART = ( Unemp_Var / lagvar12 ) ;/* Annual Return Transformation (Xt / Xt-12 ) */
    MDT = dif(lag(Unemp_Var)); /* Monthly Difference Transformation ( Xt - Xt-1 ) */  
    pctchng = ( ( Unemp_Var / lag( Unemp_Var ) ) ** 12 - 1 ) * 100;
    AG = dif12( Unemp_Var ) / lag12( Unemp_Var ) * 100; /*computed percent change from the same period in the previous year*/
  run;
  
  
/*   Mortgage Rates (Weekly) */
  
  %let id04 = %nrstr(1RsN5jzXeEbLtYxVs_rXvBBXrasaymG6k);
  %let _url = %nrstr(https://docs.google.com/uc?export=download&id=)&&id04;
  filename url_file url "&_url";
  
  data MortgageRate30;
    infile url_file missover dsd;
    input date :$10. Rates;
  run;
  
  
/*   Total Non-farm Payrolls (Monthly) */
  %let id05 = %nrstr(1iDdiHWP7ihEtEh1zED3XQup0ksdNmK_J);
  %let _url = %nrstr(https://docs.google.com/uc?export=download&id=)&&id05;
  filename url_file url "&_url";
  
  data TNFPayrolls ( drop = lagvar1   lagvar12 );
    infile url_file missover dsd;
    input date :$10. Payrolls;
    label
    logP = "Log Transformation"
    MGT = "Monthly Growth Transformation"
    AGT = "Annual Growth Transformation"
    MRT = "Monthly Return Transformation"
    ART = "Annual Return Transformation"
    MDT = "Monthly Difference Transformation"
    pctchng = "Percetnage Change"
    AG = "Annual Growth in Percent"
    ;
    format logP MGT AGT MRT ART MDT comma10.5 pctchng AG percent10.2;
    lagvar1 = lag(Payrolls) ;
    lagvar12 = lag12(Payrolls);
    logP = log(Payrolls); /*Log transformation*/
    MGT = log ( Payrolls / lagvar1 ); /*Monthly Growth Transformation ( ln(Xt / Xt-1) )*/ 
    AGT = log ( Payrolls / lagvar12 ); /*Annual Growth Transformation ( ln(Xt / Xt-12) ) */
    MRT = ( Payrolls / lagvar1 ) ;/* Monthly Return Transformation ( Xt / Xt-1 ) */
    ART = ( Payrolls / lagvar12 ) ;/* Annual Return Transformation (Xt / Xt-12 ) */
    MDT = dif(lag(Payrolls)); /* Monthly Difference Transformation ( Xt - Xt-1 ) */ 
    pctchng = ( ( Payrolls / lag( Payrolls ) ) ** 12 - 1 ) * 100;
    AG = dif12( Payrolls ) / lag12( Payrolls ) * 100; /*computed percent change from the same period in the previous year*/
  run;
  

  
/*   Fed Funds Rate (Daily) */
  
  
  %let id06 = %nrstr(1o4XiUZAUk0K5eXyjyjU5jCBafpCnvcJa);
  %let _url = %nrstr(https://docs.google.com/uc?export=download&id=)&&id06;
  filename url_file url "&_url";
  
  data FedFundsR;
    infile url_file missover dsd firstobs=2;
    input date :$10. Fed_Rate;
  run;
  
  
/*   Housing Permits (Monthly) */
  
  %let id07 = %nrstr(1p1oHE48ef87PLNcsLdfw1AbVo0VmwwGA);
  %let _url = %nrstr(https://docs.google.com/uc?export=download&id=)&&id07;
  filename url_file url "&_url";
  
  data Permits;
    infile url_file missover dsd;
    input date :$10. Permits;
    label
    logP = "Log Transformation"
    MGT = "Monthly Growth Transformation"
    AGT = "Annual Growth Transformation"
    MRT = "Monthly Return Transformation"
    ART = "Annual Return Transformation"
    MDT = "Monthly Difference Transformation"
    pctchng = "Percetnage Change"
    AG = "Annual Growth in Percent"
    ;
    format logP MGT AGT MRT ART MDT comma10.5 pctchng AG percent10.2;
    lagvar1 = lag(Permits) ;
    lagvar12 = lag12(Permits);
    logP = log(Permits); /*Log transformation*/
    MGT = log ( Permits / lagvar1 ); /*Monthly Growth Transformation ( ln(Xt / Xt-1) )*/ 
    AGT = log ( Permits / lagvar12 ); /*Annual Growth Transformation ( ln(Xt / Xt-12) ) */
    MRT = ( Permits / lagvar1 ) ;/* Monthly Return Transformation ( Xt / Xt-1 ) */
    ART = ( Permits / lagvar12 ) ;/* Annual Return Transformation (Xt / Xt-12 ) */
    MDT = dif(lag(Permits)); /* Monthly Difference Transformation ( Xt - Xt-1 ) */  
    pctchng = ( ( Permits / lag( Permits ) ) ** 12 - 1 ) * 100;
    AG = dif12( Permits ) / lag12( Permits ) * 100; /*computed percent change from the same period in the previous year*/
  run;
  
  
/*   Producer Price Index (Monthly) */
   
  %let id08 = %nrstr(1sWqtgRpuOFZ6JHbIQXs399JAgcxeR5zP);
  %let _url = %nrstr(https://docs.google.com/uc?export=download&id=)&&id08;
  filename url_file url "&_url";
  
  data ProducerPI(drop = lagvar1 lagvar12);
    infile url_file missover dsd firstobs=2;
    input date :$10. PPI_Var;
    label
    logP = "Log Transformation"
    MGT = "Monthly Growth Transformation"
    AGT = "Annual Growth Transformation"
    MRT = "Monthly Return Transformation"
    ART = "Annual Return Transformation"
    MDT = "Monthly Difference Transformation"
    pctchng = "Percetnage Change"
    AG = "Annual Growth in Percent"
    ;
    format logP MGT AGT MRT ART MDT comma10.5 pctchng AG percent10.2;
    lagvar1 = lag(PPI_Var) ;
    lagvar12 = lag12(PPI_Var);
    logP = log(PPI_Var); /*Log transformation*/
    MGT = log ( PPI_Var / lagvar1 ); /*Monthly Growth Transformation ( ln(Xt / Xt-1) )*/ 
    AGT = log ( PPI_Var / lagvar12 ); /*Annual Growth Transformation ( ln(Xt / Xt-12) ) */
    MRT = ( PPI_Var / lagvar1 ) ;/* Monthly Return Transformation ( Xt / Xt-1 ) */
    ART = ( PPI_Var / lagvar12 ) ;/* Annual Return Transformation (Xt / Xt-12 ) */
    MDT = dif(lag(PPI_Var)); /* Monthly Difference Transformation ( Xt - Xt-1 ) */  
    pctchng = ( ( PPI_Var / lag( PPI_Var ) ) ** 12 - 1 ) * 100;
    AG = dif12( PPI_Var ) / lag12( PPI_Var ) * 100; /*computed percent change from the same period in the previous year*/
  run;
 
 
 
/* Consumer Price Index (Monthly) */

  %let id09 = %nrstr(1t2sUcFeJKm4nh7s5fkb7wRGUr0to8M4t);
  %let _url = %nrstr(https://docs.google.com/uc?export=download&id=)&&id09;
  filename url_file url "&_url";
  
  data ConsumerPI;
    infile url_file missover dsd firstobs=2;
    input date :$10. CPI_Var;
    label
    logP = "Log Transformation"
    MGT = "Monthly Growth Transformation"
    AGT = "Annual Growth Transformation"
    MRT = "Monthly Return Transformation"
    ART = "Annual Return Transformation"
    MDT = "Monthly Difference Transformation"
    pctchng = "Percetnage Change"
    AG = "Annual Growth in Percent"
    ;
    format logP MGT AGT MRT ART MDT comma10.5 pctchng AG percent10.2;
    lagvar1 = lag(CPI_Var) ;
    lagvar12 = lag12(CPI_Var);
    logP = log(CPI_Var); /*Log transformation*/
    MGT = log ( CPI_Var / lagvar1 ); /*Monthly Growth Transformation ( ln(Xt / Xt-1) )*/ 
    AGT = log ( CPI_Var / lagvar12 ); /*Annual Growth Transformation ( ln(Xt / Xt-12) ) */
    MRT = ( CPI_Var / lagvar1 ) ;/* Monthly Return Transformation ( Xt / Xt-1 ) */
    ART = ( CPI_Var / lagvar12 ) ;/* Annual Return Transformation (Xt / Xt-12 ) */
    MDT = dif(lag(CPI_Var)); /* Monthly Difference Transformation ( Xt - Xt-1 ) */  
    pctchng = ( ( CPI_Var / lag( CPI_Var ) ) ** 12 - 1 ) * 100;
    AG = dif12( CPI_Var ) / lag12( CPI_Var ) * 100; /*computed percent change from the same period in the previous year*/
  run;
  
  
  
  
  
  data PD_DATA.macro(rename = (date = act_date));
    set &datasets;
  run;