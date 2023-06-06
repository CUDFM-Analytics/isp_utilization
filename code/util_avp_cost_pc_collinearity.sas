%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 
libname int clear; 

%LET dat = data.analysis; 
%LET today = %SYSFUNC(today(), YYMMDD10.);



ods pdf file = "S:\FHPC\DATA\HCPF_Data_files_SECURE\Kim\isp\isp_utilization\code\util_avp_cost_pc_allcomb_adj_&today..pdf" startpage=no;
PROC FREQ DATA = data.allcomb_wide; 
TABLE adj_pd_total_16cat*adj_pd_total_17cat*adj_pd_total_18cat*int / list; 
RUN; 
ods pdf close; 


* Get separate datasets that include only each adj variable (by fy), intervention, and ds originated from: ;
DATA adj16 (rename = (adj_pd_total_16cat = value ds16 = ds) keep = int adj_pd_total_16cat ds16 ) 
     adj17 (rename = (adj_pd_total_17cat = value ds17 = ds) keep = int adj_pd_total_17cat ds17 ) 
     adj18 (rename = (adj_pd_total_18cat = value ds18 = ds) keep = int adj_pd_total_18cat ds18 )  ;
SET  &dat (KEEP = int adj: ); 
ds16 = "adj16";
ds17 = "adj17";
ds18 = "adj18";
RUN; 

* append into one ds; 
DATA data.allcomb_long;
SET  adj16 adj17 adj18; 
RUN; 


ods pdf file = "S:\FHPC\DATA\HCPF_Data_files_SECURE\Kim\isp\isp_utilization\code\util_avp_cost_pc_allcomb_adj.pdf" startpage=no;
ods output table = tab_out; 
proc tabulate data = allcomb0;
class int ds value; 
table value='Cat',
      int='Intervention: Invariant'*ds='Year'*(n='n' colpctn='pct')*F=10./ RTS=13.;
run; 

ods output table = tab_out; 
proc tabulate data = allcomb0;
class int ds value; 
table value='Cat',
      ds='Year'*int='Intervention: Invariant'*(n='n' colpctn='pct')*F=10./ RTS=13.;
run; 
ods output close; 
ods pdf close; 

* 
DATA.analysis_numeric =====================================================================;
DATA data.analysis_numeric;
SET  data.analysis; 
format sex race; 
IF sex = 'F' then sex_numeric = 1;
ELSE sex_numeric = 0;
race_numeric = input(race, best7.);
RUN; 
*===========================================================================================;

/*VISUALIZE COLLINEARITY DIAGNOSTICS sas*/
OPTIONS pageno=1 linesize=88 pagesize=60 SOURCE;
%LET root  = %qsubstr(%sysget(SAS_EXECFILEPATH), 1, 
             %length(%sysget(SAS_EXECFILEPATH))-%length(%sysget(SAS_EXECFILEname))-6); *remove \Code\;

%LET script= %qsubstr(%sysget(SAS_EXECFILEPATH), 1, %length(%sysget(SAS_EXECFILEPATH))-4);

%LET file  = %qsubstr(%sysget(SAS_EXECFILENAME), 1, %length(%sysget(SAS_EXECFILENAME))-4);

%LET today = %SYSFUNC(today(), YYMMDD10.);
%put &root ;
%put &script;
%put &file;

* Send log output to code folder, pdf results to reports folder for MG to view;
%LET log   = &script._&today..log;
%LET pdf   = &root./reports/&file._&today..pdf;
/*%put &log &pdf; */

PROC PRINTTO LOG = "&log" NEW; RUN;
ODS PDF FILE     = "&pdf" STARTPAGE = no;

Title &file;

proc odstext;
p "Date:              &today";
p "Project Root: &root";
p "Script:            &file";
p "Log File:         &log";
p "Results File:  &pdf";
RUN; 

/*https://blogs.sas.com/content/iml/2020/02/17/visualize-collinearity-diagnostics.html*/

* find collinearity; 
* for reg have to convert char to numeric: vars race, sex, budget_grp_new; 

/*PROC CORR Data =  data.dat_reg_pc_cost outp=pc_cost_corr;*/
/*VAR int int_imp time age sex_numeric race_numeric*/
/*                         budget_group*/
/*                         rae_person_new  fqhc*/
/*                         bh_2016 bh_2017 bh_2018*/
/*                         adj_pd_total_16cat */
/*                         adj_pd_total_17cat */
/*                         adj_pd_total_18cat;*/
/*RUN; */
/**/
/*DATA pc_cost_corr_ge70 (drop=i);*/
/*set  pc_cost_corr (where=(_TYPE_ in ("CORR")));*/
/*array col(*) int--adj_pd_total_18cat;*/
/*do i=1 to dim(col);*/
/*if (col{i}<0.6 AND col{i}>-.6) OR col{i}=1 then col{i}=.; */
/*end; */
/*RUN; */
/**/
/*%let keep_vars = _type_ _name_ int int_imp age budget_group; */
/*DATA pc_cost_corr_print ;*/
/*SET  pc_cost_corr_ge70 (keep = &keep_vars);*/
/*RUN; */
/**/
/*PROC PRINT DATA = pc_cost_corr_print; */
/*RUN; */

proc contents data = &dat varnum; run; 

PROC REG DATA = data.analysis_numeric;
MODEL ind_pc_cost = int         int_imp     time 
                    season1     season2     season3
                    age         sex_numeric race_numeric
                    budget_group
                    rae_person_new      fqhc
                    bh_2016     bh_2017     bh_2018
                    adj_pd_total_16cat 
                    adj_pd_total_17cat 
                    adj_pd_total_18cat / tol vif collin covb; 
ods select ParameterEstimates CollinDiag; 
ods output CollinDiag = Collin;
RUN ;  Quit; 

proc format;
value CollinFmt 
  0.0 -<  0.4  = "PropLow"
  0.4 -<  0.5  = "PropMed"
  0.5 -<  1.0  = "PropHigh"
  1.0 -<  20   = "CondLow"
   20 -<  30   = "CondMed"
   30 -< 100   = "CondHigh"
   other       = "CondExtreme";
run;

data CollinLong;
length VarName $32 TextVal $5;
set collin(drop=Model Dependent Eigenvalue);
array v[*] _numeric_;
do j = 2 to dim(v);
   VarName = vname(v[j]);
   Val = v[j];
   if j=2 then TextVal = put(Val, 5.0);
   else do;
      if Val<0.4 then TextVal = ' ';
      else TextVal = put(100*Val, 2.0); *convert proportion to pct;
   end;
   output;
end;
keep Number VarName Val TextVal;
run;

/*Title "Collinearity Diagnostics Long";*/
/*proc print data = collinlong ; */
/*run ; */
/*title; */

/* create a discrete attribute map:
   https://blogs.sas.com/content/iml/2019/07/15/create-discrete-heat-map-sgplot.html
*/
data Order;                            /* create discrete attribute map */
length Value $15 FillColor $15;
input raw FillColor;
Value = put(raw, CollinFmt.);          /* use format to assign values */
retain ID 'SortOrder'                  /* name of map */
     Show 'AttrMap';                   /* always show all groups in legend */
datalines;
0   White 
0.4 VeryLightRed
0.5 ModerateRed
1   VeryLightGreen 
20  VeryLightYellow
30  LightOrange
100 CXF03B20
;

/* Create a discrete heat map and overlay text for the condition numbers 
   and the important (high) cells of the proportion of variance. */
title "Collinearity Diagnostics";
proc sgplot data=CollinLong dattrmap=Order noautolegend;
  format Val CollinFmt.;
  heatmapparm x=VarName y=Number colorgroup=Val / outline 
              attrid=SortOrder nomissingcolor discretey;
  text x=VarName y=Number text=TextVal / strip textattrs=(size=14);
  refline "ConditionIndex" / axis=x lineattrs=(color=DarkGray)
          discreteoffset=0.5 discretethickness=0.08;
  xaxis display=(nolabel);
run;

proc printto; run; 
ods pdf close; 

* 
LOGISTIC ==============================================================================
===========================================================================================;
proc logistic data = &dat;
CLASS  mcaid_id   
       age (ref='1')
       race
       sex
       time
       budget_group
       int            (ref='0')
       int_imp        (ref='0')
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
MODEL ind_pc_cost = int int_imp time 
                    age sex race
                         budget_group
                         rae_person_new  fqhc
                         bh_er16      bh_er17       bh_er18 
                         bh_hosp16    bh_hosp17     bh_hosp18 
                         bh_oth16     bh_oth17      bh_oth18
                         adj_pd_total_16cat 
                         adj_pd_total_17cat 
                         adj_pd_total_18cat ; 
store logistic_pc_model / label = "cost_pc_logistic";
ods select parameterEstimates;
RUN; 

proc plm restore= logistic_pc_model;
   show Hessian CovB;
   ods output Cov=CovB;
run;

proc iml;
use CovB nobs p;                         /* read number of obs (p) */
   cols = "Col1":("Col"+strip(char(p))); /* variable names are Col1 - Colp */
   read all var cols into Cov;           /* read COVB matrix */
   read all var "Parameter";             /* read names of parameters */
close;

/* Hessian and covariance matrices are inverses */
Hessian = inv(Cov);
print Hessian[r=Parameter c=Parameter F=BestD8.4];

v = eigval(Hessian); /* show Hessian is positive definite */
print v;

/* incidentally, stderr are the sqrt of diagonal elements */
stderr = sqrt(vecdiag(Cov)); 
*print stderr;
quit;


ods GRAPHICS ON; 
PROC PRINCOMP DATA = &DAT
    std
    OUT=PCOUT
    PLOTS=(SCREE PROFILE PATTERN SCORE);
var int int_imp time ind_pc_cost
                    age 
                         budget_group
                         rae_person_new  fqhc
                         bh_er16      bh_er17       bh_er18 
                         bh_hosp16    bh_hosp17     bh_hosp18 
                         bh_oth16     bh_oth17      bh_oth18
                         adj_pd_total_16cat 
                         adj_pd_total_17cat 
                         adj_pd_total_18cat ;
ods output eigenvectors=EV;
RUN; 
