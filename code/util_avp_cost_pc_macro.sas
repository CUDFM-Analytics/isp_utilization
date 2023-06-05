**********************************************************************************************
AUTHOR   : KTW
PROJECT  : ISP Utilization
PURPOSE  : Hurdle Model, Primary Care Costs
VERSION  : 2023-06-02
OUTPUT   : pdf & log file
REFS     : enter some output into util_isp_predicted_costs.xlsx
***********************************************************************************************;
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/macro_hurdle.sas"; 

OPTIONS pageno=1 linesize=88 pagesize=60 SOURCE;
%LET root  = %qsubstr(%sysget(SAS_EXECFILEPATH), 1, 
             %length(%sysget(SAS_EXECFILEPATH))-%length(%sysget(SAS_EXECFILEname))-6); *remove \Code\;

%LET script  = %qsubstr(%sysget(SAS_EXECFILEPATH), 1, %length(%sysget(SAS_EXECFILEPATH))-4);

%LET file  = %qsubstr(%sysget(SAS_EXECFILENAME), 1, %length(%sysget(SAS_EXECFILENAME))-4);

%LET today = %SYSFUNC(today(), YYMMDD10.);

* Send log output to code folder, pdf results to reports folder for MG to view;
%LET log   = &root./code/&file._&today..log;
%LET pdf   = &root./reports/&file._&today..pdf;

PROC PRINTTO LOG = "&log" NEW;  RUN;
ODS PDF FILE     = "&pdf" STARTPAGE = no;

Title &file;

proc odstext;
p "Date:              &today";
p "Project Root: &root";
p "Script:            &file";
p "Log File:         &log";
p "Results File:  &pdf";
RUN; 

%LET dat  = data.analysis;

%LET pvar_pc = ind_pc_cost;
%LET cvar_pc = adj_pd_pc_tc;
%LET avp_pc  = avp_cost_pc;

%put Dataset: &dat; 
%put ProbVar (pvar) = &pvar_pc;
%put CostVar (cvar) = &cvar_pc;
%put AVP (actual vs pred) &avp_pc;

%hurdle(pvar = &pvar_pc,
        cvar = &cvar_pc,
        avp  = &avp_pc); 


PROC PRINTTO; RUN; 
ODS PDF CLOSE; 

   
