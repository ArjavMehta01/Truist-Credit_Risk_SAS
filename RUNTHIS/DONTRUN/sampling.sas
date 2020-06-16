/* Author: ZHEN */
/* Purpose: Generate sample id only select a portion of the data. */
/* Seed: 7919 */
/* Portion: 10% */


%let n_seed = 7919;
%let portion = 0.1;



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


  



