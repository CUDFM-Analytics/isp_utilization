**********************************************************************************************
AUTHOR   : KTW
PROJECT  : ISP Utilization
PURPOSE  : Macro, COST dv's
VERSION  : 2023-06-22
OUTPUT   : pdf & log file
RELATIONSHIPS : 
Per Mark : Use mode for ref class vars budget_group & race if possible
            - default for budget_grp_num_r is the mode
            - race = I didn't want to tempt fate so just let it choose since it ran w/ default (ok w Mark)
***********************************************************************************************;
%INCLUDE "S:/FHPC/DATA/HCPF_Data_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas";
options source;
%hurdle1_gm_v_gee(dat=data.analysis,  
                  pvar = ind_pc_cost,    
                  cvar = adj_pd_pc_tc,      
                  dv= cost_pc
                  );

%macro hurdle1_gm_v_gee(dat=,pvar=,cvar=,dv=);
%LET today = %sysfunc(today(), yymmdd10.);
%LET log   = &util./code/&dv._gm_norefs_&today..log;
%LET pdf   = &report./&dv._gm_norefs_&today..pdf;

PROC PRINTTO LOG = "&log" NEW; RUN;
ODS PDF FILE     = "&pdf" STARTPAGE = no style=journal;

Title "Proc genmod with same settings as proc gee reports, DV=" &dv.;
footnote "&today";
ods text = "Date: &today";
ods text = "Script: %sysget(SAS_EXECFILENAME)";
ods text = "Log File: &log";

TITLE "Probability Model: " &dv.; 
PROC GENMOD DATA  = &dat;
CLASS  mcaid_id int(ref='0') int_imp(ref='0') budget_grp_num_r 
             race sex rae_person_new age_cat_num fqhc(ref ='0')
             bh_oth16(ref='0')      bh_oth17(ref='0')       bh_oth18(ref='0')
             bh_er16(ref='0')       bh_er17(ref='0')        bh_er18(ref='0')
             bh_hosp16(ref='0')     bh_hosp17(ref='0')      bh_hosp18(ref='0')
             adj_pd_total_16cat(ref='0')
             adj_pd_total_17cat(ref='0')
             adj_pd_total_18cat(ref='0')
       &pvar(ref= '0') ;
MODEL  &pvar = int int_imp time budget_grp_num_r race sex rae_person_new age_cat_num fqhc
             bh_oth16               bh_oth17                bh_oth18
             bh_er16                bh_er17                 bh_er18
             bh_hosp16              bh_hosp17               bh_hosp18
             adj_pd_total_16cat 
             adj_pd_total_17cat 
             adj_pd_total_18cat            / DIST=binomial LINK=logit ; 
REPEATED SUBJECT = mcaid_id / corr=exch ; 
store out=out.pmodel_costpc_genmod_norefs;
run;

* positive cost model ;
TITLE "Cost Model:" &dv; 
PROC GEE DATA  = &dat desc;
WHERE &cvar > 0;
CLASS mcaid_id 
      int(ref="0") int_imp(ref="0") budget_grp_num_r 
      race sex rae_person_new age_cat_num fqhc(ref ="0")
      bh_oth16(ref="0")      bh_oth17(ref="0")       bh_oth18(ref="0")
      bh_er16(ref="0")       bh_er17(ref="0")        bh_er18(ref="0")
      bh_hosp16(ref="0")     bh_hosp17(ref="0")      bh_hosp18(ref="0")
      adj_pd_total_16cat(ref="0")
      adj_pd_total_17cat(ref="0")
      adj_pd_total_18cat(ref="0");
MODEL &cvar = time       season1    season2     season3
                     int        int_imp 
                     age_cat_num        race    sex       
                     budget_grp_num_r   fqhc    rae_person_new 
                     bh_er16    bh_er17     bh_er18
                     bh_hosp16  bh_hosp17   bh_hosp18
                     bh_oth16   bh_oth17    bh_oth18    
                     adj_pd_total_16cat  
                     adj_pd_total_17cat  
                     adj_pd_total_18cat     / dist = gamma link = log ;
REPEATED SUBJECT = mcaid_id / type = exch;
store out=out.cmodel_costpc_genmod_norefs;
RUN;
TITLE; 

* interest group = time invariant ISP participation, which is set twice.
  the top in the stack will be recoded as not exposed (unexposed)
  the bottom group keeps the exposed status;

* [INTGROUP]-------------------------------------------------------
from original dataset as b;
data intgroup;
  set &dat &dat (in = b);
  where int = 1;
  if ^b then int = 0;
  exposed = b;
run;

* the predictions for util and cost will be made for each person twice, once exposed and once unexposed;
* [P_INTGROUP] -----------------------------------------------------
(matching the proc gee specifications to see why results are different)
prob of util / score data from [INTGROUP] and restored [OUT.PMODEL_COSTPC_GENMOD_NOREFS];
proc plm restore=out.pmodel_costpc_genmod_noref;
   score data=intgroup out=p_intgroup predicted=p_prob / ilink;
run;

* [CP_INTGROUP] ----------------------------------------------------
prob of cost from [P_INTGROUP] and cmodel store [OUT.CMODEL_COSTPC_GENMOD_NOREFS];
proc plm restore=out.cmodel_costpc_genmod_noref;
   score data=p_intgroup out=cp_intgroup predicted=p_cost / ilink;
run;

*[OUT.&DV_MEAN_GM]  ------------------------------------------------
person average cost is calculated from [CP_INTGROUP] ;
data out.&dv._mean_gm;
  set cp_intgroup;
  a_cost = p_prob*p_cost;* (1-p term = 0);
run;

* [OUT.&DV_AVP_GM] ------------------------------------------------------ 
group average cost is calculated and contrasted from [OUT.&DV_MEAN_GM] ;
proc sql;
create table out.&dv._avp_gm as
  select mean(case when exposed=1 then a_cost else . end ) as cost_exposed,
         mean(case when exposed=0 then a_cost else . end ) as cost_unexposed,
  calculated cost_exposed - calculated cost_unexposed as cost_diff
  from out.&dv._mean_gm;
quit;

TITLE &dv "avp"; 
proc print data = out.&dv._avp_gm;
run;

proc means data = out.&dv._mean_gm;
by exposed;
var p_prob p_cost a_cost; 
RUN; 

PROC PRINTTO; RUN; 
ODS PDF CLOSE; 
%mend;



