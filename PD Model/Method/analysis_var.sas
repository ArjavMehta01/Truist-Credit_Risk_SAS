/* Author: Zheng */
/* Purpose: Univariate analysis for model explanatory variables (vs. response) */


%let datasets = PD_DATA.train_cur PD_DATA.train_del;

%let outfile = week9.ppt;
%let extension = powerpoint;

%let macro = QDT_ump gdp_annual_rate HS;

%let c_var = FICO; %let v_var = cscore_b;
%let num_var = oltv dti curr_rte cscore_b loan_age;
%let class_var = fthb_flg Num_unit Prop_typ Purpose Occ_stat &c_var;

%let train_var = orig_rt orig_amt cscore_b cltv dti orig_trm loan_age 
                 orig_chn curr_rte purpose &macro;


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
  value c_cltv low -< 20 = '[0-20)'
               20 -< 40 = '[20,40)'
               40 -< 60 = '[40,60)'
               60 -< 80 = '[60,80)'
               80 -< 100 = '[80,100)'
               100 -< 120 = '[100,120)'
               120 - high = '[120+)'
  ;
run;


/* --------------------------------------- */
/* Split the data into Prime vs. Sub-Prime */
/* --------------------------------------- */
%macro prepare();

/*   data PD_DATA.train_cur; */
/*     set PD_DATA.train_cur; */
/*     &c_var = put(&v_var, c_&c_var..); */
/*   run; */
/*   data PD_DATA.train_del; */
/*     set PD_DATA.train_del; */
/*     &c_var = put(&v_var, c_&c_var..); */
/*   run; */

  data chisq_test(keep = loan_id cscore_b next_stat)
       PD_DATA.train(keep = loan_id &train_var SDQ PPY yqtr orig_dte &class_var next_stat);
    set &datasets;
    label gdp_annual_rate = "GDP: Annual Growth"
          QDT_ump = "Unemployment Rate: Quarterly Difference";
    if next_stat = "SDQ" then SDQ = 1;
      else SDQ = 0;
    if next_stat = "PPY" then PPY = 1;
      else PPY = 0;
      *imporve the graph;
    cltv = round(cltv,1);
    orig_rt = round(orig_rt,0.05);
    orig_amt = round(orig_amt,10000);
    curr_rte = round(curr_rte,0.05);
  run; 
  
  proc sort data = PD_DATA.train;
    by loan_id;
  run;
  
  data tmp;
    set PD_DATA.train;
    by loan_id;
    if last.loan_id;
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
%macro time_plot();
* Get the probability of SDQ and PPY;
  proc sort data = PD_DATA.train(keep = yqtr PPY SDQ &macro) out = uni_data;
    by yqtr;
  run;
  ods output Summary = time_uni(keep = _numeric_);
  proc means data = uni_data mean;
    var PPY SDQ &macro;
    by yqtr;
  run;
  
* Get the time series plot;
  %macro time_uni(var, n_var);
    title "Time series plot for &n_var";
    proc sgplot data = time_uni;
      series x = yqtr y = SDQ_Mean /  legendlabel = "Probability of Default" lineattrs = (color = "cxe34a33" thickness = 2);
      series x = yqtr y = &var._Mean / Y2Axis legendlabel = "&n_var" lineattrs = (color = "cx3182bd" thickness = 2);
      xaxis label = "Year" grid;
      yaxis label = "Probability of Default" grid valuesformat = percent8.2;
      y2axis label = "&n_var";
    run;
    proc sgplot data = time_uni;
      series x = yqtr y = PPY_Mean / legendlabel = "Probability of Prepayment" lineattrs = (color = "cxa1d99b" thickness = 2);
      series x = yqtr y = &var._Mean / Y2Axis legendlabel = "&n_var" lineattrs = (color = "cx3182bd" thickness = 2);
      xaxis label = "Year" grid;
      yaxis label = "Probability of Prepayment" grid valuesformat = percent8.2;
      y2axis label = "&n_var";
    run;
    title;
  %mend time_uni;
  
  ods &extension select all;
  %time_uni(QDT_ump, Unemployment Rate: Quartly Difference);
  %time_uni(gdp_annual_rate, GDP: Annual Growth);
  %time_uni(hs, Housing Starts);
/*   %time_uni(hpi, Housing Price Index); */
/*   %time_uni(gdp, GDP Growth Rate); */
  ods &extension select none;

%mend time_plot;


%macro scat_plot();

  %macro scat_uni(driver, n_driver, option=);
    ods output ParameterEstimates = param;
    proc logistic data = tmp;
      model SDQ (event = "1") = &driver;
      output out = pdct p = prob xbeta = logit;
    run;
    
    data _null_;
      set param;
      if _n_ = 2 then do;
        call symputx('est_p', put(estimate, 8.5));
        call symputx('pva_p', put(probchisq, pvalue6.4));
      end;
    run;
  
    * Plot the Estimated PD vs Historical PD;
    
    proc sort data = pdct nodupkey;
      by &driver;
    run;
  
    ods output CrossTabFreqs = tmp2;
    proc freq data = tmp;
      table &driver.*SDQ;
    run;
    
    data tmp3(keep = &driver rowpercent);
      label rowpercent = "Probability of Default (%)";
      set tmp2;
      if SDQ = 1 & _type_ = "11";
    run;
    
    data plot;
      merge tmp3 pdct;
      prob = prob * 100;
      by &driver;
    run;
    
    ods &extension exclude none;
    title "Binomial Logistic Regression on &n_driver";
    footnote j = l "Data: Training Set";
    proc sgplot data = plot;
      series x = &driver y = prob / lineattrs = (color = "cxe34a33" thickness = 2);
      scatter x = &driver y = rowpercent;
      inset ("Estimate" = "&est_p"
             "Pr > Chi-Square" = "&pva_p") / border opaque;
      xaxis grid;
      yaxis grid &option;
      discretelegend / ACROSS = 2;
    run;
    title;
    footnote;
    ods &extension exclude all;
  %mend scat_uni;
  
  %scat_uni(cltv, Current Loan To Value);
  %scat_uni(QDT_ump, Unemployment Rate: Quarterly Difference);
  %scat_uni(gdp_annual_rate, GDP: Annual Growth);
  %scat_uni(orig_rt, Interest rate, option = %nrstr(max=30));
  %scat_uni(orig_amt, Original Unpaid Balance, option = %nrstr(max=2));
  %scat_uni(cscore_b, FICO, option = %nrstr(max=50));
  %scat_uni(dti, Debt To Income Ratio);
  %scat_uni(loan_age, Loan Age, option = %nrstr(max=4));
  %scat_uni(curr_rte, Note Rate, option = %nrstr(max=30));
%mend scat_plot;



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

  %scat_plot();
  %time_plot();
  
  ods &extension close;
%mend outres;

%outres();

quit;

*ods trace on;
ods output CrossTabFreqs = _tmp;
proc freq data = PD_DATA.train_cur (where = ((cscore_b le 670) and (^missing(act_upb))));
  table next_stat * orig_chn;
run;
proc sgplot data = _tmp(where = (next_stat = "PPY"));
  vbar colPercent / response = colPercent group = orig_chn stat = sum;
  yaxis label = "P of Prepayment";
  xaxis label = "test";
run;

