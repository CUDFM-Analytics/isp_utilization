**********************************************************************************************
AUTHOR   : Carter Sevick (adapted KW)
PROJECT  : ISP
PURPOSE  : define the bootstrap process to parallelize
VERSION  : 2023-10-31
HISTORY  : copied on 08-24-2023 from Carter/Examples/boot total cost/
***********************************************************************************************;
%LET projRoot = S:\FHPC\DATA\HCPF_DATA_files_SECURE\Kim\isp\isp_utilization;
%LET libout = "&projRoot\data_boot_processed\cost_total";
%LET pvar   = ind_cost_total; 
%LET cvar   = cost_total; 

* location for bootstrap products ;
libname out &libout;
* location of input data to boot (where resampled sets are); 
libname in "&projRoot\data_boot_processed";
* get formats; 
libname util "&projRoot\data"; 
OPTIONS FMTSEARCH=(in, util);

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
* probability model ;
ODS SELECT NONE; OPTIONS NONOTES;
PROC GENMOD DATA = in._resample_out_&i desc;
BY    replicate;
CLASS bootunit 
      int(ref='0')  
      int_imp(ref='0') 
      bh_oth17(ref='0') bh_oth18(ref='0') bh_oth19(ref='0') 
      bh_er17(ref='0') bh_er18(ref='0') bh_er19(ref='0')
      bh_hosp17(ref='0') bh_hosp18(ref='0') bh_hosp19(ref='0') 
      adj_pd_total_17cat(ref='0') 
      adj_pd_total_18cat(ref='0') 
      adj_pd_total_19cat(ref='0')
      fqhc(ref ='0')
      budget_grp_new(ref='MAGI Eligible Children')
      age_cat(ref='ages 21-44')
      rae_person_new(ref='3')
      race(ref='non-Hispanic White/Caucasian') 
      sex(ref='Female') 
      &pvar (ref='0');
MODEL &pvar = time int int_imp season1 season2 season3 
                    bh_oth17 bh_oth18 bh_oth19 bh_er17 bh_er18 bh_er19 bh_hosp17 bh_hosp18 bh_hosp19
                    adj_pd_total_17cat adj_pd_total_18cat adj_pd_total_19cat
                    fqhc budget_grp_new age_cat rae_person_new race sex / DIST=binomial LINK=logit;
REPEATED SUBJECT = bootunit / type=ind;
STORE out.prob_stored_&i;
RUN;
ODS SELECT ALL; OPTIONS NOTES;

* cost model - UPDATE DV in WHERE statement and MODEL statements;
ODS SELECT NONE; OPTIONS NONOTES;
PROC GENMOD DATA = in._resample_out_&i  ;
BY    replicate;
WHERE &cvar >0;
CLASS bootunit 
      int(ref='0')  
      int_imp(ref='0') 
      bh_oth17(ref='0') bh_oth18(ref='0') bh_oth19(ref='0') 
      bh_er17(ref='0') bh_er18(ref='0') bh_er19(ref='0')
      bh_hosp17(ref='0') bh_hosp18(ref='0') bh_hosp19(ref='0') 
      adj_pd_total_17cat(ref='0') 
      adj_pd_total_18cat(ref='0') 
      adj_pd_total_19cat(ref='0')
      fqhc(ref ='0')
      budget_grp_new(ref='MAGI Eligible Children')
      age_cat(ref='ages 21-44')
      rae_person_new(ref='3')
      race(ref='non-Hispanic White/Caucasian') 
      sex(ref='Female') ;
MODEL &cvar = time int int_imp season1 season2 season3 
                bh_oth17 bh_oth18 bh_oth19 bh_er17 bh_er18 bh_er19 bh_hosp17 bh_hosp18 bh_hosp19
                adj_pd_total_17cat adj_pd_total_18cat adj_pd_total_19cat
                fqhc budget_grp_new age_cat rae_person_new race sex / DIST = gamma LINK = log;
REPEATED SUBJECT = bootunit / type=ind;
STORE out.cost_stored_&i;
RUN;
ODS SELECT ALL; OPTIONS NOTES;

