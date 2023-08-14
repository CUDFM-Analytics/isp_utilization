**********************************************************************************************
AUTHOR   : KTW
PROJECT  : ISP Utilization
PURPOSE  : Hurdle Model, Total Pd Cost
VERSION  : 2023-06-21
OUTPUT   : pdf & log file
NOTES    : See 'variables_to_copy_paste.txt' for full lists of vars
Per Mark : Use mode for ref class vars budget_group, race

***********************************************************************************************;
%INCLUDE "S:/FHTotal/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 
libname ana clear;
libname raw clear;

OPTIONS pageno=1 linesize=88 pagesize=60 SOURCE;
%LET root  = %qsubstr(%sysget(SAS_EXECFILEPATH), 1, 
             %length(%sysget(SAS_EXECFILEPATH))-%length(%sysget(SAS_EXECFILEname))-6); *remove \Code\;

%LET script= %qsubstr(%sysget(SAS_EXECFILEPATH), 1, %length(%sysget(SAS_EXECFILEPATH))-4);

%LET file  = %qsubstr(%sysget(SAS_EXECFILENAME), 1, %length(%sysget(SAS_EXECFILENAME))-4);

%LET today = %SYSFUNC(today(), YYMMDD10.);

* Send log output to code folder, pdf results to reports folder for MG to view;
%LET log   = &root./code/&file._&today..log;
%LET pdf   = &root./reports/&file._&today..pdf;

PROC PRINTTO LOG = "&log" NEW; RUN;
ODS PDF FILE     = "&pdf" STARTPAGE = no;

Title &file;

proc odstext;
p "Date: &today";
p "Root: &root";
p "Script: &file";
p "Log File: &log";
p "Results File: &pdf";
RUN; 

%LET dat  = data.analysis; 
%LET pvar = ind_total_cost;
%LET cvar = adj_pd_total_tc;

TITLE "Probability Model: Total Cost"; 
PROC GEE DATA  = &dat DESC;
CLASS  mcaid_id int(ref="0") int_imp(ref="0") budget_grp_num_r 
             race sex rae_person_new age_cat_num fqhc(ref ="0")
             bh_oth16(ref="0")      bh_oth17(ref="0")       bh_oth18(ref="0")
             bh_er16(ref="0")       bh_er17(ref="0")        bh_er18(ref="0")
             bh_hosp16(ref="0")     bh_hosp17(ref="0")      bh_hosp18(ref="0")
             adj_pd_total_16cat(ref="0")
             adj_pd_total_17cat(ref="0")
             adj_pd_total_18cat(ref="0")
       ind_total_cost(ref= "0") ;
MODEL  ind_total_cost = int int_imp time budget_grp_num_r race sex rae_person_new age_cat_num fqhc
             bh_oth16               bh_oth17                bh_oth18
             bh_er16                bh_er17                 bh_er18
             bh_hosp16              bh_hosp17               bh_hosp18
             adj_pd_total_16cat 
             adj_pd_total_17cat 
             adj_pd_total_18cat            / DIST=binomial LINK=logit ; 
REPEATED SUBJECT = mcaid_id / type=exch ; 
store p_MODEL;
run;

* positive cost model ;
TITLE "Cost Model: Total"; 
PROC GEE DATA  = &dat desc;
WHERE adj_pd_total_tc > 0;
CLASS mcaid_id 
      int(ref="0") int_imp(ref="0") budget_grp_num_r 
      race sex rae_person_new age_cat_num fqhc(ref ="0")
      bh_oth16(ref="0")      bh_oth17(ref="0")       bh_oth18(ref="0")
      bh_er16(ref="0")       bh_er17(ref="0")        bh_er18(ref="0")
      bh_hosp16(ref="0")     bh_hosp17(ref="0")      bh_hosp18(ref="0")
      adj_pd_total_16cat(ref="0")
      adj_pd_total_17cat(ref="0")
      adj_pd_total_18cat(ref="0");
MODEL adj_pd_total_tc = time       season1    season2     season3
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
data out.cost_total_meanCost;
  set cp_intgroup;
  a_cost = p_prob*p_cost;* (1-p term = 0);
run;

* group average cost is calculated and contrasted ;
proc sql;
create table out.avp_cost_total as
  select mean(case when exposed=1 then a_cost else . end ) as cost_exposed,
         mean(case when exposed=0 then a_cost else . end ) as cost_unexposed,
  calculated cost_exposed - calculated cost_unexposed as cost_diff
  from out.cost_total_meanCost;
quit;

TITLE "avp_cost_total"; 
proc print data = out.avp_cost_total;
run;

proc means data = out.cost_total_meancost;
by exposed;
var p_prob p_cost a_cost; 
RUN; 

PROC PRINTTO; RUN; 
ODS PDF CLOSE; 
