/* Author: Jonas */
/* Purpose: Contingency table of categorical data */



%let score = 670;

%let CUR_var = oltv orig_amt loan_age ump;
%let DEL_var = oltv hs;

/*

%let d_train = PD_DATA.train_cur;
  data test(keep = FICO next_stat c_amt c_fico c_oltv c_dti);
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
           c_fico label = "Credit Score Cohort"    length = $10.
           c_oltv label = "Original Loan to Value" length = $10.
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
    
    if cscore_b le 349 then c_fico = "[0-350)";
      else if cscore_b le 619 then c_fico = "[350,619]";
      else if cscore_b le 639 then c_fico = "[620,639]";
      else if cscore_b le 659 then c_fico = "[640,659]";
      else if cscore_b le 679 then c_fico = "[660,679]";
      else if cscore_b le 699 then c_fico = "[680,699]";
      else if cscore_b le 719 then c_fico = "[700,719]";
      else if cscore_b le 739 then c_fico = "[720,739]";
      else if cscore_b ge 740 then c_fico = "[740+)";
    
    if dti lt 10 then c_dti = "[0-10)";
      else if dti lt 20 then c_dti = "[10,20)";
      else if dti lt 30 then c_dti = "[20,30)";
      else if dti lt 40 then c_dti = "[30,40)";
      else if dti lt 50 then c_dti = "[40,50)";
      else if dti lt 60 then c_dti = "[50,60)";
      else if dti lt 70 then c_dti = "[60,70)";
      else if dti ge 70 then c_dti = "[70+)"; 

    if oltv lt 60 then c_oltv = "[0-60)";
      else if oltv lt 65 then c_oltv = "[60,65)";
      else if oltv lt 70 then c_oltv = "[65,70)";
      else if oltv lt 75 then c_oltv = "[70,75)";
      else if oltv lt 80 then c_oltv = "[75,80)";
      else if oltv lt 85 then c_oltv = "[80,85)";
      else if oltv lt 90 then c_oltv = "[85,90)";
      else if oltv lt 95 then c_oltv = "[90,95)";
      else if oltv ge 95 then c_oltv = "[95+)"; 
    
    
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


%macro pdct(d_pd);
ods powerpoint exclude all;

  %if "&d_pd" = "CUR" %then %do;
    %let next = DEL;
  %end;
  %if "&d_pd" = "DEL" %then %do;
    %let next = SDQ;
  %end;

* Split training dataset into prime vs. sub-prime;
  data sub_&d_pd prm_&d_pd;
    set PD_DATA.train_&d_pd;
    
    attrib fico label = "FICO"             length = $10.
           hs   label = "Housing Starts"
           ump  label = "Unemployment Rate"
    ;
    if cscore_b le 349 then fico = "[0-350)";
      else if cscore_b le 619 then fico = "[350,619]";
      else if cscore_b le 639 then fico = "[620,639]";
      else if cscore_b le 659 then fico = "[640,659]";
      else if cscore_b le 679 then fico = "[660,679]";
      else if cscore_b le 699 then fico = "[680,699]";
      else if cscore_b le 719 then fico = "[700,719]";
      else if cscore_b le 739 then fico = "[720,739]";
      else if cscore_b ge 740 then fico = "[740+)";
    
    if 0 < cscore_b < &score then output sub_&d_pd;
    if &score <=cscore_b then output prm_&d_pd;
    
    keep &&&d_pd._var fico act_upb next_stat;
  run;
  
* Split testing dataset into prime vs. sub-prime;
  data p_sub_&d_pd p_prm_&d_pd;
    set PD_DATA.test_&d_pd;
    
    attrib fico label = "FICO"             length = $10.
           hs   label = "Housing Starts"
           ump  label = "Unemployment Rate"
    ;
    if cscore_b le 349 then fico = "[0-350)";
      else if cscore_b le 619 then fico = "[350,619]";
      else if cscore_b le 639 then fico = "[620,639]";
      else if cscore_b le 659 then fico = "[640,659]";
      else if cscore_b le 679 then fico = "[660,679]";
      else if cscore_b le 699 then fico = "[680,699]";
      else if cscore_b le 719 then fico = "[700,719]";
      else if cscore_b le 739 then fico = "[720,739]";
      else if cscore_b ge 740 then fico = "[740+)";
    
    if 0 < cscore_b < &score then output p_sub_&d_pd;
    if &score <=cscore_b then output p_prm_&d_pd;
    
    keep &&&d_pd._var fico act_upb next_stat;
  run;
  
* Regression of sub-prime group;
  proc logistic data = sub_&d_pd;
    class next_stat (ref = "&d_pd") fico / param = glm;
    model next_stat = &&&d_pd._var / link = glogit rsquare cl;
    weight act_upb / normalize;
    lsmeans / e ilink cl;
    code file = "%sysfunc(getoption(work))/sub_tmp.sas";
  run;

* Test of prediction;
  data sub_tmp;
    set p_sub_&d_pd;
    %include "%sysfunc(getoption(work))/sub_tmp.sas";
  run;
  
* Getting the output data;
  ods output OneWayFreqs = sub_tmp_f(keep = next_stat percent);
  proc freq data = sub_tmp;
    table next_stat;
  run;
  ods output Summary = sub_tmp_m(keep = label_: p_:);
  proc means data = sub_tmp mean;
    var p_:;
    weight act_upb;
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
  quit;
  ods powerpoint exclude none;
  title "One Way Chi-Square Test of &d_pd Data";
  footnote j = l "Group: Sub-Prime";
  proc freq data = sub_tmp;
    table next_stat / chisq
    testp = (&sub);
  run;
  title;
  footnote;
  ods powerpoint exclude all;
  
* Regression of prime group;
  proc logistic data = prm_&d_pd;
    class next_stat (ref = "&d_pd") fico / param = glm;
    model next_stat = &&&d_pd._var / link = glogit rsquare cl;
    weight act_upb / normalize;
    lsmeans / e ilink cl;
    code file = "%sysfunc(getoption(work))/prm_tmp.sas";
  run;

* Test of prediction;
  data prm_tmp;
    set p_prm_&d_pd;
    %include "%sysfunc(getoption(work))/prm_tmp.sas";
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
  proc sql;
    create table work.prm_tmp_r as
    select f.next_stat "Next State",
           percent "Actual Probability (%)",
           predict "Predicted Probability (%)"
      from work.prm_tmp_m as m inner join work.prm_tmp_f as f
        on m.next_stat = f.next_stat
      order by f.next_stat
      ;
  quit;
  ods powerpoint exclude none;
  title "One Way Chi-Square Test of &d_pd Data";
  footnote j = l "Group: Prime";
  proc freq data = prm_tmp;
    table next_stat / chisq
    testp = (&prm);
  run;
  title;
  footnote;
  ods powerpoint exclude all;

* Final report;
  data tmp_r;
    set sub_tmp_r(in = s) prm_tmp_r(in = p);
    format predict 8.2;
    if s then FICO = "Sub-Prime";
    if p then FICO = "Prime";
  run;
  
  ods powerpoint exclude none;
  title "Prediction of Test-Set";
  footnote j = l "Data: &d_pd";
  proc report data = tmp_r;
    columns FICO next_stat percent predict;
    define FICO / group center;
    define next_stat / display center;
    define percent / analysis center;
    define predict / analysis center;
    compute next_stat;
      if next_stat = "&next" then call define(_row_, "style", "style={background=cxdeebf7}");
    endcomp;
  run;
  title;
  footnote;
  ods powerpoint exclude all;
%mend pdct;

options nodate;
ods powerpoint file = "&p_report/test.ppt"
              style = Sapphire;
%pdct(DEL);
%pdct(CUR);

ods powerpoint close;