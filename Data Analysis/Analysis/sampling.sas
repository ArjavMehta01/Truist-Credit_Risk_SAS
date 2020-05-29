/* Author: Jonas */
/* Purpose: Generate sample only select a portion of the data. */
/* Seed: 7919 */

* change the value of this macro variable: Q1-Q4;
%let quater = Q1;




/*

%let portion = 0.1;
%let n_seed = 7919;

* Read the acquisition data file, only keep the ID number;
filename ACQid "&p_data/ACQ_ID.csv";

data id_input;
  infile ACQid dsd firstobs = 2;
  input num id channel $ rate balance date1 $ date2 $ state $;
  keep id;
run;


proc surveyselect data = id_input
  outall
  noprint
  method = SRS 
  out = id_sample (rename=(selected = train_flg))
  rate = &portion
  seed = &n_seed;
run;

proc export data = id_sample 
  outfile = "&p_data/ACQ_IDsample.csv"
  dbms = csv;
run;


*/

filename ACQid "&p_data/ACQ_IDsample.csv";

data id_sample;
  infile ACQid dsd firstobs = 2;
  input tran_flg loan_id:$12.;
run;

proc sort data = id_sample;
  by loan_id;
run;

proc sort data = DATA.combined_&quater tagsort;
  by loan_id;
run;


data DATA.sample_&quater;
  merge DATA.combined_&quater id_sample;
  by loan_id;
  if tran_flg & ^missing(dlq_stat);
run;
  


