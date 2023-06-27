**********************************************************************************************
AUTHOR   : KTW
PROJECT  : ISP Utilization
PURPOSE  : Hurdle 1, using macro file , COST dv's
VERSION  : 2023-06-27
OUTPUT   : pdf & log file
RELATIONSHIPS : include statements 
NB DV Use _r recoded integer variables  
***********************************************************************************************;
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/macro_hurdle1_visit_dvs.sas";

PROC PRINT DATA = data.analysis_meta; RUN; 

%LET today = %SYSFUNC(today(), YYMMDD10.);

%hurdle1(dat=data.analysis,  pvar = ind_pc_visit,       nvar = n_pc_pm_r,       dv= visits_pc   ); * SUCCESS; 
%hurdle1(dat=data.analysis,  pvar = ind_ed_visit,       nvar = n_ed_pm_r,       dv= visits_ed   ); * SUCCESS;
%hurdle1(dat=data.analysis,  pvar = ind_ffs_bh_visit,   nvar = n_ffs_bh_pm_r,   dv= visits_ffsbh); * SUCCESS;
%hurdle1(dat=data.analysis,  pvar = ind_tel_visit,      nvar = n_tel_pm_r,      dv= visits_tel  ); * SUCCESS;
