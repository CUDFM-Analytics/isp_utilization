**********************************************************************************************
AUTHOR   : KTW
PROJECT  : ISP Utilization
PURPOSE  : Macro, COST dv's using GENMOD instead of PROC GEE
VERSION  : 2023-06-29
OUTPUT   : pdf & log file w/ _genmod string

https://stats.oarc.ucla.edu/sas/dae/negative-binomial-regression/
The param=ref option changes the coding of prog from effect coding, which is the default, to reference coding. 
The ref=first option changes the reference group to the first level of prog.  We have used two options 
on the model statement.  The type3 option is used to get the multi-degree-of-freedom test of the categorical 
variables listed on the class statement, and the dist = negbin option is used to indicate that a 
negative binomial distribution should be used. 
***********************************************************************************************;
%LET dat = data.analysis; 
%LET today = %sysfunc(today(), yymmdd10.);


%macro hurdle1_genmod(dat=,pvar=,cvar=,dv=);
%LET today = %sysfunc(today(), yymmdd10.);
* Send log output to code folder, pdf results to reports folder for MG to view;
%LET log   = &util./code/&dv._gm_&today..log;
%LET pdf   = &report./&dv._gm_&today..pdf;

PROC PRINTTO LOG = "&log" NEW; RUN;
ODS PDF FILE     = "&pdf" STARTPAGE = no style=journal;

Title "&dv.";
footnote "&today";
ods text = "Date: &today";
ods text = "Script: %sysget(SAS_EXECFILENAME)";
ods text = "Log File: &log";
ods text = "Results File: &pdf";

TITLE "Probability Model: " &dv.; 
PROC GENMOD DATA  = &dat;
CLASS  mcaid_id int int_imp budget_grp_num_r 
             race(ref='non-Hispanic White/Caucasian') 
             sex(ref='Female')
             rae_person_new(ref='3')
             age_cat_num(ref='5') 
             fqhc
             bh_oth16      bh_oth17       bh_oth18
             bh_er16       bh_er17        bh_er18
             bh_hosp16     bh_hosp17      bh_hosp18
             adj_pd_total_16cat
             adj_pd_total_17cat
             adj_pd_total_18cat
        &pvar 
        / (param=ref ref=first);
MODEL  &pvar(event='1') = int int_imp time budget_grp_num_r race sex rae_person_new age_cat_num fqhc
             bh_oth16               bh_oth17                bh_oth18
             bh_er16                bh_er17                 bh_er18
             bh_hosp16              bh_hosp17               bh_hosp18
             adj_pd_total_16cat 
             adj_pd_total_17cat 
             adj_pd_total_18cat            / DIST=binomial LINK=logit ; 
             * default link is logit for genmod so don't need to specify it but it's fine; 
REPEATED SUBJECT = mcaid_id / type=exch; 
store out=out.store_prob_pcCost;
run;

* positive cost model ;
TITLE "Cost Model: " &dv; 
PROC GENMOD DATA  = &dat desc;
WHERE &cvar > 0;
CLASS mcaid_id 
      int int_imp budget_grp_num_r 
      race(ref='non-Hispanic White/Caucasian') 
      sex(ref='Female') 
      rae_person_new(ref='3') 
      age_cat_num(ref='5')  
      fqhc(ref ='0')
      bh_oth16      bh_oth17       bh_oth18
      bh_er16       bh_er17        bh_er18
      bh_hosp16     bh_hosp17      bh_hosp18
      adj_pd_total_16cat
      adj_pd_total_17cat
      adj_pd_total_18cat
            / param=ref ref=first;
MODEL &cvar = time       season1    season2     season3
                     int        int_imp 
                     age_cat_num        race    sex       
                     budget_grp_num_r   fqhc    rae_person_new 
                     bh_er16    bh_er17     bh_er18
                     bh_hosp16  bh_hosp17   bh_hosp18
                     bh_oth16   bh_oth17    bh_oth18    
                     adj_pd_total_16cat  
                     adj_pd_total_17cat  
                     adj_pd_total_18cat     / dist=gamma link=log ;
                     * specify link = log because default is logit for genmod;
REPEATED SUBJECT = mcaid_id / type = exch;
store out=out.store_cost_pcCost;

RUN;
TITLE; 

data intgroup;
  set &dat &dat (in = b);
  where int = 1;
  if ^b then int = 0;
  exposed = b;
run;

* the predictions for util and cost will be made for each person twice, once exposed and once unexposed;

* prob of util ;
proc plm restore = out.store_prob_pcCost;
   score data=intgroup out=p_intgroup predicted=p_prob / ilink;
run;

* prob of cost ;
proc plm restore = out.store_cost_pcCost;
   score data=p_intgroup out=cp_intgroup predicted=p_cost / ilink;
run;

* person average cost is calculated ;
data out.&dv._mean_genmod;
  set cp_intgroup;
  a_cost = p_prob*p_cost;* (1-p term = 0);
run;

* group average cost is calculated and contrasted ;
proc sql;
create table out.&dv._avp as
  select mean(case when exposed=1 then a_cost else . end ) as cost_exposed,
         mean(case when exposed=0 then a_cost else . end ) as cost_unexposed,
  calculated cost_exposed - calculated cost_unexposed as cost_diff
  from out.&dv._mean_genmod;
quit;

TITLE "&dv._avp"; 
proc print data = out.&dv._avp;
run;

proc means data = out.&dv._mean_genmod;
by exposed;
var p_prob p_cost a_cost; 
RUN; 

PROC PRINTTO; RUN; 
ODS PDF CLOSE; 
%mend;



