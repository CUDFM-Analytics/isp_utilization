**********************************************************************************************
AUTHOR   : KTW
PROJECT  : ISP Utilization
PURPOSE  : Hurdle Model, Primary Care Costs
VERSION  : 2023-06-08
OUTPUT   : pdf & log file
NOTES    : See 'variables_to_copy_paste.txt' for full lists of vars
Per Mark : Use mode for ref class vars budget_group, race

***********************************************************************************************;
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 
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
%LET pvar = ind_pc_cost;
%LET cvar = adj_pd_pc_tc;

PROC PRINT DATA = data.analysis_meta; RUN; 

*
[MACRO] ==============================================================================
=========================================================================================;
%macro p_model(class_vars=,model_vars=, model_number=);
TITLE "Probability Model: DV PC Cost &model_number." ;
TITLE2 "With model vars &model_vars" ;  
PROC GEE DATA  = &dat;
CLASS  &class_vars;
MODEL  ind_pc_cost = &model_vars / DIST=binomial LINK=logit ; 
REPEATED SUBJECT = mcaid_id / type=exch ; 
/*store p_MODEL;*/
run;
TITLE; TITLE2;
%mend;

* 
[Models] ==============================================================================
1. Success
2. Failure
Variable Priorities (can remove once finalized)
1. mcaid_id 
2. int(ref='0') 
3. int_imp(ref= '0') 
4. budget_group   (mode already default: numeric 5, format MAGI Eligible Children )
5. race 
6. sex
7. rae_person_new (use mode as reference: =3
* try age_cat first (give priority)
age_cat(ref='1') 
age(ref='1') 
fqhc(ref='0') 
* Try original bh variables  
bh_2018(ref='0')
adj_pd_total_18cat(ref='-1') 
ind_pc_cost(ref= '0')
===========================================================================================;

            %LET class01 = mcaid_id int(ref='0') int_imp(ref= '0') ind_pc_cost(ref= '0');
            %LET model01 = int int_imp time;          
            %p_model(class_vars=&class01, model_vars=&model01);
            
            * The below DID NOT WORK! Why??;
            %LET class02 = mcaid_id int(ref='0') int_imp(ref= '0') ind_pc_cost(ref= '0') budget_grp_new(ref="MAGI Eligible Children");
            %LET model02 = int int_imp time budget_grp_new;          
            %p_model(class_vars=&class02, model_vars=&model02);
            * HESSIAN ERROR = tried without ref, with ref=Disabled, etc... no go...;

proc freq data = &dat;
tables int int_imp ind_pc_cost budget_grp_num_r race sex rae_person_new age_cat_num; 
RUN; 


%LET class = mcaid_id int(ref='0') int_imp(ref='0') ind_pc_cost(ref='0') budget_grp_num_r 
             race sex rae_person_new age_cat_num fqhc(ref ='0')
             bh_oth16(ref='0')      bh_oth17(ref='0')       bh_oth18(ref='0')
             bh_er16(ref='0')       bh_er17(ref='0')        bh_er18(ref='0')
             bh_hosp16(ref='0')     bh_hosp17(ref='0')      bh_hosp18(ref='0')
             adj_pd_total_18cat;
%LET model = int int_imp time budget_grp_num_r race sex rae_person_new age_cat_num fqhc
             bh_oth16               bh_oth17                bh_oth18
             bh_er16                bh_er17                 bh_er18
             bh_hosp16              bh_hosp17               bh_hosp18
             adj_pd_total_18cat;          
%p_model(class_vars=&class, model_vars=&model);
* 1. budget_grp_num_r uses ref=5 but if I specify that as a reference, I get Hessian error?? Why??;
* 2. age_cat_num: SUCCESS //
  3. fqhc(ref='0')
  4. bh_all originals: SUCCESS
  5. tried with adj's, and with ref: (ref='-1') HESSIAN
  6. tried without refs, HESSIAN
  7. Tried with only adj_..._18cat - wouldn't run;


TITLE "Probability Model: PC Cost"; 
PROC GEE DATA  = &dat DESC;
CLASS  mcaid_id   
       int(ref= '0')        int_imp(ref= '0')
/*       age    (ref= '1')    */
       race                 sex            
       budget_group         
       fqhc(ref= '0')        rae_person_new
       bh_2016(ref= '0')    bh_2017(ref= '0')     bh_2018(ref= '0')
/*     bh_hosp16(ref= '0')  bh_hosp17(ref= '0')   bh_hosp18(ref= '0')*/
/*     bh_er16  (ref= '0')  bh_er16  (ref= '0')   bh_er16  (ref= '0')*/
/*     bh_oth16 (ref= '0')  bh_oth17 (ref= '0')   bh_oth17 (ref= '0')*/
/*       adj_pd_total_16cat(ref='-1')  */
/*       adj_pd_total_17cat(ref='-1')   */
/*       adj_pd_total_18cat(ref='-1')*/
       ind_pc_cost       (ref= '0') ;
MODEL  ind_pc_cost = &mod9_varlist        / DIST=binomial LINK=logit ; 
REPEATED SUBJECT = mcaid_id / type=exch ; 
store p_MODEL;
run;

* positive cost model ;
TITLE "Cost Model: PC"; 
PROC GEE DATA  = &dat desc;
WHERE adj_pd_pc_tc > 0;
CLASS mcaid_id   
      season1(ref='-1')    season2(ref='-1')     season3(ref='-1')      
      int    (ref= '0')    int_imp(ref= '0')
      age    (ref= '1')    race                  sex            
      budget_group         fqhc(ref= '0')        rae_person_new(ref='1')
      bh_hosp16(ref= '0')  bh_hosp17(ref= '0')   bh_hosp18(ref= '0')
      bh_er16  (ref= '0')  bh_er16  (ref= '0')   bh_er16  (ref= '0')
      bh_oth16 (ref= '0')  bh_oth17 (ref= '0')   bh_oth17 (ref= '0')
      adj_pd_total_16cat(ref='-1')  
      adj_pd_total_17cat(ref='-1')   
      adj_pd_total_18cat(ref='-1');

MODEL adj_pd_pc_tc = time       season1    season2     season3
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
data out.meanCost;
  set cp_intgroup;
  a_cost = p_prob*p_cost;* (1-p term = 0);
run;

* group average cost is calculated and contrasted ;
proc sql;
create table out.avp_cost_pc as
  select mean(case when exposed=1 then a_cost else . end ) as cost_exposed,
         mean(case when exposed=0 then a_cost else . end ) as cost_unexposed,
  calculated cost_exposed - calculated cost_unexposed as cost_diff
  from meanCost;
quit;

TITLE "avp_cost_pc"; 
proc print data = out.avp_cost_pc;
run;

proc means data = out.meancost;
by exposed;
var p_prob p_cost a_cost; 
RUN; 

PROC PRINTTO; RUN; 
ODS PDF CLOSE; 

   
