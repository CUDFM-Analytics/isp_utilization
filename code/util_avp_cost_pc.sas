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

%LET dat = data.analysis_dataset ; 
%put &dat; 


PROC FREQ DATA = &dat; 
TABLES time ind_pc_cost; 
RUN; 

PROC SQL; 
CREATE TABLE n_time_id AS 
SELECT mcaid_id
     , count(time) as n_quarters
FROM &dat
GROUP BY mcaid_id;
QUIT; 

PROC FREQ DATA = n_time_id;
TABLES n_quarters;
RUN; 

PROC FREQ DATA = &dat;
TABLES time*ind_pc_cost;
RUN; 

PROC CORR DATA = &dat;
var time ind_pc_cost; 
RUN; 

**********************************************************************************************
* Model 01, intercept and time only ; 
TITLE "p model: DV ind_pc_cost with time (class) & random intercept";
TITLE2 "type=exch";  
PROC GEE DATA  = &dat DESC;
     CLASS  mcaid_id    
            time(ref="1")
            ind_pc_cost(ref="0");
     MODEL ind_pc_cost = time  / DIST = binomial LINK = logit ; 
  REPEATED SUBJECT = mcaid_id / type = exch ; *ind;
/*  store p_MODEL;*/
run;

* Model 01, intercept and time only but type ind ; 
TITLE "p model: DV ind_pc_cost with time (class) & random intercept";
TITLE2 "type=exch";  
PROC GEE DATA  = &dat DESC;
     CLASS  mcaid_id    
            time(ref="1")
            ind_pc_cost(ref="0");
     MODEL ind_pc_cost = time  / DIST = binomial LINK = logit ; 
  REPEATED SUBJECT = mcaid_id / type = ind ; *ind;
/*  store p_MODEL;*/
run;

**********************************************************************************************
* MODEL 01a, time not in class statement just to check: ; 
TITLE "p MODEL: DV ind_pc_cost with time (linear) & random intercept";
TITLE2 "type=exch";  
PROC GEE DATA  = &dat DESC;
     CLASS  mcaid_id    
            ind_pc_cost(ref="0");
     MODEL ind_pc_cost = time  / DIST = binomial LINK = logit ; 
  REPEATED SUBJECT = mcaid_id / type = exch ; *ind;
/*  store p_MODEL;*/
run;

PROC FREQ DATA = &dat; 
tables adj_pd_total_18cat; 
RUN;

***********************************************************************************************  ; 
* took out budgetgroup'; 
TITLE "p model with ind ";
TITLE2 "type=exch";  
PROC GEE DATA  = &dat DESC;
CLASS  mcaid_id   
       age (ref='1')
       race
       sex
       time
/*       budget_group*/
       int            (ref='0')
/*       int_imp        (ref='0')*/
       fqhc           (ref='0')
       rae_person_new (ref='1')
       bh_er16        (ref='0')
       bh_er17        (ref='0')
       bh_er18        (ref='0')
       bh_hosp16      (ref='0')
       bh_hosp17      (ref='0')
       bh_hosp18      (ref='0')
       bh_oth16       (ref='0')
       bh_oth17       (ref='0')
       bh_oth18       (ref='0')
       ind_pc_cost    (ref='0')
       adj_pd_total_16cat
       adj_pd_total_17cat
       adj_pd_total_18cat;
MODEL  ind_pc_cost = age
                     race
                     sex
                     time
/*                     budget_group      */
                     int
/*                     int_imp*/
                     fqhc
                     rae_person_new
                     bh_er16
                     bh_er17
                     bh_er18
                     bh_hosp16
                     bh_hosp17
                     bh_hosp18
                     bh_oth16
                     bh_oth17
                     bh_oth18
                     adj_pd_total_16cat
                     adj_pd_total_17cat
                     adj_pd_total_18cat / DIST=binomial LINK=logit ; 
REPEATED SUBJECT = mcaid_id / type=exch ; 
/*  store p_MODEL;*/
run;

* Model 02a, intercept and time with adj's and time linear ; 
TITLE "p model: DV ind_pc_cost with time (class), random intercept, & adj's for 16-18";
TITLE2 "type=exch";  
PROC GEE DATA  = &pc_cost DESC;
     CLASS  mcaid_id    
            ind_pc_cost(ref="0")
            adj_pd_total_16cat(ref="-1")
            adj_pd_total_17cat(ref="-1")
            adj_pd_total_18cat(ref="-1");
     MODEL ind_pc_cost = time adj_pd_total_16cat adj_pd_total_17cat adj_pd_total_18cat 
            / DIST=binomial LINK=logit ; 
     REPEATED SUBJECT = mcaid_id 
            / type=exch ; 
/*  store p_MODEL;*/
run;
** NOTES It isn't taking -1 as the ref for 16cat... why?? It is for 17 and 18... "; 
TITLE "p model: DV ind_pc_cost with time (class), random intercept, & adj's for 16-18";
TITLE2 "type=exch";  
PROC GEE DATA  = &pc_cost DESC;
     CLASS  mcaid_id    
            ind_pc_cost(ref="0")
            adj_pd_total_16cat(ref="-1")
            adj_pd_total_17cat(ref="-1")
            adj_pd_total_18cat(ref="-1");
     MODEL ind_pc_cost = time adj_pd_total_16cat adj_pd_total_17cat adj_pd_total_18cat 
            / DIST=binomial LINK=logit ; 
     REPEATED SUBJECT = mcaid_id 
            / type=exch ; 
/*  store p_MODEL;*/
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

   
