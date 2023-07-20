%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 
%LET dat  = data.analysis;
%LET pvar = ind_pc_cost;       
%LET dv   = cost_pc;

*----- with GENMOD -----------------------------------;
TITLE "Probability Model: with PROC GENMOD"; 
PROC GENMOD DATA  = &dat;
CLASS  mcaid_id int(ref='0') int_imp(ref='0') budget_grp_num_r 
             race sex rae_person_new age_cat_num fqhc(ref ='0')
             bh_oth16(ref='0')      bh_oth17(ref='0')       bh_oth18(ref='0')
             bh_er16(ref='0')       bh_er17(ref='0')        bh_er18(ref='0')
             bh_hosp16(ref='0')     bh_hosp17(ref='0')      bh_hosp18(ref='0')
             adj_pd_total_16cat(ref='0')
             adj_pd_total_17cat(ref='0')
             adj_pd_total_18cat(ref='0')
       &pvar(ref= '0') ;
MODEL  &pvar = int int_imp time budget_grp_num_r race sex rae_person_new age_cat_num fqhc
             bh_oth16               bh_oth17                bh_oth18
             bh_er16                bh_er17                 bh_er18
             bh_hosp16              bh_hosp17               bh_hosp18
             adj_pd_total_16cat 
             adj_pd_total_17cat 
             adj_pd_total_18cat            / DIST=binomial LINK=logit ; 
REPEATED SUBJECT = mcaid_id / corr=exch ; 
store out=pmodel_genmod;
run;

*----- with GEE -----------------------------------;
TITLE "Probability Model with PROC GEE"; 
PROC GEE DATA  = &dat;
CLASS  mcaid_id int(ref='0') int_imp(ref='0') budget_grp_num_r 
             race sex rae_person_new age_cat_num fqhc(ref ='0')
             bh_oth16(ref='0')      bh_oth17(ref='0')       bh_oth18(ref='0')
             bh_er16(ref='0')       bh_er17(ref='0')        bh_er18(ref='0')
             bh_hosp16(ref='0')     bh_hosp17(ref='0')      bh_hosp18(ref='0')
             adj_pd_total_16cat(ref='0')
             adj_pd_total_17cat(ref='0')
             adj_pd_total_18cat(ref='0')
       &pvar(ref= '0') ;
MODEL  &pvar = int int_imp time budget_grp_num_r race sex rae_person_new age_cat_num fqhc
             bh_oth16               bh_oth17                bh_oth18
             bh_er16                bh_er17                 bh_er18
             bh_hosp16              bh_hosp17               bh_hosp18
             adj_pd_total_16cat 
             adj_pd_total_17cat 
             adj_pd_total_18cat            / DIST=binomial LINK=logit ; 
REPEATED SUBJECT = mcaid_id / corr=exch ; 
store out=pMODEL_gee;
run;
