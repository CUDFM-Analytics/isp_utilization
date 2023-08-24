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

/* * location of input data to boot ;
libname in "&projRoot\analytic dataset";

* data to boot ;
%let data = in.analyze3H ;

* include macro programs ;
%include "&projRoot\bootstrap and macro code\MACRO_resample_V3.sas";   */

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
 



* read in data ;
data _resample_out_;
  set out._resample_out_&i;
run;


* run models and output store objects ;

* probability model ;
ods select none;
options nonotes;
proc genmod data=_resample_out_; 
  by replicate;
 class bootUnit age_cat7 (ref='21-44') gender rethnic_new (ref='White/Caucasian') RAE_person_new (ref='3') 
       Budget_grp_new (ref='MAGI Eligible Children') adj_pd_total_16cat (ref='0') adj_pd_total_17cat (ref='0') adj_pd_total_18cat (ref='0') 
       bho_n_hosp_16bin bho_n_hosp_17bin bho_n_hosp_18bin
       bho_n_er_16bin bho_n_er_17bin bho_n_er_18bin bho_n_other_16tri bho_n_other_17tri bho_n_other_18tri psych_visit_offer 
         / param=ref order=internal ref=first;
 model pd_pharm_bin_qrt (event='Yes') = age_cat7 gender rethnic_new RAE_person_new Budget_grp_new qrt_cnt adj_pd_total_16cat adj_pd_total_17cat adj_pd_total_18cat
       bho_n_hosp_16bin bho_n_hosp_17bin bho_n_hosp_18bin bho_n_er_16bin bho_n_er_17bin bho_n_er_18bin 
       bho_n_other_16tri bho_n_other_17tri bho_n_other_18tri psych_visit_offer  / dist=binomial;
 repeated subject=bootUnit / type=exch; 
 store out.prob_stored_&i;
run;
ods select all;
options notes;


* cost model ;
ods select none;
options nonotes;
proc genmod data=_resample_out_; 
  by replicate; where pd_pharm_bin_qrt=1;
 class bootUnit age_cat7 (ref='21-44') gender rethnic_new (ref='White/Caucasian') RAE_person_new (ref='3') 
       Budget_grp_new (ref='MAGI Eligible Children') adj_pd_total_16cat (ref='0') adj_pd_total_17cat (ref='0') adj_pd_total_18cat (ref='0') 
       bho_n_hosp_16bin bho_n_hosp_17bin bho_n_hosp_18bin
       bho_n_er_16bin bho_n_er_17bin bho_n_er_18bin bho_n_other_16tri bho_n_other_17tri bho_n_other_18tri psych_visit_offer 
         / param=ref order=internal ref=first;
 model Pharmacy_cost_top = age_cat7 gender rethnic_new RAE_person_new Budget_grp_new qrt_cnt adj_pd_total_16cat adj_pd_total_17cat adj_pd_total_18cat
       bho_n_hosp_16bin bho_n_hosp_17bin bho_n_hosp_18bin bho_n_er_16bin bho_n_er_17bin bho_n_er_18bin 
       bho_n_other_16tri bho_n_other_17tri bho_n_other_18tri psych_visit_offer  / dist=GAMMA link=log;
 repeated subject=bootUnit / type=IND; 
 store out.cost_stored_&i;
run;
ods select all;
options notes;


