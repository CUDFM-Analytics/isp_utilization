**********************************************************************************************
AUTHOR   : Carter Sevick, adapted by KW
PROJECT  : ISP
PURPOSE  : bootstrap specs
VERSION  : 2023-08-24
HISTORY  : copied on 08-24-2023 from Carter/Examples/boot total cost/
;

%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 
***********************************************************************************************;
OPTIONS pageno=1 linesize=88 pagesize=60 SOURCE;
%LET root  = %qsubstr(%sysget(SAS_EXECFILEPATH), 1, 
             %length(%sysget(SAS_EXECFILEPATH))-%length(%sysget(SAS_EXECFILEname)));
%LET script  = %qsubstr(%sysget(SAS_EXECFILENAME), 1,
               %length(%sysget(SAS_EXECFILENAME))-4); * remove .sas to use in log, pdf;
%LET today = %SYSFUNC(today(), YYMMDD10.);
%LET log   = &root&script._&today..log;

PROC PRINTTO LOG = "&log" NEW; RUN;

%PUT Today: &today;
%PUT Root: &root;
%PUT Notes: Copied from Carter/Examples/total boot cost/ on 08-24-2023 to make sure most recent;
%PUT See ISP Utilization Sharepoint Log.docx for meeting and code notes; 

* 
[OUTPUT] ==============================================================================
[Descr]
1. [Step 1]
2. [Step 2]
===========================================================================================;
%let projRoot = M:\Carter\Examples\boot total cost;

* include macro programs ;
%include "&projRoot\code\MACRO_parallel.sas";
 
* kick off the processes ;
%parallel(
    folder=  &projRoot\code /* data / program location */,
    progName= program_to_boot.sas /* name of the program that will act on the data  */,
    taskName= mytask /*, place holder names for the individual tasks */,
    nprocess = 8 /* number of processes to activate */,
    nboot    = 500 /* total number of bootstrap iterations*/,
    seed     = 837567 /* a seed value for replicability */,
    topseed = 1000000000 /* largest possible seed */
);


%let projRoot = M:\Carter\Examples\boot total cost;

* include macro programs ;
%include "&projRoot\code\MACRO_parallel.sas";
 
* kick off the processes ;
%parallel(
    folder=  &projRoot\code /* data / program location */,
    progName= program_to_boot.sas /* name of the program that will act on the data  */,
    taskName= mytask /*, place holder names for the individual tasks */,
    nprocess = 8 /* number of processes to activate */,
    nboot    = 500 /* total number of bootstrap iterations*/,
    seed     = 837567 /* a seed value for replicability */,
    topseed = 1000000000 /* largest possible seed */
);
 

