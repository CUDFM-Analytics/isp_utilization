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
libname raw clear;  
/*proc options option=memsize value;*/
/*run;*/

%LET dat = data.analysis_dataset ; 
%put &dat; 

proc options option=memsize value;
run;


PROC CONTENTS DATA = &dat VARNUM; RUN; 

PROC GEE DATA  = &dat DESC;
     CLASS  mcaid_id    
            adj_pd_total_16cat (ref="-1")
            adj_pd_total_17cat (ref="-1")
            adj_pd_total_18cat (ref="-1")
            time(ref="1")
            ind_pc_cost(ref="0");
     model ind_pc_cost = adj_pd_total_16cat 
                         adj_pd_total_17cat 
                         adj_pd_total_18cat
                         time  / dist = binomial link = logit ; 
  repeated subject = mcaid_id / type = exch ; *ind;
/*  store p_model;*/
run;


TITLE "probability model"; 
PROC GEE DATA  = data.analysis_dataset DESC;
     CLASS  mcaid_id    
/*            age         sex     race        */
/*            rae_person_new */
/*            budget_group          */
/*            fqhc    */
/*            bho_n_er_16pm    bho_n_er_17pm    bho_n_er_18pm  */
/*            bho_n_hosp_16pm  bho_n_hosp_17pm  bho_n_hosp_18pm*/
/*            bh_n_other_16pm bh_n_other_17pm bh_n_other_18pm*/
            adj_pd_total_16cat (ref="-1")
            adj_pd_total_17cat (ref="-1")
            adj_pd_total_18cat (ref="-1")
            time        (ref="1")
            int         (ref="0")
            int_imp     (ref="0")
            ind_cost_pc (ref="0");
     model ind_cost_pc = adj_pd_total_16cat 
                         adj_pd_total_17cat 
                         adj_pd_total_18cat
/*                         age            sex             race */
/*                         rae_person_new budget_group  */
/*                         fqhc*/
/*                         bho_n_er_16pm    bho_n_er_17pm    bho_n_er_18pm  */
/*                         bho_n_hosp_16pm  bho_n_hosp_17pm  bho_n_hosp_18pm*/
/*                         bh_n_other_16pm bh_n_other_17pm bh_n_other_18pm*/
                         time 
                         int_imp
                         int 
                         / dist = binomial link = logit ; 
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

   
