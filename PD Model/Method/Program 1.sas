



/* Reading In MacroEconomic Variables */


/* Reading in Unemployment data from Google Drive */

%let id02 = %nrstr(1SAM-jrybVOBECHwkcaJMgN8V8uJCsqw-);
%let _url = %nrstr(https://docs.google.com/uc?export=download&id=)&&id02;
filename url_file url "&_url";

 
  data Unemployment ( keep = yqtr lagging_UMP QDT_UMP QGT_UMP AG_UMP);
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
  	lagging_UMP = lag ( dif (Unemp_var) ) ;
  	lagvar1 = lag(Unemp_Var) ;
  	lagvar4 = lag4(Unemp_Var);
  	logP_UMP = log(Unemp_Var); /*Log transformation*/
  	QGT_UMP = log ( Unemp_Var / lagvar1 ); /*Quarterly Growth Transformation ( ln(Xt / Xt-1) )*/ 
  	AGT_UMP = log ( Unemp_Var / lagvar4 ); /*Annual Growth Transformation ( ln(Xt / Xt-4) ) */
  	QRT_UMP = ( Unemp_Var / lagvar1 ) ;/* Quarterly Return Transformation ( Xt / Xt-1 ) */
  	ART_UMP = ( Unemp_Var / lagvar4 ) ;/* Annual Return Transformation (Xt / Xt-4 ) */
  	QDT_UMP = dif(Unemp_Var); /* Quarterly Difference Transformation ( Xt - Xt-1 ) */	
  	pctchng_UMP = ( ( Unemp_Var / lag( Unemp_Var ) ) ** 4 - 1 ) ;
  	AG_UMP = dif4( Unemp_Var ) / lag4( Unemp_Var ) ; /*computed percent change from the same period in the previous year*/
  	yqtr = yyq(year(date),qtr(date));
  run;
  



  %let id03 = %nrstr(1AC_Mweg4cpiFieyFqKCmUdxCvJERJtLh);
  %let _url = %nrstr(https://docs.google.com/uc?export=download&id=)&&id03;
  filename url_file url "&_url";
  
  data GDP (keep = yqtr GDP_Annual_Rate QRT_GDP Ggr QDT_GDP AG_GDP QGT_GDP );
  	infile url_file missover dsd firstobs = 2;
  	input chardate:$10. GDP_Var;
  	
  	date = input( chardate , yymmdd10.);
  	
  	format yqtr yyq.  QGT_GDP QRT_GDP  QDT_GDP comma10.5 AG_GDP GDP_Annual_Rate percentn10.2 date mmddyy10.;
  	lagvar1 = lag(GDP_Var);
  	Ggr = (gdp_var - lag(GDP_var) ) / gdp_var;
  	
  	QGT_GDP = log ( GDP_Var / lag(GDP_Var) ); /*Quarterly Growth Transformation ( ln(Xt / Xt-1) ) */
  	
  	QRT_GDP= ( GDP_Var / lag(GDP_Var) ) ;/* Quarterly Return Transformation ( Xt / Xt-1 )*/

  	QDT_GDP = dif(lag(GDP_Var)); /* Quarterly Difference Transformation ( Xt - Xt-1 ) */	
  
  	AG_GDP = dif4( GDP_Var ) / lag4( GDP_Var ); /*computed percent change from the same period in the previous year*/
	
	g = ( GDP_Var - lagvar1 ) / lag(GDP_Var)  ;
	s = 1+g;
	pow = 4;
	y = s**pow;
	
	GDP_Annual_Rate =  y- 1 ;
	
   
   yqtr = yyq(year(date),qtr(date));
   	
 run;
 

/* Running Frequency table to check what the term for maximum number of mortgages is */
proc freq data = PD_DATA.train_final_cur;
table Orig_Trm;
run;

/* Importing 30 Year mortgage rate */

%let id04 = %nrstr(1xOUakY-7uC7GDLMOUljzkcdhaXekvlA8);
%let _url = %nrstr(https://docs.google.com/uc?export=download&id=)&&id04;
filename url_file url "&_url";
  
data Mortgage30 (keep = yqtr MortgageRt );

  	infile url_file missover dsd firstobs = 2;
  	input chardate:$10. MortgageRt;

  	date = input( chardate , yymmdd10.);

  	format yqtr yyq. MortgageRt comma10.2 date mmddyy10.;

  	lagvar1 = lag(MortgageRt);   
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

data macros (keep = yqtr date HPI HS PPI Permits Payroll);
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

proc sort data = Mortgage30;
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

/* Merging Unemployment and GDP and Mortgage30 to Training and Testing Data sets */
data temp_train_cur;
merge PD_DATA.train_cur Unemployment GDP Mortgage30;
by yqtr;
if ^missing (Loan_id);
run; 

data temp_train_del;
merge PD_DATA.train_del Unemployment GDP  Mortgage30;
by yqtr;
if ^missing (Loan_id);
run; 

data temp_test_cur;
merge PD_DATA.test_cur Unemployment GDP  Mortgage30;
by yqtr;
if ^missing (Loan_id);
run; 

data temp_test_del;
merge PD_DATA.test_del Unemployment GDP  Mortgage30;
by yqtr;
if ^missing (Loan_id);
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
merge temp_train_cur macros  ( rename = (date = orig_dte hpi = orig_hpi) drop = yqtr) ;
by orig_dte;
CLTV = oltv*(orig_hpi/hpi)*(act_upb/orig_amt);
run;


data  PD_DATA.train_Final_del ;
merge temp_train_del macros( rename = (date = orig_dte hpi = orig_hpi) drop = yqtr) ;
by orig_dte;
CLTV = oltv*(orig_hpi/hpi)*(act_upb/orig_amt);
run;


data  PD_DATA.test_Final_cur ;
merge temp_test_cur macros  ( rename = (date = orig_dte hpi = orig_hpi) drop = yqtr) ;
by orig_dte;
CLTV = oltv*(orig_hpi/hpi)*(act_upb/orig_amt);
run;


data  PD_DATA.test_Final_del ;
merge temp_test_del macros  ( rename = (date = orig_dte hpi = orig_hpi) drop = yqtr) ;
by orig_dte;
CLTV = oltv*(orig_hpi/hpi)*(act_upb/orig_amt);
run;



/* Calculating the Macroeconomics into Quarterly Data by average */

ods output summary = test ( keep = _numeric_) ;
proc means data = macros mean;
by yqtr;
run;

/* Sorting the Final Datasets */

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

*Merging Mortgage30;


data PD_DATA.train_Final_cur ;
merge PD_DATA.train_Final_cur Mortgage30;
by yqtr;
Diff_Mortgage = Curr_rte - MortgageRt;
run;

data PD_DATA.train_Final_del ;
merge PD_DATA.train_Final_del Mortgage30;
by yqtr;
Diff_Mortgage = Curr_rte - MortgageRt;
run;

data PD_DATA.test_Final_cur ;
merge PD_DATA.test_Final_cur Mortgage30;
by yqtr;
Diff_Mortgage = Curr_rte - MortgageRt;
run;

data PD_DATA.test_Final_del ;
merge PD_DATA.test_Final_del Mortgage30;
by yqtr;
Diff_Mortgage = Curr_rte - MortgageRt;
run;



data PD_DATA.train_Final_cur( drop = HS PPI HPI Permits date_mean rename = (HS_mean = HS PPI_mean = PPI Permits_mean = Permits HPI_mean =HPI Payroll_mean = Payrolls));
merge PD_DATA.train_Final_cur test;
label 
HS_mean = 'Housing Starts'
PPI_mean = 'Producer Price Index'
Permits_mean = 'Housing Permits'
HPI_mean = 'Housing Price Index'
Payroll_mean = 'Payrolls'
;
format HS_mean PPI_mean Permits_mean HPI_mean Payroll_mean comma10.2;
by yqtr;
run;


data PD_DATA.train_final_del( drop = HS PPI HPI Permits date_mean rename = (HS_mean = HS PPI_mean = PPI Permits_mean = Permits HPI_mean =HPI Payroll_mean = Payrolls ));
merge PD_DATA.train_Final_del test;
label 
HS_mean = 'Housing Starts'
PPI_mean = 'Producer Price Index'
Permits_mean = 'Housing Permits'
HPI_mean = 'Housing Price Index'
Payroll_mean = 'Payrolls'
;
format HS_mean PPI_mean Permits_mean HPI_mean Payroll_mean comma10.2;
by yqtr;
run;


data PD_DATA.test_final_cur( drop = HS PPI HPI Permits date_mean rename = (HS_mean = HS PPI_mean = PPI Permits_mean = Permits HPI_mean =HPI Payroll_mean = Payrolls  ));
merge PD_DATA.test_final_cur test;
label 
HS_mean = 'Housing Starts'
PPI_mean = 'Producer Price Index'
Permits_mean = 'Housing Permits'
HPI_mean = 'Housing Price Index'
Payroll_mean = 'Payrolls'
;
format HS_mean PPI_mean Permits_mean HPI_mean Payroll_mean comma10.2;
by yqtr;
run;




data PD_DATA.test_final_del( drop = HS PPI HPI Permits date_mean rename = (HS_mean = HS PPI_mean = PPI Permits_mean = Permits HPI_mean =HPI Payroll_mean = Payrolls));
merge PD_DATA.test_Final_del test;
label 
HS_mean = 'Housing Starts'
PPI_mean = 'Producer Price Index'
Permits_mean = 'Housing Permits'
HPI_mean = 'Housing Price Index'
Payroll_mean = 'Payrolls'
;
format HS_mean PPI_mean Permits_mean HPI_mean Payroll_mean comma10.2;
by yqtr;
run;

data xyz ;
set PD_DATA.test_final_cur;
UPB_Ratio = act_upb / orig_amt ;
run;

/* Running Binomial Logistic Regression on Diff_Mortgage */


data xyz;
set PD_DATA.train_final_cur;
if next_stat = 'PPY' then flag = 1;
else flag = 0; 
run;

proc logistic data = xyz (where = (cscore_b < 670 )) plots(Maxpoints = 5000 ) = all;
class flag (ref = '1');
model flag = diff_Mortgage / link = glogit;
weight act_upb /normalize;
run;

proc boxplot data = xyz;
plot diff_Mortgage*Purpose / MAXPANELS=100;
run;

ods output CrossTabFreqs = _tmp;
proc freq data = PD_DATA.train_final_cur (where = ((cscore_b le 670) and (^missing(act_upb))));
  table next_stat * Purpose;
run;

/* Splitting the Data into Two segments */

%let score = 670;
%let seg = cscore_b;
%let n_c1 = Sub_Prime;
%let n_c2 = Prime;


%let Macros = HS PPI Permits UMP Payrolls MortgageRt ;

%let MacroTransf = QGT_GDP QRT_GDP AG_GDP QDT_UMP QGT_UMP AG_UMP ggr lagging_UMP GDP_Annual_Rate ;

%let CUR_var = CLTV dti cscore_b orig_amt purpose curr_rte loan_age Orig_chn Orig_rt Orig_trm Num_bo &Macros &MacroTransf diff_mortgage;

%let DEL_var = CLTV dti cscore_b Orig_chn Orig_rt Orig_trm Num_bo curr_rte &Macros &MacroTransf diff_Mortgage;

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

    if 0 < &seg < &score then output c1_test_&d_pd;
    if &score <= &seg then output c2_test_&d_pd ;
    if ^missing(&seg);
    keep &&&d_pd._var next_stat yqtr act_upb  ;
    
  run;

%mend Split_Data;

%Split_Data(DEL);
%Split_Data(CUR);

*Categorical Variables;
ods output CrossTabFreqs = _tmp;
proc freq data = PD_DATA.train_final_cur (where = ((cscore_b le 670) and (^missing(act_upb))));
  table next_stat * Purpose;
run;


proc sgplot data = _tmp(where = (next_stat = "DEL"));
  vbar colPercent / response = colPercent group = Purpose stat = sum;
  yaxis label = "Percentage of Loans in state DEL ";
  xaxis label = "Origination Channel";
run;


/* Regression Modelling */

%let score = 670;
%let seg = cscore_b;
%let n_c1 = Sub_Prime;
%let n_c2 = Prime;
%let c_var = Purpose ;


%let Macros = HS Permits Payrolls ;

%let MacroTransf = QDT_UMP GDP_Annual_Rate ;

%let CUR_var = CLTV dti cscore_b orig_amt loan_age Orig_rt Orig_trm &Macros &MacroTransf diff_Mortgage;

%let DEL_var = CLTV Orig_rt HS QGT_GDP QDT_UMP;


  proc template;
      edit Base.Corr.StackedMatrix;
         column (RowName RowLabel) (Matrix) * (Matrix2);
         edit matrix;
            cellstyle _val_  = -1.00 as {backgroundcolor=CXEEEEEE},
                      _val_ <= -0.75 as {backgroundcolor=wheat},
                      _val_ <= -0.50 as {backgroundcolor=pink},
                      _val_ <= -0.25 as {backgroundcolor=cyan},
                      _val_ <=  0.25 as {backgroundcolor=white},
                      _val_ <=  0.50 as {backgroundcolor=cyan},
                      _val_ <=  0.75 as {backgroundcolor=pink},
                      _val_ <   1.00 as {backgroundcolor= wheat},
                      _val_  =  1.00 as {backgroundcolor=CXEEEEEE};
            end;
         end;
      run;
  

 proc corr data = PD_DATA.train_final_cur  nosimple nomiss plots (MAXPOINTS = NONE) = all;
var &Cur_var;
ods select PearsonCorr;
run;
   
   proc template;
      delete Base.Corr.StackedMatrix;
   run;



/* Orig_chn */

/*  Delinquent subprime Data*/
/* %let Macro_Del_Var  = GDP_Annual_Rate QGT_GDP lagging_UMP*/
/*  */
/* %let Del_Var = Orig_rt Num_bo CLTV Dti*/

%let d_pd = CUR;

%let c_Var = Purpose Orig_chn;
%let Macros = Permits  ;
%let MacroTransf =  GDP_Annual_Rate QDT_UMP ;
%let CUR_Var = CLTV  Dti diff_Mortgage    &Macros &MacroTransf  ; 
%let num = 1;

%macro test(num);

 %if "&d_pd" = "CUR" %then %do;
    %let next = DEL;
    %let n_next = Delinquent;
  %end;
  %if "&d_pd" = "DEL" %then %do;
    %let next = SDQ;
    %let n_next = Default;
    %let c_var = ;
  %end;


  
* Multinomial Logistic Regression;
  ods output ParameterEstimates = &d_pd._c&num._pa(keep = variable response classval0 estimate probchisq);
  proc logistic data = c&num._&d_pd;
    class next_stat (ref = "&d_pd") &c_var / param = glm;
    model next_stat = &&&d_pd._var &c_var/ link = glogit  rsquare cl lackfit ;
    weight act_upb / normalize;
    lsmeans / e ilink cl;
    store c&num._&d_pd._File;
    code file = "%sysfunc(getoption(work))/&num._tmp.sas";
  run;
    
proc plm source = c&num._&d_pd._File;
 effectplot slicefit( x = diff_Mortgage plotby = next_stat) / ilink;
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
  
  
  proc freq data = c1_test_cur;
  table next_stat;
  run;
  
/*  c&num._&d_pd */
* Prediction for the test;
    data c&num._tmp;
    set c&num._&d_pd;
    %include "%sysfunc(getoption(work))/&num._tmp.sas";
  run;
/*  */
/* * Prediction for forecast; */
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
/*  */
/* proc freq data = c&num._tmp; */
/*  */
/* run; */
  
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
  proc means data = c&num._tmp(where = (act_upb ^= . )) mean ;
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


/*  QGT_GDP QRT_GDP AG_GDP QDT_UMP QGT_UMP AG_UMP ggr lagging_UMP GDP_Annual_Rate */

/* cscore_b Orig_amt HS PPI AG_GDP AG_UMP UMP 

%let CUR_var =  CLTV dti cscore_b orig_amt loan_age  HS  &MacroTransf  

*/

%let d_pd = CUR;

%let c_Var = Purpose Orig_chn;
%let Macros = Permits  ;
%let MacroTransf =  GDP_Annual_Rate QDT_UMP ;
%let CUR_Var = CLTV  Dti diff_Mortgage    &Macros &MacroTransf  ; 
%test(1);
%test(2);

%let d_pd = DEL;
%let c_var = ;
%let Macros = GDP_Annual_Rate QDT_UMP HS;
%let DEL_Var = CLTV Curr_Rte dti cscore_b ;
%test(1);
%test(2);


/* %let DEL_var = CLTV Orig_rt HS QGT_GDP QDT_UMP; */
/*  */
/*  */
/*  */
/* %let d_pd = DEL; */
/* %let c_var = purpose; */
/* %let DEL_var = Cltv Orig_rt HS QGT_GDP QDT_UMP diff_Mortgage ; */
/*  */
/* %let d_pd = CUR; */
/* %let Cur_Var = CLTV HS GDP_Annual_Rate QDT_UMP dti cscore_b ; */
/* %let c_var = Purpose; */
/*  */
/* %test(1); */
/*  */
/* %test(2); */



options nodate;
ods powerpoint file = "&p_report/model1.ppt"
               style = Sapphire;
 ods powerpoint exclude all;              
               
ods html file = "&p_report/model1.html"
        style = Sapphire;
        
        
ods html exclude all;

proc options option=config;
run;


ods powerpoint close;
ods html close;




proc Univariate data = PD_DATA.train_Final_cur plots ;
var Orig_trm;
run;











/* proc hpbin data= PD_DATA.train_final_del numbin=5; */
/* input loan_age/numbin=4; */
/* input all other variables; */
/* ods output Mapping=Mapping; */
/* run; */
/*  */
/*  */
/*  */
/* proc hpbin data=PD_DATA.train_final_del WOE BINS_META=Mapping; */
/* target next_stat/level=nominal; */
/* run; */
