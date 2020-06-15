/* Author: Jonas */
/* Purpose: Merge data sets for each quarter and generate the traning sample*/




* selected loan-level drivers;
%let v_comb = ;

* change the value of this macro variable: Q1-Q4;

%let quater = Q1;


%let y_start = 2006;
%let y_end = 2017;


* genrate the name of data sets;

%let d_comb =;
  
%macro get_name();
  %do i = &y_start %to &y_end;
    %let d_comb = &d_comb COMB.comb_&i.&quater;
  %end;
%mend get_name;

%get_name();
    
%put Using data sets: &d_comb;


* concatenate data sets;
data DATA.combined_&quater;
  set &d_comb;
  drop seller;
run;


