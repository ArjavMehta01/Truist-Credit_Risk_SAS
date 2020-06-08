/* Author: Jonas */
/* Purpose: Build multinomial logistic regression */


%let var = oltv cltv dti cscore_b loan_age 
           gdp gdp_mdt hs_mdt ump_mdt ppi_mdt tnf_mdt;


%let d_pd = del;

proc logistic data = PD_DATA.&d_pd;
  class fico;
  model next_stat = &var;
run;
