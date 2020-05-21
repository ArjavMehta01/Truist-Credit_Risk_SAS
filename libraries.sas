/* Author: Group B */
/* Purpose: library file for local path */

* Change to your local path;
* %let p_local = /folders/myfolders/GitHub/Truist-Credit_Risk_SAS;



%let p_local = /folders/myfolders/GitHub/Truist-Credit_Risk_SAS;




%let p_data = %sysfunc(cat(&p_local,/Data Analysis/));
%let p_acq = %sysfunc(cat(&p_local,/Data/Acquisition/));
%let p_perf = %sysfunc(cat(&p_local,/Data/Performance/));

%put Your local library path: &p_local;

libname TRUIST_B "&p_local";
libname DATA "&p_data";
libname ACQ "&p_acq";
libname ACT "&p_perf";


quit;