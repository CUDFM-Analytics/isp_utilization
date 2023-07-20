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
%macro hurdle_gee(dat=,pvar=,cvar=,dv=);
* Send log output to code folder, pdf results to reports folder for MG to view;
%LET root_dir  = %qsubstr(%sysget(SAS_EXECFILEPATH), 1, 
             %length(%sysget(SAS_EXECFILEPATH))-%length(%sysget(SAS_EXECFILEname))-6); *remove \Code\;

%LET script  = %qsubstr(%sysget(SAS_EXECFILEPATH), 1, 
               %length(%sysget(SAS_EXECFILEPATH))-4);

%LET log   = &util./code/&dv._gee_&today..log;
%LET pdf   = &report./&dv._gee_&today..pdf;

PROC PRINTTO LOG = "&log" NEW; RUN;
ODS PDF FILE     = "&pdf" STARTPAGE = no;

Title &dv.;

proc odstext;
p "Date: &today";
p "Root: &root_dir";
p "Script: &script";
p "Log File: &log";
p "Results File: &pdf";
RUN; 

TITLE "Probability Model"; 
PROC GEE DATA  = &dat DESC;
CLASS  mcaid_id int(ref="0") int_imp(ref="0") budget_grp_num_r 
             race sex rae_person_new age_cat_num fqhc(ref ="0")
             bh_oth16(ref="0")      bh_oth17(ref="0")       bh_oth18(ref="0")
             bh_er16(ref="0")       bh_er17(ref="0")        bh_er18(ref="0")
             bh_hosp16(ref="0")     bh_hosp17(ref="0")      bh_hosp18(ref="0")
             adj_pd_total_16cat(ref="0")
             adj_pd_total_17cat(ref="0")
             adj_pd_total_18cat(ref="0")
       &pvar(ref= "0") ;
MODEL  &pvar = int int_imp time budget_grp_num_r race sex rae_person_new age_cat_num fqhc
             bh_oth16               bh_oth17                bh_oth18
             bh_er16                bh_er17                 bh_er18
             bh_hosp16              bh_hosp17               bh_hosp18
             adj_pd_total_16cat 
             adj_pd_total_17cat 
             adj_pd_total_18cat            / DIST=binomial LINK=logit ; 
REPEATED SUBJECT = mcaid_id / type=exch ; 
store out=out.costpc_logit_gee;
run;

* positive cost model ;
TITLE "Cost Model"; 
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
store out=out.costpc_gamma_gee;
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
* [P_INTGROUP]
 prob of util------------------------------------------------- ;
proc plm restore=out.costpc_logit_gee;
   score data=intgroup out=p_intgroup predicted=p_prob / ilink;
run;

* [CP_INTGROUP] 
prob of cost -------------------------------------------------;
proc plm restore=out.costpc_gamma_gee;
   score data=p_intgroup out=cp_intgroup predicted=p_cost / ilink;
run;

* [out.&dv._meanCost_gee]
person average cost is calculated------------------------------;
data out.&dv._meanCost_gee;
  set cp_intgroup;
  a_cost = p_prob*p_cost;* (1-p term = 0);
run;

* [out.&dv._avp_gee]
group average cost is calculated and contrasted-----------------;
proc sql;
create table out.&dv._avp_gee as
  select mean(case when exposed=1 then a_cost else . end ) as cost_exposed,
         mean(case when exposed=0 then a_cost else . end ) as cost_unexposed,
  calculated cost_exposed - calculated cost_unexposed as cost_diff
  from out.&dv._meanCost_gee;
quit;

TITLE "&dv._avp_gee"; 
proc print data = out.&dv._avp_gee;
run;

proc means data = out.&dv._meancost_gee;
by exposed;
var p_prob p_cost a_cost; 
RUN; 

PROC PRINTTO; RUN; 
ODS PDF CLOSE; 
%mend;



