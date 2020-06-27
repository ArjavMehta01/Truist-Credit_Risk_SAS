
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


/* Sorting Unemployment data by quarters to match with Act_date  */

proc sort data = Unemployment;
by yqtr;
run;


proc sort data = PD_DATA.out_cur;
by yqtr;
run;

proc sort data = PD_DATA.out_del;
by yqtr;
run;

proc print data = PD_DATA.out_del(obs=100);
run;


data temp_outtest_cur;
merge PD_DATA.out_cur Unemployment;
by yqtr;
run; 

data temp_outtest_del;
merge PD_DATA.out_del Unemployment  ;
by yqtr;
run; 

/* ########## */

proc sort data = temp_outtest_cur ;
by Orig_Dte;
run;

proc sort data = temp_outtest_del ;
by Orig_Dte;
run;


proc sort data = macros ;
by date;
run;



data  PD_DATA.outtest_Final_cur ;
merge temp_outtest_cur macros  ( rename = (date = orig_dte hpi = orig_hpi)) ;
by orig_dte;
CLTV = oltv*(orig_hpi/hpi)*(act_upb/orig_amt);
run;


data  PD_DATA.outtest_Final_del ;
merge temp_outtest_del macros  ( rename = (date = orig_dte hpi = orig_hpi)) ;
by orig_dte;
CLTV = oltv*(orig_hpi/hpi)*(act_upb/orig_amt);
run;



%let score = 670;

%let CUR_var = CLTV Dti Cscore_b purpose Curr_rte HS GDP;
%let DEL_var = Curr_rte CLTV Cscore_b QDT_UMP ;

/* Out of Sample DataSet */

%macro Outtest_FICO(d_pd);

  data PD_DATA.Outtest_del_&d_pd;
    set PD_DATA.outtest_final_&d_pd(keep = act_upb yqtr next_stat &DEL_var);
    length FICO $10;
    
    if 0 < cscore_b < &score then FICO = 'Sub-Prime';
    if &score <=cscore_b then FICO = 'Prime';
    if ^missing(FICO);
  run;

%mend Outtest_FICO;



%macro fitouttest(d_pd);

%let d_pd = DEL;

 
  %if "&d_pd" = "CUR" %then %do;
    %let next = DEL;
    %let n_next = Delinquent;
  %end;
  %if "&d_pd" = "DEL" %then %do;
    %let next = SDQ;
    %let n_next = Default;
  %end;


  %Outtest_FICO(&d_pd);
  data PD_DATA.outtest_del_prm PD_DATA.outtest_del_sub;
    set PD_DATA.Outtest_del_&d_pd;
   
    if FICO = 'Sub-Prime' then output PD_DATA.outtest_del_sub;
    if FICO = 'Prime' then output PD_DATA.outtest_del_prm;
  run;
  
%mend fitouttest;




%let CUR_var = CLTV Dti Cscore_b purpose Curr_rte HS GDP;
%let DEL_var = Curr_rte CLTV Cscore_b QDT_UMP ;

/* Training Model delinquent SubPrime */
%let d_pd = DEL;
  %if "&d_pd" = "CUR" %then %do;
    %let next = DEL;
    %let n_next = Delinquent;
  %end;
  %if "&d_pd" = "DEL" %then %do;
    %let next = SDQ;
    %let n_next = Default;
  %end;


  proc logistic data = PD_DATA.train_del_sub ;
    class next_stat (ref = "&d_pd")  / param = glm;
    model next_stat = &DEL_var / link = glogit rsquare cl;
    weight act_upb / normalize;
    lsmeans / e ilink cl;
    code file = "&p_PDDATA./sub_tmp.sas";
  run;
  
  
  
/*  Test of prediction; */
  data sub_tmp_out;
    set PD_DATA.outtest_&d_pd._sub;
    %include "&p_PDDATA./sub_tmp.sas";
  run;
   
  ods output OneWayFreqs = sub_tmp_out_f(keep = next_stat percent);
  proc freq data = sub_tmp_out;
    table next_stat;
  run;
  
  ods output Summary = sub_tmp_out_m(keep = label_: p_:);
  proc means data = sub_tmp_out mean;
    var p_:;
    weight act_upb ;
  run;
  
  proc transpose data = sub_tmp_out_m 
                  out = sub_tmp_out_m(keep = _name_ col1 
                            rename = (_name_ = p_next_stat col1 = predict)
                              );
  run;
  
  
  data sub_tmp_out_m;
    set sub_tmp_out_m;
    _idx = find(p_next_stat, "_mean", "i");
    next_stat = substr(p_next_stat, _idx-3, 3);
    predict = round(predict*100, 0.0001);
    call symputx (trim(next_stat), predict);
    keep next_stat predict;
  run;
  
  %let sub_out = &CUR &DEL &PPY &SDQ;
  %put &sub_out;
  
  proc sql;
    create table work.sub_tmp_out_r as
    select f.next_stat "Next State",
           percent "Actual Probability (%)",
           predict "Predicted Probability (%)"
      from work.sub_tmp_out_m as m inner join work.sub_tmp_out_f as f
        on m.next_stat = f.next_stat
      order by f.next_stat
      ;
  title "One Way Chi-Square Test of &d_pd Data";
  footnote j = l "Group: SubPrime"; 
   proc freq data = sub_tmp_out;
    table next_stat / chisq
    testp = (&sub_out);
  run;
  title;
  footnote;
  
  

/*    */
/*   ods output CrossTabFreqs = sub_qtr_out_f(where = (next_stat = "&next") */
/*                                         keep = next_stat yqtr colpercent */
/*                                       rename = (colpercent = historic) */
/*                                         ); */
/*   proc freq data = sub_tmp_out; */
/*     table next_stat*yqtr; */
/*   run; */
/*    */
/*   proc sort data = sub_tmp_out; */
/*     by yqtr; */
/*   run; */
/*   ods output Summary = sub_qtr_out_m(keep = yqtr P_next_stat&next._Mean */
/*                                rename = (P_next_stat&next._Mean = predict)); */
/*   proc means data = sub_tmp_out mean; */
/*     var p_:; */
/*     by yqtr; */
/*     weight act_upb; */
/*   run; */
/*   proc sort data = sub_qtr_out_f; */
/*     by yqtr; */
/*   run; */
/*    */
/*   data sub_qtr_out; */
/*     merge sub_qtr_:; */
/*     by yqtr; */
/*     predict = predict*100; */
/*   run; */
/*    */
/*   title "Prediction of Test-Set"; */
/*   footnote j = l "Data: &d_pd Group: SubPrime"; */
/*   proc sgplot data = sub_qtr_out; */
/*     scatter x = yqtr y = historic / legendlabel = "Historical" ; */
/*     series x = yqtr y = predict / lineattrs = (color = "cxe34a33" thickness = 2) legendlabel = "Predict"; */
/*     xaxis label = "Year" grid; */
/*     yaxis label = "Probability of &n_next (%)" grid; */
/*   run; */
/*   title; */
/*   footnote; */

















