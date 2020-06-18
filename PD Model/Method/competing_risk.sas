/* Author: Jonas */
/* Purpose: Build multinomial logistic regression */


%let cvar = fthb_flg Prop_typ Purpose Num_unit Occ_stat;

%let var = oltv dti curr_rte cscore_b loan_age hs ump gdp &cvar;


%put ----------------------------------------------------------------- DATA PREPARATION;
* Grouping the FICO;

%macro by_FICO(d_pd);

  data PD_DATA._&d_pd;
    set PD_DATA.&d_pd(keep = act_date next_stat &var);
    length FICO $10;
    format yqtr yyq.;
    
    yqtr = yyq(year(act_date),qtr(act_date));
    
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
  %end;
  %if "&d_pd" = "DEL" %then %do;
    %let next = SDQ;
    %let n_next = Default;
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
    yaxis label = "Probability of &n_next" grid;
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
  %check(670);
  %check(750);
  ods powerpoint close;
%mend checkloop;

/* %checkloop(); */


%put ----------------------------------------------------------------- FIT REGRESSION;
%macro fit(d_pd);
%let d_pd = CUR;


  %if "&d_pd" = "CUR" %then %do;
    %let next = DEL;
    %let n_next = Delinquent;
  %end;
  %if "&d_pd" = "DEL" %then %do;
    %let next = SDQ;
    %let n_next = Default;
  %end;

  %let score = 670;
  %by_FICO(&d_pd);
  
  data PD_DATA._prm PD_DATA._sub;
    set PD_DATA._&d_pd;
    
    if next_stat = "&next" then next_flg = 1;
      else next_flg = 0;
    
    if FICO = 'Sub-Prime' then output PD_DATA._sub;
    if FICO = 'Prime' then output PD_DATA._prm;
  run;
  
  
    
    
/*   ods powerpoint select all; */
  title "The Multinomial Logistic Regression";
  footnote j = l "Dataset: &d_pd FICO: Prime";
  footnote2 j = l "Baseline Category: &d_pd";
  
  ods select ModelBuildingSummary;
  ods output ModelBuildingSummary = _tmp(keep = effectentered);
  proc logistic data = PD_DATA._prm;
    class next_stat (ref = "&d_pd") &cvar/ param = glm;
    model next_stat = &var / link = glogit selection = S;
    lsmeans / e ilink cl;
  run;
  
  %let v_fit = ;
  data _null_;
    set _tmp;
    call symputx('v_tmp', effectentered);
    call symputx('v_fit', cat("&v_fit", "&v_tmp"));
  run;
  %put &v_fit;
  
  ods select Coef LSMeans;
  proc logistic data = PD_DATA._prm;
    class next_stat (ref = "&d_pd") &cvar/ param = glm;
    model next_stat = &var / link = glogit selection = B;
    lsmeans / e ilink cl;
  run;
  
  
  
  title;
  footnote; 
  
  
  
  title "The Multinomial Logistic Regression";
  footnote j = l "Dataset: &d_pd FICO: Sub-Prime";
  footnote2 j = l "Baseline Category: &d_pd";
  ods select ModelANOVA Coef LSMeans;
  proc logistic data = PD_DATA._sub;
    class next_stat (ref = "&d_pd") &cvar/ param = glm;
    model next_stat = &var / link = glogit selection = S;
  run;
  title;
  footnote;
/*   ods powerpoint select none; */
%mend fit;

/* %fit(DEL); */
/* %fit(CUR); */

proc datasets lib = PD_DATA;
  delete _:;
run;

/*


proc print data = PD_DATA.cur;
  where next_stat = "SDQ";
run;

proc print data = DATA.sample;
  where loan_id = "623301207056";
run;

*/