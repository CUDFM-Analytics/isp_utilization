**********************************************************************************************
AUTHOR   : KTW
PROJECT  : ISP Utilization
PURPOSE  : Hurdle 1, using macro file , visit dv's
VERSION  : 2023-06-22
OUTPUT   : pdf & log file
RELATIONSHIPS : see include statements 
Per Mark : Use mode for ref class vars budget_group & race if possible
            - default for budget_grp_num_r is the mode
            - race = I didn't want to tempt fate so just let it choose since it ran w/ default (ok w Mark)
***********************************************************************************************;
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/config.sas"; 
libname int clear; 
* Macro for hurdle model and log; 
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/macro_hurdle_visits.sas";
* Macro to print ouput in PDF wiht date; 
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/macro_results_visits.sas";

PROC SQL;
CREATE TABLE data.cols_visit_dvs AS 
SELECT name, type, length, label
FROM dictionary.columns 
WHERE UPCASE(LIBNAME)="DATA" AND
      UPCASE(MEMNAME)="UTILIZATION" AND
      (NAME LIKE "ind_visit%" or
      NAME LIKE "visit%");
QUIT; 

PROC PRINT DATA = data.cols_visit_dvs; RUN; 

* 
[%HURDLE] =================================================================
1. [&prob] Indicator variable where 1 indicates PMPQ visits>0, 0 indicates n visits=0
   [VARS] 1) ind_pc_visit  2) ind_ed_visit 3) ind_ffs_bh_visit 4) ind_tel_visit

2. [&visits] PMPQ Visits where n_... >0 : recoded _r was orig values x6 to get integers
   [VARS] 1) n_pc_pm_r     2) n_ed_pm_r    3) n_ffs_bh_pm_r     4) n_tel_pm_r

3. &dv = String for title, naming purposes only

[%RESULTS] =================================================================
1. &pmodel = Naming / notes only (not used for exec or var calls etc) 
2. &vmodel = Naming / notes only (not used for exec or var calls etc) 
3. &dv     = Has to match out.{&dv.}_avp, out.{&dv}_meanvisit from %HURDLE  
===========================================================================================;

*[DV: visit PC] 
Ran on 08-23-2023 > Updated rows 95:100 to use int_imp instead of int======================;
%LET outcome = pc;
%LET dat = data.utilization;
%hurdle  (dat = &dat, 
          prob= ind_visit_pc, 
          visits=visits_pc, 
          dv=visits_pc,
          type=exch
          );
%deltable(tables=work.intgroup work.p_intgroup work.cp_intgroup);

*[DV: visit ED] type=exch
%LET outcome = ed;
%hurdle  (dat = &dat, 
          prob= ind_visit_ed, 
          visits=visits_ed, 
          dv=visits_ed,
          type=exch
          );
%deltable(tables=work.intgroup work.p_intgroup work.cp_intgroup);

*[DV: visit TEL] =========================================================================;
%LET outcome = tel; 

%hurdle  (dat = &dat, 
          prob= ind_visit_tel, 
          visits=visits_tel, 
          dv=visits_tel,
          type=exch
          );
%deltable(tables=work.intgroup work.p_intgroup work.cp_intgroup);


