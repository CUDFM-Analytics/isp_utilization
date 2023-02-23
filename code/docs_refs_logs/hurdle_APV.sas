
* study data ;
data postemanc_grp2;
  set postemanc_grp;

  * indicator of utilization ;
  pvar = n_primary_care>0;

run;  

* probability model ;
proc gee data  = postemanc_grp2 desc;
  class uniqid  ;
  model pvar = emancipated relmonth emancipated*relmonth / dist = binomial link = logit ;
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
