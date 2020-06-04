/* Author: Jonas */
/* Purpose: Prepare the dataset for further analysis */



%put DATA VALIDATION;

/*    
* data validataion;

filename ACQid "&p_acq/ACQ_IDsample.csv";

data id_sample;
  infile ACQid dsd firstobs = 2;
  input tran_flg loan_id:$12.;
  keep loan_id;
  if tran_flg = 1;
run;

proc sort data = id_sample;
  by loan_id;
run;

proc sort data = data.sample out = id_sample2(keep=loan_id) nodupkey;
  by loan_id;
run;

proc compare base = id_sample compare = id_sample2;
run;
*/



/*

proc freq data = data.sample;
  table zb_code dlq_stat;
run;

*/



%put DATA PREPARATION;


/*

proc sort data = DATA.sample(drop = orig_rt orig_dte zb_date)
          out = PD_DATA.origin;
  by loan_id;
run;



* Prepare the data: create a new status variable;
data PD_DATA.origin tmp_id(keep = loan_id curr_stat 
                         rename = (loan_id = _id curr_stat = Next_stat)
                         );
  set PD_DATA.origin;
  attrib Curr_stat length = $3.
                   label = "Current State"
                   ;
                    
  by loan_id;
  retain _def 0;
  
  if first.loan_id then do;            
    _def = 0;
  end;
  
  if ^_def then do;
    if dlq_stat = 0 then
      Curr_stat = "CUR";
    else if dlq_stat le 3 then
      Curr_stat = "DEL";
    else if dlq_stat = 999 and zb_code in ("01" "06") then
      Curr_stat = "PPY";
    else _def = 1;
  end;
  if _def then Curr_stat = "SDQ";
run;

data PD_DATA.origin(drop = _:);
  merge PD_DATA.origin tmp_id(firstobs = 2);
  attrib Next_stat length = $3.
                   label = "Next State"
                   ;
  if loan_id ne _id then next_stat = "";
run;



data _final(drop = curr_stat);
  set PD_DATA.origin(keep = loan_id curr_stat);
  by loan_id;
  attrib Final_stat length = $3.
                   label = "Final State"
                   ;
  
  if last.loan_id then do;
    Final_stat = curr_stat;
    output;
  end;
run;

* Grouping the FICO;

data PD_DATA.loan;
  merge PD_DATA.origin _final;
  by loan_id;
  length fico $10;
  if 0 < cscore_b < 620 then
    fico = '[0-620)';
  if 620 <=cscore_b < 660 then
    fico = '[620-660)';
  if 660 <=cscore_b < 700 then
    fico = '[660-700)';
  if 700 <=cscore_b < 740 then
    fico = '[700-740)';
  if 740 <=cscore_b < 780 then
    fico = '[740-780)';
  if 780 <=cscore_b then
    fico = '[780+)';
  
  drop dlq_stat zb_code cscore_b;
run;


%put DATA GROUPING;

data PD_DATA.cur PD_DATA.del;
  set PD_DATA.loan;
  if Curr_stat = "CUR" then output PD_DATA.cur;
  if Curr_stat = "DEL" then output PD_DATA.del;
run;

*/

%put DATA SUMMARY;

* ODS powerpoint output;
ods powerpoint file = "&p_pdres/summary.ppt"
               style = Sapphire;

ods graphics on / width=7in height=7in;

options nodate;

ods powerpoint exclude all;


* Freq table: calculate the PD;
ods output CrossTabFreqs = _freq1(keep = next_stat final_stat _type_ rowpercent
                                  where = (_type_ = "11" and final_stat = "SDQ")
                                  );
proc freq data = PD_DATA.cur;
  table Next_stat*final_stat;
run;

ods output CrossTabFreqs = _freq2(keep = next_stat final_stat _type_ rowpercent
                                  where = (_type_ = "11" and final_stat = "SDQ")
                                  );
proc freq data = PD_DATA.del;
  table Next_stat*final_stat;
run;

data _tmp1;
  merge _freq1(keep = next_stat rowpercent
               rename = (rowpercent = CUR)
               )
        _freq2(keep = next_stat rowpercent
               rename = (rowpercent = DEL)
               );
  by next_stat;
run;

proc transpose data = _tmp1
               prefix = stat
               out = _tmp2(drop = _label_);
run;

* Concatenate tables: data for bar chart;
data _tmp3;
  set _freq1(in = a) _freq2(in = b);
  if a then stat = "CUR";
  if b then stat = "DEL";
  keep stat next_stat rowpercent;
run;


ods powerpoint exclude none;

title "Competing Risk Transition Matrix";
proc report data = _tmp2;
  columns _name_ ('Next State'(stat1 stat3 stat2 stat4));
  define _name_ / "Current State";
  define stat1 / "Current (CUR)";
  define stat2 / "Delinquent (DEL)";
  define stat3 / "Prepay (PPY)";
  define stat4 / "Default (SDQ)";
run;
title;

title "Historical Transition Rate";
proc sgplot data = _tmp3;
  vbar next_stat/ response = rowpercent group = stat
                  groupdisplay = cluster nooutline;
  styleattrs datacolors = (cx9ecae1 cx3182bd);
  keylegend / title = "Current State";
  yaxis label = "Probability of Default(%)"
        grid  gridattrs = (color = 'cxdeebf7');
run;
title;

ods powerpoint exclude all;     

proc sort data = PD_DATA.origin(where = (curr_stat in ("CUR" "DEL"))) out = _box;
  by curr_stat;
run;

ods powerpoint exclude none;  

title "Box Plot for Loan-level Drivers";
proc boxplot data = _box;
  plot (oltv dti cscore_b)*curr_stat / boxstyle = schematic outbox = _outbox;
  inset min mean max stddev/
      header = 'Overall Statistics'
      pos    = tm;
run;
title;

ods select MissingValues;
proc univariate data = PD_DATA.origin;
  var oltv dti cscore_b act_upb;
run;


title "Frequency table of outliers";
proc freq data = _outbox;
  table curr_stat*_var_*_type_ / nocol nopercent;
  where _type_ in ("FARLOW" "LOW" "HIGH");
run;
title;

ods powerpoint exclude all;

/* proc means data = _outbox (where = (_type_ in ("FARLOW" "LOW") and _var_ in ("Oltv" "Cscore_b"))); */
/*   var _value_; */
/*   by _type_; */
/* run; */


ods powerpoint close;




* Prepare for the scatter plot;

/*
data _tmp4;
  set PD_DATA.origin;
  by loan_id;
  if first.loan_id;
  keep cscore_b loan_id final_stat;
run;

ods output CrossTabFreqs = _tmp5;
proc freq data = _tmp4;
  table cscore_b*final_stat;
run;

data _tmp6(keep = cscore_b rowpercent);
  label rowpercent = "Probability of Default (%)";
  set _tmp5;
  if final_stat = "SDQ" & _type_ = "11";
run;

 



title "Scatter Plots of PD by FICO";
proc sgscatter data = _tmp6;
  compare X = cscore_b Y = rowpercent / grid;
run;
title;



*/







/* 
proc sgscatter data = PD_DATA.del;
  matrix oltv dti cscore_b / diagonal = (histogram kernel);
run;
 */



/*
%put FORMAT;

proc format lib = PD_DATA;
  value fico low -< 620 = '[0-620)'
             620 -< 660 = '[620-660)'
             660 -< 700 = '[660-700)'
             700 -< 740 = '[700-740)'
             740 -< 780 = '[740-780)'
             780 - high = '[780+)'
  ;
run;
             
*/

%put DATA MERGING;
/*
* Merge the loan-level data with macros by date;

proc sort data = PD_DATA.loan;
  by act_date;
run;

data PD_DATA.merge;
  merge PD_DATA.loan PD_DATA.macro;
  by act_date;

run;

*/



    
    
    
    
    
    
    