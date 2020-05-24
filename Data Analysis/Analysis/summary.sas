/* Author: Jonas */
/* Purpose: Example of Statistics analysis on 2005Q1 data */

%let _date = 2005Q1;
%let d_comb = COMB.COMB_&_date;
%let v_comb = orig_amt oltv ocltv cscore_b cscore_c dti last_rt last_upb Ar_cost;

options nodate;

ods pdf file = "&p_data.Contents.pdf"
        style = Sapphire;

title "Content Table";
proc contents data = &d_comb varnum;
  ods select Position;
  ods output Position = content;
run;
title;

/*
● Unpaid Balance (UPB)
● LTV
● Loan Age
● Remaining Until Maturity
● Interest Rate
● Delinquency Status
● Debt-to-Income (DTI)
*/

ods output MissingValues = miss_value;
proc univariate data = &d_comb;
  var &v_comb;
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

ods pdf file = "&p_data.Summaries.pdf"
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