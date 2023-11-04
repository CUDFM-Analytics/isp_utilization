**********************************************************************************************
AUTHOR   : Carter Sevick (adapted: KW)
PROJECT  : ISP Utilization Analysis
PURPOSE  : bootstrap specs
VERSION  : 2023-08-30
HISTORY  : copied on 08-24-2023 from Carter/Examples/boot total cost/
           09-13: changed lightSort to No (program_to_boot_resample_costpc.sas)
***********************************************************************************************;
%LET projRoot = S:\FHPC\DATA\HCPF_DATA_files_SECURE\Kim\isp\isp_utilization; 
*include macro program ;
%INCLUDE "&projRoot./code/util_bootstrap/MACRO_parallel.sas";

* kick off the processes ;
%parallel(
    folder  = &projRoot/code/util_bootstrap         /* data, program location */,
    progName= program_to_boot_resample.sas          /* name of the program that will act on the data  */,
    taskName= mytask                                /*, place holder names for the individual tasks */,
    nprocess= 8                                     /* number of processes to activate */,
    nboot   = 500                                   /* total number of bootstrap iterations*/,
    seed    = 837567                                /* a seed value for replicability */,
    topseed = 1000000000                            /* largest possible seed */
);
 

*Expectation Checks:--------------------------------------------------------- ;
libname out "&projRoot\data_boot_processed";
* location of input data to boot ;
libname in "&projRoot\data";
* get formats; 
OPTIONS FMTSEARCH=(in);


* data to boot ;
%let isp = in.utilization;

/*PROC CONTENTS DATA = &data; RUN; */
PROC FREQ DATA = &isp; TABLES int; RUN; * Oct 3 INT = 0 13231202, 1=1893477;

PROC SQL; 
SELECT int
     , count(distinct mcaid_id) as n_un_id
FROM &isp
GROUP BY int;
QUIT; 

PROC SQL; 
SELECT count(distinct replicate)
FROM out._resample_out_1;
QUIT; 

PROC SQL; 
SELECT count(distinct bootunit)
FROM out._resample_out_1
WHERE replicate eq 1; 
QUIT; 

* See doc with updated values: they are perfect!
* 11/03 
  Unique ID INT=0 : 1604443
  Unique ID INT=1 : 319518
  Expectation pre-run: ~640606 (x=.2(1604443)+319518, x=~320888+319518, x=~640406)
* 10/03 
  Unique ID INT=0 : 1476464
  Unique ID INT=1 : 282511
  Unique BootUnit in out._resample_1*replicate = 577804, which matches .2(1476464)+282511; 


