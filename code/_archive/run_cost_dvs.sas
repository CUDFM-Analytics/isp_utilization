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


%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/config.sas"; 
libname int clear; 

* Macro for hurdle model and log; 
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/macro_hurdle_visits.sas";
%LET dat = data.utilization;

* Macro to print ouput in PDF wiht date; 
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/macro_results_visits.sas";

/*PROC SQL;*/
/*CREATE TABLE data.cols_visit_dvs AS */
/*SELECT name, type, length, label*/
/*FROM dictionary.columns */
/*WHERE UPCASE(LIBNAME)="DATA" AND*/
/*      UPCASE(MEMNAME)="UTILIZATION" AND*/
/*      (NAME LIKE "ind_visit%" or*/
/*      NAME LIKE "visit%");*/
/*QUIT; */

PROC PRINT DATA = data.cols_visit_dvs; RUN; 

* 
[%HURDLE] =================================================================
1. [&prob] Indicator variable where 1 indicates PMPQ visits>0
           1) ind_pc_visit  2) ind_ed_visit 3) ind_ffs_bh_visit 4) ind_tel_visit
2. [&visits] PMPQ Visits where n_... >0 : recoded _r was orig values x6 to get integers
           1) n_pc_pm_r     2) n_ed_pm_r    3) n_ffs_bh_pm_r     4) n_tel_pm_r
3. &dv = 

[%RESULTS] =================================================================
1. &pmodel = Naming / notes only (not used for exec or var calls etc) 
2. &vmodel = Naming / notes only (not used for exec or var calls etc) 
3. &dv     = Has to match out.{&dv.}_avp, out.{&dv}_meanvisit from %HURDLE  
===========================================================================================;

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






