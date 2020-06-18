/* Author: Jonas */
/* Purpose: Concatenate data set save as local SAS dataset */



* 1 means keep all data sets;
* 0 means keep only the final data set;
%let keep = 1;




* genrate the name of data sets;

%let d_comb =;
  
%macro get_name();
  %do i = 1 %to 4;
    %let d_comb = &d_comb DATA.sample_Q&i;
  %end;
%mend get_name;

%get_name();
    
%put Using data sets: &d_comb;


* concatenate the sample data;
data sample;
  set &d_comb;
  drop tran_flg;
run;

* export data as csv file;
proc export data = sample 
  outfile = "&p_data/sample.csv"
  dbms = csv;
run;

* delete the quarterly dataset;
%if ^&keep %then %do;
  proc datasets library = DATA nolist;
    delete &d_comb;
  run;
%end;




