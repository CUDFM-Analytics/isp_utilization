**********************************************************************************************
AUTHOR   : KTW
PROJECT  : ISP Utilization
PURPOSE  : Hurdle 1, using macro file , COST dv's
VERSION  : 2023-06-22
OUTPUT   : pdf & log file
RELATIONSHIPS : see include statements 
NB DV Use _r recoded integer variables  
***********************************************************************************************;
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/macro_hurdle1_visit_dvs.sas";

%LET today = %SYSFUNC(today(), YYMMDD10.);

PROC CONTENTS DATA = data.analysis VARNUM; RUN; 

%hurdle1(dat=data.analysis,  pvar = ind_pc_visit,    nvar = n_pc_pm_r,      dv= visits_pc);
%hurdle1(dat=data.analysis,  pvar = ind_total_cost,  nvar = adj_pd_total_tc,   dv= cost_total);
%hurdle1(dat=data.analysis,  pvar = ind_rx_cost,    cvar = adj_pd_rx_tc,      dv= cost_rx);
