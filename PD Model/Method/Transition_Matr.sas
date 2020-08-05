
%let score = 670;
%let seg = cscore_b;
%let n_c1 = Sub_Prime;
%let n_c2 = Prime;

%let c_var = ;


%let CUR_macro = HS GDP;
%let DEL_macro = QDT_UMP;



%let CUR_var = CLTV Dti Cscore_b Curr_rte &CUR_macro;
%let DEL_var = Curr_rte CLTV Cscore_b &DEL_macro;

%macro test(num);
  
* Multinomial Logistic Regression;
  ods output ParameterEstimates = &d_pd._c&num._pa(keep = variable response classval0 estimate probchisq);
  proc logistic data = PD_DATA.train_&d_pd._&num;
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
    set PD_DATA.out_sample_&num._&d_pd;
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

%test(1);

%test(2);


%let d_pd = DEL;
 %if "&d_pd" = "CUR" %then %do;
    %let next = DEL;
    %let n_next = Delinquent;
  %end;
  %if "&d_pd" = "DEL" %then %do;
    %let next = SDQ;
    %let n_next = Default;
  %end;

%macro predict(d_pd);
ods powerpoint exclude all;


 

/* * Split training dataset into two classes; */
/*   data c1_&d_pd c2_&d_pd p_&d_pd; */
/*     set PD_DATA.train_&d_pd; */
/*      */
/*     attrib FICO label = "FICO"             length = $10. */
/*            hs   label = "Housing Starts" */
/*            ump  label = "Unemployment Rate" */
/*     ; */
/*     */
/*     if 0 < &seg < &score then output c1_&d_pd; */
/*     if &score <= &seg then output c2_&d_pd; */
/*     output p_&d_pd; */
/*      */
/*     keep &&&d_pd._var &c_var act_upb next_stat yqtr &seg; */
/*   run; */
  
  
  
* Split testing dataset into two classes;
/*   data p_c1_&d_pd p_c2_&d_pd; */
/*     set PD_DATA.out_&d_pd; */
/*     where orig_dte < "30Mar2016"d; */
/*      */
/*     if 0 < &seg < &score then output p_c1_&d_pd; */
/*     if &score <= &seg then output p_c2_&d_pd; */
/*      */
/*     keep &&&d_pd._var &c_var act_upb next_stat yqtr; */
/*      */
/*   run; */
  
  %test(1);
  %test(2);
  
  
/*   data PD_DATA.p_&d_pd; */
/*     length group $20; */
/*     set p_c1_&d_pd(in = c1) p_c2_&d_pd(in = c2); */
/*     if c1 then group = "&n_c1"; */
/*     if c2 then group = "&n_c2"; */
/*   run; */
%mend predict;

/* options nodate; */
/* ods powerpoint file = "&p_report/model1.ppt" */
/*                style = Sapphire; */
/* ods html file = "&p_report/model1.html" */
/*         style = Sapphire; */
/* ods html exclude all; */

/* %predict(DEL); */
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


proc export data = PD_DATA.prime
dbms = csv
outfile = "&p_pd/Prime.csv"
replace ;
run;

proc export data = PD_DATA.sub_prime
dbms = csv
outfile = "&p_pd/Sub_Prime.csv"
replace ;
run;
 


