%macro lppub (quarter);
  *****************************************;
  ** upload and format acquisition files **;
  *****************************************;

  data acq (drop=x_orig_date x_first_pay x_prod_type);
    infile "&directory.Acquisition_&quarter..txt" delimiter='|' missover dsd 
      lrecl=32767;
    input &acq_head;
    *converting date formats from mm/yyyy to sas date;
    format orig_dte frst_pay mmddyy8.;
    orig_dte=mdy(input(substr(x_orig_date, 1, 2), 2.), 1, 
      input(substr(x_orig_date, 4, 4), 4.));
    frst_pay=mdy(input(substr(x_first_pay, 1, 2), 2.), 1, 
      input(substr(x_first_pay, 4, 4), 4.));
  run;

  proc sort data=acq;
    by loan_id;
  run;

  **************************************;
  ** upload and format activity files **;
  **************************************;

  data temp (drop=x_zb_date x_period x_loan_age x_maturity_date x_adj_rem_months 
      x_dlq_status x_lpi_dte x_fcc_dte x_disp_dte);
    infile "&directory.Performance_&quarter..txt" delimiter='|' MISSOVER DSD 
      lrecl=32767;
    input &perf_head;
    *Converting dates from mm/yyyy to SAS Date;
    format y_act_date z_zb_date lpi_dte fcc_dte disp_dte y_maturity_date mmddyy8.;
    z_zb_date=mdy(input(substr(x_zb_date, 1, 2), 2.), 1, input(substr(x_zb_date, 
      4, 4), 4.));
    *Converting dates from MM/DD/YYYY to SAS Date;
    y_act_date=mdy(input(substr(x_period, 1, 2), 2.), 1, input(substr(x_period, 
      7, 4), 4.));
    lpi_dte=mdy(input(substr(x_lpi_dte, 1, 2), 2.), 1, input(substr(x_lpi_dte, 7, 
      4), 4.));
    fcc_dte=mdy(input(substr(x_fcc_dte, 1, 2), 2.), 1, input(substr(x_fcc_dte, 7, 
      4), 4.));
    disp_dte=mdy(input(substr(x_disp_dte, 1, 2), 2.), 1, input(substr(x_disp_dte, 
      7, 4), 4.));
    y_maturity_date=mdy(input(substr(x_maturity_date, 1, 2), 2.), 1, 
      input(substr(x_maturity_date, 4, 4), 4.));
    *To convert delinquency status from character to number, we set 'X' values to '999';

    if x_dlq_status='X' then
      y_dlq_stat=999;
    else
      y_dlq_stat=x_dlq_status*1;
  run;

  *sorting loans by activity date to keep in chronological order;

  proc sort data=temp;
    by loan_id y_act_date;
  run;

  ****************************************************************************** *****************************************;
  **----------------------- retaining elements from activity files required for static data set -----------------------**;
  ****************************************************************************** *****************************************;

  data act (drop=y_mod_ind y_servicer y_prev_upb y_maturity_date_rt 
      y_maturity_date y_rem_mths y_non_int_upb y_prin_forg_upb y_prin_forg_upb_o 
      y_prin_forg_upb_fhfa y_rem_mths_rt rename=(y_act_upb=last_upb 
      y_dlq_stat=z_last_status y_curr_rte=last_rt y_act_date=last_activity_date 
      y_num_periods=z_num_periods_last));
    set temp (where=(y_act_date <="&fn_end."d));
    by loan_id y_act_date;
    length servicer $80;
    retain servicer;
    retain y_num_periods f30_dte f60_dte f90_dte f180_dte fce_dte f180_upb 
      fce_upb mod_flag fmod_dte fmod_upb z_non_int_upb z_prin_forg_upb z_orig_rate 
      modir_cost modfb_cost modfg_cost modtrm_chng modupb_chng y_maturity_date_rt 
      z_num_periods_180 z_num_periods_ce;
    format f30_dte f60_dte f90_dte f180_dte fce_dte fmod_dte y_maturity_date_rt 
      mmddyy8.;
    y_rem_mths_rt=lag(y_rem_mths);
    y_prev_upb=lag(y_act_upb);
    y_prin_forg_upb=sum(y_prin_forg_upb_fhfa, y_prin_forg_upb_o);

    if first.loan_id then
      do;
        servicer=y_servicer;
        z_orig_rate=y_curr_rte;
        y_maturity_date_rt=y_maturity_date;
        y_num_periods=1;
        y_prev_upb=.;
        y_rem_mths_rt=.;
        modtrm_chng=0;
        modupb_chng=0;
        z_non_int_upb=y_non_int_upb;
        z_prin_forg_upb=y_prin_forg_upb;

        if 999 > y_dlq_stat >=1 then
          f30_dte=y_act_date;
        else
          f30_dte=.;

        if 999 > y_dlq_stat >=2 then
          f60_dte=y_act_date;
        else
          f60_dte=.;

        if 999 > y_dlq_stat >=3 then
          f90_dte=y_act_date;
        else
          f90_dte=.;

        if 999 > y_dlq_stat >=6 then
          f180_dte=y_act_date;
        else
          f180_dte=.;

        if 999 > y_dlq_stat >=6 then
          f180_upb=y_act_upb;
        else
          f180_upb=.;

        if 999 > y_dlq_stat >=6 then
          z_num_periods_180=y_num_periods;
        else
          z_num_periods_180=.;

        if 999 > y_dlq_stat >=6 and z_zb_code in ('02', '03', '09', '15') then
          fce_dte=y_act_date;
        else
          fce_dte=.;

        if 999 > y_dlq_stat >=6 and z_zb_code in ('02', '03', '09', '15') then
          fce_upb=y_act_upb;
        else
          fce_upb=.;

        if 999 > y_dlq_stat >=6 and z_zb_code in ('02', '03', '09', '15') then
          z_num_periods_ce=y_num_periods;
        else
          z_num_periods_ce=.;

        if y_mod_ind='Y' then
          mod_flag=1;
        else
          mod_flag=0;

        if y_mod_ind='Y' then
          fmod_dte=y_act_date;
        else
          fmod_dte=.;

        if y_mod_ind='Y' then
          fmod_upb=y_act_upb;
        else
          fmod_upb=.;

        if y_mod_ind='Y' then
          modir_cost=(((z_orig_rate - y_curr_rte) / 1200) * y_act_upb);
        else
          modir_cost=0;

        if y_mod_ind='Y' then
          modfb_cost=((y_curr_rte / 1200) * max(z_non_int_upb, 0));
        else
          modfb_cost=0;

        if y_mod_ind='Y' then
          modfg_cost=max(z_prin_forg_upb, 0);
        else
          modfg_cost=0;
      end;
    else
      do;
        *servicer field will capture the current servicer*;

        if y_servicer ne '' then
          servicer=y_servicer;
        y_num_periods=y_num_periods + 1;
        *capturing the last upb for zero balance loans;

        if y_act_upb <=0 and z_zb_code in ('01', '02', '03', '06', '09', '15', 
          '16') then
            y_act_upb=y_prev_upb;

        if y_mod_ind='Y' and (y_non_int_upb <> . or y_non_int_upb <> 0) then
          z_non_int_upb=y_non_int_upb;

        if y_mod_ind='Y' and (y_prin_forg_upb <> . or y_prin_forg_upb <> 0) then
          z_prin_forg_upb=y_prin_forg_upb;
        *Performance flags*;

        if 999 > y_dlq_stat >=1 and f30_dte=. then
          f30_dte=y_act_date;

        if 999 > y_dlq_stat >=2 and f60_dte=. then
          f60_dte=y_act_date;

        if 999 > y_dlq_stat >=3 and f90_dte=. then
          f90_dte=y_act_date;

        if 999 > y_dlq_stat >=6 and F180_DTE=. then
          do;
            f180_dte=y_act_date;
            f180_upb=y_act_upb;
            z_num_periods_180=y_num_periods;
          end;

        if (999 > y_dlq_stat >=6 or z_zb_code in ('02', '03', '09', '15')) and 
          fce_dte=. then
            do;
            fce_dte=y_act_date;
            fce_upb=y_act_upb;
            z_num_periods_ce=y_num_periods;
          end;

        if y_mod_ind='Y' and mod_flag=0 then
          do;
            mod_flag=1;
            fmod_dte=y_act_date;
            fmod_upb=y_act_upb;
          end;

        if y_mod_ind='Y' then
          do;

            if y_maturity_date_rt ne y_maturity_date then
              modtrm_chng=1;

            if y_rem_mths_rt ne . and y_rem_mths_rt < y_rem_mths then
              modtrm_chng=1;

            if y_act_upb > y_prev_upb then
              modupb_chng=1;
            modir_cost=modir_cost + (((z_orig_rate - y_curr_rte) / 1200) * y_act_upb);
            modfb_cost=modfb_cost + ((y_curr_rte / 1200) * max(z_non_int_upb, 0) );
            modfg_cost=max(z_prin_forg_upb, 0);
          end;
      end;

    if last.loan_id;
  run;

  ************************************;
  ** merge to create combined dataset **;
  ************************************;

  data comb_&quarter (drop=z_zb_code z_zb_date z_last_status z_num_periods_180 
      z_num_periods_ce z_num_periods_last z_non_int_upb z_prin_forg_upb 
      z_orig_rate);
    merge acq (in=a) act (in=b);
    by loan_id;

    if a;
    ** correcting the null ce values on early dlq loans upb values **;

    if 0 < z_num_periods_180 <=8 then
      f180_upb=orig_amt;

    if 0 < z_num_periods_ce <=8 then
      fce_upb=orig_amt;
    ** minimum credit score **;
    cscore_mn=min(cscore_b, cscore_c);
    **setting mipct equal to 0 when missing like freddie**;
    mi_pct=max(mi_pct, 0);
    ** origination home value **;
    orig_val=orig_amt/(oltv/100);
    **correcting missing cltvs**;
    ocltv=max(oltv, ocltv);
    format last_dte date9.;

    if disp_dte ne . then
      last_dte=disp_dte;
    else
      last_dte=last_activity_date;
    *last status;
    length last_stat $1;

    if z_zb_code='09' then
      last_stat="F";
    else if z_zb_code='03' then
      last_stat="S";
    else if z_zb_code='02' then
      last_stat="T";
    else if z_zb_code='15' then
      last_stat="N";
    else if z_zb_code='16' then
      last_stat="L";
    else if z_zb_code='06' then
      last_stat="R";
    else if z_zb_code='01' then
      last_stat="P";
    else if 999 > z_last_status > 9 then
      last_stat="9";
    else if 9 >=z_last_status > 0 then
      last_stat=put(z_last_status, 1.);
    else if z_last_status=0 then
      last_stat="C";
    else
      last_stat='X';
    *nulling out activity beyond cutoff;

    if lpi_dte > "&fn_end."d then
      lpi_dte=.;

    if fcc_dte > "&fn_end."d then
      fcc_dte=.;

    if disp_dte > "&fn_end."d then
      disp_dte=.;
    *90 days back from completion date is unnecessary to align with freddie >= intnx("month",&fn_end.,-2);

    if fcc_dte=. and last_stat in ("F", "S", "T", "N") then
      fcc_dte=z_zb_date;
    *disposition completion flag;
    complt_flg=(disp_dte > .);

    if last_stat not in ("F", "S", "T", "N") then
      complt_flg=.;
    *compute net loss statistics for completed cases;

    if complt_flg=1 then
      do;
        *mod costs for defaulted loans after default;
        modir_cost=modir_cost + (intck("month", z_zb_date, 
          last_dte)*((z_orig_rate - last_rt) / 1200) * last_upb);
        modfb_cost=modfb_cost + (intck("month", z_zb_date, last_dte)*(last_rt / 
          1200) * z_non_int_upb);
        *max is to floor at zero because neg int costs dont make sense but happen when lpi > disp;
        int_cost=max(intck("month", lpi_dte, last_dte)*(((last_rt/100)-0.0035)/12) 
          *sum(last_upb, -1*z_non_int_upb, -1*z_prin_forg_upb), 0);

        if int_cost=. then
          int_cost=0;

        if fcc_cost=. then
          fcc_cost=0;

        if pp_cost=. then
          pp_cost=0;

        if ar_cost=. then
          ar_cost=0;

        if ie_cost=. then
          ie_cost=0;

        if tax_cost=. then
          tax_cost=0;

        if ns_procs=. then
          ns_procs=0;

        if ce_procs=. then
          ce_procs=0;

        if rmw_procs=. then
          rmw_procs=0;

        if o_procs=. then
          o_procs=0;
        net_loss=sum(last_upb, fcc_cost, pp_cost, ar_cost, ie_cost, tax_cost, 
          int_cost, -1* ns_procs, -1*ce_procs, -1*rmw_procs, -1*o_procs);
        net_sev=(net_loss/last_upb);
      end;
    modtot_cost=sum(modir_cost, modfb_cost, modfg_cost);

    if mod_flag=0 then
      do;
        modtot_cost=.;
        modir_cost=.;
        modfb_cost=.;
        modfg_cost=.;
      end;
  run;

%mend;

%LPPUB(2000Q1);
%LPPUB(2000Q2);
%LPPUB(2000Q3);
%LPPUB(2000Q4);
%LPPUB(2001Q1);
%LPPUB(2001Q2);
%LPPUB(2001Q3);
%LPPUB(2001Q4);