/*
  programmer: Carter Sevick
  Purpose   : create a general resampling macro, intention is for bootstrapping

parameters  : data    = data set to be resampled,
              out     = resample results, 
              subject = identification of sampling units, if a subject has multiple rows all are selected into the sample
              reps    = desired number of replicates,
              seed    = seed number for random sampling, default is 0, causes every run to create a unique result
              strata  = variable to define strata to sample within, the effect is to bootstrap BY each level of the variable 
              bootUnit = Names a column that makes each booted unit unique (if a subject is selected twice the boot unit column 
                         will have different IDs for each instance (default = bootUnit)
              repName = provide a name to the replicate column from SURVEYSELECT
              samprate = [0 - 1] proportion of the data to be drawn in the bootstrap. if also using the STRATA arg then a list to specify strata specific sampling rates 
                         may be entered or a SAS dataset name. if entering a list the proportions must be in sorted order of the strata. See PROC SURVEY SELECT for more details 
              lightSort = YES - if YES (default) then sorting of the final data (when using cluster bootstrap) is only on the replicate column and hadbled by PROC SORT using the TAGSORT option.

update      : 9 APR 2015 -  add a default data output name
                            made 'subject' an option
                            Now RESAMPLE can create a normal bootstrap, or one with clustered data
                            The sub-macro RESAMPLEBASIC performs the basic bootstrap sample
                            common macro arguments have the same function
            : 5 OCT 2015 -  STRATA= argument added to reSampleBasic
  
            : 27 Dec 2017 - Column added to make booted units unique, this is necessary if your statistical method
                            makes use of a subject ID (such as a mixed model 
                          - added an argument to rename the replicate column
                          - worked the STRATA argument into the main macro
            : 12 April 2023 - added samprate and lightSort arguments.
*/
 

%macro reSampleBasic(data=,out=,seed=0,reps=, strata=, bootUnit=bootUnit, samprate=1);
* select N replicates from the data ;
proc surveyselect data=&data out=&out seed=&Seed method=urs samprate=&samprate outhits rep=&reps;
%if %scan(&strata,1) ne %then %do; strata &strata; %end;
run;

proc sort data = &out;
  by replicate &strata ;
run;

data &out;
  set &out;
  by replicate &strata ;
  if first.replicate then &bootUnit=1;
  else &bootUnit+1;
run;

%mend;

%macro resample(data=, out=_resample_out_, subject=, reps=, strata=, seed=0, bootUnit=bootUnit, repName = replicate, samprate=1, lightSort = NO);

%if &subject = %str() %then %do;

* select N replicates from the data ;
%reSampleBasic(data=&data,out=&out,seed=&seed,reps=&reps, strata=&strata, bootUnit=&bootUnit, samprate=&samprate);

%end;

%else %do;

* create a list of the unique sampling units (needed if this is repeated sampling) ;
proc sort data = &data (keep = &strata &subject) out = _dedup_ nodupkey;
  by &strata &subject;
run;

* select N replicates from the data ;
%reSampleBasic(data=_dedup_,out=&out._tmp,seed=&seed,reps=&reps, strata=&strata, bootUnit=&bootUnit, samprate=&samprate);

* final selection of rows and replicate group assignment ;
proc sql;

create table &out as
  select a.replicate as &repName, 
         a.&bootUnit, 
         b.*
  from &out._tmp as a inner join &data as b
    on a.&subject = b.&subject
	%if %scan(&strata,1) ne %then %do; and a.&strata = b.&strata %end;
    %if %upcase(&lightSort) NE YES %then %do;
  order by &repName, 
             &bootUnit
         %if %scan(&strata,1) ne %then %do; ,b.&strata %end;
    %end;
  ;
quit;
%if %upcase(&lightSort) = YES %then %do;

proc sort data = &out tagsort;
  by &repName;
run;

%end;

* clean up your mess! ;
proc datasets library = work nolist;
  delete _dedup_ &out._tmp;
  run;
quit;/**/
%end;

%mend;


 
