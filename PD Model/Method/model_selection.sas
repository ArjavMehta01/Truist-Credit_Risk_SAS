/* Author: Jonas */
/* Purpose: Build multinomial logistic regression */


%let t_year = 2016;
%let t_rate = 0.8;
%let t_seed = 7919;


%macro prep(d_pd);
%let d_pd = DEL;
  * get the out-of-sample data;
  data PD_DATA.out_&d_pd PD_DATA._&d_pd;
    set PD_DATA.&d_pd;
    if orig_dte lt "01Jan&t_year."d then output PD_DATA._&d_pd;
      else output PD_DATA.out_&d_pd;
  run;

  proc sort data = PD_DATA._&d_pd;
    by loan_id;
  run;
  
  * crate the training set;
  proc surveyselect data = PD_DATA._&d_pd noprint outall
                  method = SRS
                     out = PD_DATA._&d_pd (rename = (selected = train_flg))
                    rate = &t_rate
                    seed = &t_seed;
    strata loan_id;
  run;


%mend prep;  