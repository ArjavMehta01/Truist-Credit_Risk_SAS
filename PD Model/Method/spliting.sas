/* Author: Jonas */
/* Purpose: Build multinomial logistic regression */

options mstored sasmstore = PD_DATA;

%let t_year = 2016;
%let t_rate = 0.8;
%let t_seed = 7919;


%let cvar = fthb_flg Num_unit Prop_typ Purpose Occ_stat;
%let var = Orig_amt oltv dti curr_rte cscore_b loan_age hs ump gdp ppi hpi &cvar;


%macro prep(d_pd);
  * get the out-of-sample data;
  data PD_DATA.out_&d_pd PD_DATA._&d_pd;
    set PD_DATA.&d_pd (keep = loan_id orig_dte act_date next_stat act_upb &var);

    format yqtr yyq.; 
    yqtr = yyq(year(act_date),qtr(act_date));
    
    if missing(act_upb) then act_upb = Orig_amt;
    
    
    if orig_dte lt "01Jan&t_year."d then output PD_DATA._&d_pd;
      else output PD_DATA.out_&d_pd;
  run;
  
  proc sort data = PD_DATA._&d_pd;
    by loan_id;
  run;
  
  proc sort data = PD_DATA._&d_pd(keep = loan_id) nodupkey out = list;
    by loan_id;
  run;
  
  * crate the training set;
  proc surveyselect data = list noprint outall
                  method = SRS
                     out = list (rename = (selected = train_flg))
                    rate = &t_rate
                    seed = &t_seed;
  run;
  
  data PD_DATA.train_&d_pd PD_DATA.test_&d_pd;
    merge PD_DATA._&d_pd list;
    by loan_id;
    if train_flg = 1 then output PD_DATA.train_&d_pd;
    if train_flg = 0 then output PD_DATA.test_&d_pd;
    drop train_flg;
  run;

%mend prep;


/* %prep(DEL);   */
/* %prep(CUR); */


%macro out_csv(d_pd);
  proc export data = PD_DATA.test_&d_pd 
    outfile = "&p_data/test_&d_pd..csv"
    dbms = csv;
  run;
  proc export data = PD_DATA.out_&d_pd 
    outfile = "&p_data/out_&d_pd..csv"
    dbms = csv;
  run;
  proc export data = PD_DATA.train_&d_pd 
    outfile = "&p_data/train_&d_pd..csv"
    dbms = csv;
  run;
%mend out_csv;


%out_csv(DEL);
%out_csv(CUR);
/* %fit(DEL); */
/* %fit(CUR); */

