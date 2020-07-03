/* Author: Zheng */
/* Purpose: Generate the marginal PD from transition matrix */


%macro transition_matrix(input, output, date = yqtr, response = SDQ, plot = TRUE);

  proc sort data = &input nodupkey out = tmp;
    by &date;
  run;
  proc contents data = tmp varnum noprint out = var_list(keep = name);
  run;
  data _null_;
    set var_list end = last;
    where name ^in("curr_stat" "&date");
    call symputx('var'||left(_n_), name);
    if last then call symputx('n', _n_);
  run;
  %let var = ;
  %do i = 1 %to &n;
    %let var = &var &&var&i;
  %end;

  data tmp;
    set tmp;
    by &date;
    array initial &var;
    if first.&date then do _i = 1 to &n;
      curr_stat = scan("&var", _i);
      do _j = 1 to &n;
        initial[_j] = 0;
      end;
      output;
    end;
    drop _:;
  run;

  data tmp;
    merge tmp(in = a) &input.(in = b);
    by &date curr_stat;
    if a;
  run;

  



%mend transition_matrix;


%transition_matrix(PD_DATA.prime, prime);



/* data tmp; */
/*   set PD_DATA.out_del(in = d) PD_DATA.out_cur(in = c); */
/*   if d then _to = "DEL_to_"; */
/*   if c then _to = "CUR_to_"; */
/*   state = cat(_to, next_stat); */
/*   where orig_dte < "30Mar2016"d; */
/*   if 0 < &seg < &score then group = "sub-prime"; */
/*     if &score <= &seg then group = "prime"; */
/* run; */
/*  */
/* proc sort data = tmp(keep = act_date yqtr loan_id state group); */
/*   by loan_id act_date; */
/* run; */
/*  */
/* proc sort data = tmp; */
/*   by act_date; */
/* run; */
/*  */
/* data _tmp; */
/*   set PD_DATA.out_del; */
/*   where orig_dte < "30Mar2016"d; */
/*   if 0 < &seg < &score ;run; */
/*  */
/* proc sort data =_tmp; */
/*   by loan_id yqtr; */
/* run; */
/*  */
/* proc freq data = tmp(where = (group = "sub-prime")); */
/* table yqtr*state; */
/* run; */