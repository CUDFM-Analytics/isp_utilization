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

*[EXCH] 11-2-2023 =================================================================;
%hurdle  (dat=&dat, pvar=ind_cost_pc, cvar=cost_pc, dv=cost_pc, type=exch);
proc datasets library=work kill; quit; 
%hurdle  (dat=&dat, pvar=ind_cost_total, cvar=cost_total, dv=cost_total, type=exch);
proc datasets library=work kill; quit; 
%hurdle  (dat=&dat, pvar=ind_cost_rx, cvar=cost_rx, dv=cost_rx, type=exch);
proc datasets library=work kill; quit; 

*[TYPE=IND] 11-2-2023 =================================================================;
%hurdle  (dat=&dat, pvar=ind_cost_pc, cvar=cost_pc, dv=cost_pc, type=ind);
proc datasets library=work kill; quit; 
%hurdle  (dat=&dat, pvar=ind_cost_total, cvar=cost_total, dv=cost_total, type=ind);
proc datasets library=work kill; quit; 
%hurdle  (dat=&dat, pvar=ind_cost_rx, cvar=cost_rx, dv=cost_rx, type=ind);
proc datasets library=work kill; quit; 

* Results: ; 
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/macro_hurdle_costs_results_v2.sas";
%results (dv = cost_pc, pvar=ind_cost_pc, cvar=cost_pc);
%results (dv = cost_total, pvar=ind_cost_total, cvar=cost_total);
%results (dv = cost_rx, pvar=ind_cost_rx, cvar=cost_rx);

*********************************************************************************************
VISITS 
***********************************************************************************************;
* Macro for hurdle model and log; 
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/macro_hurdle_visits.sas";

*[DV: visit PC] 
08 -23-2023 Updated rows 95:100 to use int_imp instead of int======================;
%hurdle  (dat = &dat, prob= ind_visit_pc, visits=visits_pc, dv=visits_pc, type=exch);
proc datasets library=work kill; quit; 
%hurdle  (dat = &dat, prob= ind_visit_pc, visits=visits_pc, dv=visits_pc, type=ind);
proc datasets library=work kill; quit; 


*[DV: visit ED] type=exch;
%hurdle  (dat = &dat, prob= ind_visit_ed, visits=visits_ed, dv=visits_ed,type=exch);
proc datasets library=work kill; quit; 
%hurdle  (dat = &dat, prob= ind_visit_ed, visits=visits_ed, dv=visits_ed,type=ind);
proc datasets library=work kill; quit; 


*[DV: visit TEL] =========================================================================;
%hurdle  (dat = &dat, prob= ind_visit_tel, visits=visits_tel, dv=visits_tel,type=exch);
proc datasets library=work kill; quit; 
%hurdle  (dat = &dat, prob= ind_visit_tel, visits=visits_tel, dv=visits_tel,type=ind);
proc datasets library=work kill; quit; 


*[DV: visit FFSBH] =========================================================================;
%hurdle  (dat = &dat, prob= ind_visit_ffsbh, visits=visits_ffsbh, dv=visits_ffsbh,type=exch);
proc datasets library=work kill; quit; 
%hurdle  (dat = &dat, prob= ind_visit_ffsbh, visits=visits_ffsbh, dv=visits_ffsbh,type=ind);
proc datasets library=work kill; quit; 


** RESULTS ===================================;
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/macro_results_visits.sas";
%results_visits(dv=visits_pc, visittype=pc); 






