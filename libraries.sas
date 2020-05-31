/* Author: Group B */
/* Purpose: library file for local path */

  

%let p_local = /folders/myfolders/Git;

  
  
%let p_anly = %sysfunc(cat(&p_local,/Truist-Credit_Risk_SAS/Data Analysis/));
%let p_report = %sysfunc(cat(&p_local,/Report/));

%let p_data = %sysfunc(cat(&p_local,/Data/));
  %let p_acq = %sysfunc(cat(&p_local,/Data/Acquisition/));
  %let p_perf = %sysfunc(cat(&p_local,/Data/Performance/));
  %let p_comb = %sysfunc(cat(&p_local,/Data/Combine/));
  
  
libname TRUIST_B "&p_local";
  libname REPORT "&p_report";
  libname DATA "&p_data";
    libname ACQ "&p_acq";
    libname ACT "&p_perf";
    libname COMB "&p_comb";


quit;