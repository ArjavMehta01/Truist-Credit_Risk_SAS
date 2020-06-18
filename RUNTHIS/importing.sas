/* Author: Zheng */
/* Purpose: Import Loan performance data from LOCAL Path */


%put ------------------------------------------------------------------OPTION1;
* 1 means keep all data sets;
* 0 means keep only the combined data set;
%let keep = 0;

%put ------------------------------------------------------------------OPTION2;
* only keep one firm data;
%let bank = WELLS FARGO;

%put ------------------------------------------------------------------OPTION3;
* change the value of this macro variable: Q1-Q4;
%let quarter = Q3;

%put ------------------------------------------------------------------OPTION4;
* year range;
%let y_start = 2008;
%let y_end = 2008;



%put ------------------------------------------------------------------PROGRAM;
%let acq_head = loan_id :$12.     orig_chn :$1.     seller :$80.
                orig_rt           orig_amt          orig_trm 
                x_orig_date :$7.  x_first_pay :$7.  oltv
                ocltv             num_bo            dti
                cscore_b          fthb_flg :$1.     purpose :$1. 
                prop_typ :$2.     num_unit          occ_stat :$1.
                state :$2.        zip_3 :$3.        mi_pct 
                product :$3.      cscore_c          mi_type 
                relo_flg :$1. 
                ;
              
%let acq_label = %sysfunc(propcase(
    /* -> */     loan_id      = " LOAN IDENTIFIER"                             
                 orig_chn     = " ORIGINATION CHANNEL" 
    /* -> */     seller       = " SELLER NAME" 
    /* -> */     orig_rt      = " ORIGINAL INTEREST RATE"  
    /* -> */     orig_amt     = " ORIGINAL UPB"   
                 orig_trm     = " ORIGINAL LOAN TERM" 
    /* -> */     orig_dte     = " ORIGINATION DATE" 
                 frst_pay     = " FIRST PAYMENT DATE" 
    /* -> */     oltv         = " ORIGINAL LOAN-TO-VALUE (LTV)" 
                 ocltv        = " ORIGINAL COMBINED LOAN-TO-VALUE (CLTV)"      
                 num_bo       = " NUMBER OF BORROWERS"   
    /* -> */     dti          = " ORIGINAL DEBT TO INCOME RATIO" 
    /* -> */     cscore_b     = " BORROWER CREDIT SCORE AT ORIGINATION"      
                 fthb_flg     = " FIRST TIME HOME BUYER INDICATOR"  
                 purpose      = " LOAN PURPOSE" 
                 prop_typ     = " PROPERTY TYPE" 
                 num_unit     = " NUMBER OF UNITS"    
                 occ_stat     = " OCCUPANCY TYPE" 
                 state        = " PROPERTY STATE"        
                 zip_3        = " ZIP CODE SHORT"       
                 mi_pct       = " PRIMARY MORTGAGE INSURANCE PERCENT" 
                 product      = " PRODUCT TYPE"  
                 cscore_c     = " CO-BORROWER CREDIT SCORE AT ORIGINATION"     
                 mi_type      = " MORTGAGE INSURANCE TYPE" 
                 relo_flg     = " RELOCATION MORTGAGE INDICATOR" 
                 ));
                
%let perf_head = loan_id :$12.       x_period :$10.     servicer :$80. 
                 curr_rte            act_upb            loan_age 
                 rem_mths            adj_rem_months     x_maturity_date :$7. 
                 msa :$5.            x_dlq_status :$3.  mod_ind :$1. 
                 zb_code :$2.        x_zb_date :$7.     x_lpi_dte :$10. 
                 x_fcc_dte :$10.     x_disp_dte :$10.   fcc_cost 
                 pp_cost             ar_cost            ie_cost
                 tax_cost            ns_procs           ce_procs 
                 rmw_procs           o_procs            non_int_upb 
                 prin_forg_upb_fhfa  repch_flag :$1.    prin_forg_upb_o
                 serv_transfer :$1.
                 ;

%let perf_label = %sysfunc(propcase(
   /* -> */      loan_id            = " LOAN IDENTIFIER"  
   /* -> */      act_date           = " MONTHLY REPORTING PERIOD" 
                 servicer           = " SERVICER NAME"  
   /* -> */      curr_rte           = " NOTE RATE" 
   /* -> */      act_upb            = " CURRENT ACTUAL UPB" 
   /* -> */      loan_age           = " LOAN AGE" 
                 rem_mths           = " REMAINING MONTHS TO LEGAL MATURITY" 
                 adj_rem_months     = " ADJUSTED MONTHS TO MATURITY" 
                 maturity_date      = " MATURITY DATE" 
                 msa                = " METROPOLITAN STATISTICAL AREA (MSA)" 
   /* -> */      dlq_stat           = " CURRENT LOAN DELINQUENCY STATUS" 
                 mod_ind            = " MODIFICATION FLAG" 
   /* -> */      zb_code            = " ZERO BALANCE CODE" 
   /* -> */      zb_date            = " ZERO BALANCE EFFECTIVE DATE" 
                 lpi_dte            = " LAST PAID INSTALLMENT DATE" 
                 fcc_dte            = " FORECLOSURE DATE" 
                 disp_dte           = " DISPOSITION DATE" 
                 fcc_cost           = " FORECLOSURE COSTS" 
                 pp_cost            = " PROPERTY PRESERVATION AND REPAIR COSTS " 
                 ar_cost            = " ASSET RECOVERY COSTS" 
                 ie_cost            = " MISCELLANEOUS HOLDING EXPENSES AND CREDITS" 
                 tax_cost           = " ASSOCIATED TAXES FOR HOLDING PROPERTY " 
                 ns_procs           = " NET SALE PROCEEDS " 
                 ce_procs           = " CREDIT ENHANCEMENT PROCEEDS " 
                 rmw_procs          = " REPURCHASE MAKE WHOLE PROCEEDS " 
                 o_procs            = " OTHER FORECLOSURE PROCEEDS " 
                 non_int_upb        = " NON INTEREST BEARING UPB" 
                 prin_forg_upb_fhfa = " PRINCIPAL FORGIVENESS AMOUNT" 
                 repch_flag         = " REPURCHASE MAKE WHOLE PROCEEDS FLAG " 
                 prin_forg_upb_o    = " FORECLOSURE PRINCIPAL WRITE-OFF AMOUNT" 
                 serv_transfer      = " SERVICING ACTIVITY INDICATOR " 
               ));

%macro acq(date, output, option);
  *****************************************;
  ** import and format acquisition files **;
  *****************************************;
  filename f_acq "&p_acq";
  
  data &output..acq_&date;
    infile f_acq("Acquisition_&date..txt") dlm = "|" missover dsd lrecl=32767 &option;
    label &acq_label;
    input &acq_head;
    
    *date conversion;
    format orig_dte frst_pay mmddyy8.;
    orig_dte = mdy(input(substr(x_orig_date,1,2),2.),1,input(substr(x_orig_date,4,4),4.)); 
    frst_pay = mdy(input(substr(x_first_pay, 1, 2), 2.), 1, input(substr(x_first_pay, 4, 4), 4.));
/*     where seller contains "&bank"; */
    *keep loan_id seller orig_rt orig_amt orig_dte oltv dti cscore_b;
  run;
  
%mend acq;


%macro perf(date, output, option);
  *****************************************;
  ** import and format performance files **;
  *****************************************;
  filename f_act "&p_perf";
  
  data &output..act_&date;
    infile f_act("Performance_&date..txt") dlm = "|" missover dsd lrecl=32767 &option;
    label &perf_label;
    input &perf_head;
    
    *date conversion;
    format act_date    zb_date    lpi_dte 
           fcc_dte     disp_dte   maturity_date 
           mmddyy8.;  
    zb_date       = mdy(input(substr(x_zb_date,1,2),2.),1,input(substr(x_zb_date,4,4),4.));
    act_date      = mdy(input(substr(x_period,1,2),2.),1,input(substr(x_period,7,4),4.));
    lpi_dte       = mdy(input(substr(x_lpi_dte,1,2),2.),1,input(substr(x_lpi_dte,7,4),4.));
    fcc_dte       = mdy(input(substr(x_fcc_dte,1,2),2.),1,input(substr(x_fcc_dte,7,4),4.));
    disp_dte      = mdy(input(substr(x_disp_dte,1,2),2.),1,input(substr(x_disp_dte,7,4),4.));
    maturity_date = mdy(input(substr(x_maturity_date,1,2),2.),1,input(substr(x_maturity_date,4,4),4.));
    
    *delinquency status conversion (set 'X' values to '999');
    if x_dlq_status = 'X' then dlq_stat = 999;
      else dlq_stat = x_dlq_status*1;
    
    *keep loan_id act_date curr_rte act_upb loan_age dlq_stat zb_date zb_code;  
  run;

%mend perf;
  

%macro comb(date, outfile);

  **************************************;
  ** merge to create combined dataset **;
  **************************************;
  
  data &outfile..comb_&date;
    merge ACQ.acq_&date (in = acq) ACT.act_&date (in = act);
    
    by loan_id;
    
    if find(seller,"&bank",'i') ge 1;
    drop x_:;
  run;


  data &outfile..comb_&date;
    merge &outfile..comb_&date id_sample;
    by loan_id;
    if tran_flg & ^missing(dlq_stat);
    drop seller;
  run;
  

%if ^&keep %then %do;
  proc datasets library = ACQ nolist;
    delete acq_&date;
  run;

  proc datasets library = ACT nolist;
    delete act_&date;
  run;
%end;
  
%mend comb;


********************;
** testing macros **;
********************;
/*
%let o_test = %str(obs=10);
%acq(2005Q1, work)
%perf(2005Q1, work, &o_test)
*/


********************;
** sample loan_id **;
********************;
* select the data based on loan_id;
filename ACQid "&p_data/ACQ_IDsample.csv";

data id_sample;
  infile ACQid dsd firstobs = 2;
  input tran_flg loan_id:$12.;
run;

proc sort data = id_sample;
  by loan_id;
run;


*****************************;
** import files using loop **;
*****************************;

%macro importloop(q);
  %do y_id = &y_start %to &y_end;
    %acq(&y_id&q, ACQ)
/*     %perf(&y_id&q, ACT) */
/*     %comb(&y_id&q, COMB) */
  %end;
%mend importloop;


%importloop(&quarter)

;
proc freq data = ACQ.acq_2008q3;
  table product;
 run;

  