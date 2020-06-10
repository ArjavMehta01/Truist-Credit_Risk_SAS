/* Author: Jonas */
/* Purpose: Build multinomial logistic regression */


%let var = oltv dti cscore_b loan_age;


%let d_pd = data;


  
  
proc logistic data = PD_DATA.&d_pd;
  model final_stat = oltv;
run;
