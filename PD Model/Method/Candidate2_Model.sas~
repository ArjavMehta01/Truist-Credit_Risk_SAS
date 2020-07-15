/* Data Prep */


/* Reading in Unemployment data from Google Drive */



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
  
  
  %let id02 = %nrstr(1Pyf8AO44zzDxDUfSWdwi4Bi4wUNhybgb);
  %let _url = %nrstr(https://docs.google.com/uc?export=download&id=)&&id02;
  filename url_file url "&_url";
  
  data GDP (keep = yqtr ggr gdp_var);
  	infile url_file missover dsd  firstobs = 2;
  	input chardate :$10. GDP_Var;
  	date = input(chardate , mmddyy10.);
  	label 
  	GDP_Var = "US GDP"
  	logP_GDP = "Log Transformation"
  	MGT_GDP = "Monthly Growth Transformation"
  	AGT_GDP = "Annual Growth Transformation"
  	MRT_GDP = "Monthly Return Transformation"
  	ART_GDP = "Annual Return Transformation"
  	MDT_GDP = "Monthly Difference Transformation"
  	pctchng_GDP = "Percentage Change"
  	AG_GDP = "Annual Growth in Percent"
  	;
  	format logP_GDP MGT_GDP AGT_GDP MRT_GDP ART_GDP MDT_GDP comma10.5 pctchng_GDP AG_GDP percent10.2 date mmddyy10.;
  	lagvar1 = lag(GDP_Var) ;
  	lagvar12 = lag12(GDP_Var);
  	logP_GDP = log(GDP_Var); /*Log transformation */
  	Ggr = (gdp_var - lagvar1) / gdp_var;
  	MGT_GDP = log ( GDP_Var / lagvar1 ); /*Quarterly Growth Transformation ( ln(Xt / Xt-1) ) */
  	AGT_GDP = log ( GDP_Var / lagvar12 ); /*Annual Growth Transformation ( ln(Xt / Xt-4) )*/
  	MRT_GDP= ( GDP_Var / lagvar1 ) ;/* Quarterly Return Transformation ( Xt / Xt-1 )*/
  	ART_GDP = ( GDP_Var / lagvar1 ) ;/* Annual Return Transformation (Xt / Xt-4 )*/
  	MDT_GDP = dif(lag(GDP_Var)); /* Quarterly Difference Transformation ( Xt - Xt-1 ) */	
  	pctchng_GDP = ( ( GDP_Var / lag( GDP_Var ) ) ** 12 - 1 ) * 100; 
  	AG_GDP = dif12( GDP_Var ) / lag12( GDP_Var ) * 100; /*computed percent change from the same period in the previous year*/
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

data macros (keep = date HPI UMP HS GDP PPI Permits QDT_UMP ART_UMP AG_UMP);
  infile url_file dsd firstobs = 2;
  format date mmddyy8.;
  input &mac_head;
  label
  	logP_UMP = "Log Transformation"
  	QGT_UMP = "Quarterly Growth Transformation"
  	QRT_UMP = "Quarterly Return Transformation"
  	QDT_UMP = "Quarterly Difference Transformation"
  	pctchng_UMP = "Percetnage Change"
  	AG_UMP = "Annual Growth in Percent"
  	;
  	format yqtr yyq. logP_UMP QGT_UMP AGT_UMP QRT_UMP ART_UMP QDT_UMP comma10.5 pctchng_UMP AG_UMP percentN10.2 date ddmmyy10. 
  	logP_UMP = log(UMP); /*Log transformation*/
  	QGT_UMP = log ( UMP / lag (UMP) ); /*Quarterly Growth Transformation ( ln(Xt / Xt-1) )*/ 
  	QRT_UMP = ( UMP / lagvar1 ) ;/* Quarterly Return Transformation ( Xt / Xt-1 ) */
  	QDT_UMP = dif(UMP); /* Quarterly Difference Transformation ( Xt - Xt-1 ) */	
  	pctchng_UMP = ( ( UMP / lag (UMP ) ) ** 12 - 1 ) * 100;
  	AG_UMP = dif4( UMP ) / lag4( UMP ) * 100; /*computed percent change from the same period in the previous year*/
  	
  if date ge '01JAN2006'd;
  drop _:;
  yqtr = yyq(year(date),qtr(date));
run;


/* Sorting Unemployment data by quarters to match with Act_date  */

proc sort data = Unemployment;
by yqtr;
run;

data PD_DATA.train_cur;
set PD_DATA.train_cur;
UPB = act_upb / orig_amt ; 
run;

data PD_DATA.train_del;
set PD_DATA.train_del;
UPB = act_upb / orig_amt;
run;



/* Sorting Training and testing data sets */
proc sort data = PD_DATA.train_cur;
by yqtr;
run;

proc sort data = PD_DATA.train_del;
by yqtr;
run;

proc sort data = PD_DATA.test_cur;
by yqtr;
run;

proc sort data = PD_DATA.test_del;
by yqtr;
run;


/* Merging Unemployment to Training and Testing Data sets */
data temp_train_cur;
merge PD_DATA.train_cur Unemployment ;
by yqtr;
run; 

data temp_train_del;
merge PD_DATA.train_del Unemployment;
by yqtr;
run; 

data temp_test_cur;
merge PD_DATA.test_cur Unemployment ;
by yqtr;
run; 

data temp_test_del;
merge PD_DATA.test_del Unemployment ;
by yqtr;
run; 


/* Sorting the newly made datasets by Orig_Dte to merge with Macros (HPI) */

proc sort data = temp_train_cur ;
by Orig_Dte;
run;


proc sort data = temp_train_del ;
by Orig_Dte;
run;

proc sort data = temp_test_cur ;
by Orig_Dte;
run;

proc sort data = temp_test_del ;
by Orig_Dte;
run;


proc sort data = macros ;
by date;
run;


/* Adding CLTV in the datasets and merging them with MacroEconomics */

data  PD_DATA.train_Final_cur ;
merge temp_train_cur macros  ( rename = (date = orig_dte hpi = orig_hpi)) ;
by orig_dte;
CLTV = oltv*(orig_hpi/hpi)*(act_upb/orig_amt);
run;



data  PD_DATA.train_Final_del ;
merge temp_train_del macros  ( rename = (date = orig_dte hpi = orig_hpi)) ;
by orig_dte;
CLTV = oltv*(orig_hpi/hpi)*(act_upb/orig_amt);
run;


data  PD_DATA.test_Final_cur ;
merge temp_test_cur macros  ( rename = (date = orig_dte hpi = orig_hpi)) ;
by orig_dte;
CLTV = oltv*(orig_hpi/hpi)*(act_upb/orig_amt);
run;


data  PD_DATA.test_Final_del ;
merge temp_test_del macros  ( rename = (date = orig_dte hpi = orig_hpi)) ;
by orig_dte;
CLTV = oltv*(orig_hpi/hpi)*(act_upb/orig_amt);
run;

/* proc export  */
/*   data=PD_DATA.train_Final_cur */
/*   dbms=csv  */
/*   outfile="/folders/myfolders/Truist-Credit_Risk_SAS/Train_Current.csv"  */
/*   replace; */
/* run; */
/*  */
/*  */
/* proc export  */
/*   data=PD_DATA.train_Final_del */
/*   dbms=csv  */
/*   outfile="/folders/myfolders/Truist-Credit_Risk_SAS/Train_Delinq.csv"  */
/*   replace; */
/* run; */
/*  */
/*  */
/* proc export  */
/*   data=PD_DATA.test_Final_cur */
/*   dbms=csv  */
/*   outfile="/folders/myfolders/Truist-Credit_Risk_SAS/Test_Current.csv"  */
/*   replace; */
/* run; */
/*  */
/* proc export  */
/*   data=PD_DATA.test_Final_del */
/*   dbms=csv  */
/*   outfile="/folders/myfolders/Truist-Credit_Risk_SAS/Test_Delinq.csv"  */
/*   replace; */
/* run; */







%let score = 670;
%let CUR_var =   CLTV dti cscore_b purpose curr_rte HS HPI PPI UMP GDP  ;
%let DEL_var = cltv dti cscore_b HS HPI PPI UMP GDP QDT_UMP;

/* Model 1 */

/* Training Dataset to Prime and Subprime  */

%macro by_FICO(d_pd);

  data PD_DATA._&d_pd;
    set PD_DATA.train_final_&d_pd(keep = next_stat yqtr act_upb &DEL_var);
    length FICO $10;
    
    if 0 < cscore_b < &score then FICO = 'Sub-Prime';
    if &score <=cscore_b then FICO = 'Prime';
    if ^missing(FICO);
  run;

%mend by_FICO;

/* Function to Segregate the Train Data to PRIME Dataset and SUBPRIME Dataset */


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

  %let score = 670;
  %by_FICO(&d_pd);
  
  data PD_DATA.train_del_prm PD_DATA.train_del_sub;
    set PD_DATA._&d_pd;
    
    if FICO = 'Sub-Prime' then output PD_DATA.train_del_sub;
    if FICO = 'Prime' then output PD_DATA.train_del_prm;
  run;
  
%mend fit;









/* Testing Dataset to Prime and Subprime  */

%macro Test_FICO(d_pd);

  data PD_DATA._&d_pd;
    set PD_DATA.test_final_&d_pd(keep = act_upb yqtr next_stat &DEL_var);
    length FICO $10;
    
    if 0 < cscore_b < &score then FICO = 'Sub-Prime';
    if &score <=cscore_b then FICO = 'Prime';
    if ^missing(FICO);
  run;

%mend Test_FICO;



/* Function to Segregate the Test Data to PRIME Dataset and SUBPRIME Dataset */

%macro fittest(d_pd);

%let d_pd = DEL;

 
  %if "&d_pd" = "CUR" %then %do;
    %let next = DEL;
    %let n_next = Delinquent;
  %end;
  %if "&d_pd" = "DEL" %then %do;
    %let next = SDQ;
    %let n_next = Default;
  %end;


  %Test_FICO(&d_pd);
  data PD_DATA.test_del_prm PD_DATA.test_del_sub;
    set PD_DATA._&d_pd;
   
    if FICO = 'Sub-Prime' then output PD_DATA.test_del_sub;
    if FICO = 'Prime' then output PD_DATA.test_del_prm;
  run;
  
%mend fittest;

%fittest(DEL);
/* %fit(DEL); */
/* %fit(CUR); */

/* Regression Modelling */

%let score = 670;



/* Regression of subprime group Delinquent */
%let d_pd = DEL;
  %if "&d_pd" = "CUR" %then %do;
    %let next = DEL;
    %let n_next = Delinquent;
  %end;
  %if "&d_pd" = "DEL" %then %do;
    %let next = SDQ;
    %let n_next = Default;
  %end;



proc logistic data = PD_DATA.train_del_prm plots = all;
class next_stat (ref = "DEL") / param=glm;
model next_stat = &del_var / link = glogit rsquare;
store del_prime;
weight act_upb / normalize;
lsmeans / e ilink cl ; 
run;



title "Probability for different states vs Note Rate";
proc plm source=del_prime;
 effectplot fit(x=cscore_b plotby=next_stat)  / ilink;
run;
footnote "Delinquent : Prime";
title;


proc plm restore=del_subprime;
   effectplot contour(x= cscore_b y=Curr_rte plotby=next_stat);
run; 


/* Two continuous variables with classfication  */

proc plm source = del_prime;
 effectplot slicefit( x = Curr_rte sliceby = Cscore_b  plotby = next_stat) / ilink;
run;
/*  */


  proc logistic data = PD_DATA.train_del_sub ;
    class next_stat (ref = "&d_pd")  / param = glm;
    model next_stat = &DEL_var / link = glogit rsquare cl;
    weight act_upb / normalize;
    lsmeans / e ilink cl ;
    code file = "&p_PDDATA./sub_tmp.sas";
  run;

  
  
/*  Test of prediction; */
  data sub_tmp;
    set PD_DATA.train_del_sub;
    %include "&p_PDDATA./sub_tmp.sas";
  run;
   
  ods output OneWayFreqs = sub_tmp_f(keep = next_stat percent);
  proc freq data = sub_tmp;
    table next_stat;
  run;
  
  ods output Summary = sub_tmp_m(keep = label_: p_:);
  proc means data = sub_tmp mean;
    var p_:;
    weight act_upb ;
  run;
  
  proc transpose data = sub_tmp_m 
                  out = sub_tmp_m(keep = _name_ col1 
                            rename = (_name_ = p_next_stat col1 = predict)
                              );
  run;
  
  
  data sub_tmp_m;
    set sub_tmp_m;
    _idx = find(p_next_stat, "_mean", "i");
    next_stat = substr(p_next_stat, _idx-3, 3);
    predict = round(predict*100, 0.0001);
    call symputx (trim(next_stat), predict);
    keep next_stat predict;
  run;
  
  
  
 ods output OneWayChiSq = sub_tmp_chi(keep = label1 cvalue1);
 proc freq data = sub_tmp;
    table next_stat / chisq
    testp = (&sub);
  run;
  title;
  footnote;
  
  data _null_;
    set sub_tmp_chi;
    call symputx('K'||left(_n_), label1);
    call symputx('V'||left(_n_), cvalue1);
  run;
  
  %let sub = &CUR &DEL &PPY &SDQ;
  %put &sub;
  
  proc sql;
    create table work.sub_tmp_r as
    select f.next_stat "Next State",
           percent "Actual Probability (%)",
           predict "Predicted Probability (%)"
      from work.sub_tmp_m as m inner join work.sub_tmp_f as f
        on m.next_stat = f.next_stat
      order by f.next_stat
      ;
 
  
  
  
  

  
  ods output CrossTabFreqs = sub_qtr_f(where = (next_stat = "&next")
                                        keep = next_stat yqtr colpercent
                                      rename = (colpercent = historic)
                                        );
  proc freq data = sub_tmp;
    table next_stat*yqtr;
  run;
  
  proc sort data = sub_tmp;
    by yqtr;
  run;
  ods output Summary = sub_qtr_m(keep = yqtr P_next_stat&next._Mean
                               rename = (P_next_stat&next._Mean = predict));
  proc means data = sub_tmp mean;
    var p_:;
    by yqtr;
    weight act_upb;
  run;
  proc sort data = sub_qtr_f;
    by yqtr;
  run;
  
  data sub_qtr;
    merge sub_qtr_:;
    by yqtr;
    predict = predict*100;
  run;
  
  title "Prediction of the Training Set";
  footnote j = l "Data: &d_pd Group: SubPrime";
  proc sgplot data = sub_qtr;
    series x = yqtr y = historic / legendlabel = "Historical" ;
    series x = yqtr y = predict / lineattrs = (color = "cxe34a33" thickness = 2) legendlabel = "Predict";
    inset ("&K1" = "&V1"
           "&K3" = "&V3") / border opaque;
    xaxis label = "Year" grid;
    yaxis label = "Probability of &n_next (%)" grid;
  run;
  title;
  footnote;




/*   Regression for Prime group of Delinquent Dataset */


  proc logistic data = PD_DATA.train_del_prm;
    class next_stat (ref = "&d_pd") fico / param = glm;
    model next_stat = &DEL_var/ link = glogit rsquare cl;
    weight act_upb ;
    lsmeans / e ilink cl;
    code file = "&p_PDDATA./prm_tmp.sas";
  run;


/*  Test of prediction */
  data prm_tmp;
    set PD_DATA.train_del_prm ;
    %include "&p_PDDATA/prm_tmp.sas";
  run;
  
* Getting the output data;
  ods output OneWayFreqs = prm_tmp_f(keep = next_stat percent);
  proc freq data = prm_tmp;
    tables next_stat;
  run;
  ods output Summary = prm_tmp_m(keep = label_: p_:);
  proc means data = prm_tmp mean;
    var p_:;
    weight act_upb;
  run;
  proc transpose data = prm_tmp_m 
                  out = prm_tmp_m(keep = _name_ col1 
                            rename = (_name_ = p_next_stat col1 = predict)
                              );
  run;
  data prm_tmp_m;
    set prm_tmp_m;
    _idx = find(p_next_stat, "_mean", "i");
    next_stat = substr(p_next_stat, _idx-3, 3);
    predict = round(predict*100, 0.0001);
    call symputx (trim(next_stat), predict);
    keep next_stat predict;
  run;
  
  %let prm = &CUR &DEL &PPY &SDQ;
  %put &prm;
  
 ods output OneWayChiSq = prm_tmp_chi(keep = label1 cvalue1);
 proc freq data = prm_tmp;
    table next_stat / chisq
    testp = (&sub);
  run;
  title;
  footnote;
  
  data _null_;
    set prm_tmp_chi;
    call symputx('K'||left(_n_), label1);
    call symputx('V'||left(_n_), cvalue1);
  run;
  
  
  proc sql;
    create table work.prm_tmp_r as
    select f.next_stat "Next State",
           percent "Actual Probability (%)",
           predict "Predicted Probability (%)"
      from work.prm_tmp_m as m inner join work.prm_tmp_f as f
        on m.next_stat = f.next_stat
      order by f.next_stat
      ;
  
  
  
  ods output CrossTabFreqs = prm_qtr_f(where = (next_stat = "&next")
                                        keep = next_stat yqtr colpercent
                                      rename = (colpercent = historic)
                                        );
  proc freq data = prm_tmp;
    table next_stat*yqtr;
  run;
  proc sort data = prm_tmp;
    by yqtr;
  run;
  ods output Summary = prm_qtr_m(keep = yqtr P_next_stat&next._Mean
                               rename = (P_next_stat&next._Mean = predict));
  proc means data = prm_tmp mean;
    var p_:;
    by yqtr;
    weight act_upb;
  run;
  proc sort data = prm_qtr_f;
    by yqtr;
  run;
  data prm_qtr;
    merge prm_qtr_:;
    by yqtr;
    predict = predict*100;
  run;
  
  title "Prediction of the Training set";
  footnote j = l "Data: &d_pd Group: Prime";
  proc sgplot data = prm_qtr;
    series x = yqtr y = historic / legendlabel = "Historical";
    series x = yqtr y = predict / lineattrs = (color = "cxe34a33" thickness = 2) legendlabel = "Predict";
     inset ("&K1" = "&V1"
           "&K3" = "&V3") / border opaque;
    xaxis label = "Year" grid;
    yaxis label = "Probability of &n_next (%)" grid;
  run;
  title;
  footnote;


/* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% */



/* Training Dataset to Prime and Subprime  */

%macro bycur_FICO(d_pd);

  data PD_DATA._&d_pd;
    set PD_DATA.train_final_&d_pd(keep = next_stat yqtr act_upb &CUR_var);
    length FICO $10;
    
    if 0 < cscore_b < &score then FICO = 'Sub-Prime';
    if &score <=cscore_b then FICO = 'Prime';
    if ^missing(FICO);
  run;

%mend bycur_FICO;

/* Function to Segregate the Train Data to PRIME Dataset and SUBPRIME Dataset */


%macro fitcur(d_pd);

%let d_pd = CUR;
  %if "&d_pd" = "CUR" %then %do;
    %let next = DEL;
    %let n_next = Delinquent;
  %end;
  %if "&d_pd" = "DEL" %then %do;
    %let next = SDQ;
    %let n_next = Default;
  %end;

  %let score = 670;
  %bycur_FICO(&d_pd);
  
  data PD_DATA.train_cur_prm PD_DATA.train_cur_sub;
    set PD_DATA._&d_pd;
    
    if FICO = 'Sub-Prime' then output PD_DATA.train_cur_sub;
    if FICO = 'Prime' then output PD_DATA.train_cur_prm;
  run;
  
%mend fitcur;







/* Testing Dataset to Prime and Subprime  */

%macro Testcur_FICO(d_pd);

  data PD_DATA.Cur_&d_pd;
    set PD_DATA.test_final_&d_pd(keep = act_upb yqtr next_stat &CUR_var);
    length FICO $10;
    
    if 0 < cscore_b < &score then FICO = 'Sub-Prime';
    if &score <=cscore_b then FICO = 'Prime';
    if ^missing(FICO);
  run;

%mend Testcur_FICO;


/* Function to Segregate the Test Data to PRIME Dataset and SUBPRIME Dataset */

%macro fittest(d_pd);

%let d_pd = CUR;

 
  %if "&d_pd" = "CUR" %then %do;
    %let next = DEL;
    %let n_next = Delinquent;
  %end;
  %if "&d_pd" = "DEL" %then %do;
    %let next = SDQ;
    %let n_next = Default;
  %end;


  %Testcur_FICO(&d_pd);
  data PD_DATA.test_cur_prm PD_DATA.test_cur_sub;
    set PD_DATA.Cur_&d_pd;
   
    if FICO = 'Sub-Prime' then output PD_DATA.test_cur_sub;
    if FICO = 'Prime' then output PD_DATA.test_cur_prm;
  run;
  
%mend fittest;

%let score = 670;

%let CUR_var = dti cscore_b orig_amt curr_rte upb loan_age GDP HS HPI PPI ;


/* Regression CURRENT Dataset for SUBPRIME Group */

%let d_pd = CUR;

  proc logistic data = PD_DATA.train_cur_sub  ;
    class next_stat (ref = "&d_pd") / param = glm;
    model next_stat = &CUR_var / link = glogit rsquare cl;
    weight act_upb / normalize;
    store cur_subprime;
    lsmeans / e ilink cl;
    code file = "&p_PDDATA./sub_cur_tmp.sas";
  run;
  
/*   proc plm restore= cur_subprime; */
/* effectplot slicefit ( x = HS  sliceby = Purpose ) / clm ilink; */
/* run; */
/*  */
/* proc means data = PD_DATA.train_cur_sub; */
/* run; */
/*  */
/* title "Probability for different states vs Note Rate"; */
/* proc plm source=cur_subprime; */
/*  effectplot fit(x=dti  plotby=next_stat)  / ilink; */
/* run; */
/* title; */
/*  */
/*  */
/*   */
/*   */
/* proc plm restore=cur_subprime; */
/*    effectplot slicefit(x= CLTV sliceby = purpose  plotby=next_stat); */
/* run;  */
/*  */
/*  */
/* Two continuous variables with classfication  */
/*  */
/* title "Probability for different states vs Note Rate"; */
/* proc plm source = cur_subprime; */
/*  effectplot slicefit( x = GDP sliceby = cscore_b  plotby = next_stat) / ilink; */
/* run; */



* Test of prediction;
  data subcur_tmp;
    set PD_DATA.train_cur_sub;
    %include "&p_PDDATA./sub_cur_tmp.sas";
  run;
  
* Getting the output data;
  ods output OneWayFreqs = subcur_tmp_f(keep = next_stat percent);
  proc freq data = subcur_tmp;
    tables next_stat;
  run;
  ods output Summary = subcur_tmp_m(keep = label_: p_:);
  proc means data = subcur_tmp mean;
    var p_:;
    weight act_upb;
  run;
  proc transpose data = subcur_tmp_m 
                  out = subcur_tmp_m(keep = _name_ col1 
                            rename = (_name_ = p_next_stat col1 = predict)
                              );
  run;
  
  
  data subcur_tmp_m;
    set subcur_tmp_m;
    _idx = find(p_next_stat, "_mean", "i");
    next_stat = substr(p_next_stat, _idx-3, 3);
    predict = round(predict*100, 0.0001);
    call symputx (trim(next_stat), predict);
    keep next_stat predict;
  run;
  
  %let subcur = &CUR &DEL &PPY &SDQ;
  %put &subcur;
  
  
  ods output OneWayChiSq = subcur_tmp_chi(keep = label1 cvalue1);
  proc freq data = subcur_tmp;
    table next_stat / chisq
    testp = (&subcur);
  run;
  
  data _null_;
    set subcur_tmp_chi;
    call symputx('K'||left(_n_), label1);
    call symputx('V'||left(_n_), cvalue1);
  run;
  


  
  ods output CrossTabFreqs = subcur_qtr_f(where = (next_stat = "&next")
                                        keep = next_stat yqtr colpercent
                                      rename = (colpercent = historic)
                                        );
  proc freq data = subcur_tmp;
    table next_stat*yqtr;
  run;
  proc sort data = subcur_tmp;
    by yqtr;
  run;
  ods output Summary = subcur_qtr_m(keep = yqtr P_next_stat&next._Mean
                               rename = (P_next_stat&next._Mean = predict));
  proc means data = subcur_tmp mean;
    var p_:;
    by yqtr;
    weight act_upb;
  run;
  proc sort data = subcur_qtr_f;
    by yqtr;
  run;
  data subcur_qtr;
    merge subcur_qtr_:;
    by yqtr;
    predict = predict*100;
  run;
  
    proc sql;
    create table work.subcur_tmp_r as
    select f.next_stat "Next State",
           percent "Actual Probability (%)",
           predict "Predicted Probability (%)"
      from work.subcur_tmp_m as m inner join work.subcur_tmp_f as f
        on m.next_stat = f.next_stat
      order by f.next_stat
      ;
  quit;

  

  title "Prediction of the Training Set";
  footnote j = l "Data: &d_pd Group: Sub-Prime";
  proc sgplot data = subcur_qtr;
    series x = yqtr y = historic / legendlabel = "Historical";
    series x = yqtr y = predict / lineattrs = (color = "cxe34a33" thickness = 2) legendlabel = "Predict";
      inset ("&K1" = "&V1"
           "&K3" = "&V3") / border opaque;
    xaxis label = "Year" grid;
    yaxis label = "Probability of &n_next (%)" grid;
  run;
  title;
  footnote;



/* Regression CURRENT Dataset for Prime Group */


%let d_pd = CUR;
  %if "&d_pd" = "CUR" %then %do;
    %let next = DEL;
    %let n_next = Delinquent;
  %end;
  %if "&d_pd" = "DEL" %then %do;
    %let next = SDQ;
    %let n_next = Default;
  %end;

  proc logistic data = PD_DATA.train_cur_prm plots = all;
    class next_stat (ref = "&d_pd") / param = glm;
    model next_stat = &CUR_var / link = glogit rsquare cl influence iplots ;
    weight act_upb / normalize ;
    lsmeans / e ilink cl;
    store cur_prime;
    code file = "&p_PDDATA./prm_cur_tmp.sas";
  run;





proc plm source = cur_prime;
show effects;
effectplot fit(x=dti  plotby=next_stat)  / ilink;
run;

/*  effectplot INTERACTION(x=Boy sliceby=MomAge=-10 -5 0 5 10 15 plotby=CigsPerDay); */
proc plm restore= cur_prime;
effectplot slicefit ( x = HS  sliceby = Purpose ) / clm ilink;
run;


  data prmcur_tmp;
    set PD_DATA.train_cur_prm;
    %include "&p_PDDATA./prm_cur_tmp.sas";
  run;
  
  
  * Getting the output data;
  ods output OneWayFreqs = prmcur_tmp_f(keep = next_stat percent);
  proc freq data = prmcur_tmp;
    tables next_stat;
  run;
  ods output Summary = prmcur_tmp_m(keep = label_: p_:);
  proc means data = prmcur_tmp mean;
    var p_:;
    weight act_upb;
  run;
  proc transpose data = prmcur_tmp_m 
                  out = prmcur_tmp_m(keep = _name_ col1 
                            rename = (_name_ = p_next_stat col1 = predict)
                              );
  run;
  data prmcur_tmp_m;
    set prmcur_tmp_m;
    _idx = find(p_next_stat, "_mean", "i");
    next_stat = substr(p_next_stat, _idx-3, 3);
    predict = round(predict*100, 0.0001);
    call symputx (trim(next_stat), predict);
    keep next_stat predict;
  run;
  
  %let prmcur = &CUR &DEL &PPY &SDQ;
  %put &prmcur;
  
  
  
  
  
  ods output OneWayChiSq = prmcur_tmp_chi(keep = label1 cvalue1);
  proc freq data = prmcur_tmp;
    table next_stat / chisq
    testp = (&prmcur);
  run;
  
  data _null_;
    set prmcur_tmp_chi;
    call symputx('K'||left(_n_), label1);
    call symputx('V'||left(_n_), cvalue1);
  run;
  
  
  ods output CrossTabFreqs = prmcur_qtr_f(where = (next_stat = "&next")
                                        keep = next_stat yqtr colpercent
                                      rename = (colpercent = historic)
                                        );
  proc freq data = prmcur_tmp;
    table next_stat*yqtr;
  run;
  
  proc sort data = prmcur_tmp;
    by yqtr;
  run;
  
  ods output Summary = prmcur_qtr_m(keep = yqtr P_next_stat&next._Mean
                               rename = (P_next_stat&next._Mean = predict));
  proc means data = prmcur_tmp mean;
    var p_:;
    by yqtr;
    weight act_upb;
  run;
  proc sort data = prmcur_qtr_f;
    by yqtr;
  run;
  data prmcur_qtr;
    merge prmcur_qtr_:;
    by yqtr;
    predict = predict*100;
  run;
  
  
  proc sql;
    create table work.prmcur_tmp_r as
    select f.next_stat "Next State",
           percent "Actual Probability (%)",
           predict "Predicted Probability (%)"
      from work.prmcur_tmp_m as m inner join work.prmcur_tmp_f as f
        on m.next_stat = f.next_stat
      order by f.next_stat
      ;
  quit;
  


  title "Prediction of the Training Set";
  footnote j = l "Data: &d_pd Group: Prime";
  proc sgplot data = prmcur_qtr;
    series x = yqtr y = historic / legendlabel = "Historical";
    series x = yqtr y = predict / lineattrs = (color = "cxe34a33" thickness = 2) legendlabel = "Predict";
    inset ("&K1" = "&V1"
           "&K3" = "&V3") / border opaque;
    xaxis label = "Year" grid;
    yaxis label = "Probability of &n_next (%)" grid;
  run;
  title;
  footnote;
  
 
 
 proc freq data = PD_DATA.test_del_sub;
 table next_stat*yqtr;
 run;
