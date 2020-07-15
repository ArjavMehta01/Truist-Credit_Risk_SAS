

/* Reading in Unemployment data from Google Drive */



%let id02 = %nrstr(1fP2Ggzb-Ry20sgsQXJ3tkz9G1UPSDJbZ);
%let _url = %nrstr(https://docs.google.com/uc?export=download&id=)&&id02;
filename url_file url "&_url";

 
  data Unemployment ( keep = QDT_UMP Unemp_Var yqtr QGT_UMP AG_UMP);
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
  




  %let id03 = %nrstr(1Pyf8AO44zzDxDUfSWdwi4Bi4wUNhybgb);
  %let _url = %nrstr(https://docs.google.com/uc?export=download&id=)&&id03;
  filename url_file url "&_url";
  
  data GDP (keep = yqtr ggr GDP_Var QGT_GDP QRT_GDP AG_GDP );
  	infile url_file missover dsd firstobs = 2;
  	input chardate:$10. GDP_Var;
  	
  	date = input( chardate , yymmdd10.);
  	
  	;
  	format yqtr yyq.  QGT_GDP QRT_GDP  QDT_GDP comma10.5 AG_GDP percent10.2 date mmddyy10.;
  	
  	Ggr = (gdp_var - lag(GDP_var) ) / gdp_var;
  	
  	QGT_GDP = log ( GDP_Var / lag(GDP_Var) ); /*Quarterly Growth Transformation ( ln(Xt / Xt-1) ) */
  	
  	QRT_GDP= ( GDP_Var / lag(GDP_Var) ) ;/* Quarterly Return Transformation ( Xt / Xt-1 )*/

  	QDT_GDP = dif(lag(GDP_Var)); /* Quarterly Difference Transformation ( Xt - Xt-1 ) */	
  
  	AG_GDP = dif4( GDP_Var ) / lag4( GDP_Var ) * 100; /*computed percent change from the same period in the previous year*/

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

data macros (keep = yqtr date HPI HS PPI Permits);
  infile url_file dsd firstobs = 2;
  format date mmddyy8. yqtr yyq.;
  input &mac_head;
  
  if date ge '01JAN2006'd;
  drop _:;
  yqtr = yyq(year(date),qtr(date));
run;



/* Sorting Unemployment data by quarters to match with Act_date  */

proc sort data = Unemployment;
by yqtr;
run;

proc sort data = GDP ;
by yqtr;
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
merge PD_DATA.train_cur Unemployment GDP;
by yqtr;
run; 

/* proc sort data = temp_train_cur; */
/* by yqtr; */
/* run; */
/*  */
/* data temp_train_cur; */
/* merge temp_train_cur GDP ; */
/* by yqtr; */
/* run;  */

data temp_train_del;
merge PD_DATA.train_del Unemployment GDP ;
by yqtr;
run; 

data temp_test_cur;
merge PD_DATA.test_cur Unemployment GDP ;
by yqtr;
run; 

data temp_test_del;
merge PD_DATA.test_del Unemployment GDP;
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





ods output summary = test ( keep = _numeric_) ;
proc means data = macros mean;
by yqtr;
run;


proc sort data = PD_DATA.train_Final_cur;
by yqtr;
run;

proc sort data = PD_DATA.train_Final_del;
by yqtr;
run;

proc sort data = PD_DATA.test_Final_cur ;
by yqtr;
run;

proc sort data = PD_DATA.test_Final_del ;
by yqtr;
run;


data PD_DATA.train_Final_cur( drop = HS PPI HPI Permits date_mean rename = (HS_mean = HS PPI_mean = PPI Permits_mean = Permits HPI_mean =HPI ));
merge PD_DATA.train_Final_cur test;
label 
HS_mean = 'Housing Starts'
PPI_mean = 'Producer Price Index'
Permits_mean = 'Housing Permits'
HPI_mean = 'Housing Price Index'
;
format HS_mean PPI_mean Permits_mean HPI_mean comma10.2;
by yqtr;
run;


data PD_DATA.train_final_del( drop = HS PPI HPI Permits date_mean rename = (HS_mean = HS PPI_mean = PPI Permits_mean = Permits HPI_mean =HPI ));
merge PD_DATA.train_Final_del test;
label 
HS_mean = 'Housing Starts'
PPI_mean = 'Producer Price Index'
Permits_mean = 'Housing Permits'
HPI_mean = 'Housing Price Index'
;
format HS_mean PPI_mean Permits_mean HPI_mean comma10.2;
by yqtr;
run;


data PD_DATA.test_final_cur( drop = HS PPI HPI Permits date_mean rename = (HS_mean = HS PPI_mean = PPI Permits_mean = Permits HPI_mean =HPI ));
merge PD_DATA.test_final_cur test;
label 
HS_mean = 'Housing Starts'
PPI_mean = 'Producer Price Index'
Permits_mean = 'Housing Permits'
HPI_mean = 'Housing Price Index'
;
format HS_mean PPI_mean Permits_mean HPI_mean comma10.2;
by yqtr;
run;




data PD_DATA.test_final_del( drop = HS PPI HPI Permits date_mean rename = (HS_mean = HS PPI_mean = PPI Permits_mean = Permits HPI_mean =HPI ));
merge PD_DATA.test_Final_del test;
label 
HS_mean = 'Housing Starts'
PPI_mean = 'Producer Price Index'
Permits_mean = 'Housing Permits'
HPI_mean = 'Housing Price Index'
;
format HS_mean PPI_mean Permits_mean HPI_mean comma10.2;
by yqtr;
run;


%let score = 670;
%let seg = cscore_b;
%let n_c1 = Sub_Prime;
%let n_c2 = Prime;



%let macros = HS PPI Permits GDP QGT_GDP QRT_GDP AG_GDP QDT_UMP QGT_UMP AG_UMP ggr;

%let CUR_var = CLTV dti cscore_b orig_amt purpose curr_rte act_upb loan_age   act_upb &macros ;

%let DEL_var = CLTV dti cscore_b HS PPI act_upb &macros;

%macro Split_Data(d_pd);
  %if "&d_pd" = "CUR" %then %do;
    %let next = DEL;
    %let n_next = Delinquent;
  %end;
  %if "&d_pd" = "DEL" %then %do;
    %let next = SDQ;
    %let n_next = Default;
  %end;

* Split training dataset into two classes;
  data c1_&d_pd c2_&d_pd ;
    set PD_DATA.train_final_&d_pd ;
  
    if 0 < &seg < &score then output c1_&d_pd;
    if &score <= &seg then output c2_&d_pd;
    if ^missing(&seg);
    
    keep &&&d_pd._var next_stat yqtr act_upb;
    
  run;
  
* Split testing dataset into two classes;
  data c1_test_&d_pd c2_test_&d_pd;
    set PD_DATA.test_final_&d_pd;
   
    ;
  
    if 0 < &seg < &score then output c1_test_&d_pd;
    if &score <= &seg then output c2_test_&d_pd ;
    if ^missing(&seg);
    keep &&&d_pd._var next_stat yqtr act_upb ;
    
  run;

%mend Split_Data();

%Split_Data(DEL);
%Split_Data(CUR);

/* Regression Modelling */

%let score = 670;
%let seg = cscore_b;
%let n_c1 = Sub_Prime;
%let n_c2 = Prime;
%let c_var = ;

%let macros = HS PPI GDP QGT_GDP QRT_GDP AG_GDP  QDT_UMP QGT_UMP AG_UMP ggr;

%let CUR_var = CLTV dti cscore_b orig_amt purpose curr_rte loan_age  &macros ;

%let DEL_var = CLTV dti cscore_b  &macros;


%let d_pd = CUR;
%let num = 1;
%let c_var = Purpose;
%macro test(num);

 %if "&d_pd" = "CUR" %then %do;
    %let next = DEL;
    %let n_next = Delinquent;
  %end;
  %if "&d_pd" = "DEL" %then %do;
    %let next = SDQ;
    %let n_next = Default;
  %end;


  
* Multinomial Logistic Regression;
  ods output ParameterEstimates = &d_pd._c&num._pa(keep = variable response classval0 estimate probchisq);
  proc logistic data = c&num._&d_pd;
    class next_stat (ref = "&d_pd") &c_var / param = glm;
    model next_stat = &&&d_pd._var &c_var/ link = glogit rsquare cl selection = B;
    weight act_upb / normalize;
    lsmeans / e ilink cl;
    code file = "%sysfunc(getoption(work))/&num._tmp.sas";
  run;
  
  ods html exclude none;
  title "Parameter Estimates";
  title2 j = l "Data: &d_pd. Group: &&&n_c&num";
  proc report data = &d_pd._c&num._pa;
    columns variable response classval0 estimate probchisq;
    define variable / "Variable" display;
    define response / "Response" display;
    define estimate / display;
    define probchisq / display;
    compute probchisq;
      if response = "&next" then do;
        call define(_row_, "style", "style={background=cxdeebf7}");
          if probchisq > 0.05 then
            call define(_row_, "style", "style={background=cxdeebf7 foreground=cxde2d26}");
      end;
    endcomp;
  run;
  title;
  ods html exclude all;
  
  ods html exclude none;
  title "Parameter Estimates (Next: &next)";
  footnote j = l "Data: &d_pd. Group: &&&n_c&num";
  proc report data = &d_pd._c&num._pa (where = (response = "&next"));
    columns variable response classval0 estimate probchisq;
    define variable / "Variable" display;
    define response / "Response" display;
    define classval0 / "Class" display;
    define estimate / display;
    define probchisq / display;
    compute probchisq;
      if probchisq > 0.05 then
        call define(_row_, "style", "style={foreground=cxde2d26}");
    endcomp;
  run;
  title;
  footnote;
  title "Parameter Estimates (Next: PPY)";
  footnote j = l "Data: &d_pd. Group: &&&n_c&num";
  proc report data = &d_pd._c&num._pa (where = (response = "PPY"));
    columns variable response classval0 estimate probchisq;
    define variable / "Variable" display;
    define response / "Response" display;
    define classval0 / "Class" display;
    define estimate / display;
    define probchisq / display;
    compute probchisq;
      if probchisq > 0.05 then
        call define(_row_, "style", "style={foreground=cxde2d26}");
    endcomp;
  run;
  title;
  footnote;
  ods html exclude all;
  
* Prediction for the test;
  data c&num._tmp;
    set c&num._&d_pd;
    %include "%sysfunc(getoption(work))/&num._tmp.sas";
  run;

/* * Prediction for forcast; */
/*   proc means data = c&num._&d_pd(drop = yqtr next_stat) mean; */
/*     weight act_upb; */
/*     output out = p_tmp_m(keep = &&&d_pd._var &seg _stat_ where = (_stat_ = "MEAN")); */
/*   run; */
/*   data _null_; */
/*     set PD_DATA.out_&d_pd(obs = 1); */
/*     if _n_ = 1 then call symputx ('p_macro', &&&d_pd._macro); */
/*   run; */
/*   data p_tmp; */
/*     set p_tmp_m; */
/*     &c_var = put(&v_var, c_&c_var..); */
/*     &&&d_pd._macro = &p_macro; */
/*     keep &&&d_pd._var &c_var; */
/*   run; */
/*   data p_c&num._&d_pd; */
/*     set p_tmp; */
/*     %include "%sysfunc(getoption(work))/&num._tmp.sas"; */
/*     drop I_: U_:; */
/*   run; */
  
* Getting the output data;
  ods output OneWayFreqs = c&num._f(keep = next_stat percent);
  proc freq data = c&num._tmp;
    table next_stat;
  run;
  ods output Summary = c&num._m(keep = label_: p_:);
  proc means data = c&num._tmp mean;
    var p_:;
    weight act_upb;
  run;
  proc transpose data = c&num._m 
                  out = c&num._m(keep = _name_ col1 
                            rename = (_name_ = p_next_stat col1 = predict)
                              );
  run;
  data c&num._m;
    set c&num._m;
    _idx = find(p_next_stat, "_mean", "i");
    next_stat = substr(p_next_stat, _idx-3, 3);
    predict = round(predict*100, 0.0001);
    call symputx (trim(next_stat), predict);
    keep next_stat predict;
  run;
  
* ChiSqr test;
%if "&d_pd" = "DEL" %then %do;
  %let c&num = &CUR &DEL &PPY &SDQ;
%end;
%if "&d_pd" = "CUR" %then %do;
  %let c&num = &CUR &DEL &PPY &SDQ;
%end;
  %put Estimated Probability: &&&c&num;
  ods output OneWayChiSq = c&num._chi(keep = label1 cvalue1);
  proc freq data = c&num._tmp;
    table next_stat / chisq
    testp = (&&&c&num);
  run;
  data _null_;
    set c&num._chi;
    call symputx('K'||left(_n_), label1);
    call symputx('V'||left(_n_), cvalue1);
  run;

* Comparation plot;
  ods output CrossTabFreqs = c&num._plot(where = (next_stat = "&next")
                                          keep = next_stat yqtr colpercent
                                        rename = (colpercent = historic)
                                        );
  proc freq data = c&num._tmp;
    table next_stat*yqtr;
  run;
  proc sort data = c&num._tmp;
    by yqtr;
  run;
  ods output Summary = c&num._plot2(keep = yqtr P_next_stat&next._Mean
  											rename = (P_next_stat&next._Mean = predict));
  proc means data = c&num._tmp mean;
    var p_:;
    by yqtr;
    weight act_upb;
  run;
  proc sort data = c&num._plot;
    by yqtr;
  run;
  data c&num._plot;
    merge c&num._plot:;
    by yqtr;
    predict = predict*100;
  run;
  
* Prepare for output;
  proc sql;
    create table work.c&num._r as
    select f.next_stat "Next State",
           percent "Actual (%)",
           predict "Predicted (%)"
      from work.c&num._m as m inner join work.c&num._f as f
        on m.next_stat = f.next_stat
      order by f.next_stat
      ;
  quit;
  proc transpose data = c&num._r out = c&num._r(drop = _name_);
    id next_stat;
  run;

* Output the results;
  ods powerpoint exclude none;
  title "Overall Prediction";
  proc print data = c&num._r noobs;
    format _numeric_ 8.2;
  run;  
  title;
  
  title j = l "Group: &&&n_c&num";
  proc sgplot data = c&num._plot;
    series x = yqtr y = historic / legendlabel = "Actual";
    series x = yqtr y = predict / lineattrs = (color = "cxe34a33" thickness = 2) legendlabel = "Predicted";
    inset ("&K1" = "&V1"
           "&K3" = "&V3") / border opaque;
    xaxis label = "Year" grid;
    yaxis label = "Probability of &n_next (%)" grid;
  run;
  title;
  ods powerpoint exclude all;  
  
%mend test;

%let d_pd = DEL;
%let c_var = ;
%test(1);
%test(2);


options nodate;
ods powerpoint file = "&p_report/model1.ppt"
               style = Sapphire;
ods html file = "&p_report/model1.html"
        style = Sapphire;
ods html exclude all;

ods powerpoint close;
ods html close;
