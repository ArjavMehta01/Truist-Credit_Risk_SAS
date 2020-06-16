/* Author: Zheng */
/* Purpose1: Merge data sets for each quarter and generate the traning sample*/
/* Purpose2: Generate quarterly data and state variables*/


%put ------------------------------------------------------------------OPTION1;
* change the value of this macro variable: Q1-Q4;
%let quarter = Q1;

%put ------------------------------------------------------------------OPTION2;
* year range;
%let y_start = 2006;
%let y_end = 2017;

%put ------------------------------------------------------------------OPTION3;
* turn on this option to merge loan-level data and macros;
* 1 means merge;
* 0 means not merge;
%let merge = 1;

%put ------------------------------------------------------------------PROGRAM;
%macro prep();
  * genrate the name of data sets;
  %let d_comb =;
  %macro get_name();
    %do i = &y_start %to &y_end;
      %let d_comb = &d_comb COMB.comb_&i.&quarter;
    %end;
  %mend get_name;
  
  %get_name();
      
  %put Using data sets: &d_comb;
  
  * concatenate data sets;
  data DATA.sample_&quarter;
    set &d_comb;
  run;
  
  
  
  * Prepare the data: create a new status variable;
  proc sort data = DATA.sample_&quarter tagsort;
    by loan_id;
  run;
  
  data DATA.sample_&quarter tmp_id(keep = loan_id curr_stat 
                                   rename = (loan_id = _id curr_stat = Next_stat)
                                   );
    set DATA.sample_&quarter;
    attrib Curr_stat length = $3.
                     label = "Current State"
                     ;
      
      
    by loan_id;
    retain _def 0;
    retain _start;
      
    if first.loan_id then do;            
      _def = 0;
      _start = loan_age;
    end;
      
    if _def then delete;
      
    if ^_def then do;
      if dlq_stat = 0 then
        Curr_stat = "CUR";
      else if dlq_stat le 3 then
        Curr_stat = "DEL";
      else if dlq_stat = 999 and zb_code in ("01" "06") then
        Curr_stat = "PPY";
      else _def = 1;
    end;
    if _def then Curr_stat = "SDQ";
      
    if mod(loan_age - _start, 3) = 0 then output DATA.sample_&quarter tmp_id;
      else if last.loan_id then output DATA.sample_&quarter tmp_id;
      
  run;
  
  data DATA.sample_&quarter(drop = _:);
    merge DATA.sample_&quarter tmp_id(firstobs = 2);
    attrib Next_stat length = $3.
                     label = "Next State"
                     ;
    if loan_id ne _id then next_stat = "";
    drop tran_flg;
  run;
%mend prep;

* get the curr_stat and next_stat;
%if ^&merge %then %do;
  %prep();
%end;


%put ------------------------------------------------------------------STACK;
%macro merge();
  /* Importing Macroeoconomics Data from GDrive*/
    * Setup the head format;
  %let mac_head = 
                   Rate    date : ddmmyy10.  Rate_MDT  TNF_MDT   GDP    GDP_MDT  
                   HS      HS_MDT            UMP       UMP_MDT   PPI    PPI_MDT        
                   Permits HOP_MDT           Payroll   HPI       _HPI_MDT      
  ;
  
  * Gernate the URL;
  
  %let id = %nrstr(1iindNDXZyr_5Rowfc_RZxa-NTSxE1eab);
  %let _url = %nrstr(https://docs.google.com/uc?export=download&id=)&&id;
  
  filename url_file url "&_url";
  
  data DATA.macros;
    infile url_file dsd firstobs = 2;
    format date mmddyy8.;
    input &mac_head;
  
    if date ge "01JAN&y_start"d;
    drop _:;
  run;
    
  * Stacking all the sample dataset;
  data DATA.loan;
    set DATA.sample_q1 DATA.sample_q2 DATA.sample_q3 DATA.sample_q4;
  run;
  
  * Merge the loan-level data with macros by date;
  proc sort data = DATA.macros out = work.macros;
    by date;
  run;
  
  proc sort data = DATA.loan out = DATA.tmp_loan tagsort;
    by act_date;
  run;
  
  data DATA.sample;
    merge DATA.tmp_loan work.macros(rename = (date = act_date));
    by act_date;
    if ^missing(loan_id);
  run;
  
  
  data DATA.cur DATA.del;
    set DATA.sample;
    if ^missing(next_stat);
    if Curr_stat = "CUR" then output DATA.cur;
    if Curr_stat = "DEL" then output DATA.del;
  run;
  
  /*
  * export data as csv file;
  proc export data = DATA.cur 
    outfile = "&p_data/cur.csv"
    dbms = csv;
  run;
  proc export data = DATA.del 
    outfile = "&p_data/del.csv"
    dbms = csv;
  run;
  */
 
  proc datasets lib = DATA;
    delete tmp:;
  run;

%mend merge;

* Merging the lona-level and macros data;
%if &merge %then %do;
  %merge();
%end;
