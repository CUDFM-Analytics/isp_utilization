%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 
libname int clear; 

%LET dat = data.analysis_dataset ; 

* probability model ;
PROC GEE DATA  = &dat desc;
    CLASS mcaid_id    
          age         sex     race        
          rae_person_new 
          budget_grp_new          fqhc    
          bh_er2016   bh_er2017   bh_er2018 
          bh_hosp2016 bh_hosp2017 bh_hosp2018 
          bh_oth2016  bh_oth2017  bh_oth2018
          adj_pd_total_16cat 
          adj_pd_total_17cat  
          adj_pd_total_18cat
          time 
          int 
          int_imp 
          ind_cost_pc ;
    MODEL ind_cost_pc = age            sex             race 
                        rae_person_new budget_grp_new  fqhc
                        bh_er2016      bh_er2017       bh_er2018 
                        bh_hosp2016    bh_hosp2017     bh_hosp2018 
                        bh_oth2016     bh_oth2017      bh_oth2018
                        adj_pd_total_16cat 
                        adj_pd_total_17cat 
                        adj_pd_total_18cat
                        time 
                        int_imp
                        int/ dist = binomial link = logit ;
  repeated subject = uniqid / type = exch;
  store p_model;
run;

* positive cost model ;
proc gee data  = postemanc_grp2 desc;
where pd_primary_care>0;
  class uniqid  ;
  model pd_primary_care = emancipated relmonth emancipated*relmonth / dist = gamma link = log ;
  repeated subject = uniqid / type = exch;
  store c_model;
run;

* interest group ;
* the group of interest (emancipated youth) is set twice, 
  the top in the stack will be recoded as not emancipated (unexposed)
  the bottom group keeps the emancipated status
;
data intgroup;
  set postemanc_grp2 postemanc_grp2 (in = b);
  where emancipated = 1;

  if ^b then emancipated = 0;

  exposed = b;
run;

* the predictions for util and cost will be made for each person twice, once exposed and once unexposed;
* prob of util ;
proc plm restore=p_model;
   score data=intgroup out=p_intgroup predicted=p_prob / ilink;
run;

* prob of cost ;
proc plm restore=c_model;
   score data=p_intgroup out=cp_intgroup predicted=p_cost / ilink;
run;

* person average cost is calculated ;
data meanCost;
  set cp_intgroup;

  a_cost = p_prob*p_cost;* (1-p term = 0);

run;

* group average cost is calculated and contrasted ;
proc sql;

create table apv_ana as
  select mean(case when exposed=1 then a_cost else . end ) as cost_exposed,
         mean(case when exposed=0 then a_cost else . end ) as cost_unexposed,
  calculated cost_exposed - calculated cost_unexposed as cost_diff
  from meanCost;

quit;

proc print data = apv_ana;
run;
