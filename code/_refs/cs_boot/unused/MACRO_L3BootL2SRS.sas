
* 
  programmer: Carter Sevick
  Purpose   : complex boot plan....

MACRO action:
  
1) create a sampling frame of all unique level3 and 2 IDs + strata, if specified
2) create a sampling frame of uniue level 3 IDs
3) create a bootstrap sample of level 3 units, create an identifier to maintain uniquness for those selected more than once
4) create a stratified (by L3) random sample of L2 units
5) inner join the L3 bootstrap to the L2 SRS (by replicate and L3 ID) - associating L2 units with their L3 boot units
6) add all L1 measurements to selected L2 units and output final data 

WARNING: the macro will expect that level 2 is nested within level3 which is nested within any strata. THIS IS NOT CHECKED!!!!!!!
;

%macro L3L2Resample(
  data = /* data to dootstrap */,
  out  = _resample_out_ /* output data name */,
  level3 = /* name of the level3 variable (such as practice) */,
  level2 = /* name of the level2 variable (such as patient) */,
  strata = /* variable to define strata to sample within, the effect is to bootstrap BY each level of the variable */,
  reps =   /* desired number of bootstrap replicates */,
  seed1 = 0 /* seed number for L3 random sampling, default is 0, causes every run to create a unique result */,
  seed2 = 0 /* seed number for L2 random sampling, default is 0, causes every run to create a unique result */,
  L3BootId= L3_id /* Names a column that makes each booted unit unique (if a subject is selected twice the boot unit column 
                         will have different IDs for each instance (default = L3_id) */,
  L2_SampRate =.5 /* sampling rate of level 2 ids */
);

* sampling frames ;
proc sort data = &data(keep = &Level3 &strata &level2) out = _L3L2Ids_ nodupkey;
  by &Level3 &strata &level2;
run;

data _L3Ids_;
  set _L3L2Ids_ (keep = &Level3 &strata);
  by &Level3;
  if first.&Level3;
run;

* sample from L3: boot with replacement ;
%if %scan(&strata,1) ne %then %do;
proc sort data = _L3Ids_;
  by &strata;
run;
%end;
proc surveyselect data=_L3Ids_ out=_L3Sample_ seed=&Seed1 method=urs samprate=1 outhits rep=&reps;
%if %scan(&strata,1) ne %then %do; strata &strata; %end;
run;
data _L3Sample_;
  set _L3Sample_;
  &L3BootID = _n_;
run;

* simple random sample from L2 stratified by L3 ;
proc surveyselect data=_L3L2Ids_ out=_L2Sample_ seed=&Seed2 method=srs samprate=&L2_SampRate rep=&reps;
  strata &Level3 &strata;  
run;

* create final boot data ;
Proc sql;

create table _L3L2Join_ as
  select a.replicate, a.&L3BootID, a.&Level3, b.&Level2
  from _L3Sample_ as a inner join _L2Sample_ as b
    on a.replicate = b.replicate and a.&Level3 = a.&Level3;

create table &out as
  select a.replicate, a.&L3BootID, b.*
  from _L3L2Join_ as a inner join &data as b
    on a.&Level3 = b.&Level3 and a.&Level2 = b.&Level2
  order by a.replicate, a.&L3BootID, b.&Level2 ;

quit;


%mend;
