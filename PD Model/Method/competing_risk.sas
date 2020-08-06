/* Author: Jonas */
/* Purpose: Build multinomial logistic regression */

options mstored sasmstore = PD_DATA;


/* %let cvar = fthb_flg Num_unit Prop_typ Purpose Occ_stat; */
%let cvar = Occ_stat;

/* %let var = oltv dti curr_rte cscore_b loan_age hs ump gdp ppi hpi &cvar; */
%let var = oltv dti curr_rte cscore_b loan_age hs ump gdp ppi hpi &cvar;
%put ----------------------------------------------------------------- DATA CONTENTS;

/* ods pdf file = "&p_report/var_list.pdf"; */
/* ods select Position; */
/* title "Contents"; */
/* proc contents data = PD_DATA.DEL (keep = &var) varnum; */
/* run;   */
/* title; */
/*  */
/* ods pdf close; */


%put ----------------------------------------------------------------- DATA PREPARATION;
* Grouping the FICO;

%macro by_FICO(d_pd) / store source;

  data PD_DATA._&d_pd;
    set PD_DATA.&d_pd (keep = act_date next_stat Orig_amt act_upb &var);
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

%mend by_FICO;

/*
proc freq data = data.loan;
  table curr_stat*next_stat;
run;
*/



%put ----------------------------------------------------------------- PLOT;
* compute the probability;
%macro plot(d_pd);

  %if "&d_pd" = "CUR" %then %do;
    %let next = DEL;
    %let n_next = Delinquent;
    %let y_max = 5;
  %end;
  %if "&d_pd" = "DEL" %then %do;
    %let next = SDQ;
    %let n_next = Default;
    %let y_max = 30;
  %end;

  proc sort data = PD_DATA._&d_pd (keep = FICO yqtr next_stat) tagsort;
    by FICO yqtr;
  run;

  ods output CrossTabFreqs = tmp(keep = yqtr FICO 
                                        rowpercent next_stat 
                                where = (next_stat = "&next"));
  proc freq data = PD_DATA._&d_pd;
    table yqtr*next_stat;
    by FICO;
  run;


  ods powerpoint select all;
  title "Time series plots for &d_pd data";
  title2 j = l "Next State: &n_next";
  footnote j = l "Sub-Prime: FICO < &score; Prime: FICO ≥ &score";
  proc sgplot data = tmp;
    loess y = rowpercent x = yqtr / group = FICO smooth = 0.25;
    xaxis label = "Year" grid;
    yaxis label = "Probability of &n_next(%)" grid max = &y_max;
  run;
  title;
  ods powerpoint select none;
  
%mend plot;


%macro check(score);
  %by_FICO(DEL);
  %by_FICO(CUR);
  %plot(DEL);
  %plot(CUR);
%mend check;

%macro checkloop();
  options nodate;
  ods powerpoint file = "&p_report/fico.ppt"
                 style = Sapphire;
  ods powerpoint select none;
  ods graphics on / width = 4in height = 3in; 
  ods layout gridded rows = 2 columns = 1;
  %check(670);
  %check(750);
  ods layout end;
  ods powerpoint close;
%mend checkloop;

/* %checkloop(); */

%put ----------------------------------------------------------------- FIT REGRESSION;
%macro fit(d_pd) / store source;

  %if "&d_pd" = "CUR" %then %do;
    %let next = DEL;
    %let n_next = Delinquent;
    %let report = ModelANOVA;
    %let option =;
  %end;
  %if "&d_pd" = "DEL" %then %do;
    %let next = SDQ;
    %let n_next = Default;
    %let report = ModelBuildingSummary;
    %let option = selection = S;
  %end;

  %let score = 670;
  %by_FICO(&d_pd);
  
  options nodate;
  ods html file = "&p_report/fit_&d_pd..html"
           style = Sapphire;
  ods html select none;
  
  
  data PD_DATA._prm PD_DATA._sub;
    set PD_DATA._&d_pd;
/*     if next_stat = "&next" then next_flg = 1; */
/*       else next_flg = 0; */
    if FICO = 'Sub-Prime' then output PD_DATA._sub;
    if FICO = 'Prime' then output PD_DATA._prm;
  run;
  
  %let cvar = c_oltv c_dti c_fico c_amt Occ_stat;
  %let var = curr_rte loan_age hs ump gdp ppi hpi &cvar;
  
  ods html select all;
  title "The Multinomial Logistic Regression";
  footnote j = l "Dataset: &d_pd FICO: Prime";
  footnote2 j = l "Baseline Category: &d_pd";
  
  ods select &report;
  ods output ParameterEstimates = tmp_p;
  proc logistic data = PD_DATA._prm;
    class next_stat (ref = "&d_pd") &cvar / param = glm;
    model next_stat = &var / link = glogit &option;
  run;
    
  
  title2 "Parameter Estimates";
  proc report data = tmp_p;
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
  
  title "The Multinomial Logistic Regression";
  footnote j = l "Dataset: &d_pd FICO: Sub-Prime";
  footnote2 j = l "Baseline Category: &d_pd";
  
  ods select &report;
  ods output ParameterEstimates = tmp_s;
  proc logistic data = PD_DATA._sub;
    class next_stat (ref = "&d_pd") &cvar/ param = glm;
    model next_stat = &var / link = glogit &option;
    lsmeans / e ilink cl;
  run;
  
  title2 "Parameter Estimates";
  proc report data = tmp_s;
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
  footnote; 
  ods html select none;
  ods html close;
  
  proc datasets lib = PD_DATA;
    delete _:;
  run;
%mend fit;


/* %fit(DEL); */
%fit(CUR);




/*


proc print data = PD_DATA.cur;
  where next_stat = "SDQ";
run;

proc print data = DATA.sample;
  where loan_id = "623301207056";
run;

*/