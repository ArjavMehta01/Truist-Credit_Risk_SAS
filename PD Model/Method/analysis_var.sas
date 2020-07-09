/* Author: Zheng */
/* Purpose: Univariate analysis for model explanatory variables (vs. response) */


%let datasets = PD_DATA.train_cur PD_DATA.train_del;

%let outfile = week8.ppt;
%let extension = powerpoint;

%let macro = hs ump gdp ppi hpi;
%let c_var = FICO; %let v_var = cscore_b;
%let num_var = oltv dti curr_rte cscore_b loan_age;
%let class_var = fthb_flg Num_unit Prop_typ Purpose Occ_stat &c_var;


proc format;
  value c_&c_var low -< 350 = '[0-350)'
               350 -< 620 = '[350,619]'
               620 -< 640 = '[620,639]'
               640 -< 660 = '[640,659]'
               660 -< 680 = '[660,679]'
               680 -< 700 = '[680,699]'
               700 -< 720 = '[700,719]'
               720 -< 740 = '[720,739]'
               740 - high = '[740+)'
  ;
run;



/* --------------------------------------- */
/* Split the data into Prime vs. Sub-Prime */
/* --------------------------------------- */
%macro prepare();
  data uni_data(keep = &macro SDQ PPY yqtr) chisq_test(keep = loan_id cscore_b next_stat);
    set &datasets;
    if next_stat = "SDQ" then SDQ = 1;
      else SDQ = 0;
    if next_stat = "PPY" then PPY = 1;
      else PPY = 0;
  run; 
  data PD_DATA.train_cur;
    set PD_DATA.train_cur;
    &c_var = put(&v_var, c_&c_var..);
  run;
  data PD_DATA.train_del;
    set PD_DATA.train_del;
    &c_var = put(&v_var, c_&c_var..);
  run;
%mend prepare;
/* %prepare(); */

/* ----------------------------------------------------------- */
/* Pearson's chi-square test for the frequency if missing FICO */
/* ----------------------------------------------------------- */
%macro test_loop(test);
  proc sort data = &test nodupkey out = uni_fico;
    by loan_id;
  run;
  ods output OneWayFreqs = test;
  proc freq data = &test;
    where missing(cscore_b);
    table next_stat;
  run;
  data _null_;
    set test end = last;
    call symputx('var'||left(_n_), next_stat);
    call symputx('key'||left(_n_), percent);
    if last then call symputx('n', _n_);
  run;
  %let varlist = ;
  %let testlist = ;
  %do i = 1 %to &n;
    %let &&var&i = &&key&i;
    %let varlist = &varlist %str(" ")&&var&i;
    %let testlist = &testlist %str(&)&&var&i;
  %end;
  
  ods &extension select all;
  
  
  title "Univariate analysis of FICO";
  proc univariate data = uni_fico;
    var cscore_b;
    histogram cscore_b / normal ( mu = est sigma = est color = blue w = 2.5);
  run;
  title;
  title "Pearson's chi-square test";
  proc freq data = &test;
  where ^missing(cscore_b) and next_stat in ("&varlist");
  table next_stat / chisq 
    testp = (&testlist);
  run;
  title;
  ods &extension select none;
%mend test_loop;


/* ------------------------------------------------ */
/* Univariate analysis for macroeconomics variables */
/* ------------------------------------------------ */
%macro uni_analysis();
* Get the probability of SDQ and PPY;
  proc sort data = uni_data;
    by yqtr;
  run;
  ods output Summary = uni_mean(keep = _numeric_);
  proc means data = uni_data mean;
    var PPY SDQ &macro;
    by yqtr;
  run;
  data uni_plot;
    format GDP_Mean percent8.2;
    set uni_mean;
    GDP_Mean = (GDP_Mean - lag(GDP_Mean))/lag(GDP_Mean) ;
  run;
  
* Get the time series plot;
  %macro uni_plot(var, n_var);
    title "Time series plot for &n_var";
    proc sgplot data = uni_plot;
      series x = yqtr y = SDQ_Mean /  legendlabel = "Probability of Default" lineattrs = (color = "cxe6550d" thickness = 2);
      series x = yqtr y = &var._Mean / Y2Axis legendlabel = "&n_var" lineattrs = (color = "cx3182bd" thickness = 2);
      xaxis label = "Year" grid;
      yaxis label = "Probability of Default" grid valuesformat = percent8.2;
      y2axis label = "&n_var";
    run;
    proc sgplot data = uni_plot;
      series x = yqtr y = PPY_Mean / legendlabel = "Probability of Prepayment" lineattrs = (color = "cxa1d99b" thickness = 2);
      series x = yqtr y = &var._Mean / Y2Axis legendlabel = "&n_var" lineattrs = (color = "cx3182bd" thickness = 2);
      xaxis label = "Year" grid;
      yaxis label = "Probability of Prepayment" grid valuesformat = percent8.2;
      y2axis label = "&n_var";
    run;
    title;
  %mend uni_plot;
  
  ods &extension select all;
  %uni_plot(ump, Unemployment Rate);
  %uni_plot(hs, Housing Starts);
  %uni_plot(ppi, Producer Price Index);
  %uni_plot(hpi, Housing Price Index);
  %uni_plot(gdp, GDP Growth Rate);
  ods &extension select none;

%mend uni_analysis;

/* ------------------ */
/* Regression fitting */
/* ------------------ */
%macro mul_reg(d_pd);
  proc logistic data = PD_DATA.train_&d_pd;
    class next_stat (ref = "&d_pd") &class_var / param = glm;
    model next_stat = &num_var &class_var/ link = glogit selection = stepwise;
    weight act_upb / normalize;
  run;
%mend mul_reg;
/* %mul_reg(DEL); */
/* %mul_reg(CUR); */


/* ------------------ */
/* Output the results */
/* ------------------ */
%macro outres();
  ods &extension file = "&p_pdres/&outfile"
                 style = Sapphire;
  ods &extension select none;
  ods graphics on / width = 5in height = 5in;
  options nodate;
  ods noproctitle;
  
  %test_loop(chisq_test);
  %uni_analysis();
 
  ods &extension close;
%mend outres;

%outres();

quit;