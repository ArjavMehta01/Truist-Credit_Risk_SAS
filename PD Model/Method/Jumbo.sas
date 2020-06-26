/* Author: Jonas */
/* Purpose: Build multinomial logistic regression */


%let cvar = fthb_flg Prop_typ Purpose Num_unit Occ_stat;

%let var = oltv dti curr_rte cscore_b loan_age hs ump gdp &cvar;



  

proc contents data = PD_DATA.cur;
run;

 proc freq data = PD_DATA.cur;
 table orig_amt;
 run;



  data PD_DATA.Loans;
    set PD_DATA.del(keep = act_date next_stat Orig_amt &var);
    format yqtr yyq.;
    yqtr = yyq(year(act_date),qtr(act_date));
    if (0 < Orig_amt < 510000) then Loan_Type = 'Conventional';
    if (510000<=Orig_amt) then Loan_Type = 'Jumbo';
    if ^missing(Orig_amt);  
   run;
   
   
/*    proc freq data = Pd_data.loans; */
/*    table Loan_Type; */
/*    run; */
/*     */
/*   */
/*   proc sgplot data = PD_DATA.Loans ; */
/*     loess y = cscore_b x = orig_amt  /  group = Loan_Type smooth = 0.25; */
/*     xaxis label = "Loans" grid; */
/*     yaxis label = "Fico" grid; */
/*   run; */
/*  */
/*     */
/*     */
/*   proc sort data = PD_DATA.Loans out = PD_DATA.tmp (keep =  yqtr next_stat Orig_amt Loan_Type) tagsort; */
/*     by Orig_amt yqtr; */
/*   run; */
/*  */
/*  */
/*  */
/*  */
/*  */





    proc print data = PD_data.loans (obs = 100);
   run;
   
   
   
/*    proc freq data = PD_DATA.Loans; */
/*    table Loan_Type; */
/*    run; */
   
   
   
   
   





%put ----------------------------------------------------------------- DATA PREPARATION;
* Grouping the Original Amount;

%macro by_Orig_amt(d_pd);

   data PD_DATA._&d_pd;
    set PD_DATA.&d_pd(keep = act_date next_stat Orig_amt &var);
    format yqtr yyq.;
    yqtr = yyq(year(act_date),qtr(act_date));
    if (0 < Orig_amt < &score) then Loan_Type = 'Conventional';
    if (&score<=Orig_amt) then Loan_Type = 'Jumbo';
    if ^missing(Orig_amt);  
   run;
   

%mend by_Orig_amt;

/*
proc freq data = data.loan;
  table curr_stat*next_stat;
run;
*/











%put ----------------------------------------------------------------- PLOT;
* compute the probability;
%macro plot(d_pd);

  %if "&d_pd" = "CUR" %then %do;
    %let next = DEL;
    %let n_next = Delinquent;
  %end;
  %if "&d_pd" = "DEL" %then %do;
    %let next = SDQ;
    %let n_next = Default;
  %end;

  proc sort data = PD_DATA._&d_pd (keep =  yqtr next_stat Orig_amt Loan_Type) tagsort;
    by Orig_amt yqtr;
  run;

  ods output CrossTabFreqs = tmp(keep = yqtr Orig_amt Loan_Type
                                        rowpercent next_stat 
                                where = (next_stat = "&next"));
  proc freq data = PD_DATA._&d_pd;
    table yqtr*next_stat;
    by Loan_Type;
  run;


 
  title "Time series plots for &d_pd data";
  title2 j = l "Next State: &n_next";
  footnote j = l "Conventional : Original Amount < &score; Jumbo: Original Amount ≥ &score";
  proc sgplot data = tmp;
    loess y = rowpercent x = yqtr / group = Loan_Type smooth = 0.25;
    xaxis label = "Year" grid;
    yaxis label = "Probability of &n_next" grid;
  run;
  title;
  
  
%mend plot;


%macro check(score);
  %by_Orig_amt(DEL);
  %by_Orig_amt(CUR);
  %plot(DEL);
  %plot(CUR);
%mend check;

%macro checkloop();
  %check(480000);
  %check(510000);
%mend checkloop;

%checkloop();


%put ----------------------------------------------------------------- FIT REGRESSION;
%macro fit(d_pd);
%let d_pd = DEL;


  %if "&d_pd" = "CUR" %then %do;
    %let next = DEL;
    %let n_next = Delinquent;
  %end;
  %if "&d_pd" = "DEL" %then %do;
    %let next = SDQ;
    %let n_next = Default;
  %end;

  %let score = 510000;
  %by_Orig_amt(&d_pd);
  
  data PD_DATA._jumbo PD_DATA._conv;
    set PD_DATA._&d_pd;
    
    if next_stat = "&next" then next_flg = 1;
      else next_flg = 0;
    
    if Loan_Type = 'Conventional' then output PD_DATA._conv;
    if Loan_Type = 'Jumbo' then output PD_DATA._jumbo;
    if ^missing(Loan_Type);
  run;
  
  
    
    

  title "The Multinomial Logistic Regression";
  footnote j = l "Dataset: &d_pd Jumbo";
  footnote2 j = l "Baseline Category: &d_pd";
  
  ods output ParameterEstimates = Multi_tmp(keep = effectentered);
  proc logistic data = PD_DATA._jumbo;
    class next_stat (ref = "&d_pd") &cvar/ param = glm;
    model next_stat = &var / link = glogit ;
    lsmeans / e ilink cl;
  run;
  


  ods select Coef LSMeans;
  proc logistic data = PD_DATA._conv;
    class next_stat (ref = "&d_pd") &cvar/ param = glm;
    model next_stat = &var / link = glogit ;
    lsmeans / e ilink cl;
  run;
  
  
  
  title;
  footnote; 
  
  
%mend fit;

%fit(DEL);
%fit(CUR);



/*


proc print data = PD_DATA.cur;
  where next_stat = "SDQ";
run;

proc print data = DATA.sample;
  where loan_id = "623301207056";
run;

*/


%let id02 = %nrstr(1fP2Ggzb-Ry20sgsQXJ3tkz9G1UPSDJbZ);
%let _url = %nrstr(https://docs.google.com/uc?export=download&id=)&&id02;
filename url_file url "&_url";

 
  data Unemployment ( keep = QDT_UMP Unemp_Var yqtr);
  	infile url_file missover dsd firstobs= 2;
  	input chardate:$10. Unemp_Var;
  	date = input(chardate,yymmdd10.);
  	label
  	logP_UMP = "Log Transformation"
  	QGT_UMP = "Quarterly Growth Transformation"
  	AGT_UMP = "Annual Growth Transformation"
  	QRT_UMP = "Quarterly Return Transformation"
  	ART_UMP = "Annual Return Transformation"
  	QDT_UMP = "Quarterly Difference Transformation"
  	pctchng_UMP = "Percetnage Change"
  	AG_UMP = "Annual Growth in Percent"
  	;
  	format yqtr yyq. logP_UMP QGT_UMP AGT_UMP QRT_UMP ART_UMP QDT_UMP comma10.5 pctchng_UMP AG_UMP percentN10.2 date ddmmyy10. ;
  	lagvar1 = lag(Unemp_Var) ;
  	lagvar4 = lag4(Unemp_Var);
  	logP_UMP = log(Unemp_Var); /*Log transformation*/
  	QGT_UMP = log ( Unemp_Var / lagvar1 ); /*Quarterly Growth Transformation ( ln(Xt / Xt-1) )*/ 
  	AGT_UMP = log ( Unemp_Var / lagvar4 ); /*Annual Growth Transformation ( ln(Xt / Xt-12) ) */
  	QRT_UMP = ( Unemp_Var / lagvar1 ) ;/* Quarterly Return Transformation ( Xt / Xt-1 ) */
  	ART_UMP = ( Unemp_Var / lagvar12 ) ;/* Annual Return Transformation (Xt / Xt-12 ) */
  	QDT_UMP = dif(Unemp_Var); /* Quarterly Difference Transformation ( Xt - Xt-1 ) */	
  	pctchng_UMP = ( ( Unemp_Var / lag( Unemp_Var ) ) ** 12 - 1 ) * 100;
  	AG_UMP = dif4( Unemp_Var ) / lag4( Unemp_Var ) * 100; /*computed percent change from the same period in the previous year*/
  	yqtr = yyq(year(date),qtr(date));
  run;
  
  
  

/* Importing Macroeoconomics Data from GDrive*/


* Setup the head format;
%let mac_head = 
                 Rate    date : ddmmyy10.  Rate_MDT  TNF_MDT   GDP    GDP_MDT  
                 HS      HS_MDT            UMP       UMP_MDT   PPI    PPI_MDT        
                 Permits HOP_MDT           Payroll   HPI       _HPI_MDT      
;

* Gernate the URL;

%let id = %nrstr(1iindNDXZyr_5Rowfc_RZxa-NTSxE1eab);
%let _url = %nrstr(https://docs.google.com/uc?export=download&id=)&&id;

filename url_file url "&_url";

data macros (keep = date HPI );
  infile url_file dsd firstobs = 2;
  format date mmddyy8.;
  input &mac_head;

  if date ge '01JAN2006'd;
  drop _:;
run;








proc sort data = Unemployment;
by yqtr;
run;

proc sort data = PD_DATA.train_cur;
by yqtr;
run;



data temp;
merge PD_DATA.train_cur Unemployment ;
by yqtr;
run; 



proc sort data = temp ;
by Orig_Dte;
run;

proc sort data = macros ;
by date;
run;





data  PD_DATA.train_Final_cur ;
merge temp macros  ( rename = (date = orig_dte hpi = orig_hpi)) ;
by orig_dte;
CLTV = oltv*(orig_hpi/hpi)*(act_upb/orig_amt);
run;













