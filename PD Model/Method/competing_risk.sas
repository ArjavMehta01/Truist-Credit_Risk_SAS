/* Author: Jonas */
/* Purpose: Build multinomial logistic regression */


%let var = oltv dti curr_rte loan_age hs ump ppi gdp;




%put ----------------------------------------------------------------- DATA PREPARATION;
* Grouping the FICO;
%macro by_fico(d_pd);

  data PD_DATA.tmp_&d_pd;
    set PD_DATA.&d_pd.(keep = cscore_b next_stat &var);
    length fico $10;
    if 0 < cscore_b < 670 then
      fico = 'Sub-Prime';
    if 670 <=cscore_b then
      fico = 'Prime';
  run;

%mend by_fico;

%by_fico(DEL);







%put ----------------------------------------------------------------- FIT REGRESSION;
%macro fit(d_pd);
  * Data For multinomial logistic regression;
  proc sort data = PD_DATA.tmp_&d_pd out = mlt;
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
/* %fit(CUR); */


/*


proc print data = PD_DATA.cur;
  where next_stat = "SDQ";
run;

proc print data = DATA.sample;
  where loan_id = "623301207056";
run;

*/