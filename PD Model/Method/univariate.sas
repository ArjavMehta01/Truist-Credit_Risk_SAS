/* Author: Jonas */
/* Purpose: Univariate analysis for all variables */






%macro analysis(driver, n_driver);

  data tmp;
    set DATA.tmp;
    by loan_id;
    if first.loan_id;
    keep &driver loan_id def_flg;
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
  
  ods powerpoint exclude none;
  
  title "Scatter Plots of PD by &n_driver";
  proc sgscatter data = tmp2;
    compare X = &driver Y = rowpercent / grid;
  run;
  title;
  
  title "Univariate Analysis of &n_driver";
  proc univariate data = tmp;
  var &driver;

  ods select Moments BasicMeasures ExtremeObs MissingValues;

  run;
  title;
  
  ods powerpoint exclude all;
%mend pd_scatter;