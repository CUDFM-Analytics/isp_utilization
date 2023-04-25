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

%LET dat = data.analysis_dataset2 ; 
* updated on 4/17 with int_imp quarters changed see create file; 

proc options option=memsize value;
run;

proc contents data = &dat ; run ; 

* 4/20 try intercept, time and only one adj at a time; 
%macro one_adj(adjvar=);
TITLE "Probability Model Intercept, Time, & "&adjvar; 
PROC GEE DATA  = &dat DESC;
     CLASS  mcaid_id    
            time
            ind_cost_pc
            &adjvar(ref="-1");
     model ind_cost_pc = time &adjvar / dist = binomial link = logit ; 
  repeated subject = mcaid_id / type = ind ; *exch;
/*  store p_model;*/
run;  
%mend; 

%one_adj(adjvar=adj_pd_total_16cat); * success; 
%one_adj(adjvar=adj_pd_total_17cat); * success; 
%one_adj(adjvar=adj_pd_total_18cat); * success; 

* probability model 
Per Mark, try without bh and adj vars, then we will slowly re-introduce if so;

* Email 4/13 
Once you have checked the int_imp variable lets run 3 models with just the following covariates:
Model 1:
Intercept
Time

Model 2:
Intercept
Time
Int_imp
Int

Model 3:
Intercept
Time 
Adj_pd_total_16cat
Adj_pd_total_17cat
Adj_pd_total_18cat


Email 4/18: Try independent correlation
Email 4/19 try just 16, 17 then try 16, 18; 

ods pdf file = "S:\FHPC\DATA\HCPF_Data_files_SECURE\Kim\isp\isp_utilization\code\util_avp_cost_pc_model_16_17.pdf" startpage=no;

TITLE "Model 1: Probability Model with adj16, adj17, Intercept, & Time"; 
PROC GEE DATA  = &dat DESC;
     CLASS  mcaid_id    
            time
            ind_cost_pc
            adj_pd_total_16cat
            adj_pd_total_17cat;
     model ind_cost_pc = time adj_pd_total_16cat adj_pd_total_17cat / dist = binomial link = logit ; 
  repeated subject = mcaid_id / type = ind ; *exch;
/*  store p_model;*/
run;  

TITLE "Model 1: Probability Model with adj16, adj17, Intercept, & Time"; 
PROC GEE DATA  = &dat DESC;
     CLASS  mcaid_id    
            time(ref="1")
            ind_cost_pc(ref="0")
            adj_pd_total_16cat(ref="-1")
            adj_pd_total_17cat(ref="-1");
     model ind_cost_pc = time adj_pd_total_16cat adj_pd_total_17cat / dist = binomial link = logit ; 
  repeated subject = mcaid_id / type = ind ; *exch;
/*  store p_model;*/
run;  

TITLE "Model 1: Probability Model with adj16, adj18, Intercept, & Time"; 
PROC GEE DATA  = &dat DESC;
     CLASS  mcaid_id    
            time 
            ind_cost_pc 
            adj_pd_total_16cat 
            adj_pd_total_18cat;
     model ind_cost_pc = time adj_pd_total_16cat adj_pd_total_18cat  / dist = binomial link = logit ; 
  repeated subject = mcaid_id / type = ind ; *exch;
/*  store p_model;*/
run;  

proc freq data = &dat ; tables adj_pd_total_16cat; run; 

TITLE "Model 2: Probability Model with adj16, adj17, Intercept, Time, and both intervention variables"; 
PROC GEE DATA  = &dat DESC;
     CLASS  mcaid_id    
            time (ref="0")
            ind_cost_pc (ref="0")
            adj_pd_total_16cat (ref="0")
            adj_pd_total_17cat (ref="0")
            int (ref="0")
            int_imp (ref="0");
     model ind_cost_pc = time 
                         int_imp
                         int / dist = binomial link = logit ; 
  repeated subject = mcaid_id / type = ind ; *exch;
/*  store p_model;*/
run;  


TITLE "Model 2: Probability Model with adj16, adj17, Intercept, Time, and both intervention variables"; 
PROC GEE DATA  = &dat DESC;
     CLASS  mcaid_id    
            time (ref="0")
            ind_cost_pc (ref="0")
            adj_pd_total_16cat (ref="0")
            adj_pd_total_18cat (ref="0")
            int (ref="0")
            int_imp (ref="0");
     model ind_cost_pc = time / dist = binomial link = logit ; 
  repeated subject = mcaid_id / type = ind ; *exch;
/*  store p_model;*/
run;  
 

ods pdf file = "S:\FHPC\DATA\HCPF_Data_files_SECURE\Kim\isp\isp_utilization\code\util_avp_cost_pc_models1_2_3.pdf" startpage=no;


TITLE "Model 1: Probability Model with adj16, adj17, Intercept, & Time"; 
PROC GEE DATA  = &dat DESC;
     CLASS  mcaid_id    
            time (ref="1")
            ind_cost_pc (ref="0");
     model ind_cost_pc = time / dist = binomial link = logit ; 
  repeated subject = mcaid_id / type = ind ; *exch;
/*  store p_model;*/
run;  


TITLE "Model 2: Probability Model with Intercept, Time, int, and int_imp"; 
PROC GEE DATA  = &dat DESC;
     CLASS  mcaid_id    
            time 
            int 
            int_imp 
            ind_cost_pc ;
     model ind_cost_pc = time 
                         int_imp
                         int / dist = binomial link = logit ; 
  repeated subject = mcaid_id / type = ind; *exch;
/*  store p_model;*/
run;

TITLE "Model 3: Probability Model with Intercept, Time, and adj vars (x3)"; 
PROC GEE DATA  = &dat DESC;
     CLASS  mcaid_id    
            adj_pd_total_16cat 
            adj_pd_total_17cat  
            adj_pd_total_18cat
            ind_cost_pc ;
     model ind_cost_pc = adj_pd_total_16cat 
                         adj_pd_total_17cat 
                         adj_pd_total_18cat
                         time  / dist = binomial link = logit ; 
  repeated subject = mcaid_id / type = ind ; *exch;
  store p_model;
run;

ods pdf close; 


TITLE "Model 1: Probability Model with Intercept and Time only"; 
PROC GEE DATA  = &dat DESC;
     CLASS  mcaid_id    
            time 
            ind_cost_pc ;
     model ind_cost_pc = time / dist = binomial link = logit ; 
  repeated subject = mcaid_id / type = ind ; *exch;
/*  store p_model;*/
run;  


TITLE "Model 2: Probability Model with Intercept, Time, int, and int_imp"; 
PROC GEE DATA  = &dat DESC;
     CLASS  mcaid_id    
            time 
            int 
            int_imp 
            ind_cost_pc ;
     model ind_cost_pc = time 
                         int_imp
                         int / dist = binomial link = logit ; 
  repeated subject = mcaid_id / type = ind; *exch;
/*  store p_model;*/
run;

TITLE "Model 3: Probability Model with Intercept, Time, and adj vars (x3)"; 
PROC GEE DATA  = &dat DESC;
     CLASS  mcaid_id    
            adj_pd_total_16cat 
            adj_pd_total_17cat  
            adj_pd_total_18cat
            ind_cost_pc ;
     model ind_cost_pc = adj_pd_total_16cat 
                         adj_pd_total_17cat 
                         adj_pd_total_18cat
                         time  / dist = binomial link = logit ; 
  repeated subject = mcaid_id / type = ind ; *exch;
  store p_model;
run;

ods pdf close; 


TITLE "probability model"; 
PROC GEE DATA  = &dat DESC;
     CLASS  mcaid_id    
            age         sex     race        
            rae_person_new 
            budget_grp_new          fqhc    
            bh_er2016   bh_er2017   bh_er2018 
            bh_hosp2016 bh_hosp2017 bh_hosp2018 
            bh_oth2016  bh_oth2017  bh_oth2018
            adj_pd_total_16cat (ref="-1")
            adj_pd_total_17cat (ref="-1")
            adj_pd_total_18cat (ref="-1")
            time (ref="1")
            int (ref="0")
            int_imp (ref="0")
            ind_cost_pc (ref="0");
     model ind_cost_pc = age            sex             race 
                         rae_person_new budget_grp_new  fqhc
                         bh_er2016      bh_er2017       bh_er2018 
                         bh_hosp2016    bh_hosp2017     bh_hosp2018 
                         bh_oth2016     bh_oth2017      bh_oth2018
                         adj_pd_total_16cat 
                         adj_pd_total_17cat 
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

   
