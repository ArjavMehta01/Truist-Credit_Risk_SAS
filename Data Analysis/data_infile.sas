%let directory = /<INSERT FILEPATH TO UNZIPPED PAIR(S) OF FILES HERE>/;

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

%macro file_import (quarter);
  data acq_&quarter (drop=x_orig_date zip x_first_pay x_prod_type);
    infile "&directory.Acquisition_&quarter..txt" delimiter='|' MISSOVER DSD 
      lrecl=32767;
    input &acq_head;
    ** date conversion - convert mm/yyyy to sas date **;
    format orig_dte frst_dte mmddyy8.;
    orig_dte=mdy(input(substr(x_orig_date, 1, 2), 2.), 1, 
      input(substr(x_orig_date, 4, 4), 4.));
    frst_dte=mdy(input(substr(x_first_pay, 1, 2), 2.), 1, 
      input(substr(x_first_pay, 4, 4), 4.));
    ** product **;
    length product $ 4;
    product='fr30';
  run;

  data act_&quarter (drop=x_zb_date x_period x_maturity_date X_LPI_dte X_fcc_dte 
      X_disp_dte);
    infile "&directory.Performance_&quarter..txt" delimiter='|' MISSOVER DSD 
      lrecl=32767;
    input &perf_head;
    ** date conversion - mm/yyyy to sas date **;
    format zb_dte maturity_date monthly_rpr_prd lpi_date fcc_date disp_date 
      mmddyy8.;
    zb_dte=mdy(input(substr(x_zb_date, 1, 2), 2.), 1, input(substr(x_zb_date, 4, 
      4), 4.));
    maturity_date=mdy(input(substr(x_maturity_date, 1, 2), 2.), 1, 
      input(substr(x_maturity_date, 4, 4), 4.));
    ** date conversion - mm/dd/yyyy string to sas date **;
    monthly_rpr_prd=mdy(input(substr(x_period, 1, 2), 2.), 1, 
      input(substr(x_period, 7, 4), 4.));
    lpi_date=mdy(input(substr(x_lpi_dte, 1, 2), 2.), 1, input(substr(x_lpi_dte, 
      7, 4), 4.));
    fcc_date=mdy(input(substr(x_fcc_dte, 1, 2), 2.), 1, input(substr(x_fcc_dte, 
      7, 4), 4.));
    disp_date=mdy(input(substr(x_disp_dte, 1, 2), 2.), 1, 
      input(substr(x_disp_dte, 7, 4), 4.));
  run;

%mend;