/* Author: Zheng */
/* Purpose: library file for local path */

  
%let p_local = /folders/myfolders/GitHub/Truist-Credit_Risk_SAS;

  
%let p_anly = %sysfunc(cat(&p_local,/Data Analysis/));
%let p_report = %sysfunc(cat(&p_local,/Report/));

%let p_data = %sysfunc(cat(&p_local,/Data/));
  %let p_acq = %sysfunc(cat(&p_local,/Data/Acquisition/));
  %let p_perf = %sysfunc(cat(&p_local,/Data/Performance/));
  %let p_comb = %sysfunc(cat(&p_local,/Data/Combine/));

%let p_pd = %sysfunc(cat(&p_local,/PD Model/));
  %let p_pddata = %sysfunc(cat(&p_local,/PD Model/Data/));
  %let p_pdres = %sysfunc(cat(&p_local,/PD Model/Result/));


libname TRUIST_B "&p_local";
  libname REPORT "&p_report";
  libname DATA "&p_data";
    libname ACQ "&p_acq";
    libname ACT "&p_perf";
    libname COMB "&p_comb";
  libname PD "&p_pd";
    libname PD_DATA "&p_pddata";


quit;