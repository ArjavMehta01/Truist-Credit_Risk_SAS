
proc sort data = DATA.loan;
  by loan_id act_date;
run;


%macro update(d_pd);
  proc sort data = PD_DATA.test_final_&d_pd;
    by loan_id act_date;
  run;
  data PD_DATA.test_final_&d_pd;
    merge PD_DATA.test_final_&d_pd(in = a) DATA.loan(in = b);
    by loan_id act_date;
    if a;
    if ^missing(loan_id);
  run;
  proc export data = PD_DATA.test_final_&d_pd 
    outfile = "&p_pddata/test_final_&d_pd..csv"
    dbms = csv;
  run;
  proc sort data = PD_DATA.train_final_&d_pd;
    by loan_id act_date;
  run;
  data PD_DATA.train_final_&d_pd;
    merge PD_DATA.train_final_&d_pd(in = a) DATA.loan(in = b);
    by loan_id act_date;
    if a;
    if ^missing(loan_id);
  run;
  proc export data = PD_DATA.train_final_&d_pd 
    outfile = "&p_pddata/train_final_&d_pd..csv"
    dbms = csv;
  run;
%mend update;

%update(DEL);
%update(CUR);