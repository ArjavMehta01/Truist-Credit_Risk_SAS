/* Author: Jonas */
/* Purpose: Example of Statistics analysis on 2005Q1 data */

%let _date = 2005Q1;
%let d_comb = COMB.COMB_&_date;
%let v_comb = orig_amt oltv cscore_b dti last_upb;

options nodate;

ods pdf file = "&p_data.Contents.pdf"
        style = Sapphire;

title "Content Table";
<<<<<<< Updated upstream
proc contents data = &d_comb varnum;
=======
proc contents data = DATA.sample varnum;
>>>>>>> Stashed changes
  ods select Position;
  ods output Position = content;
run;
title;

ods pdf close;

/*
● Unpaid Balance (UPB)
● LTV
● Loan Age
● Remaining Until Maturity
● Interest Rate
● Delinquency Status
● Debt-to-Income (DTI)
*/

<<<<<<< Updated upstream
ods output MissingValues = miss_value;
proc univariate data = &d_comb;
  var &v_comb;
=======
%let d_comb = DATA.sample;

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
  
  if missing(zb_code) and dlq_stat = 999 then delete;
  keep &v_comb def_flg;
run;

proc sort data = DATA.tmp;
  by loan_id descending def_flg;
>>>>>>> Stashed changes
run;

data content(rename = (variable = varname));
  set content(keep = variable label);
run;

proc sort data = content;
  by varname;
run;


proc sort data = miss_value;
  by varname;
run;

data tmp;
  merge miss_value(keep = varname count countnobs
                   in = miss)
        content;
  by varname;
  if miss;
run;

<<<<<<< Updated upstream
ods pdf file = "&p_data.Summaries.pdf"
=======

proc datasets library = DATA nolist;
  delete tmp;
run;


/*
ods pdf file = "&p_anly.Summaries.pdf"
>>>>>>> Stashed changes
        style = Sapphire
        startpage = never;
options orientation = landscape;

title "Statistics Summaries of &_date Data";

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
proc freq data = &d_comb;
  tables last_stat;
run;
title;
ods pdf close;


quit;