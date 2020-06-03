/* Author: Jonas */
/* Purpose: Prepare the dataset for further analysis */



%put DATA VALIDATION;

/*    
* data validataion;

filename ACQid "&p_acq/ACQ_IDsample.csv";

data id_sample;
  infile ACQid dsd firstobs = 2;
  input tran_flg loan_id:$12.;
  keep loan_id;
  if tran_flg = 1;
run;

proc sort data = id_sample;
  by loan_id;
run;

proc sort data = data.sample out = id_sample2(keep=loan_id) nodupkey;
  by loan_id;
run;

proc compare base = id_sample compare = id_sample2;
run;
*/




%put DATA PREPARATION;

* Prepare the data: create a new status variable;
data PD_DATA.data tmp_id(keep = loan_id curr_stat 
                         rename = (loan_id = check_id curr_stat = Next_stat)
                         );
  set DATA.sample(drop = orig_rt orig_dte zb_date);
  attrib Curr_stat length = $3.
                   label = "Current State"
                   ;
                   
  if dlq_stat = 0 then
    Curr_stat = "CUR";
  else if dlq_stat le 3 then
    Curr_stat = "DEL";
  else if dlq_stat = 999 and zb_code in ("01" "06") then
    Curr_stat = "PPY";
  else Curr_stat = "SDQ";
run;

data PD_DATA.data(drop = check_id);
  merge PD_DATA.data tmp_id(firstobs = 2);
  attrib Next_stat length = $3.
                   label = "Next State"
                   ;
  if loan_id ne check_id then next_stat = "";
run;



/*
proc freq data = PD_DATA.data;
  table dlq_stat*curr_stat;
run;

*/




* Merge the loan-level data with macros by date;

proc sort data = PD_DATA.data;
  by act_date;
run;

data PD_DATA.data;
  merge PD_DATA.data PD_DATA.macro;
  by act_date;

run;





%let v_comb = loan_id oltv dti cscore_b act_date orig_amt act_upb loan_age dlq_stat zb_code;


* prepare data for calculating PD;
data PD_DATA.G1 PD_DATA.G2;
  set DATA.sample;
  if missing(zb_code) and dlq_stat = 999 then delete;
  if missing(dlq_stat) then delete;
  
  select(dlq_stat);
    when(1) output PD_DATA.G1;
    when(2) output PD_DATA.G2;
    when(3) output PD_DATA.G3;
    otherwise;
  end;
  
  keep &v_comb;
run;

data tmp;
  set data.sample;
  
  if dlq_stat = 999;
  keep dlq_stat zb_code;
  run;
proc freq data =data.sample;
  table dlq_stat;
run;
    
    
proc freq data = data.sample;
  table zb_code dlq_stat;
    run;
    
    
    
    
    
    
    