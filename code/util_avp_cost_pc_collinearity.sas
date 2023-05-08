%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 
libname int clear; 

%LET dat = data.analysis_dataset; 

DATA data.allcomb_wide; 
SET  &dat (KEEP = int adj: ); 
RUN; 


ods pdf file = "S:\FHPC\DATA\HCPF_Data_files_SECURE\Kim\isp\isp_utilization\code\util_avp_cost_pc_allcomb_adj_v2.pdf" startpage=no;
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


/*VISUALIZE COLLINEARITY DIAGNOSTICS sas*/
/*https://blogs.sas.com/content/iml/2020/02/17/visualize-collinearity-diagnostics.html*/

* find collinearity; 
* for reg have to convert char to numeric: vars race, sex, budget_grp_new; 


ods pdf file = "S:\FHPC\DATA\HCPF_Data_files_SECURE\Kim\isp\isp_utilization\code\proc_reg_collin_2023-05-08.pdf";

PROC CORR Data =  data.dat_reg_pc_cost outp=pc_cost_corr;
VAR int int_imp time age sex_numeric race_numeric
                         budget_group
                         rae_person_new  fqhc
                         bh_er16      bh_er17       bh_er18 
                         bh_hosp16    bh_hosp17     bh_hosp18 
                         bh_oth16     bh_oth17      bh_oth18
                         adj_pd_total_16cat 
                         adj_pd_total_17cat 
                         adj_pd_total_18cat;
RUN; 

DATA pc_cost_corr_ge70 (drop=i);
set  pc_cost_corr (where=(_TYPE_ in ("CORR")));
array col(*) int--adj_pd_total_18cat;
do i=1 to dim(col);
if (col{i}<0.6 AND col{i}>-.6) OR col{i}=1 then col{i}=.; 
end; 
RUN; 

PROC REG DATA = data.dat_reg_pc_cost;
MODEL ind_pc_cost = int int_imp time 
                    age sex_numeric race_numeric
                         budget_group
                         rae_person_new  fqhc
                         bh_er16      bh_er17       bh_er18 
                         bh_hosp16    bh_hosp17     bh_hosp18 
                         bh_oth16     bh_oth17      bh_oth18
                         adj_pd_total_16cat 
                         adj_pd_total_17cat 
                         adj_pd_total_18cat / tol vif collin ; 
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

Title "Collinearity Diagnostics Long";
proc print data = collinlong ; 
run ; 
title; 

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

ods pdf close; 

