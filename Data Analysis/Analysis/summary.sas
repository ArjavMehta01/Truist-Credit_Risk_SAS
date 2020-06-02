/* Author: Jonas */
/* Purpose: Example of Statistics analysis on 2005Q1 data */

%let _date = 2005Q1;
%let d_comb = COMB.COMB_&_date;
%let v_comb = orig_amt oltv cscore_b dti last_upb;

options nodate;

ods pdf file = "&p_data.Contents.pdf"
        style = Sapphire;

title "Content Table";
proc contents data = &d_comb varnum;
  ods select Position;
  ods output Position = content;
run;
title;

ods pdf close;

/*
● Unpaid Balance (UPB)
● LTV
● Loan Age
● Remaining Until Maturity
● Interest Rate
● Delinquency Status
● Debt-to-Income (DTI)
*/

ods output MissingValues = miss_value;
proc univariate data = &d_comb;
  var &v_comb;
run;

data content(rename = (variable = varname));
  set content(keep = variable label);
run;

proc sort data = content;
  by varname;
run;


proc sort data = miss_value;
  by varname;
run;

data tmp;
  merge miss_value(keep = varname count countnobs
                   in = miss)
        content;
  by varname;
  if miss;
run;

ods pdf file = "&p_data.Summaries.pdf"
        style = Sapphire
        startpage = never;
options orientation = landscape;

title "Statistics Summaries of &_date Data";

proc means data = &d_comb
  min mean median mode max std range
  maxdec = 0
  nmiss;
  var &v_comb;
run;

options orientation = portrait;

title2 "Missing Data Values";
proc sql;
  select varname "Variable Name", label "Label",
         count "Frequency of Missing Values",
         countnobs "Percent of Total Observations"
    from tmp;
quit;

title2 "Frequencies of Last Status";
proc freq data = &d_comb;
  tables last_stat;
run;
title;
ods pdf close;



  %let id01 = %nrstr(1YqgLuVYbwK8LQGL05yiDLzt-PchZN751);
  %let _url = %nrstr(https://docs.google.com/uc?export=download&id=)&&id01;
  filename url_file url "&_url";
  
  data Housing_Starts;
    infile url_file  missover dsd firstobs=2;
    input date :$10. HousingSt_Var;
    logvar = log(HousingSt_Var);
  run;
  
  
proc univariate data = Housing_Starts normal  ; 
histogram HousingSt_Var / normal;
run;

proc means data = Housing_Starts
  min mean median mode max std range
  maxdec = 0
  nmiss;
  var HousingSt_Var;
run;

   
  %let id05 = %nrstr(1iDdiHWP7ihEtEh1zED3XQup0ksdNmK_J);
  %let _url = %nrstr(https://docs.google.com/uc?export=download&id=)&&id05;
  filename url_file url "&_url";
  
  data TNFPayrolls ( drop = lagvar1   lagvar12 );
  	infile url_file missover dsd;
  	input date :$10. Payrolls;
  	label 
  	logP = "Log Transformation"
  	MGT = "Monthly Growth Transformation"
  	AGT = "Annual Growth Transformation"
  	MRT = "Monthly Return Transformation"
  	ART = "Annual Return Transformation"
  	MDT = "Monthly Difference Transformation"
  	pctchng = "Percetnage Change"
  	AnnualGrowth = "Annual Growth in Percent"
  	;
  	format logP MGT AGT MRT ART MDT comma10.5 pctchng AG percent10.2;
  	lagvar1 = lag(Payrolls) ;
  	lagvar12 = lag12(Payrolls);
  	logP = log(Payrolls); /*Log transformation*/
  	MGT = log ( Payrolls / lagvar1 ); /*Monthly Growth Transformation ( ln(Xt / Xt-1) )*/ 
  	AGT = log ( Payrolls / lagvar12 ); /*Annual Growth Transformation ( ln(Xt / Xt-12) ) */
  	MRT = ( Payrolls / lagvar1 ) ;/* Monthly Return Transformation ( Xt / Xt-1 ) */
  	ART = ( Payrolls / lagvar12 ) ;/* Annual Return Transformation (Xt / Xt-12 ) */
  	MDT = dif(lag(Payrolls)); /* Monthly Difference Transformation ( Xt - Xt-1 ) */	
  	pctchng = ( ( Payrolls / lag( Payrolls ) ) ** 12 - 1 ) * 100;
  	AG = dif12( Payrolls ) / lag12( Payrolls ) * 100; /*computed percent change from the same period in the previous year*/
  run;
  
  
  
  

proc univariate data = TNFPayrolls normal  ; 
histogram pctchng / normal;
run;

proc means data = TNFPayrolls
  min mean median mode max std range
  maxdec = 0
  nmiss;
  var Payrolls;
run;
  
  
  
  
  
  %let id02 = %nrstr(1Nolfw8rIW7gFQEbKAR3X-4KaSKUNMZzZ);
  %let _url = %nrstr(https://docs.google.com/uc?export=download&id=)&&id02;
  filename url_file url "&_url";
  
  data GDP (drop = lagvar1 lagvar4 );
  	infile url_file missover dsd;
  	input date :$10. GDP_Var;
  	label 
  	logP = "Log Transformation"
  	QGT = "Quarterly Growth Transformation"
  	AGT = "Annual Growth Transformation"
  	QRT = "Quarterly Return Transformation"
  	ART = "Annual Return Transformation"
  	QDT = "Quarterly Difference Transformation"
  	pctchng = "Percetnage Change"
  	AnnualGrowth = "Annual Growth in Percent"
  	;
  	format logP QGT AGT QRT ART QDT comma10.5 pctchng AG percent10.2;
  	lagvar1 = lag(GDP_Var) ;
  	lagvar4 = lag4(GDP_Var);
  	logP = log(GDP_Var); /*Log transformation*/
  	QGT = log ( GDP_Var / lagvar1 ); /*Quarterly Growth Transformation ( ln(Xt / Xt-1) )*/ 
  	AGT = log ( GDP_Var / lagvar4 ); /*Annual Growth Transformation ( ln(Xt / Xt-4) ) */
  	QRT = ( GDP_Var / lagvar1 ) ;/* Quarterly Return Transformation ( Xt / Xt-1 ) */
  	ART = ( GDP_Var / lagvar1 ) ;/* Annual Return Transformation (Xt / Xt-4 ) */
  	QDT = dif(lag(GDP_Var)); /* Quarterly Difference Transformation ( Xt - Xt-1 ) */	
  	pctchng = ( ( GDP_Var / lag( GDP_Var ) ) ** 12 - 1 ) * 100;
  	AG = dif4( GDP_Var ) / lag4( GDP_Var ) * 100; /*computed percent change from the same period in the previous year*/
  run;
  




proc sgplot data = Housing_Starts;
  	 series x = date y = logvar;
run;


 
 
/*  proc expand data = Housing_Starts out = temp1 */
/*  			 from = month to = qtr; */
/*  			 id = date; */
/*  			 convert HousingSt_Var / observed = average; */
/*  run; */

/* 3 Month - Rolling average for Housing Starts */
%let roll_num = 3;
data temp01 ;
set Housing_Starts;
array summed[&roll_num] _temporary_;
if E = &roll_num then E = 1;
   else E + 1;
summed[E] = HousingSt_Var;
if _N_ >= &roll_num then do;
      roll_avg = mean(of summed[*]);
   end;
   format roll_avg comma10.2;
run;



quit;