
*** Take sample from final set ; 
DATA test ; 
SET  data.analyis_dataset (obs=10000000) ; 
KEEP mcaid_id time cost: int int_imp util: ind: ; 
RUN; 

proc contents data = test ; 
RUN ; 

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
util_tele   : Primary Care telehealth utilizaton (n PC telehealth visits) - PMPM avg for a quarter



* probability model ;
proc gee data  = test desc;
  class mcaid_id int int_imp time ind_cost_pc ;
  model ind_cost_pc = int int_imp time / dist = binomial link = logit ; 
  repeated subject = mcaid_id / type = exch;
  store p_model;
run;

* positive cost model ;
proc gee data  = fake desc;
where cost_pc_tc > 0;
class mcaid_id int int_imp time ind_cost_pc ;
model cost_pc_tc = int int_imp time / dist = gamma link = log ;
repeated subject = mcaid_id / type = exch;
store c_model;
run;

/*proc gee data  = fake desc;*/
/*where pd_amt_pc > 0;*/
/*class id ind_isp_ever ind_isp_dtd month ind_pd ;*/
/*model pd_amt_pc = ind_isp_ever ind_isp_dtd month / dist = gamma link = log ;*/
/*repeated subject = id / type = exch;*/
/*store c_model;*/
/*run;*/

* interest group ;
* the group of interest (emancipated youth) is set twice, 
  the top in the stack will be recoded as not emancipated (unexposed)
  the bottom group keeps the emancipated status
;
data intgroup;
  set fake fake (in = b);
  where ind_isp_ever = 1;

  if ^b then ind_isp_ever = 0;

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

   
