/* Author: Jonas */
/* Purpose: Test file for pushing to github */

%put This program is running for test (Date: &sysdate);

proc sql outobs = 5;
  select * from sashelp.cars;
quit;

* Zheng test;
Jonas
