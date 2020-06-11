/* Author: Jonas */
/* Purpose: Univariate analysis for all variables */




ods powerpoint file = "&p_report/_summary.ppt"
               style = Sapphire;

ods graphics on / width=4in height=4in;

options nodate;

ods noproctitle;

* Data Preparation;

** For binomial logistic regression;
%let var = oltv dti cscore_b curr_rte;
proc sort data = PD_DATA.data(keep = loan_id &var final_stat) out = uni;
  by loan_id;
run;

  
data tmp;
  set uni;
  by loan_id;
  if first.loan_id;
  if final_stat = "SDQ" then def_flg = 1;
    else def_flg = 0;
  keep &var def_flg;
run;


** For multinomial logistic regression;
proc sort data = PD_DATA.del(keep = &var next_stat) out = mlt;
  by next_stat;
run;


/* ods layout gridded rows = 1 columns = 1; */
ods powerpoint exclude none;

title "The binomial logistic regression results of multivariables";
ods select ParameterEstimates;
proc logistic data = tmp;
  model def_flg (event = "1") = &var;
  output out = pdct p = prob xbeta = logit;
run;
title;


title "The multinomial logistic regression results of multivariables";
footnote j = l "Dataset: DEL";
footnote2 j = l "Baseline Category: DEL";
ods select ParameterEstimates;
ods output ParameterEstimates = paramest;
proc logistic data = mlt;
  class next_stat (ref = "DEL");
  model next_stat = &var / link = glogit;
run;
title;
footnote;


ods powerpoint exclude all;
/* ods layout end; */

proc sort data = paramest(keep = variable response estimate probchisq);
  by response;
run;

data tmp_par;
  set paramest;
  esti = cat(estimate, "    (",put(probchisq, pvalue6.4), ")");
run;

proc transpose data = tmp_par out = paramrep;
  id variable;
  by response;
  var esti;
run;


/* ods layout gridded rows = 1 columns = 1; */
ods powerpoint exclude none;
title "The multinomial logistic regression results of multivariables";
title2 j = r "Estimate";
title3 j = r "(Pr > ChiSq)";
footnote j = l "Dataset: DEL";
footnote2 j = l "Baseline Category: DEL";
proc report data = paramrep;
  columns response intercept oltv dti cscore_b curr_rte;
  define response / display;
  define oltv / "OLTV";
  define dti / "DTI";
  define cscore_b / "FICO";
  define curr_rte / "Note Rate";
run;
title;
footnote;
ods powerpoint exclude all;
/* ods layout end; */

%macro loan_analysis(driver, n_driver);
  ods powerpoint exclude all;
  
/*   ods layout gridded rows = 3 columns = 1; */
  ods powerpoint exclude none;
  title "The binomial logistic regression results of &n_driver";
  ods select ParameterEstimates;
  proc logistic data = tmp;
    model def_flg (event = "1") = &driver;
    output out = pdct p = prob xbeta = logit;
  run;
  title;

  
  title "The multinomial logistic regression results of &n_driver";
  footnote j = l "Dataset: DEL";
  footnote2 j = l "Baseline Category: DEL";
  ods select ParameterEstimates;
  ods output ParameterEstimates = paramest;
  proc logistic data = mlt;
    class next_stat (ref = "DEL");
    model next_stat = &driver / link = glogit;
  run;
  title;
  footnote;
  
  ods powerpoint exclude all;
/*   ods layout end; */
  
  
  
  * Setup for the proc report;
  proc sort data = paramest(keep = variable response estimate probchisq);
    by response;
  run;
  
  data tmp_par;
    set paramest;
    esti = cat(estimate, "    (",put(probchisq, pvalue6.4), ")");
  run;
  
  proc transpose data = tmp_par out = paramrep;
    id variable;
    by response;
    var esti;
  run;
  
  
/*   ods layout gridded rows = 1 columns = 1; */
  ods powerpoint exclude none;
  title "The multinomial logistic regression results of multivariables";
  title2 j = r "Estimate";
  title3 j = r "(Pr > ChiSq)";
  footnote j = l "Dataset: DEL";
  footnote2 j = l "Baseline Category: DEL";
  proc report data = paramrep;
    columns response intercept oltv dti cscore_b curr_rte;
    define response / display;
    define oltv / "OLTV";
    define dti / "DTI";
    define cscore_b / "FICO";
    define curr_rte / "Note Rate";
  run;
  title;
  footnote;
  ods powerpoint exclude all;
/*   ods layout end; */
  
  
  
  
  
  * Plot the Estimated PD vs Historical PD;
  
  proc sort data = pdct nodupkey;
    by &driver;
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
  
  data plot;
    merge tmp2 pdct;
    prob = prob * 100;
    by &driver;
  run;
  
  ods powerpoint exclude none;
  title "Scatter Plots of PD by &n_driver";
  
  proc sgplot data = plot;
    series x = &driver y = prob / lineattrs = (color = "cxe34a33" thickness = 2);
    scatter x = &driver y = rowpercent;
    xaxis grid;
    yaxis grid;
  run;
  
  title;  
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
  title "Scatter Plots of PD by &n_driver";
  proc sgscatter data = tmp;
    compare X = &driver Y = rowpercent / grid;
  run;
  title;  
  ods powerpoint exclude all;
%mend macro_analysis;


%macro scatterloop;
  %loan_analysis(oltv, Original LTV);
  %loan_analysis(dti, DTI);
  %loan_analysis(cscore_b, FICO);
  %loan_analysis(curr_rte, Note Rate);
  

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

  ods output CrossTabFreqs = tmp;
  proc freq data = uni;
    table act_date*def_flg;
  run;

  data pd(keep = act_date rowpercent);
    set tmp;
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
  
  
  %macro_analysis(hs, HS);
  %macro_analysis(ump, UMP);
  %macro_analysis(ppi, PPI);
  %macro_analysis(gdp, GDP);

%mend scatterloop;

%scatterloop;

ods powerpoint close;