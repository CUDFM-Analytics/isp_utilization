**********************************************************************************************
AUTHOR   : Carter Sevick, adapted KW
PROJECT  : ISP
PURPOSE  : Part 2 of 3 > bootstrap specs
VERSION  : 2023-08-24
HISTORY  : copied on 08-24-2023 from Carter/Examples/boot total cost/
***********************************************************************************************;
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_bootstrap/00_config_boot.sas"; 

*include macro program ;
%INCLUDE "&projRoot./code/util_bootstrap/MACRO_parallel.sas";

* kick off the processes ;
%parallel(
    folder  = &projRoot/code/util_bootstrap /* data, program location */,
    progName= program_to_boot_cost_pc.sas   /* name of the program that will act on the data  */,
    taskName= mytask                        /*, place holder names for the individual tasks */,
    nprocess= 8                             /* number of processes to activate */,
    nboot   = 500                           /* total number of bootstrap iterations*/,
    seed    = 837567                        /* a seed value for replicability */,
    topseed = 1000000000                    /* largest possible seed */
);
 
