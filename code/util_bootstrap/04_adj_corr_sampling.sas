**********************************************************************************************
AUTHOR   : KTW
PROJECT  : ISP Utilization
PURPOSE  : Adj correlation to accommodate sampling rates in booted data / See Notes
VERSION  : 2023-10-11
DEPENDS  : 
NOTES    : FROM CARTER: 
Since we are sampling fewer than the full sample in each bootstrap the SD will be larger than if we selected a full N each time. 
There is a correction factor that you will need to multiply to get an appropriate estimate  
Count N = total number of SUBJECTS (not records) in the source dataset that is bootstrapped 
M = total number of distinct BOOTUNITS in each boot dataset (will be the same in each set) 
    and should be close to (n in strata1) * (sample rate in strata1) + (n in strata2) * (sample rate in strata2) 
    [might not be exact, rounding errors and all that] 
Compute: wt = sqrt(M/N) 
Then multiply the bootstrap standard deviation estimates by wt prior to computing confidence intervals. 
The resulting standard deviations will be smaller, but correctly scaled. 
;
proc options option = memsize value; run; 
%LET projRoot = S:\FHPC\DATA\HCPF_DATA_files_SECURE\Kim\isp\isp_utilization;
LIBNAME dataBoot "&projRoot/data_boot_processed";
LIBNAME costrx   "&projRoot/data_boot_processed/cost_rx";

***********************************************************************************************;
OPTIONS pageno=1 linesize=88 pagesize=60 SOURCE;
%LET root  = %qsubstr(%sysget(SAS_EXECFILEPATH), 1, 
             %length(%sysget(SAS_EXECFILEPATH))-%length(%sysget(SAS_EXECFILEname)));

%LET script  = %qsubstr(%sysget(SAS_EXECFILENAME), 1,
               %length(%sysget(SAS_EXECFILENAME))-4); * remove .sas to use in log, pdf;

%LET today = %SYSFUNC(today(), YYMMDD10.);

%LET log   = &root&script._&today..log;
%LET pdf   = &root&script._&today..pdf;

PROC PRINTTO LOG = "&log" NEW; RUN;
ODS PDF FILE     = "&pdf"
                    STARTPAGE = no;

Title %sysget(SAS_EXECFILENAME);

proc odstext;
p "Date: &today";
p "Project Root: &root";
p "Script: %sysget(SAS_EXECFILENAME)";
p "Log File: &log";
p "Results: &pdf";
RUN; 

* 
[OUTPUT] ==============================================================================
[Descr]
1. [Step 1]
2. [Step 2]
===========================================================================================;
PROC CONTENTS DATA = databoot._resample_out_1 VARNUM; RUN; 

PROC PRINT DATA = databoot._resample_out_1 (obs=50); VAR replicate bootUnit mcaid_id time;  RUN; 

PROC SQL; 
SELECT count(distinct bootUnit) as n_un_bootUnit
FROM databoot._resample_out_1
GROUP BY replicate;
QUIT; 

LIBNAME data "&projRoot/data";

PROC SQL; 
SELECT count(distinct mcaid_id) as n_un_mcaid_id
FROM data.utilization;
QUIT; 

proc printto; run; ods pdf close; 
