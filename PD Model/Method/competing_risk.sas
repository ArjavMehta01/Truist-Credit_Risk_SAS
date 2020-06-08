/* Author: Jonas */
/* Purpose: Build multinomial logistic regression */


%let d_pd = t_cur;

proc logistic data = PD_DATA.&d_pd;
  class fico;
  model next_stat = loan_age dti cltv hs_mdt ump_mdt ppi_mdt tnf_mdt;
run;
