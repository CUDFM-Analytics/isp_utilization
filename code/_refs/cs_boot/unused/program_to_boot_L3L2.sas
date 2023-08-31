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
%include "&projRoot\code\MACRO_L3BootL2SRS.sas";

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

* random seeds ;
data _null_;

  call streaminit(&seed);
  
  call symputx("seed_1_", round(rand('UNIFORM', 0, 1) * 1000000000, 1));
  call symputx("seed_2_", round(rand('UNIFORM', 0, 1) * 1000000000, 1));

run;

ods select none;
/*%resample(data=&data
        , out=_resample_out_
        , subject= ID
        , reps= &N
        , strata= 
        , seed=&seed
        , bootUnit=bootUnit
        , repName = replicate
        , samprate = 0.5
);
*/
%L3L2Resample(
  data = &data/* data to dootstrap */,
  out  = _resample_out_ /* output data name */,
  level3 = practice /* name of the level3 variable (such as practice) */,
  level2 = ID/* name of the level2 variable (such as patient) */,
  strata = /* variable to define strata to sample within, the effect is to bootstrap BY each level of the variable */,
  reps =   &N/* desired number of bootstrap replicates */,
  seed1 = &seed_1_ /* seed number for L3 random sampling, default is 0, causes every run to create a unique result */,
  seed2 = &seed_2_ /* seed number for L2 random sampling, default is 0, causes every run to create a unique result */,
  L3BootId= L3_id /* Names a column that makes each booted unit unique (if a subject is selected twice the boot unit column 
                         will have different IDs for each instance (default = L3_id) */,
  L2_SampRate =.5 /* sampling rate of level 2 ids */
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
   class L3_id ID gender rethnic pmca_cat emanc_yr;
   model pvar = relmonth relzero ageEmanc gender rethnic pmca_cat emanc_yr / dist = binomial link = logit;
   repeated subject = L3_id*ID;
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
   class L3_id ID gender rethnic pmca_cat emanc_yr;
   model cvar = relmonth relzero ageEmanc gender rethnic pmca_cat emanc_yr / dist = gamma link = log;
   repeated subject = L3_id*ID;
   store out.cost_stored_&i;
run;
ods select all;
options notes;
