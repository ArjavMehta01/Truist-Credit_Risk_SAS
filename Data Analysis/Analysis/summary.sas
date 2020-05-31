/* Author: Jonas */
/* Purpose: Example of Statistics analysis on Q1 data */


* change the value of this macro variable: Q1-Q4;
%let quater = Q1;


%let d_comb = DATA.combined_&quater;
%let v_comb = orig_amt oltv cscore_b dti last_upb;

options nodate;

ods pdf file = "&p_report.Contents.pdf"
        style = Sapphire;

title "Content Table";
proc contents data = &d_comb varnum;
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


quit;