**********************************************************************************************
AUTHOR   : Carter Sevick (adapted KW)
PROJECT  : ISP
PURPOSE  : define the bootstrap process to parallelize
VERSION  : 2023-08-24
HISTORY  : copied on 08-24-2023 from Carter/Examples/boot total cost/
CHANGES  :  -- [row 13] projRoot > %LET projRoot = S:\FHPC\DATA\HCPF_DATA_files_SECURE\Kim\isp\isp_utilization
            -- [row 20] add OPTIONS FMTSEARCH = (in)
            -- [row 73] prob model positive cost > ind_pc_cost
            -- [row 94] cost model DV > adj_pd_pc_tc
***********************************************************************************************;
%LET projRoot = S:\FHPC\DATA\HCPF_DATA_files_SECURE\Kim\isp\isp_utilization;

* location for bootstrap products ;
libname out "&projRoot\data_boot_processed\cost_pc";
* location of input data to boot - where resampled sets are, right?;
libname in "&projRoot\data_boot_processed";
* get formats; 
libname data "&projRoot\data"; 
OPTIONS FMTSEARCH=(in, data);

* data to boot ;
%let data = in.utilization;

* include macro programs;
%INCLUDE "&projRoot\code\util_bootstrap\MACRO_resample_V4.sas"; 

* get process parameters ;
** process number ;
%LET   i = %scan(&SYSPARM,1,%str( ));
** seed number ;
%LET   seed = %scan(&SYSPARM,2,%str( ));
** N bootstrap samples ;
%LET    N = %scan(&SYSPARM,3,%str( ));

* run models and output store objects ;

* probability model 
Changes: pvar added to class statement
Questions: What happens to mcaid_id in class but not model? Is it needed?;
ODS SELECT NONE;
OPTIONS NONOTES;
PROC GENMOD DATA = in._resample_out_&i desc;
   BY    replicate;
   CLASS bootunit int (ref='0') int_imp (ref='0') budget_grp_num (ref='MAGI Eligible Children')
         race (ref='non-Hispanic White/Caucasian') sex (ref='Female') rae_person_new (ref='3') age_cat(ref='ages 45-64') fqhc(ref ='0') 
         bh_oth16 (ref='0') bh_oth17 (ref='0') bh_oth18 (ref='0') bh_er16 (ref='0') bh_er17 (ref='0') bh_er18 (ref='0')
         bh_hosp16(ref='0') bh_hosp17(ref='0') bh_hosp18(ref='0') 
         adj_pd_total_16cat(ref='0') adj_pd_total_17cat(ref='0') adj_pd_total_18cat(ref='0')
         ind_cost_pc(ref='0');
   MODEL ind_cost_pc = int int_imp budget_grp_num race sex rae_person_new age_cat fqhc
                       bh_oth16 bh_oth17 bh_oth18 bh_er16 bh_er17 bh_er18 bh_hosp16 bh_hosp17 bh_hosp18
                       adj_pd_total_16cat adj_pd_total_17cat adj_pd_total_18cat / 
         DIST=binomial LINK=logit;
   REPEATED SUBJECT = bootunit / type=exch;
   STORE out.prob_stored_&i;
RUN;
ODS SELECT ALL;
OPTIONS NOTES;

* cost model - UPDATE DV in WHERE statement and MODEL statements;
ODS SELECT NONE;
OPTIONS NONOTES;
PROC GENMOD DATA = in._resample_out_&i  ;
   BY    replicate;
   WHERE cost_pc >0;
   CLASS bootunit int (ref='0') int_imp (ref='0') budget_grp_num (ref='MAGI Eligible Children')
         race (ref='non-Hispanic White/Caucasian') sex (ref='Female') rae_person_new (ref='3') age_cat(ref='ages 45-64') fqhc(ref ='0') 
         bh_oth16 (ref='0') bh_oth17 (ref='0') bh_oth18 (ref='0') bh_er16 (ref='0') bh_er17 (ref='0') bh_er18 (ref='0')
         bh_hosp16(ref='0') bh_hosp17(ref='0') bh_hosp18(ref='0') 
         adj_pd_total_16cat(ref='0') adj_pd_total_17cat(ref='0') adj_pd_total_18cat(ref='0');
   MODEL cost_pc = int int_imp budget_grp_num race sex rae_person_new age_cat fqhc
                             bh_oth16 bh_oth17 bh_oth18 bh_er16 bh_er17 bh_er18 bh_hosp16 bh_hosp17 bh_hosp18
                             adj_pd_total_16cat adj_pd_total_17cat adj_pd_total_18cat /  
         DIST = gamma LINK = log;
   REPEATED SUBJECT = bootunit / type=exch;
   STORE out.cost_stored_&i;
RUN;
ODS SELECT ALL;
OPTIONS NOTES;

