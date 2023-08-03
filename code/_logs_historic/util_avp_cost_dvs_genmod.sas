**********************************************************************************************
AUTHOR   : KTW
PROJECT  : ISP Utilization
PURPOSE  : Hurdle 1, using macro file , COST dv's
VERSION  : 2023-06-22
OUTPUT   : pdf & log file
RELATIONSHIPS : see include statements 
Per Mark : Use mode for ref class vars budget_group & race if possible
            - default for budget_grp_num_r is the mode
            - race = I didn't want to tempt fate so just let it choose since it ran w/ default (ok w Mark)
***********************************************************************************************;
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/macro_hurdle1_cost_dvs_genmod.sas";

%LET date = %sysfunc(today(), yymmdd10.);

ODS PDF FILE = "&report./cost_pc_vars_&date..pdf" startpage=never style=journal;

TITLE "PC Cost Variables Used in Hurdle Model"; 
FOOTNOTE "&date";

PROC PRINT DATA = data.analysis_meta; RUN; 

ods text =  "Frequency tables for categorical variables; use modes as class ref statements";

PROC FREQ DATA = &dat; 
TABLES ind_pc_cost int int_imp time budget_grp_num_r race sex rae_person_new age_cat_num fqhc
             bh_oth16               bh_oth17                bh_oth18
             bh_er16                bh_er17                 bh_er18
             bh_hosp16              bh_hosp17               bh_hosp18
             adj_pd_total_16cat 
             adj_pd_total_17cat 
             adj_pd_total_18cat ;
RUN; 

ods text = "Univariates for cost DV continuous var"; 

PROC UNIVARIATE DATA = &dat; 
VAR adj_pd_pc_tc; 
RUN; 

ods pdf close; 

%hurdle1_genmod(dat=data.analysis,  pvar = ind_pc_cost,    cvar = adj_pd_pc_tc,      dv= cost_pc);
%hurdle1(dat=data.analysis,  pvar = ind_total_cost, cvar = adj_pd_total_tc,   dv= cost_total);
%hurdle1(dat=data.analysis,  pvar = ind_rx_cost,    cvar = adj_pd_rx_tc,      dv= cost_rx);
