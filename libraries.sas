/* Author: Group B */
/* Purpose: library file for local path */

* Change to your local path;
* %let p_local = /folders/myfolders/GitHub/Truist-Credit_Risk_SAS;

%let p_local = /folders/myfolders/GitHub/Truist-Credit_Risk_SAS;

%let p_data = %sysfunc(cat(&p_local,/Data Analysis/));

%put Your data library path: &p_data;

libname TRUIST_B "&p_local";
libname DATA "&p_data";

quit;