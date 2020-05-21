/* Author: Jonas */
/* Purpose: Import Loan performance data from LOCAL Path */

* change the value of this macro variable: Q1-Q4;
%let quater = Q1;

%let y_start = 2005;
%let y_end = 2017;



%let acq_head = loan_id :$12.     orig_chn :$1.     seller :$80.
                orig_rt           orig_amt          orig_trm 
                x_orig_date :$7.  x_first_pay :$7.  oltv
                ocltv             num_bo            dti
                cscore_b          fthb_flg :$1.     purpose :$1. 
                prop_typ :$2.     num_unit          occ_stat :$1.
                state :$2.        zip_3 :$3.        mi_pct 
                x_prod_type :$3.  cscore_c          mi_type 
                relo_flg :$1. 
                ;
                
%let perf_head = loan_id :$12.       x_period :$10.     y_servicer :$80. 
                 y_curr_rte          y_act_upb          x_loan_age 
                 y_rem_mths          x_adj_rem_months   x_maturity_date :$7. 
                 msa :$5.            x_dlq_status :$3.  y_mod_ind :$1. 
                 z_zb_code :$2.      x_zb_date :$7.     x_lpi_dte :$10. 
                 x_fcc_dte :$10.     x_disp_dte :$10.   fcc_cost 
                 pp_cost             ar_cost            ie_cost
                 tax_cost            ns_procs           ce_procs 
                 rmw_procs           o_procs            non_int_upb 
                 prin_forg_upb_fhfa  repch_flag :$1.    prin_forg_upb_o
                 serv_transfer :$1.
                 ;


%macro acq(date, output, option);
  *****************************************;
  ** import and format acquisition files **;
  *****************************************;
  filename f_acq "&p_acq";
  
  data &output..acq_&date;
    infile f_acq("Acquisition_&date..txt") dlm = "|" missover dsd lrecl=32767 &option;
    input &acq_head;
    
    *date conversion;
    format orig_dte frst_pay mmddyy8.;
    orig_dte = mdy(input(substr(x_orig_date,1,2),2.),1,input(substr(x_orig_date,4,4),4.)); 
    frst_pay = mdy(input(substr(x_first_pay,1,2),2.),1,input(substr(x_first_pay,4,4),4.));
    
    drop x_:;
  run;
  
%mend acq;


%macro perf(date, outfile, option);
  *****************************************;
  ** import and format performance files **;
  *****************************************;
  filename f_act "&p_perf";
  
  data &outfile..tmp;
    infile f_act("Performance_&date..txt") dlm = "|" missover dsd lrecl=32767 &option;
    input &perf_head;
    
    *date conversion;
    format y_act_date    z_zb_date    lpi_dte 
           fcc_dte       disp_dte     y_maturity_date 
           mmddyy8.;  
    z_zb_date       = mdy(input(substr(x_zb_date,1,2),2.),1,input(substr(x_zb_date,4,4),4.));
    y_act_date      = mdy(input(substr(x_period,1,2),2.),1,input(substr(x_period,7,4),4.));
    lpi_dte         = mdy(input(substr(x_lpi_dte,1,2),2.),1,input(substr(x_lpi_dte,7,4),4.));
    fcc_dte         = mdy(input(substr(x_fcc_dte,1,2),2.),1,input(substr(x_fcc_dte,7,4),4.));
    disp_dte        = mdy(input(substr(x_disp_dte,1,2),2.),1,input(substr(x_disp_dte,7,4),4.));
    y_maturity_date = mdy(input(substr(x_maturity_date,1,2),2.),1,input(substr(x_maturity_date,4,4),4.));
    
    *delinquency status conversion (set 'X' values to '999');
    if x_dlq_status = 'X' then y_dlq_stat = 999;
      else y_dlq_stat = x_dlq_status*1;
      
    drop x_:;
  run;


 *sorting loans by activity date to keep in chronological order;
/*   proc sort data = tmp; */
/*     by loan_id y_act_date; */
/*   run; */
  
  
%mend perf;

********************;
** testing macros **;
********************;
/*
%let o_test = %str(obs=10);

%acq(2005Q1, work, &o_test)
%perf(2005Q1, work, &o_test)
*/

*******************************;
** running acquisition files **;
*******************************;
%macro q1loop(end);
  %do y_id = &y_start %to &end;
  %acq(&y_id&quater, ACQ)
/*   %perf(&id, ACT) */
  %end;
%mend q1loop;


%q1loop(&y_end)


  