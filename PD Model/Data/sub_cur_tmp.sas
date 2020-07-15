*****************************************;
** SAS Scoring Code for PROC Logistic;
*****************************************;

length I_Next_stat $ 3;
label I_Next_stat = 'Into: Next_stat' ;
length U_Next_stat $ 3;
label U_Next_stat = 'Unnormalized Into: Next_stat' ;
label P_Next_statDEL = 'Predicted: Next_stat=DEL' ;
label P_Next_statPPY = 'Predicted: Next_stat=PPY' ;
label P_Next_statSDQ = 'Predicted: Next_stat=SDQ' ;
label P_Next_statCUR = 'Predicted: Next_stat=CUR' ;

drop _LMR_BAD;
_LMR_BAD=0;

*** Check interval variables for missing values;
if nmiss(Dti,Cscore_b,Orig_amt,Curr_rte,UPB,Loan_age,GDP,HS,HPI,PPI) then do;
   _LMR_BAD=1;
   goto _SKIP_000;
end;

*** Compute Linear Predictors;
drop _LP0 _LP1 _LP2;
_LP0 = 0;
_LP1 = 0;
_LP2 = 0;

*** Effect: Dti;
_LP0 = _LP0 + (0.01265556705454) * Dti;
_LP1 = _LP1 + (-0.00188983884122) * Dti;
_LP2 = _LP2 + (0.06750842388858) * Dti;
*** Effect: Cscore_b;
_LP0 = _LP0 + (-0.01020315828791) * Cscore_b;
_LP1 = _LP1 + (0.00175660654575) * Cscore_b;
_LP2 = _LP2 + (0.05326049130449) * Cscore_b;
*** Effect: Orig_amt;
_LP0 = _LP0 + (-1.0020443759609E-7) * Orig_amt;
_LP1 = _LP1 + (1.8919057345734E-6) * Orig_amt;
_LP2 = _LP2 + (-4.4332381886456E-6) * Orig_amt;
*** Effect: Curr_rte;
_LP0 = _LP0 + (0.26754385669235) * Curr_rte;
_LP1 = _LP1 + (0.4015343568149) * Curr_rte;
_LP2 = _LP2 + (-0.24051260899688) * Curr_rte;
*** Effect: UPB;
_LP0 = _LP0 + (5.05915980534172) * UPB;
_LP1 = _LP1 + (-1.20461684983128) * UPB;
_LP2 = _LP2 + (31.0473605376655) * UPB;
*** Effect: Loan_age;
_LP0 = _LP0 + (0.01537390786954) * Loan_age;
_LP1 = _LP1 + (0.00234118600865) * Loan_age;
_LP2 = _LP2 + (0.0908903497225) * Loan_age;
*** Effect: GDP;
_LP0 = _LP0 + (-0.00004014558879) * GDP;
_LP1 = _LP1 + (0.0004363941255) * GDP;
_LP2 = _LP2 + (0.00048891889135) * GDP;
*** Effect: HS;
_LP0 = _LP0 + (-0.00103145089005) * HS;
_LP1 = _LP1 + (0.00034970038235) * HS;
_LP2 = _LP2 + (-0.00899763698575) * HS;
*** Effect: HPI;
_LP0 = _LP0 + (0.00739183721191) * HPI;
_LP1 = _LP1 + (-0.04502254279124) * HPI;
_LP2 = _LP2 + (0.04432082679274) * HPI;
*** Effect: PPI;
_LP0 = _LP0 + (-0.00066749089931) * PPI;
_LP1 = _LP1 + (-0.02055471307401) * PPI;
_LP2 = _LP2 + (-0.03903684129961) * PPI;

*** Predicted values;
drop _LPMAX _MAXP _IY _P0 _P1 _P2 _P3;
_LPMAX= 0;
_LP0 =    -3.67587048260099 + _LP0;
if _LPMAX < _LP0 then _LPMAX = _LP0;
_LP1 =    -2.14343494327142 + _LP1;
if _LPMAX < _LP1 then _LPMAX = _LP1;
_LP2 =    -78.2436230597316 + _LP2;
if _LPMAX < _LP2 then _LPMAX = _LP2;
_LP0 = exp(_LP0 - _LPMAX);
_LP1 = exp(_LP1 - _LPMAX);
_LP2 = exp(_LP2 - _LPMAX);
_LPMAX = exp(-_LPMAX);
_P3 = 1 / (_LPMAX + _LP0 + _LP1 + _LP2);
_P0 = _LP0 * _P3;
_P1 = _LP1 * _P3;
_P2 = _LP2 * _P3;
_P3 = _LPMAX * _P3;
P_Next_statDEL = _P0;
_MAXP = _P0;
_IY = 1;
P_Next_statPPY = _P1;
if (_P1 >  _MAXP + 1E-8) then do;
   _MAXP = _P1;
   _IY = 2;
end;
P_Next_statSDQ = _P2;
if (_P2 >  _MAXP + 1E-8) then do;
   _MAXP = _P2;
   _IY = 3;
end;
P_Next_statCUR = _P3;
if (_P3 >  _MAXP + 1E-8) then do;
   _MAXP = _P3;
   _IY = 4;
end;
select( _IY );
   when (1) do;
      I_Next_stat = 'DEL' ;
      U_Next_stat = 'DEL' ;
   end;
   when (2) do;
      I_Next_stat = 'PPY' ;
      U_Next_stat = 'PPY' ;
   end;
   when (3) do;
      I_Next_stat = 'SDQ' ;
      U_Next_stat = 'SDQ' ;
   end;
   when (4) do;
      I_Next_stat = 'CUR' ;
      U_Next_stat = 'CUR' ;
   end;
   otherwise do;
      I_Next_stat = '';
      U_Next_stat = '';
   end;
end;
_SKIP_000:
if _LMR_BAD = 1 then do;
I_Next_stat = '';
U_Next_stat = '';
P_Next_statDEL = .;
P_Next_statPPY = .;
P_Next_statSDQ = .;
P_Next_statCUR = .;
end;
