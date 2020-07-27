/* Author: Jonas */
/* Purpose: Model Baseline */

ods graphics on / width = 4in height = 3in;
options nodate;


%let score = 670;
%let seg = cscore_b;
%let n_c1 = Sub_Prime;
%let n_c2 = Prime;

proc freq data = DATA.loan;
  tables mod_ind;
run;


%let CUR_var = CLTV cscore_b orig_amt loan_age;
%let DEL_var = CLTV cscore_b;
/* %let DEL_var = dti cscore_b hs ppi hpi ump gdp; */

%macro test(num);
  ods powerpoint exclude none;
* Multinomial Logistic Regression;
  proc logistic data = c&num._&d_pd;
    class next_stat (ref = "&d_pd") / param = glm;
    model next_stat = &&&d_pd._var/ link = glogit rsquare cl;
    weight act_upb / normalize;
    lsmeans / e ilink cl;
    code file = "%sysfunc(getoption(work))/&num._tmp.sas";
  run;
  ods powerpoint exclude all;
* Prediction for the test;
  data c&num._tmp;
    set p_c&num._&d_pd;
    %include "%sysfunc(getoption(work))/&num._tmp.sas";
  run;

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
  %let c&num = &CUR &DEL &PPY &SDQ;

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
  title "Prediction of the Training Set";
  footnote j = l "Data: &d_pd Group: &&&n_c&num";
  proc sgplot data = c&num._plot;
    series x = yqtr y = historic / legendlabel = "Historical";
    series x = yqtr y = predict / lineattrs = (color = "cxe34a33" thickness = 2) legendlabel = "Predict";
    *inset ("&K1" = "&V1"
           "&K3" = "&V3") / border opaque;
    xaxis label = "Year" grid;
    yaxis label = "Probability of &n_next (%)" grid;
  run;
  title;
  footnote;
  ods powerpoint exclude all;  
  
%mend test;

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
    
    attrib hs   label = "Housing Starts"
           ump  label = "Unemployment Rate"
    ;
    if 0 < &seg < &score then output c1_&d_pd;
    if &score <= &seg then output c2_&d_pd;
    output p_&d_pd;
    
    GDP = (GDP - lag(GDP))/lag(GDP);
    
    keep &&&d_pd._var act_upb next_stat yqtr;
  run;
  
* Split testing dataset into two classes;
  data p_c1_&d_pd p_c2_&d_pd;
    set PD_DATA.train_&d_pd;
    attrib hs   label = "Housing Starts"
           ump  label = "Unemployment Rate"
    ;
    if 0 < &seg < &score then output p_c1_&d_pd;
    if &score <= &seg then output p_c2_&d_pd;
   
    keep &&&d_pd._var act_upb next_stat yqtr;
    
  run;
  
/*   %test(1); */
  %test(2);
  

%mend predict;

options nodate;
ods powerpoint file = "&p_report/model_1.ppt"
               style = Sapphire;

/* %predict(DEL); */
%predict(CUR);

ods powerpoint close;


proc boxplot data = xyz;
  plot purpose * diff_m;
run;

ods graphics max
