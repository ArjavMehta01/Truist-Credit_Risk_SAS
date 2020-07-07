
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


/* proc print data = Unemployment; */
/* run; */
/* proc print data = PD_DATA.out_cur (OBS=100); */
/* run; */

proc sort data = PD_DATA.out_del;
by yqtr;
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
 
%let d_pd = DEL;
  %if "&d_pd" = "CUR" %then %do;
    %let next = DEL;
    %let n_next = Delinquent;
  %end;
  %if "&d_pd" = "DEL" %then %do;
    %let next = SDQ;
    %let n_next = Default;
  %end;
  data PD_DATA.Out_Sample_1_&d_pd PD_DATA.Out_Sample_2_&d_pd;
    set PD_DATA.outtest_final_&d_pd(keep = act_upb yqtr next_stat &DEL_var Orig_Dte);
    length FICO $10;
    where Orig_dte < '30Mar2016'd;
    if 0 < cscore_b < &score then output PD_DATA.Out_Sample_1_&d_pd; 
    if &score <=cscore_b then output PD_DATA.Out_Sample_2_&d_pd;
    if ^missing(FICO);
  run;

%mend Outtest_FICO;


/*   data p_c1_&d_pd p_c2_&d_pd; */
/*     set PD_DATA.out_&d_pd; */
/*     where orig_dte < "30Mar2016"d; */
/*     attrib FICO label = "FICO"             length = $10. */
/*            hs   label = "Housing Starts" */
/*            ump  label = "Unemployment Rate" */
/*     ; */
/*     &c_var = put(&v_var, c_&c_var..); */
/*     if 0 < &seg < &score then output p_c1_&d_pd; */
/*     if &score <= &seg then output p_c2_&d_pd; */
/*      */
/*     keep &&&d_pd._var &c_var act_upb next_stat yqtr; */
/*      */
/*   run; */
  
  





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

  ods output ParameterEstimates = &d_pd._subprime(keep = variable response  estimate probchisq);
  proc logistic data = PD_DATA.train_&d_pd._sub ;
    class next_stat (ref = "&d_pd")  / param = glm;
    model next_stat = &&&d_pd._var / link = glogit rsquare cl;
    weight act_upb / normalize;
    lsmeans / e ilink cl;
    code file = "&p_PDDATA./sub_tmp.sas";
  run;
  
  
  
/*  Test of prediction; */
  data sub_tmp_out;
    set PD_DATA.Out_Sample_1_&d_pd;
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



/* DELINQUENT PRIME */


%let CUR_var = CLTV Dti Cscore_b purpose Curr_rte HS GDP;
%let DEL_var = Curr_rte CLTV Cscore_b QDT_UMP ;

%let d_pd = DEL;
  %if "&d_pd" = "CUR" %then %do;
    %let next = DEL;
    %let n_next = Delinquent;
  %end;
  %if "&d_pd" = "DEL" %then %do;
    %let next = SDQ;
    %let n_next = Default;
  %end;
  
  ods output ParameterEstimates = &d_pd._prime(keep = variable response  estimate probchisq);
  proc logistic data = PD_DATA.train_del_prm;
    class next_stat (ref = "&d_pd") fico / param = glm;
    model next_stat = &&&d_pd._var / link = glogit rsquare cl;
    weight act_upb ;
    lsmeans / e ilink cl;
    code file = "&p_PDDATA./out_prm_tmp.sas";
  run;

/*  Test of prediction */
  data out_prm_tmp;
    set PD_DATA.out_sample_2_&d_pd;
    %include "&p_PDDATA./out_prm_tmp.sas";
  run;

* Getting the output data;
  ods output OneWayFreqs = out_prm_tmp_f(keep = next_stat percent);
  proc freq data = out_prm_tmp;
    tables next_stat;
  run;
  ods output Summary = out_prm_tmp_m(keep = label_: p_:);
  proc means data = out_prm_tmp mean;
    var p_:;
    weight act_upb;
  run;
  proc transpose data = out_prm_tmp_m 
                  out = out_prm_tmp_m(keep = _name_ col1 
                            rename = (_name_ = p_next_stat col1 = predict)
                              );
  run;
  data out_prm_tmp_m;
    set out_prm_tmp_m;
    _idx = find(p_next_stat, "_mean", "i");
    next_stat = substr(p_next_stat, _idx-3, 3);
    predict = round(predict*100, 0.0001);
    call symputx (trim(next_stat), predict);
    keep next_stat predict;
  run;
  %let out_prm = &CUR &DEL &PPY &SDQ;
  %put &out_prm;
  proc sql;
    create table work.out_prm_tmp_r as
    select f.next_stat "Next State",
           percent "Actual Probability (%)",
           predict "Predicted Probability (%)"
      from work.out_prm_tmp_m as m inner join work.out_prm_tmp_f as f
        on m.next_stat = f.next_stat
      order by f.next_stat
      ;
  
  title "One Way Chi-Square Test of &d_pd Data";
  footnote j = l "Group: Prime";
  proc freq data = out_prm_tmp;
    table next_stat / chisq
    testp = (&out_prm);
  run;
  title;
  footnote;
  
  
  
/*   CURRENT Out of sample DATASET */
%let score = 670;
%let CUR_var = CLTV Dti Cscore_b purpose Curr_rte HS GDP;
%let DEL_var = Curr_rte CLTV Cscore_b QDT_UMP ;



%let d_pd = CUR;
  %if "&d_pd" = "CUR" %then %do;
    %let next = DEL;
    %let n_next = Delinquent;
  %end;
  %if "&d_pd" = "DEL" %then %do;
    %let next = SDQ;
    %let n_next = Default;
  %end;
  data PD_DATA.Out_Sample_1_&d_pd PD_DATA.Out_Sample_2_&d_pd;
    set PD_DATA.outtest_final_&d_pd(keep = act_upb yqtr next_stat &CUR_var Orig_Dte);
    length FICO $10;
    where Orig_dte < '30Mar2016'd;
    if 0 < cscore_b < &score then output PD_DATA.Out_Sample_1_&d_pd; 
    if &score <=cscore_b then output PD_DATA.Out_Sample_2_&d_pd;
    if ^missing(FICO);
  run;




/* CURRENT SUBPRIME */


%let CUR_var = CLTV Dti Cscore_b purpose Curr_rte HS GDP;
%let DEL_var = Curr_rte CLTV Cscore_b QDT_UMP ;

%let d_pd = CUR;
  %if "&d_pd" = "CUR" %then %do;
    %let next = DEL;
    %let n_next = Delinquent;
  %end;
  %if "&d_pd" = "DEL" %then %do;
    %let next = SDQ;
    %let n_next = Default;
  %end;

ods output ParameterEstimates = &d_pd._subprime(keep = variable response  estimate probchisq);
  proc logistic data = PD_DATA.train_cur_sub ;
    class next_stat (ref = "&d_pd") Purpose  / param = glm;
    model next_stat = &&&d_pd._var / link = glogit rsquare cl;
    weight act_upb / normalize;
    lsmeans / e ilink cl;
    code file = "&p_PDDATA./out_sub_cur_tmp.sas";
  run;



* Test of prediction;
  data out_subcur_tmp;
    set PD_DATA.out_sample_1_&d_pd;
    %include "&p_PDDATA./out_sub_cur_tmp.sas";
  run;
  
* Getting the output data;
  ods output OneWayFreqs = out_subcur_tmp_f(keep = next_stat percent);
  proc freq data = out_subcur_tmp;
    tables next_stat;
  run;
  ods output Summary = out_subcur_tmp_m(keep = label_: p_:);
  proc means data = out_subcur_tmp mean;
    var p_:;
    weight act_upb;
  run;
  proc transpose data = out_subcur_tmp_m 
                  out = out_subcur_tmp_m(keep = _name_ col1 
                            rename = (_name_ = p_next_stat col1 = predict)
                              );
  run;
  data out_subcur_tmp_m;
    set out_subcur_tmp_m;
    _idx = find(p_next_stat, "_mean", "i");
    next_stat = substr(p_next_stat, _idx-3, 3);
    predict = round(predict*100, 0.0001);
    call symputx (trim(next_stat), predict);
    keep next_stat predict;
  run;
  
  %let out_subcur = &CUR &DEL &PPY &SDQ;
  %put &out_subcur;
  proc sql;
    create table work.out_subcur_tmp_r as
    select f.next_stat "Next State",
           percent "Actual Probability (%)",
           predict "Predicted Probability (%)"
      from work.out_subcur_tmp_m as m inner join work.out_subcur_tmp_f as f
        on m.next_stat = f.next_stat
      order by f.next_stat
      ;
  quit;
/*    */
/*   title "One Way Chi-Square Test of &d_pd Data"; */
/*   footnote j = l "Group: Sub-Prime"; */
/*   proc freq data = out_subcur_tmp; */
/*     table next_stat / chisq */
/*     testp = (&out_subcur); */
/*   run; */
/*   title; */
/*   footnote; */
/*    */
/*   ods output CrossTabFreqs = subcur_qtr_f(where = (next_stat = "&next") */
/*                                         keep = next_stat yqtr colpercent */
/*                                       rename = (colpercent = historic) */
/*                                         ); */
/*   proc freq data = subcur_tmp; */
/*     table next_stat*yqtr; */
/*   run; */
/*   proc sort data = subcur_tmp; */
/*     by yqtr; */
/*   run; */
/*   ods output Summary = subcur_qtr_m(keep = yqtr P_next_stat&next._Mean */
/*                                rename = (P_next_stat&next._Mean = predict)); */
/*   proc means data = subcur_tmp mean; */
/*     var p_:; */
/*     by yqtr; */
/*     weight act_upb; */
/*   run; */
/*   proc sort data = subcur_qtr_f; */
/*     by yqtr; */
/*   run; */
/*   data subcur_qtr; */
/*     merge subcur_qtr_:; */
/*     by yqtr; */
/*     predict = predict*100; */
/*   run; */
/*    */
/*  */
/*   title "Prediction of Test-Set"; */
/*   footnote j = l "Data: &d_pd Group: Sub-Prime"; */
/*   proc sgplot data = subcur_qtr; */
/*     scatter x = yqtr y = historic / legendlabel = "Historical"; */
/*     series x = yqtr y = predict / lineattrs = (color = "cxe34a33" thickness = 2) legendlabel = "Predict"; */
/*     xaxis label = "Year" grid; */
/*     yaxis label = "Probability of &n_next (%)" grid; */
/*   run; */
/*   title; */
/*   footnote; */
/*  */
/*  */
/*  */



/* CURRENT PRIME */



%let d_pd = CUR;
  %if "&d_pd" = "CUR" %then %do;
    %let next = DEL;
    %let n_next = Delinquent;
  %end;
  %if "&d_pd" = "DEL" %then %do;
    %let next = SDQ;
    %let n_next = Default;
  %end;

ods output ParameterEstimates = &d_pd._prime(keep = variable response estimate probchisq);
  proc logistic data = PD_DATA.train_cur_prm ;
    class next_stat (ref = "&d_pd") Purpose  / param = glm;
    model next_stat = &&&d_pd._var / link = glogit rsquare cl;
    weight act_upb / normalize;
    lsmeans / e ilink cl;
    code file = "&p_PDDATA./out_prm_cur_tmp.sas";
  run;

  data out_prmcur_tmp;
    set PD_DATA.out_sample_2_&d_pd;
    %include "&p_PDDATA./out_prm_cur_tmp.sas";
  run;
  


* Getting the output data;
  ods output OneWayFreqs = out_prmcur_tmp_f(keep = next_stat percent);
  proc freq data = out_prmcur_tmp ;
    table next_stat;
  run;
  ods output Summary = out_prmcur_tmp_m(keep = label_: p_:);
  proc means data = out_prmcur_tmp mean;
    var p_:;
    weight act_upb;
  run;
  proc transpose data = out_prmcur_tmp_m
                  out = out_prmcur_tmp_m(keep = _name_ col1 
                            rename = (_name_ = p_next_stat col1 = predict)
                              );
  run;
  data out_prmcur_tmp_m;
    set out_prmcur_tmp_m;
    _idx = find(p_next_stat, "_mean", "i");
    next_stat = substr(p_next_stat, _idx-3, 3);
    predict = round(predict*100, 0.0001);
    call symputx (trim(next_stat), predict);
    keep next_stat predict;
  run;
  
* ChiSqr test;

%let num = 1;

%if "&d_pd" = "DEL" %then %do;
  %let c&num = &CUR &DEL &PPY &SDQ;
%end;
%if "&d_pd" = "CUR" %then %do;
  %let c&num = &CUR &DEL &PPY;
%end;
  %put Estimated Probability: &&&c&num;
  ods output OneWayChiSq = out_prmcur_tmp_chi(keep = label1 cvalue1);
  proc freq data = out_prmcur_tmp;
    table next_stat / chisq
    testp = (&&&c&num);
  run;
  data _null_;
    set out_prmcur_tmp_chi;
    call symputx('K'||left(_n_), label1);
    call symputx('V'||left(_n_), cvalue1);
  run;
*******************************************************************
* Comparation plot;
  ods output CrossTabFreqs = c&num._plot(where = (next_stat = "&next")
                                          keep = next_stat yqtr colpercent
                                        rename = (colpercent = historic)
                                        );
  proc freq data = out_prmcur_tmp;
    table next_stat*yqtr;
  run;
  proc sort data = out_prmcur_tmp;
    by yqtr;
  run;
  ods output Summary = &d_pd._out_prmcur_plot2(keep = yqtr P_next_stat:);
  proc means data = out_prmcur_tmp mean;
    var p_:;
    by yqtr;
    weight act_upb;
  run;
  proc sort data = c&num._plot;
    by yqtr;
  run;
  
  data outcur_plot;
    merge c&num._plot &d_pd._out_prmcur_plot2;
    by yqtr;
    predict = predict*100;
  run;
  
* Prepare for output;
  proc sql;
    create table work.c&num._r as
    select f.next_stat "Next State",
           percent "Actual (%)",
           predict "Predicted (%)"
      from work.out_prmcur_tmp_m as m inner join work.out_prmcur_tmp_f as f
        on m.next_stat = f.next_stat
      order by f.next_stat
      ;
  quit;
  proc transpose data = c&num._r out = c&num._r(drop = _name_);
    id next_stat;
  run;

* Output the results;
  
  title "Overall Prediction";
  proc print data = c&num._r noobs;
    format _numeric_ 8.2;
  run;  
  title;



 data PD_DATA.xyz;
    length curr_stat $3.;
   
    set &d_pd._out_prmcur_plot2(rename = (P_Next_statCUR_Mean = CUR P_Next_statDEL_Mean = DEL 
                                   P_Next_statPPY_Mean = PPY P_Next_statSDQ_Mean = SDQ)
                             in = c
                         );
    by yqtr;
    if d then curr_stat = "DEL";
    if c then curr_stat = "CUR";
    
    if first.yqtr then do;
      output;
      curr_stat = "PPY";
      CUR = 0; DEL = 0; PPY = 1; SDQ = 0;
      output;
      curr_stat = "SDQ";
      CUR = 0; DEL = 0; PPY = 0; SDQ = 1;
      output;
    end;
    else output;
  run;
  
  proc sort data = PD_DATA.xyz;
    by yqtr curr_stat;
  run;



proc export data = PD_DATA.xyz outfile = "&p_pddata/xyz.csv" dbms = csv;
run;

















/*   ods output OneWayFreqs = out_prmcur_tmp_f(keep = next_stat percent); */
/*   proc freq data = out_prmcur_tmp; */
/*     tables next_stat; */
/*   run; */
/*   ods output Summary = out_prmcur_tmp_m(keep = label_: p_:); */
/*   proc means data = out_prmcur_tmp mean; */
/*     var p_:; */
/*     weight act_upb; */
/*   run; */
/*   proc transpose data = out_prmcur_tmp_m  */
/*                   out = out_prmcur_tmp_m(keep = _name_ col1  */
/*                             rename = (_name_ = p_next_stat col1 = predict) */
/*                               ); */
/*   run; */
/*   data out_prmcur_tmp_m; */
/*     set out_prmcur_tmp_m; */
/*     _idx = find(p_next_stat, "_mean", "i"); */
/*     next_stat = substr(p_next_stat, _idx-3, 3); */
/*     predict = round(predict*100, 0.0001); */
/*     call symputx (trim(next_stat), predict); */
/*     keep next_stat predict; */
/*   run; */
/*    */
/*   %let out_prmcur = &CUR &DEL &PPY ; */
/*   %put &out_prmcur; */
/*   proc sql; */
/*     create table work.out_prmcur_tmp_r as */
/*     select f.next_stat "Next State", */
/*            percent "Actual Probability (%)", */
/*            predict "Predicted Probability (%)" */
/*       from work.out_prmcur_tmp_m as m inner join work.out_prmcur_tmp_f as f */
/*         on m.next_stat = f.next_stat */
/*       order by f.next_stat */
/*       ; */
/*   quit; */
/*   title "One Way Chi-Square Test of &d_pd Data"; */
/*   footnote j = l "Group: Sub-Prime"; */
/*   proc freq data = out_prmcur_tmp; */
/*     table next_stat / chisq */
/*     testp = (&out_prmcur); */
/*   run; */
/*   title; */
/*   footnote; */
/*   */
/*  */
/*  */
/*  */



/*  */
/*  */
/*  title "Parameter Estimates (Next: &next)"; */
/*   footnote j = l "Data: &d_pd. Group: Prime"; */
/*   proc report data = &d_pd._prime (where = (response = "&next")); */
/*     columns variable response  estimate probchisq; */
/*     define variable / "Variable" display; */
/*     define response / "Response" display; */
/*     define classval0 / "Class" display; */
/*     define estimate / display; */
/*     define probchisq / display; */
/*     compute probchisq; */
/*       if probchisq > 0.05 then */
/*         call define(_row_, "style", "style={foreground=cxde2d26}"); */
/*     endcomp; */
/*   run; */
/*   title; */
/*   footnote; */
/*    */
/*    */
/*    */
/*    */
/*   title "Parameter Estimates (Next: PPY)"; */
/*   footnote j = l "Data: &d_pd. Group: Prime"; */
/*   proc report data = &d_pd._prime (where = (response = "PPY")); */
/*     columns variable response  estimate probchisq; */
/*     define variable / "Variable" display; */
/*     define response / "Response" display; */
/*     define classval0 / "Class" display; */
/*     define estimate / display; */
/*     define probchisq / display; */
/*     compute probchisq; */
/*       if probchisq > 0.05 then */
/*         call define(_row_, "style", "style={foreground=cxde2d26}"); */
/*     endcomp; */
/*   run; */
/*   title; */
/*   footnote; */
/*  */






