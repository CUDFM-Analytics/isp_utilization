**********************************************************************************************
AUTHOR   : KTW
PROJECT  : ISP Utilization
PURPOSE  : Hurdle Model, Primary Care Costs
VERSION  : 2023-05-18
OUTPUT   : pdf & log file
REFS     : enter some output into util_isp_predicted_costs.xlsx
***********************************************************************************************;
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 

%LET dat = data.analysis; 
%put &dat; 

PROC PRINT DATA = data.analysis_meta; RUN;

%LET log = S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_avp_cost_total_.log;
%LET pdf = S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_avp_cost_total_.pdf;

PROC PRINTTO LOG ="&log"; RUN;
ODS PDF FILE     ="&pdf"; RUN;

TITLE "Probability Model: FFS Total Cost"; 
PROC GEE DATA  = &dat DESC;
CLASS  mcaid_id   
       season1(ref='-1')    season2(ref='-1')     season3(ref='-1')      
       int    (ref= '0')    int_imp(ref= '0')
       age    (ref= '1')    race                  sex            
       budget_group         fqhc(ref= '0')        rae_person_new
       bh_hosp16(ref= '0')  bh_hosp17(ref= '0')   bh_hosp18(ref= '0')
       bh_er16  (ref= '0')  bh_er16  (ref= '0')   bh_er16  (ref= '0')
       bh_oth16 (ref= '0')  bh_oth17 (ref= '0')   bh_oth17 (ref= '0')
       adj_pd_total_16cat(ref='-1')  
       adj_pd_total_17cat(ref='-1')   
       adj_pd_total_18cat(ref='-1')
       ind_total_cost       (ref= '0') ;
MODEL  ind_total_cost = time       season1    season2     season3
                        int        int_imp 
                        age        race        sex       
                        budget_group           fqhc       rae_person_new 
                        bh_er16    bh_er17     bh_er18
                        bh_hosp16  bh_hosp17   bh_hosp18
                        bh_oth16   bh_oth17    bh_oth18    
                        adj_pd_total_16cat  
                        adj_pd_total_17cat  
                        adj_pd_total_18cat     
        / DIST=binomial LINK=logit ; 
REPEATED SUBJECT = mcaid_id / type=exch ; 
store p_MODEL;
run;

* positive cost model ;
TITLE "Cost Model: total"; 
PROC GEE DATA  = &dat desc;
WHERE adj_pd_total_tc > 0;
CLASS mcaid_id   
      season1(ref='-1')    season2(ref='-1')     season3(ref='-1')      
      int    (ref= '0')    int_imp(ref= '0')
      age    (ref= '1')    race                  sex            
      budget_group         fqhc(ref= '0')        rae_person_new
      bh_hosp16(ref= '0')  bh_hosp17(ref= '0')   bh_hosp18(ref= '0')
      bh_er16  (ref= '0')  bh_er16  (ref= '0')   bh_er16  (ref= '0')
      bh_oth16 (ref= '0')  bh_oth17 (ref= '0')   bh_oth17 (ref= '0')
      adj_pd_total_16cat(ref='-1')  
      adj_pd_total_17cat(ref='-1')   
      adj_pd_total_18cat(ref='-1');

MODEL adj_pd_total_tc = time       season1    season2     season3
                        int        int_imp 
                        age        race        sex       
                        budget_group           fqhc       rae_person_new 
                        bh_er16    bh_er17     bh_er18
                        bh_hosp16  bh_hosp17   bh_hosp18
                        bh_oth16   bh_oth17    bh_oth18    
                        adj_pd_total_16cat  
                        adj_pd_total_17cat  
                        adj_pd_total_18cat     / dist = gamma link = log ;
REPEATED SUBJECT = mcaid_id / type = exch;
store c_model;
RUN;
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
data out.meanCost_total;
  set cp_intgroup;
  a_cost = p_prob*p_cost;* (1-p term = 0);
run;

* group average cost is calculated and contrasted ;
proc sql;
create table out.avp_cost_total as
  select mean(case when exposed=1 then a_cost else . end ) as cost_exposed,
         mean(case when exposed=0 then a_cost else . end ) as cost_unexposed,
  calculated cost_exposed - calculated cost_unexposed as cost_diff
  from out.meanCost_total;
quit;

TITLE "avp_cost_total"; 
proc print data = out.avp_cost_total;
run;

proc means data = out.meancost_total;
by exposed;
var p_prob p_cost a_cost; 
RUN; 

PROC PRINTTO; RUN; 
ODS PDF CLOSE; 

   
