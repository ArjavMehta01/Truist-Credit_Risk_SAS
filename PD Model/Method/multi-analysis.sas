/* Author: Arjav */
/* Purpose: Univariate analysis for all variables */






/* %let var = loan_id orig_amt orig_dte oltv dti GDP HS UMP Permits Payrolls; */
/*   proc sort data = PD_DATA.data(keep = loan_id &driver final_stat) out = uni tagsort; */
/*     by loan_id; */
/*   run; */


%let xlvar = Orig_amt oltv dti Cscore_b Curr_rte Loan_age CLTV ;
%let xmvar =  HS GDP UMP Rate PPI Permits Payroll HPI ;
%let xtrans = Rate_MDT HS_MDT UMP_MDT PPI_MDT HOP_MDT ;
%let xvar = Orig_amt oltv dti Cscore_b Curr_rte Loan_age CLTV Rate GDP HS UMP PPI Permits Payroll HPI Rate_MDT HS_MDT UMP_MDT PPI_MDT HOP_MDT;
%let tempvar = Orig_amt oltv dti Cscore_b Curr_rte Loan_age CLTV Rate_MDT HS_MDT UMP_MDT PPI_MDT HOP_MDT;



%let portion = 0.1;
%let n_seed = 7919; 
proc surveyselect data = PD_DATA.data (keep = loan_id &xmvar)
  noprint
  method = SRS
  out = temp_macro 
  rate = &portion
  seed = &n_seed;
run;
  
  
/* Standardizing the Macros   */

proc standard data = temp_macro  mean = 0 std = 1 out = xyz ;
run;

/* Finding correlation in the data since different units*/

/* Correlation for all variables */
proc corr data = temp_macro plots = none  pearson ;
var &xvar ;
run;

/* Correlation for transfromed macrovariables with loan level drivers */

proc corr data = temp_macro plots = none  pearson ;
var &tempvar ;
run;

/* Correlation for all macrovariables */

proc corr data = temp_macro plots = none  pearson ;
var &xmvar ;
run;


/* n PLOTS=SCORE(ELLIPSE NCOMP=3)  */
/* Principal Component Analysis */

proc standard data = temp_macro  mean = 0 std = 1 out = xyz ;
run;

proc princomp data = xyz out = PCA plots(ncomp = 3) = all n = 3 standard;
var &xmvar;
run;

proc plot data = PCA;
plot prin3*prin2  ;
run;

proc print data = PCA (obs=100);
run;



/* Factor Analysis */

proc factor data = xyz 
method = principal
priors= one
rotate = none 
scree;
var &xmvar;
run;


proc factor data = xyz 
method = principal
priors= one
nfactors = 3
rotate = none
fuzz = 0.3
outstat = Macros_variables
plot nplot = 3 
out = abc;
var &xmvar;
run;

