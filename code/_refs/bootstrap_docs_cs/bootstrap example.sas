
%let MacroPath = H:\macros and functions;
%include "&MacroPath\MACRO_resample_V3.sas";

%let datpath = H:\TestData;

proc import datafile = "&datpath\clslowbwt.csv" replace
            out = clslowbwt
			dbms = csv;
run;

*
this will create a dataset (_resample_out_) with 500 bootstrap draws 
from clslowbwt.

two new variables are added:
1) bootUnit = the new subject identifier
2) replicate = identifies specific bootstrap samples

!!!!! the old ID variable is still included, BUT YOU CAN NOT US IT IN THIS DATA FOR STATISTICS!!!!!!!!!!!
;
%resample(data=clslowbwt
        , out=_resample_out_
        , subject= ID
        , reps= 500
        , strata=
        , seed=12345
        , bootUnit=bootUnit
        , repName = replicate
);

proc contents varnum data = _resample_out_;
run;

* analysis of the original data ;
proc gee data = clslowbwt desc;
  class id;
  model low = age lwt smoke  / dist = bin;
  repeated subject = id /type = exch;
run;


* bootstrap analysis ;

** to prevent log and display from being filled up;
options nonotes;
ods select none;


** extract model estimates by replicate;
ods output GEEEmpPEst = bootRes;
proc gee data = _resample_out_ desc;
  by replicate;
  class bootunit;
  model low = age lwt smoke  / dist = bin;
  repeated subject = bootunit /type = exch;
run;

option notes;
ods select all;

* bootstrap estimated standard error ;
proc means data = bootres nway;
  class parm;
  var estimate;
run;

* stratified bootstrapping: by race - just 5 reps for a demo;
%resample(data=clslowbwt
        , out=_resample_out_STRAT
        , subject= ID
        , reps= 5
        , strata=race
        , seed=12345
        , bootUnit=bootUnit
        , repName = replicate
);


*
Here you will see that the number of subjects in the 
bootstrap samples remains constant within strata (and the same as the original data)
but the number of distinct original IDs varies (as it should)
;

proc sql;

title "N subjects and measures in the original data";
select race, 
       count(distinct ID) as person_Count,
	   count(*) as measurement_Count
   from clslowbwt
   group by race;

title "N subjects and measures in the bootstrapped data";
select race, replicate, 
       count(distinct bootunit) as bootstrap_person_Count,
       count(distinct ID) as original_ID_Count,
	   count(*) as measurement_Count
   from _resample_out_STRAT
   group by race , replicate;
quit;

