/* Author: Zheng */
/* Purpose: Generate the marginal PD from transition matrix */

%macro transition_matrix(input, output,                   /* input and output dataset */
                         date = yqtr,                     /* name of date variable */
                         initial = CUR,                   /* initial state: set up to 100% */
                         response = SDQ,                  /* response variable */
                         absorb = 1, plot = 1);           /* options: 1 for True, 0 for False */

* Prepare the input dataset;
  proc sort data = &input nodupkey out = plot(keep = &date);
    by &date;
  run;
  proc sort data = &input out = tmp;
    by &date curr_stat;
  run;
  proc contents data = tmp varnum noprint out = var_list(keep = name format);
  run;
  data _null_;
    set var_list end = last;
    where name ^in("curr_stat");
    if name ne "&date" then
      do;
        call symputx('var'||left(_n_), name);
        if name eq "&initial" then call symputx('n_i', _n_);
        if name eq "&response" then call symputx('n_r', _n_);
      end;
      else call symputx('f_date', format);
    if last then call symputx('n', _n_-1);
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
  
* Calculate the conditional probability;
  %let V_var = %sysfunc(tranwrd(%quote(&var), %str( ), %str(||)));
  %let L_var = %sysfunc(tranwrd(%quote(&var), %str( ), %str(" ")));
  proc iml;
    use tmp;
    read all;

    N = &V_var;
    R = &response;
    State = repeat(0, &n);
    State[&n_i] = 1;
    size = nrow(N);
    Con_pd = repeat(0, &n)`;
    PD = {0};
    
    do i = 1 to size/&n;
      m = N[&n*(i-1)+1 : &n*i,];
      State = m`*State;
      if i < size/&n then do;
        do j = 1 to &n;
          v0 = R[&n*(i-1)+1 : &n*i];
          v1 = R[&n*i+1 : &n*(i+1)];
          t = v0[j];
          %if &absorb %then %do;
            if j = &n_r then tmp_pd = m[j,]*v1;
              else tmp_pd = m[j,]*v1/(1-v0[j]);   /* ? */
          %end;
          %else %do;
            tmp_pd = m[j,]*v1/(1-v0[j]);
          %end;
          Con_pd = Con_pd || tmp_pd;
        end;
        PD = PD || Con_pd[&n*i+1 : &n*(i+1)]`*State;
      end;
    end;
    PD = PD`;
    N = &date || N || Con_pd`;
    create &output from N[c = {"Date" "&L_var" "Conditional"}];
      append from N;
    close &output;
    
    create plot_pd from PD[c = {"Prob"}];
      append from PD;
    close plot_pd;
  quit;

* Generate the output dataset;
  data &output;
    set &output;
    format date &f_date..;
  run;
  data &output._plot;
    set plot;
    set plot_pd;
    if _n_ ne 1;
    format prob percent10.4;
  run;

* Plot the probability chart;
  %if &plot %then %do;
    title "Predicted probability of &response";
    footnote j = l "Data: &input";
    proc sgplot data = &output._plot;
      series x = &date y = prob;
      xaxis label = "Time" grid;
      yaxis label = "Propability of &response (%)" grid;
    run;
    title;
    footnote;
  %end;
%mend transition_matrix;


%transition_matrix(PD_DATA.prime, prime_sdq);
/* %transition_matrix(PD_DATA.prime, prime_ppy, response = PPY); */
%transition_matrix(PD_DATA.sub_prime, sub_prime_sdq);
/* %transition_matrix(PD_DATA.sub_prime, sub_prime_ppy, response = PPY); */


quit;