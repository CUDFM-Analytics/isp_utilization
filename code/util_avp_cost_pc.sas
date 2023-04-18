**********************************************************************************************
AUTHOR   : KTW
PROJECT  : [PROJ NAME]
PURPOSE  : 
VERSION  : [2023-MM-DD] 
DEPENDS  : [LIST DEPENDENCIES (files, macros, abbreviations)]
REFS     : Visualize collinearity diagnostics in SAS, https://blogs.sas.com/content/iml/2020/02/17/visualize-collinearity-diagnostics.html
           'Collinearity in regression: The COLLIN option in PROC REG' 
            https://blogs.sas.com/content/iml/2020/01/23/collinearity-regression-collin-option.html;

***********************************************************************************************;

%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 
libname int clear; 
/*proc options option=memsize value;*/
/*run;*/

%LET dat = data.analysis_dataset ; 

proc options option=memsize value;
run;

proc contents data = &dat ; run ; 

* probability model 
Per Mark, try without bh and adj vars, then we will slowly re-introduce if so;
TITLE "probability model"; 
PROC GEE DATA  = &dat DESC;
     CLASS  mcaid_id    
            age         sex     race        
            rae_person_new 
            budget_grp_new          fqhc    
/*            bh_er2016   bh_er2017   bh_er2018 */
/*            bh_hosp2016 bh_hosp2017 bh_hosp2018 */
/*            bh_oth2016  bh_oth2017  bh_oth2018*/
/*            adj_pd_total_16cat */
/*            adj_pd_total_17cat  */
            adj_pd_total_18cat
            time 
            int 
            int_imp 
            ind_cost_pc ;
     model ind_cost_pc = age            sex             race 
                         rae_person_new budget_grp_new  fqhc
/*                         bh_er2016      bh_er2017       bh_er2018 */
/*                         bh_hosp2016    bh_hosp2017     bh_hosp2018 */
/*                         bh_oth2016     bh_oth2017      bh_oth2018*/
/*                         adj_pd_total_16cat */
/*                         adj_pd_total_17cat */
                         adj_pd_total_18cat
                         time 
                         int_imp
                         int / dist = binomial link = logit ; 
  repeated subject = mcaid_id / type = exch;
  store p_model;
run;


* probability model ;
TITLE "probability model"; 
proc gee data  = &dat desc;
  class mcaid_id int int_imp time ind_cost_pc ;
  model ind_cost_pc = int int_imp time / dist = binomial link = logit ; 
  repeated subject = mcaid_id / type = exch;
  store p_model;
run;

* positive cost model ;
TITLE "cost model"; 
proc gee data  = &dat desc;
where cost_pc_tc > 0;
class mcaid_id int int_imp time ind_cost_pc ;
model cost_pc_tc = int int_imp time / dist = gamma link = log ;
repeated subject = mcaid_id / type = exch;
store c_model;
run;
TITLE; 

* interest group ;
* the group of interest (emancipated youth) is set twice, 
  the top in the stack will be recoded as not emancipated (unexposed)
  the bottom group keeps the emancipated status;

data intgroup;
  set &dat &dat (in = b);
  where int = 1;
  if ^b then int = 0;
  exposed = b;
run;
*  1785893 for both with intgroup = 3571786;

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

create table apv_cost_pc as
  select mean(case when exposed=1 then a_cost else . end ) as cost_exposed,
         mean(case when exposed=0 then a_cost else . end ) as cost_unexposed,
  calculated cost_exposed - calculated cost_unexposed as cost_diff
  from meanCost;

quit;

TITLE "apv_cost_pc"; 
proc print data = apv_cost_pc;
run;

ods pdf close; 

proc means data = meancost;
by exposed;
var p_prob p_cost a_cost; 
RUN; 

   
