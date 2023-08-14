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
libname int clear; 
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/macro_hurdle_costs.sas";
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/macro_results.sas";

*[DV: Cost PC] =========================================================================;
%hurdle  (dat=data.analysis_final, pvar=ind_pc_cost, cvar=adj_pd_pc_tc, dv=cost_pc);
%results (pmodel=cost_pc_pmodel, cmodel=cost_pc_cmodel, dv=cost_pc);
%deltable(tables=work.intgroup work.p_intgroup work.cp_intgroup);

* [DV: Cost Total] =========================================================================;
%hurdle(dat=data.analysis_final,  pvar = ind_total_cost, cvar = adj_pd_total_tc,   dv= cost_total);
%results (pmodel=cost_total_pmodel, cmodel=cost_total_cmodel, dv=cost_total);
%deltable (tables=work.intgroup work.p_intgroup work.cp_intgroup);

* [DV: Cost Rx] =========================================================================;
%hurdle(dat=data.analysis_final,  pvar = ind_rx_cost,    cvar = adj_pd_rx_tc,      dv= cost_rx);
%results(pmodel=cost_rx_pmodel, cmodel=cost_rx_cmodel, dv=cost_rx);
%deltable (tables=work.intgroup work.p_intgroup work.cp_intgroup);


/*%deltable(tables=out.cost_total_pmodel out.cost_total_cmodel);*/




