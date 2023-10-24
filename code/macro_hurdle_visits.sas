**********************************************************************************************
AUTHOR   : KTW
PROJECT  : ISP Utilization
PURPOSE  : Macro, VISIT dv's
VERSION  : 2023-10-22
         : -- added data.intgroup to row 111 ish (no need to do it over and over it is the same each time)
OUTPUT   : pdf & log file

https://stats.oarc.ucla.edu/sas/dae/negative-binomial-regression/
The param=ref option changes the coding from effect coding (default) to reference coding (dummy coding)
The ref=first option changes the reference group to the first level of prog. 
The type3 option is used to get the multi-degree-of-freedom test of cat vars in class statement 
***********************************************************************************************;
%macro hurdle(dat=,      /* data.utilization */
              prob=,     /* probability variable, starts wih `ind_`  */
              visits=,   /* visit DV var, start with `visits_` */
              dv=,       /* used in ranks*/
              type=      /* correlation type (exch, ind were tested) */
              );

/*SECTION 01: INTRO / CONFIG/ DOCUMENTATION*/
OPTIONS pageno=1 linesize=88 pagesize=60 SOURCE;
%LET root  = %qsubstr(%sysget(SAS_EXECFILEPATH), 1, 
             %length(%sysget(SAS_EXECFILEPATH))-%length(%sysget(SAS_EXECFILEname)));
%LET script  = %qsubstr(%sysget(SAS_EXECFILENAME), 1,
               %length(%sysget(SAS_EXECFILENAME))-4); * remove .sas to use in log, pdf;
%LET today = %SYSFUNC(today(), YYMMDD10.);
%LET log   = &root.run_&dv._type_&type._&today..log;

PROC PRINTTO LOG = "&log" NEW; RUN;

/*SECTION 02: PROB MODEL*/
PROC GENMOD DATA  = &dat;
CLASS mcaid_id     
       int(ref='0')         int_imp(ref='0') 
       budget_grp_new(ref='MAGI Eligible Children')
       race(ref='non-Hispanic White/Caucasian')
       sex(ref='Female')
       rae_person_new(ref='3')
       age_cat(ref='ages 21-44') 
       fqhc(ref ='0')
       bh_oth17(ref='0')    bh_oth18(ref='0')       bh_oth19(ref='0')
       bh_er17(ref='0')     bh_er18(ref='0')        bh_er19(ref='0')
       bh_hosp17(ref='0')   bh_hosp18(ref='0')      bh_hosp19(ref='0')
       adj_pd_total_17cat(ref='0')
       adj_pd_total_18cat(ref='0')
       adj_pd_total_19cat(ref='0') 
       &prob;
MODEL &prob(event='1') = int      int_imp     time 
       season1         season2     season3
       budget_grp_new  race        sex         rae_person_new 
       age_cat         fqhc
       bh_oth17        bh_oth18    bh_oth19
       bh_er17         bh_er18     bh_er19
       bh_hosp17       bh_hosp18   bh_hosp19
       adj_pd_total_17cat 
       adj_pd_total_18cat 
       adj_pd_total_19cat / DIST=binomial; 
REPEATED SUBJECT = mcaid_id / type=&type ; 
store out.&dv._pmodel_&type;
output out = predout pred = pred;
run;

/*SECTION 03: POSITIVE VISIT MODEL*/
TITLE 'Visit Model'; 
PROC GENMOD DATA  = &dat desc;
WHERE &visits > 0;
CLASS mcaid_id    
       int(ref='0')         int_imp(ref='0') 
       budget_grp_new(ref='MAGI Eligible Children')
       race(ref='non-Hispanic White/Caucasian')
       sex(ref='Female')
       rae_person_new(ref='3')
       age_cat(ref='ages 21-44') 
       fqhc(ref ='0')
       bh_oth17(ref='0')    bh_oth18(ref='0')       bh_oth19(ref='0')
       bh_er17(ref='0')     bh_er18(ref='0')        bh_er19(ref='0')
       bh_hosp17(ref='0')   bh_hosp18(ref='0')      bh_hosp19(ref='0')
       adj_pd_total_17cat(ref='0')
       adj_pd_total_18cat(ref='0')
       adj_pd_total_19cat(ref='0') ;
MODEL &visits = int      int_imp     time 
       season1         season2     season3
       budget_grp_new  race        sex         rae_person_new 
       age_cat         fqhc
       bh_oth17        bh_oth18    bh_oth19
       bh_er17         bh_er18     bh_er19
       bh_hosp17       bh_hosp18   bh_hosp19
       adj_pd_total_17cat 
       adj_pd_total_18cat 
       adj_pd_total_19cat  / dist=negbin link=log ;
REPEATED SUBJECT = mcaid_id / type = &type;
store out.&dv._vmodel_&type;
RUN;
TITLE; 

/*SECTION 04: AGGREGATING ACTUAL, PREDICTED OUTCOMES W/ GROUP OF INTEREST*/
* OUT:[intgroup]      IN :[&dat &dat]

* the predictions for visits will be made for each person twice, once exposed and once unexposed;
* OUT:[P_INTGROUP]      IN :[out=out.&dv._pmodel]
 prob of util------------------------------------------------ ;
proc plm restore=out.&dv._pmodel_&type;
score data=data.intgroup out=p_intgroup predicted=p_prob / ilink;
run;

* OUT:[VP_INTGROUP]     IN :[out=out.&dv._vmodel]
prob of visit -------------------------------------------------;
proc plm restore=out.&dv._vmodel_&type;
score data=p_intgroup out=VP_intgroup predicted=p_visit / ilink;
run;

* OUT:[out.&dv._mean_&type] IN:[VP_intgroup]
Person average visit is calculated------------------------------;
data out.&dv._mean_&type;
  set VP_intgroup;
  a_visit = p_prob*p_visit;* (1-p term = 0);
run;

* OUT:[out.&dv._avp_&type] IN:[out.&dv._mean_&type]
Group average visit is calculated and contrasted-----------------;
proc sql;
create table out.&dv._avp_&type as
  select mean(case when exposed=1 then a_visit else . end ) as visit_exposed,
         mean(case when exposed=0 then a_visit else . end ) as visit_unexposed,
  calculated visit_exposed - calculated visit_unexposed as visit_diff
  from out.&dv._mean_&type;
quit;

* put AVP results in log for reference/ comparing results;
data _NULL_;
SET  out.&dv._avp_&type; 
put  visit_exposed= visit_unexposed= visit_diff=; 
RUN; 

* DECILE CALIBRATION plot prep/data ==================================================; 

proc rank data = predout out = predgroup groups = 10;
  var pred;
  ranks predgroup;
run;

proc means data = predgroup   noprint nway;
  var pred &prob;
  class predgroup;
  output out = out.&dv._meanout_&type mean = /autoname;
run;

* print results to log for reference; 
data _NULL_;
SET  out.&dv._meanout_&type (DROP= _TYPE_);
/*SET out.visits_pc_meanout_exch (DROP= _TYPE_); */
put _all_; 
RUN;

PROC PRINTTO; RUN; 
%mend;



