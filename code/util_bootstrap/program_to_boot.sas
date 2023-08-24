**********************************************************************************************
AUTHOR   : Carter Sevick, adapted by KW
PROJECT  : ISP
PURPOSE  : define the bootstrap process to parallelize
VERSION  : 2023-08-24
HISTORY  : copied on 08-24-2023 from Carter/Examples/boot total cost/
CHANGES  : -moved projRoot, libname in, libname out to config_boot
***********************************************************************************************;
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_bootstrap/config_boot.sas";
%LET ind_cost = ind_pc_cost;
%LET cost     = adj_pd_pc_tc; 

* INCLUDE macro;
%INCLUDE "&projRoot/code/util_bootstrap/macro_resample_V4.sas";
* get process parameters ;
** process number ;
%LET   i = %scan(&SYSPARM,1,%str( ));
** seed number ;
%LET    seed = %scan(&SYSPARM,2,%str( ));
** N bootstrap samples ;
%LET    N = %scan(&SYSPARM,3,%str( ));

* Draw bootstrap samples
Two new variables are added
1) bootUnit = the new subject identifier
2) replicate = identifies specific bootstrap samples
!!!!! the old ID variable is still included, BUT YOU CAN NOT USE IT IN THIS DATA FOR STATISTICS!!!!!!!!!!!;
ODS SELECT NONE;
%resample(data= &data
        , out=_resample_out_
        , subject=mcaid_id
        , reps= &N
        , strata=int
        , seed=&seed
        , bootUnit=bootUnit
        , repName = replicate
        , samprate = (1.0 .20)
);

* save a copy of the booted data ;
DATA out._resample_out_&i; 
SET _resample_out_; 
RUN;

* run models and output store objects ;

* probability model 
QUESTIONS why isn't pvar in the class statement? What happens to mcaid_id in class but not model?;
ODS SELECT NONE;
OPTIONS NONOTES;
PROC GENMOD DATA = _resample_out_ desc;
   BY    replicate;
   CLASS bootunit mcaid_id int (ref='0') int_imp (ref='0') budget_grp_new (ref='MAGI Eligible Children')
         race (ref='non-Hispanic White/Caucasian') sex (ref='Female') rae_person_new (ref='3') age_cat(ref='6') fqhc(ref ='0') 
         bh_oth16 (ref='0') bh_oth17 (ref='0') bh_oth18 (ref='0') bh_er16 (ref='0') bh_er17 (ref='0') bh_er18 (ref='0')
         bh_hosp16(ref='0') bh_hosp17(ref='0') bh_hosp18(ref='0') 
         adj_pd_total_16cat(ref='0') adj_pd_total_17cat(ref='0') adj_pd_total_18cat(ref='0');
   MODEL &ind_cost(event="1") = int int_imp budget_grp_new race sex rae_person_new age_cat fqhc
                             bh_oth16 bh_oth17 bh_oth18 bh_er16 bh_er17 bh_er18 bh_hosp16 bh_hosp17 bh_hosp18
                             adj_pd_total_16cat adj_pd_total_17cat adj_pd_total_18cat / 
         DIST=binomial LINK=logit;
   REPEATED SUBJECT = bootunit;
   STORE out.prob_stored_&i;
RUN;
ODS SELECT ALL;
OPTIONS NOTES;

* cost model ;
ODS SELECT NONE;
OPTIONS NONOTES;
PROC GENMOD DATA = _resample_out_  ;
   BY    replicate;
   WHERE &cost >0;
   CLASS bootunit mcaid_id int (ref='0') int_imp (ref='0') budget_grp_new (ref='MAGI Eligible Children')
         race (ref='non-Hispanic White/Caucasian') sex (ref='Female') rae_person_new (ref='3') age_cat(ref='6') fqhc(ref ='0') 
         bh_oth16 (ref='0') bh_oth17 (ref='0') bh_oth18 (ref='0') bh_er16 (ref='0') bh_er17 (ref='0') bh_er18 (ref='0')
         bh_hosp16(ref='0') bh_hosp17(ref='0') bh_hosp18(ref='0') 
         adj_pd_total_16cat(ref='0') adj_pd_total_17cat(ref='0') adj_pd_total_18cat(ref='0');
   MODEL &cost = int int_imp budget_grp_new race sex rae_person_new age_cat fqhc
                             bh_oth16 bh_oth17 bh_oth18 bh_er16 bh_er17 bh_er18 bh_hosp16 bh_hosp17 bh_hosp18
                             adj_pd_total_16cat adj_pd_total_17cat adj_pd_total_18cat /  
         DIST = gamma LINK = log;
   REPEATED SUBJECT = bootunit;
   STORE out.cost_stored_&i;
RUN;
ODS SELECT ALL;
OPTIONS NOTES;
