/* Author: Jonas */
/* Purpose: Example of Statistics analysis on Q1 data */

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


* change the value of this macro variable: Q1-Q4;
%let quater = Q1;


%let d_comb = DATA.sample_&quater;
%let v_comb = oltv dti cscore_b act_date orig_amt act_upb loan_age dlq_stat zb_code;


* prepare data for calculating PD;
data DATA.tmp;
  set &d_comb;
  label def_flg = "Default Flag";
  if missing(dlq_stat) then delete;
  else do;
    if dlq_stat < 3 and (nmiss(zb_code) | zb_code in ("01" "06")) then def_flg = 0;
    else def_flg = 1;
  end;
  keep &v_comb def_flg;
run;



ods output CrossTabFreqs = tmp;
proc freq data = DATA.tmp;
  table act_date*def_flg;
run;

data tmp(keep = act_date rowpercent);
  set tmp;
  if def_flg = 1 & _type_ = "11";
run;

proc sgscatter data = tmp;
  compare X = act_date Y = rowpercent;
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