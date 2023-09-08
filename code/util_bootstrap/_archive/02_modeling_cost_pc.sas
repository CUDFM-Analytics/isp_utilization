* run models and output store objects ;

* probability model 
Changes: pvar added to class statement
Questions: What happens to mcaid_id in class but not model? Is it needed?;
ODS SELECT NONE;
OPTIONS NONOTES;
PROC GENMOD DATA = out._resample_out_&i desc;
   BY    replicate;
   CLASS bootunit int (ref='0') int_imp (ref='0') budget_grp_new (ref='MAGI Eligible Children')
         race (ref='non-Hispanic White/Caucasian') sex (ref='Female') rae_person_new (ref='3') age_cat(ref='6') fqhc(ref ='0') 
         bh_oth16 (ref='0') bh_oth17 (ref='0') bh_oth18 (ref='0') bh_er16 (ref='0') bh_er17 (ref='0') bh_er18 (ref='0')
         bh_hosp16(ref='0') bh_hosp17(ref='0') bh_hosp18(ref='0') 
         adj_pd_total_16cat(ref='0') adj_pd_total_17cat(ref='0') adj_pd_total_18cat(ref='0')
         ind_pc_cost(ref='0');
   MODEL ind_pc_cost = int int_imp budget_grp_new race sex rae_person_new age_cat fqhc
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
PROC GENMOD DATA = out._resample_out_&i  ;
   BY    replicate;
   WHERE adj_pd_pc_tc >0;
   CLASS bootunit int (ref='0') int_imp (ref='0') budget_grp_new (ref='MAGI Eligible Children')
         race (ref='non-Hispanic White/Caucasian') sex (ref='Female') rae_person_new (ref='3') age_cat(ref='6') fqhc(ref ='0') 
         bh_oth16 (ref='0') bh_oth17 (ref='0') bh_oth18 (ref='0') bh_er16 (ref='0') bh_er17 (ref='0') bh_er18 (ref='0')
         bh_hosp16(ref='0') bh_hosp17(ref='0') bh_hosp18(ref='0') 
         adj_pd_total_16cat(ref='0') adj_pd_total_17cat(ref='0') adj_pd_total_18cat(ref='0');
   MODEL adj_pd_pc_tc = int int_imp budget_grp_new race sex rae_person_new age_cat fqhc
                             bh_oth16 bh_oth17 bh_oth18 bh_er16 bh_er17 bh_er18 bh_hosp16 bh_hosp17 bh_hosp18
                             adj_pd_total_16cat adj_pd_total_17cat adj_pd_total_18cat /  
         DIST = gamma LINK = log;
   REPEATED SUBJECT = bootunit / type=exch;
   STORE out.cost_stored_&i;
RUN;
ODS SELECT ALL;
OPTIONS NOTES;
