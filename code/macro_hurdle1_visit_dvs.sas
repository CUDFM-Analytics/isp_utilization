**********************************************************************************************
AUTHOR   : KTW
PROJECT  : ISP Utilization
PURPOSE  : Macro, Visit dv's
VERSION  : 2023-06-22
OUTPUT   : pdf & log file
RELATIONSHIPS : 
NOTES    : changed outcome vars so it's an integer (multiply all by 6)
***********************************************************************************************;
%macro hurdle1(dat=,pvar=,nvar=,dv=);
* Send log output to code folder, pdf results to reports folder for MG to view;
%LET log   = &util./code/&dv._&today..log;
%LET pdf   = &report./&dv._&today..pdf;

PROC PRINTTO LOG = "&log" NEW; RUN;
ODS PDF FILE     = "&pdf" STARTPAGE = no;

Title &dv.;

proc odstext;
p "Date: &today";
p "Log File: &log";
p "Results File: &pdf";
RUN; 

TITLE "Probability Model: " &dv.; 
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
store p_MODEL;
run;

* positive visit model ;
TITLE "Visit Model: " &dv; 
PROC GEE DATA  = &dat desc;
WHERE &nvar > 0;
CLASS mcaid_id 
      int(ref="0") int_imp(ref="0") budget_grp_num_r 
      race sex rae_person_new age_cat_num fqhc(ref ="0")
      bh_oth16(ref="0")      bh_oth17(ref="0")       bh_oth18(ref="0")
      bh_er16(ref="0")       bh_er17(ref="0")        bh_er18(ref="0")
      bh_hosp16(ref="0")     bh_hosp17(ref="0")      bh_hosp18(ref="0")
      adj_pd_total_16cat(ref="0")
      adj_pd_total_17cat(ref="0")
      adj_pd_total_18cat(ref="0");
MODEL &nvar = time   season1    season2     season3
                     int        int_imp 
                     age_cat_num        race    sex       
                     budget_grp_num_r   fqhc    rae_person_new 
                     bh_er16    bh_er17     bh_er18
                     bh_hosp16  bh_hosp17   bh_hosp18
                     bh_oth16   bh_oth17    bh_oth18    
                     adj_pd_total_16cat  
                     adj_pd_total_17cat  
                     adj_pd_total_18cat     / dist = negbin link = log ;
REPEATED SUBJECT = mcaid_id / type = exch;
store n_model;
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

* the predictions for util and visits will be made for each person twice, once exposed and once unexposed;

* prob of util ;
proc plm restore=p_model;
   score data=intgroup out=p_intgroup predicted=p_prob / ilink;
run;

* prob of visits ;
proc plm restore=n_model;
   score data=p_intgroup out=np_intgroup predicted=p_visit / ilink;
run;

* person average visits is calculated ;
data meanVisits;
  set np_intgroup;
  a_visit = p_prob*p_visit;* (1-p term = 0);
run;

* group average visits is calculated and contrasted ;
proc sql;
create table out.&dv._avp as
  select mean(case when exposed=1 then a_visit else . end ) as n_visits_exposed,
         mean(case when exposed=0 then a_visit else . end ) as n_visits_unexposed,
  calculated n_visits_exposed - calculated n_visits_unexposed as n_visit_diff
  from meanVisits;
quit;

TITLE "&dv._avp"; 
proc print data = out.&dv._avp;
run;

proc means data = out.&dv._meanVisits;
by exposed;
var p_prob p_visits a_visit; 
RUN; 

PROC PRINTTO; RUN; 
ODS PDF CLOSE; 
%mend;



