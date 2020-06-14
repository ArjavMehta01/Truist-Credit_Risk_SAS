/* Author: Jonas */
/* Purpose: Build multinomial logistic regression */


%let var = oltv dti curr_rte loan_age hs ump ppi gdp;


%macro fit(d_pd);
  * Data For multinomial logistic regression;
  proc sort data = PD_DATA.&d_pd(keep = &var next_stat fico) out = mlt;
    by next_stat;
  run;
    
    
  title "The Multinomial Logistic Regression";
  footnote j = l "Dataset: &d_pd";
  footnote2 j = l "Baseline Category: &d_pd";
  ods select ModelANOVA Coef LSMeans;
  proc logistic data = mlt;
    class next_stat (ref = "&d_pd") fico (ref = "Prime") / param = glm;
    model next_stat = fico &var / link = glogit;
    lsmeans fico / e ilink cl;
  run;
  title;
  footnote;
%mend fit;

%fit(DEL);
%fit(CUR);