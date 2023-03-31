%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 
libname int clear; 
libname ana clear;
libname out clear ; 
/*proc options option=memsize value;*/
/*run;*/

*** Take sample from final set ; 

* Var description: 
mcaid_id    : medicaid id (between 1 and 3 records per member: compound primary key with 'time' variable)
time        : categorical, linear quarters for FY, where 1 = 01JUL2019
int         : intervention of ISP if practice participated at any time (0,1) 
int_imp     : time-varying covariate, ISP intervention based on month practice started
ind_...     : indicator variable if value of 0 or ge 1 for any DV 
              ind_cost_pc, ind_cost_ffs, ind_cost_rx, ind_util_bh_o, ind_util_er, ind_util_pc, ind_util_tel

cost_ffs_tc : mean-preserving top coded inflation adjusted total FFS cost - PMPM avg for quarter  
cost_rx_tc  : mean-preserving top coded inflation adjusted Pharmacy cost - PMPM avg for quarter  
cost_pc_tc  : mean-preserving top coded inflation adjusted total Primary Care cost - PMPM avg for quarter  
util_bh_o   : non-hospital, non_ED capitated BH Utilization (n visits) - PMPM avg for a quarter
util_er     : ED utilization (n FFS ED visits + n BH ED visits) - PMPM avg for quarter
util_pc     : Primary Care Utilization (n PC visits in quarter) - PMPM avg for quarter 
util_tele   : Primary Care telehealth utilizaton (n PC telehealth visits) - PMPM avg for a quarter; 

ods pdf file = "&util/code/util_cost_pc_abr_20230330.pdf";

ods text = "VARS"; 
ods text = "time: categorical, linear quarters for FY, where 1 = 01JUL2019";
ods text = "int: intervention of ISP if practice participated at any time (0,1)";
ods text = "int_imp: time-varying covariate, ISP intervention based on month practice started"; 
ods text = "ind_cost_pc: indicator variable if value of 0 or ge 1 for any DV"; 
ods text = "cost_pc_tc: mean-preserving top coded inflation adjusted total Primary Care cost - PMPM avg for quarter"; 
ods text = "";
ods text = "";
ods text = "";
%LET dat = data.analysis_dataset; 

proc contents data = &dat; 
RUN ; 

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

   
