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
*Stacking Loan Level files to create full dataset;

data combined_data;
  set comb_2000q1 comb_2000q2 comb_2000q3 comb_2000q4 comb_2001q1 comb_2001q2 
    comb_2001q3 comb_2001q4 comb_2002q1 comb_2002q2 comb_2002q3 comb_2002q4 
    comb_2003q1 comb_2003q2 comb_2003q3 comb_2003q4 comb_2004q1 comb_2004q2 
    comb_2004q3 comb_2004q4 comb_2005q1 comb_2005q2 comb_2005q3 comb_2005q4 
    comb_2006q1 comb_2006q2 comb_2006q3 comb_2006q4 comb_2007q1 comb_2007q2 
    comb_2007q3 comb_2007q4 comb_2008q1 comb_2008q2 comb_2008q3 comb_2008q4 
    comb_2009q1 comb_2009q2 comb_2009q3 comb_2009q4 comb_2010q1 comb_2010q2 
    comb_2010q3 comb_2010q4 comb_2011q1 comb_2011q2 comb_2011q3 comb_2011q4 
    comb_2012q1 comb_2012q2 comb_2012q3 comb_2012q4 comb_2013q1 comb_2013q2 
    comb_2013q3 comb_2013q4 comb_2014q1 comb_2014q2 comb_2014q3 comb_2014q4 
    comb_2015q1 comb_2015q2 comb_2015q3 comb_2015q4;
run;

proc sort data=combined_data;
  by loan_id;
run;

************************************;
********start of analysis********;
************************************;
** create dataset for summary tables **;

data myfolder.statsum;
  set combined_data;
  ** Acquisition Table Flags **;
  *building flags for second lien, non owner occupied, refinanced, and mortgage insured properties;

  if ocltv > oltv then
    seclien=1;
  else
    seclien=0;

  if occ_stat in ("I", "S") then
    nonown=1;
  else
    nonown=0;

  if purpose in ("C", "R", "U") then
    refis=1;
  else
    refis=0;

  if mi_pct > 0 then
    mi=1;
  else
    mi=0;
  ** terminal counts **;

  if last_stat in ("C", "1", "2", "3", "4", "5", "6", "7", "8", "9") then
    active_cnt=1;
  else
    active_cnt=0;

  if last_stat in ("C", "1", "2", "3", "4", "5", "6", "7", "8", "9") then
    active_upb=last_upb;
  else
    active_upb=0;
  active_upb_mil=active_upb/1000000;

  if last_stat="P" then
    prepaid_cnt=1;
  else
    prepaid_cnt=0;

  if last_stat="F" then
    reo_cnt=1;
  else
    reo_cnt=0;

  if last_stat in ("S", "T") then
    alt_cnt=1;
  else
    alt_cnt=0;

  if last_stat="R" then
    repurch_cnt=1;
  else
    repurch_cnt=0;
  *default upb is the final reported upb for loans in our defaulted loan population;

  if complt_flg=1 then
    default_upb=last_upb;
  else
    default_upb=0;
  ** performance rates **;
  *calculating the portion of our originations that defaults, and the portion of originations that we lose due to default;
  default_rt=default_upb/orig_amt;

  if complt_flg=1 then
    nloss_rt=net_loss/orig_amt;
  else
    nloss_rt=0;
  ** loss components & net severity **;
  *calculating costs and proceeds due to default relative to the upb for those defaulted loans;
  tot_proc=sum(ns_procs, ce_procs, rmw_procs, o_procs);
  tot_exp=sum(fcc_cost, pp_cost, ar_cost, ie_cost, tax_cost);
  tot_cost=sum(int_cost, tot_exp, last_upb);

  if complt_flg=1 then
    do;
      int_cost1=int_cost/default_upb;
      tot_exp1=tot_exp/default_upb;
      fcc_cost1=fcc_cost/default_upb;
      pp_cost1=pp_cost/default_upb;
      ar_cost1=ar_cost/default_upb;
      ie_cost1=ie_cost/default_upb;
      tax_cost1=tax_cost/default_upb;
      tot_cost1=tot_cost/default_upb;
      ns_procs1=ns_procs/default_upb;
      ce_procs1=ce_procs/default_upb;
      rmw_procs1=rmw_procs/default_upb;
      o_procs1=o_procs/default_upb;
      tot_proc1=tot_proc/default_upb;
    end;
  ** refinance type/occupancy counts **;

  if occ_stat='I' then
    inv_cnt=1;
  else
    inv_cnt=0;

  if occ_stat='P' then
    pri_cnt=1;
  else
    pri_cnt=0;

  if occ_stat='S' then
    sec_cnt=1;
  else
    sec_cnt=0;

  if purpose='C' then
    co_cnt=1;
  else
    co_cnt=0;

  if purpose='P' then
    pur_cnt=1;
  else
    pur_cnt=0;

  if purpose='R' then
    rt_cnt=1;
  else
    rt_cnt=0;

  if purpose='U' then
    u_cnt=1;
  else
    u_cnt=0;
  ** credit score buckets **;

  if 0 < cscore_mn < 620 then
    cscorebkt='[0-620)';

  if 620 <=cscore_mn < 660 then
    cscorebkt='[620-660)';

  if 660 <=cscore_mn < 700 then
    cscorebkt='[660-700)';

  if 700 <=cscore_mn < 740 then
    cscorebkt='[700-740)';

  if 740 <=cscore_mn < 780 then
    cscorebkt='[740-780)';

  if 780 <=cscore_mn then
    cscorebkt='[780+)';
  *building a variable to sum loans in each credit bucket;
  count=1;
run;

* opening the excel document that we will write acquisition, performance, and historical loss statistics to;
* file will save to the same folder as the sas code;
ods tagsets.excelxp file="./lppub loss summary tables.xls" style=seaside 
  options (fittopage='yes' pages_fitwidth='1' pages_fitheight='1' 
  autofit_height='yes');
* building a tab with loan counts by refinance purpose;
ods tagsets.excelxp options(sheet_interval='none' 
  sheet_name='vint.refi.counts');

proc tabulate data=myfolder.statsum missing;
  class orig_dte;
  format orig_dte year.;
  var co_cnt pur_cnt rt_cnt u_cnt;
  tables (co_cnt='CASHOUT REFI' pur_cnt='PMM' rt_cnt='RATE/TERM REFI' 
    u_cnt='UNKNOWN REFI')*sum='' n='sum', (orig_dte='' all);
run;

* building a tab with loan counts by occupancy type;
ods tagsets.excelxp options(sheet_interval='none' sheet_name='vint.occ.counts');

proc tabulate data=myfolder.statsum missing;
  class orig_dte;
  format orig_dte year.;
  var inv_cnt pri_cnt sec_cnt;
  tables (inv_cnt='INVESTOR' pri_cnt='PRIMARY RES' sec_cnt='SECOND HOME')*sum='' 
    n='sum', (orig_dte='' all);
run;

* building a tab with frequencies by last status;
ods tagsets.excelxp options(sheet_interval='none' 
  sheet_name='vint.last_stat.counts');

proc freq data=myfolder.statsum;
  tables last_stat;
run;

*building summary statistics for credit score, oltv, and origination upb;
ods tagsets.excelxp options(sheet_interval='none' sheet_name='summary.stats');

proc means data=myfolder.statsum min p25 p50 mean p75 max nmiss;
  var cscore_mn oltv orig_amt;
run;

* building a tab with counts by fico bucket and vintage;
ods tagsets.excelxp options(sheet_interval='none' 
  sheet_name='vint.fico.counts');

proc tabulate data=myfolder.statsum missing;
  class orig_dte cscorebkt;
  format orig_dte year.;
  var count;
  table cscorebkt*count=''*sum='', (orig_dte='' all);
run;

* building the acquisition statistics tab of the excel document;
ods tagsets.excelxp options(sheet_interval='none' sheet_name='aqsn. stats');

proc tabulate data=myfolder.statsum missing;
  class orig_dte;
  format orig_dte year.;
  var orig_amt;
  var cscore_b cscore_c oltv ocltv dti orig_rt/weight=orig_amt;
  table (orig_dte='' all), n='loan count' orig_amt='total orig. upb'*sum='' 
    orig_amt='avg. orig upb($)'*mean cscore_b*mean='borrower credit score' 
    cscore_c*mean='co-borrower credit score' oltv*mean='ltv ratio' 
    ocltv*mean='cltv ratio' dti*mean='dti' orig_rt*mean='note rate';
run;

* building the performance statistics tab of the excel document to present loan counts, rates, and dollar amounts of different performance outcomes;
ods tagsets.excelxp options(sheet_interval='none' 
  sheet_name='perf.stat.counts');

proc tabulate data=myfolder.statsum missing;
  class orig_dte;
  format orig_dte year.;
  var orig_amt active_cnt active_upb prepaid_cnt reo_cnt alt_cnt repurch_cnt 
    default_upb mod_flag;
  var default_rt nloss_rt / weight=orig_amt;
  table (orig_dte='' all), n='loan count' orig_amt='total orig. upb'*sum='' 
    active_cnt='loan count (active)' 
    active_upb='active upb' (prepaid_cnt='prepaid' repurch_cnt='repurchased' 
    alt_cnt='alternative disposition' reo_cnt='reo disposition' 
    mod_flag='modified') default_upb='default upb'*sum='' 
    nloss_rt='net loss rate'*mean=''*f=percent10.5;
run;

* building the historical loss statistics tab of the excel document to present cost, proceed, and loss amounts by vintage;
ods tagsets.excelxp options(sheet_interval='none' 
  sheet_name='historical net loss by vintage');

proc tabulate data=myfolder.statsum (where=(complt_flg=1)) missing;
  class orig_dte;
  format orig_dte year.;
  var ar_cost1 ie_cost1 pp_cost1 fcc_cost1 tax_cost1 tot_exp1 tot_cost1 
    int_cost1 tot_proc1 ns_procs1 ce_procs1 rmw_procs1 o_procs1 net_sev/ 
    weight=default_upb;
  var default_upb net_loss;
  tables n='loan count'*f=comma10. default_upb='default upb ($m)'*sum='' (int_cost1='delinquent interest' 
    tot_exp1='total liquidation exp.' fcc_cost1='foreclosure' 
    pp_cost1='property preservation' ar_cost1='asset recovery' 
    ie_cost1='misc. holding expenses' tax_cost1='associated taxes' 
    tot_cost1='total costs' ns_procs1='net sales proceeds' 
    ce_procs1='credit enhancement' rmw_procs1='repurchase/make whole' 
    o_procs1='other proceeds' tot_proc1='total proceeds' 
    net_sev='severity')*mean=''*f=percent10.5 
    net_loss='total net loss ($m)'*sum='', (orig_dte='' all);
run;

proc tabulate data=myfolder.statsum missing;
  class orig_dte;
  format orig_dte year.;
  var default_rt/ weight=orig_amt;
  tables default_rt='default rate'*f=percent10.5*mean='', (orig_dte='' all);
run;

* building the historical loss statistics tab of the excel document to present cost, proceed, and loss amounts by vintage;
ods tagsets.excelxp options(sheet_interval='none' 
  sheet_name='historical net loss by disp dt');

proc tabulate data=myfolder.statsum (where=(complt_flg=1)) missing;
  class disp_dte;
  format disp_dte year.;
  var ar_cost1 ie_cost1 pp_cost1 fcc_cost1 tax_cost1 tot_exp1 tot_cost1 
    int_cost1 tot_proc1 ns_procs1 ce_procs1 rmw_procs1 o_procs1 net_sev/ 
    weight=default_upb;
  var default_upb net_loss;
  tables n='loan count'*f=comma10. default_upb='default upb'*sum=''

(int_cost1='delinquent interest' tot_exp1='total liquidation exp.' 
    fcc_cost1='foreclosure' pp_cost1='property preservation' 
    ar_cost1='asset recovery' ie_cost1='misc. holding expenses' 
    tax_cost1='associated taxes' tot_cost1='total costs' 
    ns_procs1='net sales proceeds' ce_procs1='credit enhancement' 
    rmw_procs1='repurchase/make whole' o_procs1='other proceeds' 
    tot_proc1='total proceeds' net_sev='severity')*mean=''*f=percent10.5 
    net_loss='total net loss'*sum='', (disp_dte='' all);
run;

proc tabulate data=myfolder.statsum missing;
  class last_dte;
  format last_dte year.;
  var default_rt/ weight=orig_amt;
  tables default_rt='default rate'*f=percent10.5*mean='', (last_dte='' all);
run;