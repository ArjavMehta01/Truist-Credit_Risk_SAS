/* Importing Macroeoconomics Data from GDrive*/


* Setup the head format;
%let mac_head = 
                 _Rate    date : ddmmyy10.  Rate_MDT   TNF_MDT    GDP    GDP_MDT  
                 _HS      HS_MDT            _UMP       UMP_MDT    _PPI   PPI_MDT        
                 _Permits HOP_MDT           _Payroll   HPI        _HPI_MDT      
;

* Gernate the URL;

%let id = %nrstr(1iindNDXZyr_5Rowfc_RZxa-NTSxE1eab);
%let _url = %nrstr(https://docs.google.com/uc?export=download&id=)&&id;

filename url_file url "&_url";

data DATA.macros;
  infile url_file dsd firstobs = 2;
  format date mmddyy8.;
  input &mac_head;

  if date ge '01JAN2006'd;
  drop _:;
run;