*****************************************************************************************
DATE CREATED: 3/29/2023

PROGRAMMER  : Carter Sevick

PURPOSE     : define the bootstrap process to parallelize 

NOTES       :

UPDATES     :

*****************************************************************************************;

%let projRoot = X:\Jake\other\IBH\cost and utilization;

* location for bootstrap products ;

libname out "&projRoot\dataProcessed";

* location of input data to boot ;
libname in "&projRoot\analytic dataset";

* data to boot ;
%let data = in.analyze3h_nofqhc ;

* include macro programs ;
%include "&projRoot\bootstrap and macro code\MACRO_resample_V4.sas";

* get process parameters ;

** process number ;
%let    i = %scan(&SYSPARM,1,%str( ));

** seed number ;
%let    seed = %scan(&SYSPARM,2,%str( ));

** N bootstrap samples ;
%let    N = %scan(&SYSPARM,3,%str( ));



*formats!!;
libname moncost 'X:\HCPF_SqlServer\AnalyticSubset'; 
options fmtsearch=(moncost); 

proc format;
 value yesno 0='No' 1='Yes'; 
 value age7cat 1="0-5" 2="6-10" 3="11-15" 4="16-20" 5="21-44" 6="45-64" 7="65+";
 value budgrN 3="MAGI 69 - 133% FPL" 5="MAGI TO 68% FPL" 6="Disabled" 11="Foster Care" 12="MAGI Eligible Children" 14="Other";
 value rae 3="3" 5="5" 6="6" 99="(1,2,4,7)"; 
 value pdpre 0="No health 1st" 1="0" 2="0-50th pcntl" 3="50th to 75th pcntl" 4="75th to 90th pcntl" 5="90th to 95th pcntl" 6="> 95th pcntl";
 value racej 1="Hispanic/Latino" 2="White/Caucasian" 3="Black/African American" 4="Asian" 5="Other People of Color" 6="Other/Unknown Race";

 value bhonb 0='0' 1='>0';
 value bhont 0='0' 1='(0-1]' 2='>1';
run;
 
*
Draw bootstrap samples 

two new variables are added:
1) bootUnit = the new subject identifier
2) replicate = identifies specific bootstrap samples

!!!!! the old ID variable is still included, BUT YOU CAN NOT US IT IN THIS DATA FOR STATISTICS!!!!!!!!!!!
;

* random seeds ;
/*
data _null_;
  call streaminit(&seed);
  
  call symputx("seed_1_", round(rand('UNIFORM', 0, 1) * 1000000000, 1));
  call symputx("seed_2_", round(rand('UNIFORM', 0, 1) * 1000000000, 1));  
run;*/

ods select none;
%resample(data=&data
        , out=_resample_out_
        , subject= clnt_id
        , reps= &N
        , strata=intervention 
        , seed=&seed
        , bootUnit=bootUnit
        , repName = replicate
		, sampRate = (.25,1)
);


* save a copy of the booted data ;
data out._resample_out_&i;
  set _resample_out_;
run;
