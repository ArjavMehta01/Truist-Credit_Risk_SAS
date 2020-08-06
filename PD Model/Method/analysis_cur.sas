/* Author: Jonas */
/* Purpose: Univariate analysis for all variables */

%let p_work = %sysfunc(cat(&p_local,/PD Model/Work/));
libname PD_TMP "&p_work";

ods powerpoint file = "&p_report/_summary2.ppt"
               style = Sapphire;

ods graphics on / width = 5in height = 5in;

options nodate;

ods noproctitle;



%let var = oltv dti curr_rte loan_age hs ump ppi gdp;
data PD_TMP.tmp_p PD_TMP.tmp_s;
  set PD_DATA.train_cur(keep = &var fico next_stat);
  label hs = "Housing Starts"
        ump = "Unemployment Rate"
        ppi = "Producer Price Index"
        gdp = "GDP"
        ;
  if next_stat = "DEL" then def_flg = 1;
    else def_flg = 0;
  keep &var def_flg fico;
  if fico = "Prime" then output PD_TMP.tmp_p;
  if fico = "Sub-Prime" then output PD_TMP.tmp_s;
run;
/*
** For multinomial logistic regression;
proc sort data = PD_DATA.del(keep = &var next_stat fico) out = mlt;
  by next_stat;
run;


/* ods layout gridded rows = 1 columns = 1; */
/* ods powerpoint exclude none; */

/* title "The Binomial Logistic Regression Results of Multivariables"; */
/* ods select ParameterEstimates; */
/* proc logistic data = tmp; */
/*   model def_flg (event = "1") = &var; */
/* run; */
/* title; */


/* title "The Multinomial Logistic Regression"; */
/* footnote j = l "Dataset: DEL"; */
/* footnote2 j = l "Baseline Category: DEL"; */
/* ods select ModelANOVA Coef LSMeans; */
/* ods output ParameterEstimates = paramest; */
/* ods trace on; */
/* proc logistic data = mlt; */
/*   class next_stat (ref = "DEL") fico (ref = "Prime") / param = glm; */
/*   model next_stat = fico &var / link = glogit; */
/*   lsmeans fico / e ilink cl; */
/* run; */
/* title; */
/* footnote; */


/* ods powerpoint exclude all; */
/* ods layout end; */
/*  */
/* proc sort data = paramest(keep = variable response estimate probchisq); */
/*   by response; */
/* run; */
/*  */
/*  */
/* data PD_TMP.tmp_par; */
/*   set paramest; */
/*   esti = cat(estimate, "    (",put(probchisq, pvalue6.4), ")"); */
/* run; */
/*  */
/* proc transpose data = PD_TMP.tmp_par out = paramrep; */
/*   id variable; */
/*   by response; */
/*   var esti; */
/* run; */


/* ods layout gridded rows = 1 columns = 1; */

/* ods powerpoint exclude none; */
/* title "The Multinomial Logistic Regression Results"; */
/* title2 j = r "Estimate"; */
/* title3 j = r "(Pr > ChiSq)"; */
/* footnote j = l "Dataset: DEL"; */
/* footnote2 j = l "Baseline Category: DEL"; */
/* proc report data = paramrep; */
/*   columns response intercept oltv dti cscore_b curr_rte loan_age hs ump ppi gdp; */
/*   define response / display; */
/*   define oltv / "OLTV"; */
/*   define dti / "DTI"; */
/*   define cscore_b / "FICO"; */
/*   define curr_rte / "Note Rate"; */
/*   define loan_age / "Month on Books"; */
/*   define hs / "Housing Starts"; */
/*   define ump / "Unemployment Rate"; */
/*   define ppi / "Producer Price Index"; */
/*   define gdp / "GDP"; */
/* run; */
/* title; */
/* footnote; */
/* ods powerpoint exclude all; */
/* ods layout end; */

%macro loan_analysis(driver, n_driver);
  ods powerpoint exclude all;

/*   ods layout gridded rows = 3 columns = 1; */
/*   ods powerpoint exclude none; */
  title "The Binomial Logistic Regression Results of &n_driver";
  title2 "Prime";
  ods output ParameterEstimates = param_p;
  proc logistic data = PD_TMP.tmp_p;
    model def_flg (event = "1") = &driver;
    output out = PD_TMP.pdct_p p = prob xbeta = logit;
  run;
  title;

  title2 "Sub-Prime";
  ods output ParameterEstimates = param_s;
  proc logistic data = PD_TMP.tmp_s;
    model def_flg (event = "1") = &driver;
    output out = PD_TMP.pdct_s p = prob xbeta = logit;
  run;
  title;
  
  data _null_;
    set param_p;
    if _n_ = 2 then do;
      call symputx('est_p', put(estimate, 8.5));
      call symputx('pva_p', put(probchisq, pvalue6.4));
    end;
  run;
  %put &est_p &pva_p;

  data _null_;
    set param_s;
    if _n_ = 2 then do;
      call symputx('est_s', put(estimate, 8.5));
      call symputx('pva_s', put(probchisq, pvalue6.4));
    end;
  run;
/*   title "The multinomial logistic regression results of &n_driver"; */
/*   footnote j = l "Dataset: DEL"; */
/*   footnote2 j = l "Baseline Category: DEL"; */
/*   ods select ParameterEstimates; */
/*   ods output ParameterEstimates = paramest; */
/*   proc logistic data = mlt; */
/*     class next_stat (ref = "DEL"); */
/*     model next_stat = &driver / link = glogit; */
/*   run; */
/*   title; */
/*   footnote; */
  
  ods powerpoint exclude all;
/*   ods layout end; */
  
  
  /*
  * Setup for the proc report;
  proc sort data = paramest(keep = variable response estimate probchisq);
    by response;
  run;
  
  data PD_TMP.tmp_par;
    set paramest;
    esti = cat(estimate, "    (",put(probchisq, pvalue6.4), ")");
  run;
  
  proc transpose data = PD_TMP.tmp_par out = paramrep;
    id variable;
    by response;
    var esti;
  run;
  
  */

  
  
  
  * Plot the Estimated PD vs Historical PD;
  
  proc sort data = PD_TMP.pdct_p nodupkey;
    by &driver;
  run;
  proc sort data = PD_TMP.pdct_s nodupkey;
    by &driver;
  run;

  
  ods output CrossTabFreqs = tmp2_p;
  proc freq data = PD_TMP.tmp_p;
    table &driver.*def_flg;
  run;
  
  ods output CrossTabFreqs = tmp2_s;
  proc freq data = PD_TMP.tmp_s;
    table &driver.*def_flg;
  run;
  
  
  data tmp2_p(keep = &driver rowpercent);
    label rowpercent = "Probability(%)";
    set tmp2_p;
    if def_flg = 1 & _type_ = "11";
  run;
  
  data tmp2_s(keep = &driver rowpercent);
    label rowpercent = "Probability(%)";
    set tmp2_s;
    if def_flg = 1 & _type_ = "11";
  run;
  
  data plot_s;
    merge tmp2_s PD_TMP.pdct_s;
    prob = prob * 100;
    by &driver;
  run;
  
  data plot_p;
    merge tmp2_p PD_TMP.pdct_p;
    prob = prob * 100;
    by &driver;
  run;
  
  ods powerpoint exclude none;
  
  *title "Binomial Logistic Regression on &n_driver";
  title2 j = l "Group: Prime";
  footnote j = l "Current State: CUR and Next State: DEL";
  proc sgplot data = plot_p;
    series x = &driver y = prob / lineattrs = (color = "cxe34a33" thickness = 2);
    scatter x = &driver y = rowpercent;
    inset ("Estimate" = "&est_p"
           "Pr > Chi-Square" = "&pva_p") / border opaque;
    xaxis grid;
    yaxis grid max = 5;
    discretelegend / ACROSS = 2;
  run;
  title;
  footnote;
  
  
  *title "Binomial Logistic Regression on &n_driver";
  title2 j = l "Group: Sub-Prime";
  footnote j = l "Current State: CUR and Next State: DEL";
  proc sgplot data = plot_s;
    series x = &driver y = prob / lineattrs = (color = "cxe34a33" thickness = 2);
    scatter x = &driver y = rowpercent;
    inset ("Estimate" = "&est_s"
           "Pr > Chi-Square" = "&pva_s") / border opaque;
    xaxis grid;
    yaxis grid max = 5;
    *discretelegend / ACROSS = 2;
  run;
  title;
  footnote;
  
  
  ods powerpoint exclude all;
%mend loan_analysis;



%macro macro_analysis(driver, n_driver);
  
  proc sort data = DATA.macros(keep = date &driver) out = work.macros;
    by date;
  run;
  
  data tmp;
    merge work.pd work.macros(rename = (date = act_date));
    by act_date;
  run;
  
  ods powerpoint exclude none;
  title "Binomial Logistic Regression by &n_driver";
  proc sgscatter data = tmp;
    compare X = &driver Y = rowpercent / grid;
  run;
  title;  
  ods powerpoint exclude all;
%mend macro_analysis;


%macro scatterloop;
  %loan_analysis(oltv, Original LTV);
  %loan_analysis(dti, DTI);
  %loan_analysis(curr_rte, Note Rate);
  %loan_analysis(loan_age, Month on Books);
  %loan_analysis(hs, Housing Starts);
  %loan_analysis(ump, Unemployment Rate);
  %loan_analysis(ppi, Producer Price Index);
  %loan_analysis(gdp, Gross Domestic Product);
/*
  * Historical PD;
  ods powerpoint exclude all;
  proc sort data = PD_DATA.data(keep = act_date curr_stat) out = uni;
    by act_date;
  run;
  
  data uni;
    set uni;
    if curr_stat = "SDQ" then def_flg = 1;
      else def_flg = 0;
    keep act_date def_flg;
  run;

  ods output CrossTabFreqs = tmp1;
  proc freq data = uni;
    table act_date*def_flg;
  run;

  data pd(keep = act_date rowpercent);
    set tmp1;
    label rowpercent = "Probability of Default (%)";
    if def_flg = 1 & _type_ = "11";
  run;
  
  ods powerpoint exclude none;
  title "Scatter Plots of PD";
  proc sgscatter data = pd;
    compare X = act_date Y = rowpercent / grid;
  run;
  title;
  ods powerpoint exclude all;
  
  
  %macro_analysis(hs, Housing Starts);
  %macro_analysis(ump, Unemployment Rate);
  %macro_analysis(ppi, Producer Price Index);
  %macro_analysis(gdp, Gross Domestic Product);
*/
%mend scatterloop;

%scatterloop;

ods powerpoint close;


/*


* Segmentation test;

data tmp;
  set PD_DATA.loan(keep = cscore_b next_stat);
  
  length fico1 fico2 fico3 $20;
  
  if ^missing(cscore_b) then do;
    if cscore_b le 750 then fico1 = "lesser than 750";
    else fico1 = "greater than 750";
    

    if 0 < cscore_b < 620 then
      fico2 = '[0-620)';
    if 620 <=cscore_b < 670 then
      fico2 = '[620-670)';
    if 670 <=cscore_b < 720 then
      fico2 = '[670-720)';
    if 720 <=cscore_b < 750 then
      fico2 = '[720-750)';
    if 750 <=cscore_b < 800 then
      fico2 = '[750-800)';
    if 800 <=cscore_b < 850 then
      fico2 = '[800-850)';
    if 850 <=cscore_b then
      fico2 = '[850+)'; 
      
    if 0 < cscore_b < 620 then
      fico3 = '[0-620)';
    if 620 <=cscore_b < 670 then
      fico3 = '[620-670)';
    if 670 <=cscore_b < 750 then
      fico3 = '[670-750)';
    if 750 <=cscore_b then
      fico3 = '[750+)'; 

  end;
run;

proc sort data = tmp nodupkey;
  by loan_id;
run;


proc freq data = tmp;
  tables fico1*next_stat / chisq;
  tables fico2*next_stat / chisq;
run;

*/
proc datasets lib = PD_TMP kill;
run;


