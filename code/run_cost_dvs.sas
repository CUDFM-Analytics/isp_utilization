**********************************************************************************************
AUTHOR   : KTW
PROJECT  : ISP Utilization
PURPOSE  : Hurdle 1, using macro file , COST dv's
VERSION  : 2023-08-24
OUTPUT   : pdf & log file
LOG      : Changed data.analysis_final to data.analysis (moved the original data.analysis to int.analysis3, then renamed _final)
RELATIONSHIPS : see include statements 
Per Mark : Use mode for ref class vars budget_group & race if possible
            - default for budget_grp_num_r is the mode
            - race = I didn't want to tempt fate so just let it choose since it ran w/ default (ok w Mark)
***********************************************************************************************;
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/config.sas"; 
libname int clear; 
PROC CONTENTS DATA = data.utilization VARNUM; run; 
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/macro_hurdle_costs.sas";
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/macro_results.sas";

* [NOTES %HURDLE] ==============================================================================
1. [PARAMS] pvar: Indicator variable where 1 indicates cost>0, 0 indicates cost=0
   [VARS] ind_cost_pc, ind_cost_total, ind_cost_rx

2. [PARAMS] cvar: Adjusted, top-coded PMPQ costs : Model subsets ds to cvar>0
   [VARS] cost_pc, cost_total, cost_rx

3. [PARAM] dv: String for title, naming purposes only
===========================================================================================;

%LET dat = data.utilization; 
*[DV: Cost PC] 08-17-2023 =================================================================;
%LET outcome = pc; 
%hurdle  (dat=&dat, pvar=ind_cost_pc, cvar=cost_pc, dv=cost_&outcome.);
%results (pmodel=cost_&outcome._pmodel, cmodel=cost_&outcome_cmodel, dv=cost_&outcome);
%deltable(tables=work.intgroup work.p_intgroup work.cp_intgroup);

*[DV: Cost Total] 
08-17-2023: Changed to int_imp as var of interest ======================================;
%LET dat = data.analysis_final ; 
%LET outcome = total; 
%hurdle  (dat=&dat, pvar=ind_&outcome._cost, cvar=adj_pd_&outcome._tc, dv=cost_&outcome.);
%results (pmodel=cost_&outcome._pmodel, cmodel=cost_&outcome_cmodel, dv=cost_&outcome);
%deltable(tables=work.intgroup work.p_intgroup work.cp_intgroup);

*[DV: Cost Rx] 
08-17-2023: Changed to int_imp as var of interest ======================================;
%LET dat = data.analysis; 
%LET outcome = rx; 
/*%LET dv=cost_&outcome.;*/
/*%PUT &dat &outcome &dv;*/
/*%LET pvar=ind_&outcome._cost;*/
/*%LET cvar=adj_pd_&outcome._tc; %put &pvar &cvar;*/
%hurdle  (dat=&dat, pvar=ind_&outcome._cost, cvar=adj_pd_&outcome._tc, dv=cost_&outcome.);
%results (pmodel=cost_&outcome._pmodel, cmodel=cost_&outcome_cmodel, dv=cost_&outcome);
%deltable(tables=work.intgroup work.p_intgroup work.cp_intgroup);





