*****************************************************************************************
DATE CREATED: 3/29/2023

PROGRAMMER  : Carter Sevick

PURPOSE     : define the bootstrap process to parallelize 

NOTES       :

UPDATES     :

*****************************************************************************************;

%let projRoot = M:\Carter\Examples\boot total cost;

* location for bootstrap products ;

libname out "&projRoot\dataProcessed";

* location of input data to boot ;
libname in "&projRoot\dataRaw";

* data to boot ;
%let data = in.studyDat ;

* include macro programs ;
%include "&projRoot\code\MACRO_resample_V4.sas";

* get process parameters ;

** process number ;
%let    i = %scan(&SYSPARM,1,%str( ));

** seed number ;
%let    seed = %scan(&SYSPARM,2,%str( ));

** N bootstrap samples ;
%let    N = %scan(&SYSPARM,3,%str( ));
 
*
Draw bootstrap samples 

two new variables are added:
1) bootUnit = the new subject identifier
2) replicate = identifies specific bootstrap samples

!!!!! the old ID variable is still included, BUT YOU CAN NOT US IT IN THIS DATA FOR STATISTICS!!!!!!!!!!!
;


ods select none;
%resample(data=&data
        , out=_resample_out_
        , subject= ID
        , reps= &N
        , strata= 
        , seed=&seed
        , bootUnit=bootUnit
        , repName = replicate
        , samprate = 0.5
);

* save a copy of the booted data ;
data out._resample_out_&i;
  set _resample_out_;
run;

* run models and output store objects ;

* probability model ;
ods select none;
options nonotes;
proc genmod data = _resample_out_ desc;
   by replicate;
   class bootunit ID gender rethnic pmca_cat emanc_yr;
   model pvar = relmonth relzero ageEmanc gender rethnic pmca_cat emanc_yr / dist = binomial link = logit;
   repeated subject = bootunit;
   store out.prob_stored_&i;
run;
ods select all;
options notes;

* cost model ;
ods select none;
options nonotes;
proc genmod data = _resample_out_  ;
   by replicate;
   where cvar >0;
   class bootunit ID gender rethnic pmca_cat emanc_yr;
   model cvar = relmonth relzero ageEmanc gender rethnic pmca_cat emanc_yr / dist = gamma link = log;
   repeated subject = bootunit;
   store out.cost_stored_&i;
run;
ods select all;
options notes;
