/* Author: Zheng */
/* Purpose: Generate the marginal PD from transition matrix */

%macro transition_matrix(input, output,                   /* input and output dataset */
                         date = yqtr,                     /* name of date variable */
                         initial = CUR,                   /* initial state: set up to 100% */
                         response = SDQ,                  /* response variable */
                         absorb = SDQ PPY,                /* absorbing state */
                         plot = 1)                        /* options: 1 for True, 0 for False */
                         / minoperator;  

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
  %let n_a = ;
  %do i = 1 %to &n;
    %let var = &var &&var&i;
    %if &&var&i in &absorb %then %do;
      %let n_a = &n_a &i;
    %end;
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
    cum_pd = repeat(0, &n)`;
    PD = {0};
    sur = {1};
    Prob = {};
    do i = 1 to size/&n;
      m = N[&n*(i-1)+1 : &n*i,];
      State = m`*State;
      if i < size/&n then do;
        do j = 1 to &n;
          v1 = R[&n*i+1 : &n*(i+1)];
          tmp_pd = m[j,]*v1;
          cum_pd = cum_pd || tmp_pd;
        end;
        PD = PD || cum_pd[&n*i+1 : &n*(i+1)]`*State;
        sur = sur || 1 - sum(State[{&n_a}]);
        Prob = Prob || (PD[i+1] - PD[i]) / sur[i];
      end;
    end;
    Prob = Prob`;
    N = &date || N || cum_pd`;
    create &output from N[c = {"Date" "&L_var" "Conditional"}];
      append from N;
    close &output;
    
    create plot_pd from Prob[c = {"Prob"}];
      append from Prob;
    close plot_pd;
  quit;

* Generate the output dataset;
  data &output;
    set &output;
    format date &f_date..;
  run;
  data &output._plot;
    set plot(firstobs = 2);
    set plot_pd;
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
%transition_matrix(PD_DATA.prime, prime_ppy, response = PPY);
%transition_matrix(PD_DATA.sub_prime, sub_prime_sdq);
%transition_matrix(PD_DATA.sub_prime, sub_prime_ppy, response = PPY);


quit;