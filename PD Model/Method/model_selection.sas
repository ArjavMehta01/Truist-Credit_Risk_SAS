/* Author: Jonas */
/* Purpose: Model 1: Static predictors */

ods graphics on / width = 4in height = 3in;
options nodate;


%let score = 670;
%let seg = cscore_b;
%let n_c1 = Sub_Prime;
%let n_c2 = Prime;

%let c_var = FICO;
%let v_var = cscore_b;
proc format;
  value c_&c_var low -< 350 = '[0-350)'
               350 -< 620 = '[350,619]'
               620 -< 640 = '[620,639]'
               640 -< 660 = '[640,659]'
               660 -< 680 = '[660,679]'
               680 -< 700 = '[680,699]'
               700 -< 720 = '[700,719]'
               720 -< 740 = '[720,739]'
               740 - high = '[740+)'
  ;
run;

%let CUR_macro = ump;
%let DEL_macro = hs;


%let CUR_var = OLTV orig_amt loan_age &CUR_macro;
%let DEL_var = OLTV &DEL_macro;

%macro test(num);
  ods powerpoint exclude all;
* Multinomial Logistic Regression;
  ods output ParameterEstimates = &d_pd._c&num._pa(keep = variable response classval0 estimate probchisq);
  proc logistic data = c&num._&d_pd;
    class next_stat (ref = "&d_pd") &c_var / param = glm;
    model next_stat = &&&d_pd._var &c_var/ link = glogit rsquare cl;
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
    set p_c&num._&d_pd;
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
  %let c&num = &CUR &DEL &PPY;
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
  ods output Summary = &d_pd._c&num._plot2(keep = yqtr P_next_stat:);
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
/*   title j = l "Group: &&&n_c&num"; */
/*   proc sgplot data = c&num._plot; */
/*     scatter x = yqtr y = historic / legendlabel = "Actual"; */
/*     series x = yqtr y = predict / lineattrs = (color = "cxe34a33" thickness = 2) legendlabel = "Predicted"; */
/*     inset ("&K1" = "&V1" */
/*            "&K3" = "&V3") / border opaque; */
/*     xaxis label = "Year" grid; */
/*     yaxis label = "Probability of &n_next (%)" grid; */
/*   run; */
/*   title; */
  ods powerpoint exclude all;  
  
%mend test;
%let d_pd = DEL;
%let num = 1;

%macro predict(d_pd);
ods powerpoint exclude all;

  %if "&d_pd" = "CUR" %then %do;
    %let next = DEL;
    %let n_next = Delinquent;
  %end;
  %if "&d_pd" = "DEL" %then %do;
    %let next = SDQ;
    %let n_next = Default;
  %end;

* Split training dataset into two classes;
  data c1_&d_pd c2_&d_pd p_&d_pd;
    set PD_DATA.train_&d_pd;
    
    attrib FICO label = "FICO"             length = $10.
           hs   label = "Housing Starts"
           ump  label = "Unemployment Rate"
    ;
    &c_var = put(&v_var, c_&c_var..);
    if 0 < &seg < &score then output c1_&d_pd;
    if &score <= &seg then output c2_&d_pd;
    output p_&d_pd;
    
    keep &&&d_pd._var &c_var act_upb next_stat yqtr &seg;
  run;
  
* Split testing dataset into two classes;
  data p_c1_&d_pd p_c2_&d_pd;
    set PD_DATA.out_&d_pd;
    where orig_dte < "30Mar2016"d;
    attrib FICO label = "FICO"             length = $10.
           hs   label = "Housing Starts"
           ump  label = "Unemployment Rate"
    ;
    &c_var = put(&v_var, c_&c_var..);
    if 0 < &seg < &score then output p_c1_&d_pd;
    if &score <= &seg then output p_c2_&d_pd;
    
    keep &&&d_pd._var &c_var act_upb next_stat yqtr;
    
  run;
  
  %test(1);
  %test(2);
  
  
/*   data PD_DATA.p_&d_pd; */
/*     length group $20; */
/*     set p_c1_&d_pd(in = c1) p_c2_&d_pd(in = c2); */
/*     if c1 then group = "&n_c1"; */
/*     if c2 then group = "&n_c2"; */
/*   run; */
%mend predict;

options nodate;
ods powerpoint file = "&p_report/model1.ppt"
               style = Sapphire;
ods html file = "&p_report/model1.html"
        style = Sapphire;
ods html exclude all;

%predict(DEL);
/* %predict(CUR); */

ods html close;
ods powerpoint close;


%macro out_matrix(num);

  data PD_DATA.&&&n_c&num;
    length curr_stat $3.;
    set del_c&num._plot2(rename = (P_Next_statCUR_Mean = CUR P_Next_statDEL_Mean = DEL 
                                   P_Next_statPPY_Mean = PPY P_Next_statSDQ_Mean = SDQ)
                             in = d
                         )
        cur_c&num._plot2(rename = (P_Next_statCUR_Mean = CUR P_Next_statDEL_Mean = DEL 
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
  
  proc sort data = PD_DATA.&&&n_c&num;
    by yqtr curr_stat;
  run;
%mend out_matrix;

%out_matrix(1);
%out_matrix(2);

/*
proc export data = PD_DATA.prime outfile = "&p_pddata/prime.csv" dbms = csv;
run;
proc export data = PD_DATA.sub_prime outfile = "&p_pddata/sub.csv" dbms = csv;
run;

data out_act;
  set PD_DATA.out_del(in = d) PD_DATA.out_cur(in = c);
  if d then _to = "DEL_to_";
  if c then _to = "CUR_to_";
  state = cat(_to, next_stat);
  where orig_dte < "30Mar2016"d;
  if 0 < &seg < &score then group = "sub-prime";
    if &score <= &seg then group = "prime";
  if next_stat = "SDQ" then def_flg = 1;
    else def_flg = 0;
run;

ods html file = "&p_pddata/out_of_sample.html";
proc freq data = out_act;
  table group*yqtr*def_flg / nocol nopercent;
run;
ods html close;

*/
/*

%let d_train = PD_DATA.train_cur;
  data test(keep = FICO next_stat c_amt c_FICO c_OLTV c_dti);
    set &d_train;
    length FICO $10;
    format yqtr yyq.;
    label hs = "Housing Starts"
          ump = "Unemployment Rate"
          ppi = "Producer Price Index"
          gdp = "GDP"
          hpi = "House Price Index"
          ;
    attrib c_amt  label = "Original Loan Amount"   length = $20.
           c_FICO label = "Credit Score Cohort"    length = $10.
           c_OLTV label = "Original Loan to Value" length = $10.
           c_dti  label = "Debt-to-Income Cohort"  length = $10.
           ;
          
    yqtr = yyq(year(act_date),qtr(act_date));
    
    if missing(act_upb) then act_upb = Orig_amt;
    
    if Orig_amt lt 100000 then c_amt = "[0-100,000)";
      else if Orig_amt lt 150000 then c_amt = "[100,000-150,000)";
      else if Orig_amt lt 200000 then c_amt = "[150,000-200,000)";
      else if Orig_amt lt 250000 then c_amt = "[200,000-250,000)";
      else if Orig_amt lt 300000 then c_amt = "[250,000-300,000)";
      else if Orig_amt lt 350000 then c_amt = "[300,000-350,000)";
      else if Orig_amt lt 400000 then c_amt = "[350,000-400,000)";
      else if Orig_amt lt 450000 then c_amt = "[400,000-450,000)";
      else if Orig_amt ge 450000 then c_amt = "[450,000+)";
    
    if cscore_b le 349 then c_FICO = "[0-350)";
      else if cscore_b le 619 then c_FICO = "[350,619]";
      else if cscore_b le 639 then c_FICO = "[620,639]";
      else if cscore_b le 659 then c_FICO = "[640,659]";
      else if cscore_b le 679 then c_FICO = "[660,679]";
      else if cscore_b le 699 then c_FICO = "[680,699]";
      else if cscore_b le 719 then c_FICO = "[700,719]";
      else if cscore_b le 739 then c_FICO = "[720,739]";
      else if cscore_b ge 740 then c_FICO = "[740+)";
    
    if dti lt 10 then c_dti = "[0-10)";
      else if dti lt 20 then c_dti = "[10,20)";
      else if dti lt 30 then c_dti = "[20,30)";
      else if dti lt 40 then c_dti = "[30,40)";
      else if dti lt 50 then c_dti = "[40,50)";
      else if dti lt 60 then c_dti = "[50,60)";
      else if dti lt 70 then c_dti = "[60,70)";
      else if dti ge 70 then c_dti = "[70+)"; 

    if OLTV lt 60 then c_OLTV = "[0-60)";
      else if OLTV lt 65 then c_OLTV = "[60,65)";
      else if OLTV lt 70 then c_OLTV = "[65,70)";
      else if OLTV lt 75 then c_OLTV = "[70,75)";
      else if OLTV lt 80 then c_OLTV = "[75,80)";
      else if OLTV lt 85 then c_OLTV = "[80,85)";
      else if OLTV lt 90 then c_OLTV = "[85,90)";
      else if OLTV lt 95 then c_OLTV = "[90,95)";
      else if OLTV ge 95 then c_OLTV = "[95+)"; 
    
    
    if 0 < cscore_b < &score then FICO = 'Sub-Prime';
    if &score <=cscore_b then FICO = 'Prime';
    if ^missing(FICO);
  run;


%macro s_plot(var);
  ods output CrossTabFreqs = tmp(where = (next_stat = "DEL") keep = next_stat c_&var rowpercent);
  proc freq data = test;
    table c_&var*next_stat / nofreq nopercent nocol;
  run;
  
  
  ods html5 select all;
  title "Contingency table of &var";
  footnote j = l "Current State: CUR";
  footnote2 j = l "Next State: DEL";
  proc freq data = test;
    table c_&var*next_stat / nofreq norow nocol;
  run;
  title;
  
  title "Line chart of &var";
  proc sgplot data = tmp;
    series x = c_&var y = rowpercent;
    xaxis grid label = "&var";
    yaxis grid label = "Probability of Delinquent(%)";
  run;
  title;
  
  ods html5 select none;
%mend s_plot;

options nodate;
ods html5 file = "&p_report/sasoutput.html" style = Sapphire;
ods html5 select none;
%s_plot(AMT);
%s_plot(DTI);
%s_plot(OLTV);
%s_plot(FICO);
ods html5 close;


*/

/* ods html5 file = "&p_report/ "; */




%macro act_PD();
* Get the historical PD for out-of-sample dataset;
  data act_prime act_sub_prime;
    set PD_DATA.out_cur PD_DATA.out_del;
    where orig_dte < "30Mar2016"d;
    if 0 < cscore_b < 670 then output act_sub_prime;
      if 670 <= cscore_b then output act_prime;
    keep yqtr next_stat;
  run;
  
  title "Sub-prime";
  proc freq data = act_sub_prime;
    table yqtr*next_stat / nocol nopercent nofreq;
  run;
  title "Prime";
  proc freq data = act_prime;
    table yqtr*next_stat / nocol nopercent nofreq;
  run;
  
  title "SDQ as next, 2016Q1";
  proc print data = PD_DATA.out_cur;
    where next_stat = "SDQ" and orig_dte < "30Mar2016"d;
  run;
  proc print data = PD_DATA.out_del;
    where next_stat = "SDQ" and orig_dte < "30Mar2016"d;
  run;
%mend act_PD;

