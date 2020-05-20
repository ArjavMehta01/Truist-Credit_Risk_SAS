/* Author: Jonas */
/* Purpose: Import Loan performance data and macroeconomics from Google Drive */


* Try this proc http;

filename _inbox "C:/Users/jonas/Desktop/test.txt"; *output dataset;
 
proc http method="get" 
 url="https://drive.google.com/open?id=164e4YneTI1zNnmDRv7AMP_hPMH4N76-e" 
 out=_inbox 
 /* proxyhost="http://yourproxy.company.com" */
;
run;


filename out "%sysfunc(getoption(WORK))/output.txt";
filename hdrout "%sysfunc(getoption(WORK))/response1.txt";
 
/* This PROC step caches the cookie for the website finance.yahoo.com */
/* and captures the web page for parsing later                        */
proc http 
  out=out
  headerout=hdrout
  url="https://drive.google.com/open?id=164e4YneTI1zNnmDRv7AMP_hPMH4N76-e" 
  method="get";
run;

endsas;
data test;
  infile hdrout;
  input t_char $ 900;
  run;
