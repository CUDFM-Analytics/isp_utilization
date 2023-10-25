**********************************************************************************************
AUTHOR   : KTW
PROJECT  : ISP Utilization
PURPOSE  : Hurdle 1, using macro file , COST dv's
VERSION  : 2023-08-24
         : 2023-08-17 INT_IMP: changed var of interest to int_imp per meeting
OUTPUT   : pdf & log file
LOG      : Changed data.analysis_final to data.analysis (moved the original data.analysis to int.analysis3, then renamed _final)
RELATIONSHIPS : see include statements 
Per Mark : Use mode for ref class vars budget_group & race if possible
            - default for budget_grp_num_r is the mode
            - race = I didn't want to tempt fate so just let it choose since it ran w/ default (ok w Mark)
***********************************************************************************************;
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/config.sas"; 
/*libname int clear; */

%LET dat = data.utilization; 
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/macro_hurdle_costs.sas";

* [NOTES %HURDLE] ==============================================================================
1. [PARAMS] pvar: Indicator variable where 1 indicates cost>0, 0 indicates cost=0
   [VARS] ind_cost_pc, ind_cost_total, ind_cost_rx

2. [PARAMS] cvar: Adjusted, top-coded PMPQ costs : Model subsets ds to cvar>0
   [VARS] cost_pc, cost_total, cost_rx

3. [PARAM] dv: String for title, naming purposes only
===========================================================================================;
*[DV: Cost PC] 08-17-2023 =================================================================;
%LET outcome = pc; 
%hurdle  (dat=&dat, pvar=ind_cost_pc, cvar=cost_pc, dv=cost_pc, type=exch);
proc datasets library=work kill; quit; 
%hurdle  (dat=&dat, pvar=ind_cost_pc, cvar=cost_pc, dv=cost_pc, type=ind);
proc datasets library=work kill; quit; 


*[DV: Cost Total] =======================================================================;
%LET outcome = total; 
* Generate point estimates with type::exch, then delete the temp datasets in work library; 
%hurdle  (dat=&dat, pvar=ind_cost_total, cvar=cost_total, dv=cost_total, type=exch);
proc datasets library=work kill; quit; 
* Generate point estimates with type::ind, then delete the temp datasets in work library; 
%hurdle  (dat=&dat, pvar=ind_cost_total, cvar=cost_total, dv=cost_total, type=ind);
proc datasets library=work kill; quit; 

*[DV: Cost Rx] ==========================================================================;
%LET outcome = rx; 
%hurdle  (dat=&dat, pvar=ind_cost_rx, cvar=cost_rx, dv=cost_rx, type=exch);
proc datasets library=work kill; quit; 
%hurdle  (dat=&dat, pvar=ind_cost_rx, cvar=cost_rx, dv=cost_rx, type=ind);
proc datasets library=work kill; quit; 

* Results: ; 
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/macro_hurdle_costs_results_v2.sas";
%results (dv = cost_pc, pvar=ind_cost_pc, cvar=cost_pc);
%results (dv = cost_total, pvar=ind_cost_total, cvar=cost_total);
%results (dv = cost_rx, pvar=ind_cost_rx, cvar=cost_rx);



