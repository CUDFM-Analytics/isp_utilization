* added a month fake variable ; 
data fake ; 
set  fake ; 
by id ; 
if first.id then month = 0; 
month + 1; 
run ;

* make indicator if pd 0 or 1 - his is better in row 20-27; 
data fake ; 
set  fake ; 
if   pd_amt_pc > 0 then ind_pd = 1;
else ind_pd = 0; 
run; 
        * checking (there was a weird neg num I put in by accident);
        proc freq data = fake ; 
        tables pd_amt_pc*ind_pd; 
        run; 

* study data ;
data fake2;
  set fake;

* indicator of utilization ;
pvar = n_primary_care>0;

run;  

* probability model ;
proc gee data  = fake desc;
  class id ind_isp_ever ind_isp_dtd month ind_pd ;
  model ind_pd = ind_isp_ever ind_isp_dtd month / dist = binomial link = logit ; 
  repeated subject = id / type = exch;
  store p_model;
run;

* positive cost model ;
proc gee data  = fake desc;
where pd_amt_pc>0;
class id ind_isp_ever ind_isp_dtd month ind_pd ;
model pd_amt_pc = ind_isp_ever ind_isp_dtd month / dist = gamma link = log ;
repeated subject = id / type = exch;
store c_model;
run;

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
