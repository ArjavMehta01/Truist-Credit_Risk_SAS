/* Author: Jonas */
/* Purpose: Build multinomial logistic regression */


%let cvar = fthb_flg Num_unit Prop_typ Purpose Occ_stat;

%let var = Orig_amt oltv dti curr_rte cscore_b loan_age hs ump gdp ppi hpi &cvar;
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

%macro by_FICO(d_pd);
%let score = 670;
%let d_pd = DEL;
  data PD_DATA._&d_pd;
    set PD_DATA.&d_pd (keep = act_date next_stat &var);
    length FICO $10;
    format yqtr yyq.;
    label hs = "Housing Starts"
          ump = "Unemployment Rate"
          ppi = "Producer Price Index"
          gdp = "GDP"
          hpi = "House Price Index"
          ;
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
%macro fit(d_pd);

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
  
  
  ods html select all;
  title "The Multinomial Logistic Regression";
  footnote j = l "Dataset: &d_pd FICO: Prime";
  footnote2 j = l "Baseline Category: &d_pd";
  
  ods select ModelANOVA;
  ods output ParameterEstimates = tmp_p;
  proc logistic data = PD_DATA._prm;
    class next_stat (ref = "&d_pd") &cvar / param = glm;
    model next_stat = &var / link = glogit;
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
  
  ods select ModelANOVA;
  ods output ParameterEstimates = tmp_s;
  proc logistic data = PD_DATA._sub;
    class next_stat (ref = "&d_pd") &cvar/ param = glm;
    model next_stat = &var / link = glogit;
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
%mend fit;


/* %fit(DEL); */
%fit(CUR);



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