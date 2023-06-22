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
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/macro_hurdle1_cost_dvs.sas";

%LET today = %SYSFUNC(today(), YYMMDD10.);

PROC CONTENTS DATA = data.analysis VARNUM; RUN; 

%hurdle1(dat=data.analysis,  pvar = ind_pc_cost,    cvar = adj_pd_pc_tc,      dv= cost_pc);
%hurdle1(dat=data.analysis,  pvar = ind_total_cost, cvar = adj_pd_total_tc,   dv= cost_total);
%hurdle1(dat=data.analysis,  pvar = ind_rx_cost,    cvar = adj_pd_rx_tc,      dv= cost_rx);
