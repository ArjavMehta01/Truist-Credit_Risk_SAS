/* Author: Jonas */

/* Purpose: Example of Statistics analysis on sample data */

options nodate;
/*
options nodate;
ods pdf file = "&p_report.Contents.pdf"
        style = Sapphire;

title "Content Table";

proc contents data = DATA.loan varnum;

  ods select Position;
  ods output Position = content;
run;
title;

ods pdf close;

*/

* prepare data for calculating PD;
data DATA.tmp;
  set DATA.sample;
  label def_flg = "Default Flag";
  if missing(dlq_stat) then delete;
  else do;
    if dlq_stat < 3 then def_flg = 0;
    else if dlq_stat = 999 and (nmiss(zb_code) or zb_code in ("01" "06")) then def_flg = 0;
    else def_flg = 1;
  end;
run;

proc sort data = DATA.tmp;
  by loan_id descending def_flg;
run;

* PD time series scatter plot;
ods output CrossTabFreqs = tmp;
proc freq data = DATA.tmp;
  table act_date*def_flg;
run;

data tmp(keep = act_date rowpercent);
  set tmp;
  label rowpercent = "Probability of Default(%)";


* change the value of this macro variable: Q1-Q4;
%let quater = Q1;

%let d_comb = DATA.sample_&quater;
/* %let d_comb = DATA.sample_Q1 DATA.sample_Q2 DATA.sample_Q3 DATA.sample_Q4 */

%let v_comb = loan_id oltv dti cscore_b act_date orig_amt act_upb loan_age dlq_stat zb_code;


* prepare data for calculating PD;
data DATA.tmp;
  set &d_comb;
  label def_flg = "Default Flag";
  if missing(dlq_stat) then delete;
  else do;
    if dlq_stat < 3 then def_flg = 0;
    else if dlq_stat = 999 and (nmiss(zb_code) or zb_code in ("01" "06")) then def_flg = 0;
    else def_flg = 1;
  end;
  keep &v_comb def_flg;
run;

proc sort data = DATA.tmp;
  by loan_id descending def_flg;
run;

* PD time series scatter plot;
ods output CrossTabFreqs = tmp;
proc freq data = DATA.tmp;
  table act_date*def_flg;
run;

data tmp(keep = act_date rowpercent);
  set tmp;
  label rowpercent = "Probability of Default (%)";
  if def_flg = 1 & _type_ = "11";
run;



ods powerpoint file = "&p_report/_summary.ppt"

               style = Sapphire;

ods graphics on / width=4in height=4in;

title "Scatter Plots of PD";
proc sgscatter data = tmp;
  compare X = act_date Y = rowpercent / grid;
run;
title;

ods powerpoint exclude all;


%macro pd_scatter(driver, n_driver);

  data tmp;
    set DATA.tmp;
    by loan_id;
    if first.loan_id;
    keep &driver loan_id def_flg;
  run;
  

  ods output CrossTabFreqs = tmp2;
  proc freq data = tmp;
    table &driver.*def_flg;
  run;

  
  data tmp2(keep = &driver rowpercent);
    label rowpercent = "Probability of Default (%)";
    set tmp2;
    if def_flg = 1 & _type_ = "11";
  run;
  
  ods powerpoint exclude none;
  
  title "Scatter Plots of PD by &n_driver";
  proc sgscatter data = tmp2;
    compare X = &driver Y = rowpercent / grid;
  run;
  title;
  
  title "Univariate Analysis of &n_driver";
  proc univariate data = tmp;
  var &driver;

  ods select Moments BasicMeasures ExtremeObs MissingValues;

  run;
  title;
  
  ods powerpoint exclude all;
%mend pd_scatter;


%macro scatterloop;
  %pd_scatter(oltv, LTV);
  %pd_scatter(dti, DTI);
  %pd_scatter(cscore_b, FICO);
%mend scatterloop;

%scatterloop;

ods powerpoint close;



proc datasets lib = DATA nolist;
  delete tmp;
run;

/*
ods pdf file = "&p_anly.Summaries.pdf"
        style = Sapphire
        startpage = never;
options orientation = landscape;

title "Statistics Summaries of &quater data (firm = &bank)";

proc means data = &d_comb
  min mean median mode max std range
  maxdec = 0
  nmiss;
  var &v_comb;
run;
options orientation = portrait;
title2 "Missing Data Values";
proc sql;
  select varname "Variable Name", label "Label",
         count "Frequency of Missing Values",
         countnobs "Percent of Total Observations"
    from tmp;
quit;
title2 "Frequencies of Last Status";
footnote j=left "1 = 30 – 59 days; 2 = 60 – 89 days; Sequence continues thereafter for every 30 day period";
footnote2 j=left "C = Current, or less than 30 days past due; F = Deed-in-Lieu, REO; L = Reperforming Loan Sale;
 N = Note Sale; P = Prepaid or Matured; R = Repurchased; S = Short Sale; T = Third Party Sale; X = missing";
proc freq data = &d_comb;
  tables last_stat;
run;
title;
footnote;
ods pdf close;

*/
quit;