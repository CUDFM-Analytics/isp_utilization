
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 

%let dat = data.analysis; 
/*%let all = data.analysis_allcols; */

OPTIONS pageno=1 linesize=88 pagesize=60 SOURCE;
%LET root  = %qsubstr(%sysget(SAS_EXECFILEPATH), 1, 
             %length(%sysget(SAS_EXECFILEPATH))-%length(%sysget(SAS_EXECFILEname))-6); *remove \Code\;

%LET script  = %qsubstr(%sysget(SAS_EXECFILEPATH), 1, 
               %length(%sysget(SAS_EXECFILEPATH))-4);

%LET today = %SYSFUNC(today(), YYMMDD10.);

%LET log   = &script._&today..log;
%LET pdf   = &report./budget_grp_freqs&today..pdf;

PROC PRINTTO LOG = "&log" NEW; RUN;
ODS PDF FILE     = "&pdf"
                    STARTPAGE = no;

Title %sysget(SAS_EXECFILENAME);

proc odstext;
p "Date:              &today";
p "Root:   &root";
p "Script:            %sysget(SAS_EXECFILENAME)";
p "";
p "Frequencies for budget_group variables"; 
RUN; 

PROC FREQ DATA = &dat; tables budget: ; RUN; 

proc printto; run; ods pdf close; 
