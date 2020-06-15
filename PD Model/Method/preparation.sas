/* Author: Jonas */
/* Purpose: Prepare the dataset for further analysis */



%put DATA VALIDATION;

/*    
* data validataion;

filename ACQid "&p_acq/ACQ_IDsample.csv";

data id_sample;
  infile ACQid dsd firstobs = 2;
  input tran_flg loan_id:$12.;
  keep loan_id;
  if tran_flg = 1;
run;

proc sort data = id_sample;
  by loan_id;
run;

proc sort data = data.sample out = id_sample2(keep=loan_id) nodupkey;
  by loan_id;
run;

proc compare base = id_sample compare = id_sample2;
run;
*/



/*

proc freq data = data.sample;
  table zb_code dlq_stat;
run;

*/



%put ----------------------------------------------------------------- DATA PREPARATION ;

%macro prep();

  proc sort data = DATA.sample(drop = orig_rt zb_date)
            out = PD_DATA.loan;
    by loan_id;
  run;
  
  
  
  * Prepare the data: create a new status variable;
  data PD_DATA.loan tmp_id(keep = loan_id curr_stat 
                           rename = (loan_id = _id curr_stat = Next_stat)
                           );
    set PD_DATA.loan;
    attrib Curr_stat length = $3.
                     label = "Current State"
                     ;
    
    
    
    by loan_id;
    retain _def 0;
    retain _start;
    
    if first.loan_id then do;            
      _def = 0;
      _start = loan_age;
    end;
    
    if _def then delete;
    
    if ^_def then do;
      if dlq_stat = 0 then
        Curr_stat = "CUR";
      else if dlq_stat le 3 then
        Curr_stat = "DEL";
      else if dlq_stat = 999 and zb_code in ("01" "06") then
        Curr_stat = "PPY";
      else _def = 1;
    end;
    if _def then Curr_stat = "SDQ";
    
    if mod(loan_age - _start, 3) = 0 then output PD_DATA.loan tmp_id;
      else if last.loan_id then output PD_DATA.loan tmp_id;
    
  run;
  
  
/*   proc print data = PD_DATA.loan (obs = 1000); */
/*     var loan_id Curr_stat _def; */
/*     where Curr_stat = "SDQ"; */
/*   run; */
  
  data PD_DATA.loan(drop = _:);
    merge PD_DATA.loan tmp_id(firstobs = 2);
    attrib Next_stat length = $3.
                     label = "Next State"
                     ;
    if loan_id ne _id then next_stat = "";
  run;
  
  
  
  data _final(drop = curr_stat);
    set PD_DATA.loan(keep = loan_id curr_stat);
    by loan_id;
    attrib Final_stat length = $3.
                     label = "Final State"
                     ;
    
    if last.loan_id then do;
      Final_stat = curr_stat;
      output;
    end;
  run;
  
  * Grouping the FICO;
  
  data PD_DATA.loan;
    merge PD_DATA.loan _final;
    by loan_id;
    length fico $10;
    if 0 < cscore_b < 670 then
      fico = 'Sub-Prime';
    if 670 <=cscore_b then
      fico = 'Prime';
    
    drop dlq_stat zb_code;
  run;
  
  

%mend prep;



* UN-comment this code to run the prepration function;

%prep()






%put ----------------------------------------------------------------- DATA SUMMARY;

%macro summary();
  
  * ODS powerpoint output;
  ods powerpoint file = "&p_pdres/summary.ppt"
                 style = Sapphire;
  
  ods graphics on / width=4in height=2in;
  
  options nodate;
  
  ods powerpoint exclude all;
  
  
  /*
  
  * Freq table: calculate the PD;
  ods output CrossTabFreqs = _freq1(keep = next_stat final_stat _type_ rowpercent
                                    where = (_type_ = "11" and final_stat = "SDQ")
                                    );
  proc freq data = PD_DATA.cur;
    table Next_stat*final_stat;
  run;
  
  
  ods output CrossTabFreqs = _freq2(keep = next_stat final_stat _type_ rowpercent
                                    where = (_type_ = "11" and final_stat = "SDQ")
                                    );
  proc freq data = PD_DATA.del;
    table Next_stat*final_stat;
  run;
  
  data _tmp1;
    merge _freq1(keep = next_stat rowpercent
                 rename = (rowpercent = CUR)
                 )
          _freq2(keep = next_stat rowpercent
                 rename = (rowpercent = DEL)
                 );
    by next_stat;
  run;
  
  */
  
  * Historical Transition Rate;
  
  ods output OneWayFreqs = _freq1(keep = next_stat percent);
  proc freq data = PD_DATA.cur;
    table Next_stat;
  run;
  
  ods output OneWayFreqs = _freq2(keep = next_stat percent);
  proc freq data = PD_DATA.del;
    table Next_stat;
  run;
  
  data _tmp1;
    merge _freq1(rename = (percent = CUR))
          _freq2(rename = (percent = DEL));
    by next_stat;
  run;
  
  proc transpose data = _tmp1
                 prefix = stat
                 out = _tmp2;
  run;
  
  * Concatenate tables: data for bar chart;
  data _tmp3;
    set _freq1(in = a) _freq2(in = b);
    if a then stat = "CUR";
    if b then stat = "DEL";
    keep stat next_stat percent;
  run;
  
  
  proc sort data = PD_DATA.origin(where = (curr_stat in ("CUR" "DEL"))
                                  keep = curr_stat oltv dti cscore_b) out = _box;
    by curr_stat;
  run;
  
  
  ods powerpoint exclude none;
  
  title "Competing Risk Transition Matrix(%)";
  footnote "";
  proc report data = _tmp2;
    columns _name_ ('Next State'(stat1 stat2 stat3 stat4));
    define _name_ / "Current State";
    define stat1 / "Current (CUR)";
    define stat2 / "Delinquent (DEL)";
    define stat3 / "Prepay (PPY)";
    define stat4 / "Default (SDQ)";
  run;
  title;
  
  title "Historical Transition Rate";
  proc sgplot data = _tmp3;
    vbar next_stat/ response = percent group = stat
                    groupdisplay = cluster nooutline;
    styleattrs datacolors = (cx9ecae1 cx3182bd);
    keylegend / title = "Current State";
    yaxis label = "Probability of Default(%)"
          grid  gridattrs = (color = 'cxdeebf7');
  run;
  title;
  
  ods graphics on / width=3in height=4in;
  
  title "Box Plot for Loan-level Drivers";
  proc boxplot data = _box;
    plot (oltv dti cscore_b)*curr_stat / name = '' boxstyle = schematic 
      outbox = _outbox(where = (_type_ in ("FARLOW" "LOW"))) ;
    
    inset min mean(5.0) max/
        header = 'Overall Statistics'
        pos    = tm;
  run;
  title;
  
  ods powerpoint exclude all;
  
  ods output MissingValues = _misscur(keep = varname countnobs count);
  proc univariate data = PD_DATA.cur;
    var oltv dti cscore_b;
  run;
  ods output MissingValues = _missdel(keep = varname countnobs count);
  proc univariate data = PD_DATA.del;
    var oltv dti cscore_b;
  run;
  
  
  ods output CrossTabFreqs = _freq3(keep = curr_stat _var_ _type_ _type_2 frequency
                                    where = (_type_2 = "111"));
  proc freq data = _outbox;
    table curr_stat*_var_*_type_ / nocol nopercent;
  run;
  
  
  data _null_;
    if 0 then set PD_DATA.cur(keep = loan_id) nobs = n;
    call symputx('ncur', n);
    stop;
  run;
  
  data _null_;
    if 0 then set PD_DATA.del(keep = loan_id) nobs = n;
    call symputx('ndel', n);
    stop;
  run;
  
  data _missadd;
    input Curr_stat $ varname $ _Type_ $ count;
    datalines;
    CUR Oltv MISSING 0
    DEL Oltv MISSING 0
    ;
  run;
  
  data _miss;
    set _misscur(in = a) _missdel(in = b) _missadd;
    _type_ = "MISSING";
    if a then curr_stat = "CUR";
    if b then curr_stat = "DEL";
  run;
  
  data _tmp1;
    set _freq3(drop = _type_2) _miss(rename = (varname = _var_ count = frequency) drop = countnobs);
    format cntout percent9.4;
    if curr_stat = "CUR" then cntout = frequency/&ncur;
    if curr_stat = "DEL" then cntout = frequency/&ndel;
    freq = trim(left(put(frequency,8.))) || " " || "(" || trim(left(put(cntout,percent9.4))) || ")";
    drop frequency cntout;
  run;
  
  proc sort data = _tmp1;
    by curr_stat _var_ _type_;
  run;
  
  proc transpose data = _tmp1(where = (curr_stat = "CUR")) out = _tbcur(drop = _name_);
    id _type_;
    by _var_;
    var freq;
  run;
  
  proc transpose data = _tmp1(where = (curr_stat = "DEL")) out = _tbdel(drop = _name_);
    id _type_;
    by _var_;
    var freq;
  run;
  
  data _tbcur;
    set _tbcur;
    select (_var_);
      when("Cscore_b") _var = "FICO";
      when("Dti") _var = "DTI";
      when("Oltv") _var = "OLTV";
    end;
    drop = _var_;
  run;
  
  data _tbdel;
    set _tbdel;
    select (_var_);
      when("Cscore_b") _var = "FICO";
      when("Dti") _var = "DTI";
      when("Oltv") _var = "OLTV";
    end;
    drop = _var_;
  run;
  
  
  ods powerpoint exclude none;
  
  title "Frequency Table of Outliers and Missing Value";
  footnote j=l "Current State = CUR";
  proc report data = _tbcur;
    columns _var ("Outlier" (low farlow)) missing;
    define _var / "Variable";
    define low / "Low";
    define farlow / "Low Far";
    define missing / "Missing Value";
  run;
  footnote j=l "Current State = DEL";
  proc report data = _tbdel;
    columns _var ("Outlier" (low farlow)) missing;
    define _var / "Variable";
    define low / "Low";
    define farlow / "Low Far";
    define missing / "Missing Value";
  run;
  title;
  footnote;
  ods powerpoint exclude all;
  /* proc means data = _outbox (where = (_type_ in ("FARLOW" "LOW") and _var_ in ("Oltv" "Cscore_b"))); */
  /*   var _value_; */
  /*   by _type_; */
  /* run; */
  
  
  /* 
  proc sgscatter data = PD_DATA.del;
    matrix oltv dti cscore_b / diagonal = (histogram kernel);
  run;
  */
  
  ods powerpoint close;

%mend summary;





* DON'T run this;

/* %summary(); */




%put ----------------------------------------------------------------- FORMAT;

%macro format();
  proc format lib = PD_DATA;
    value fico low -< 620 = '[0-620)'
               620 -< 660 = '[620-660)'
               660 -< 700 = '[660-700)'
               700 -< 740 = '[700-740)'
               740 -< 780 = '[740-780)'
               780 - high = '[780+)'
    ;
  run;
%mend format;

/* %format() */


%put ----------------------------------------------------------------- DATA MERGING;


%macro merge();

  * Merge the loan-level data with macros by date;
  
  proc sort data = DATA.macros out = work.macros;
    by date;
  run;
  
  * Creat the orig_hpi;
  proc sort data = PD_DATA.loan out = PD_DATA.tmp_loan;
    by orig_dte;
  run;
  
  data PD_DATA.tmp_loan;
    merge PD_DATA.tmp_loan work.macros(keep = date hpi rename = (date = orig_dte));
    by orig_dte;
    rename hpi = orig_hpi;
  run;
  
  proc sort data = PD_DATA.tmp_loan tagsort;
    by act_date;
  run;
  
  data PD_DATA.data;
    merge PD_DATA.tmp_loan work.macros(rename = (date = act_date));
    by act_date;
    
    if missing(act_upb) then CLTV = oltv;
      else CLTV = oltv*(orig_hpi/hpi)*(act_upb/orig_amt);
      
    if ^missing(loan_id);
  run;
  

%mend merge;



* Merging the lona-level and macros data;

/* %merge(); */



%put ----------------------------------------------------------------- DATA GROUPING;
  
data PD_DATA.cur PD_DATA.del;
  set PD_DATA.data;
  if ^missing(next_stat);
  if Curr_stat = "CUR" then output PD_DATA.cur;
  if Curr_stat = "DEL" then output PD_DATA.del;
run;



proc datasets lib = PD_DATA nolist;
  delete tmp_:;
run;


quit;



    
    
    
    
    
    
    