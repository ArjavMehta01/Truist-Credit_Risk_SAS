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






%put DATA MERGING;

* Merge the loan-level data with macros by date;

proc sort data = DATA.sample(keep = ) out = PD_DATA.data;
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
    
    
    
    
    
    
    
    
    
    