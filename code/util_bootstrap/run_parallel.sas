**********************************************************************************************
AUTHOR   : Carter Sevick, adapted KW
PROJECT  : ISP
PURPOSE  : Part 2 of 3 > bootstrap specs
VERSION  : 2023-08-24
HISTORY  : copied on 08-24-2023 from Carter/Examples/boot total cost/
***********************************************************************************************;
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_bootstrap/config_boot.sas";
* projRoot ------------------------------------------------------------------------------------; 
*include macro program ;
%INCLUDE "&projRoot./code/util_bootstrap/MACRO_parallel.sas";
%LET folder = &projRoot/code/util_bootstrap;
%LET progName = program_to_boot.sas;
%LET taskName = test; 

%LET ind_cost = ind_pc_cost;
%LET cost     = adj_pd_pc_tc; 
%put _global_;
* kick off the processes ;
%parallel(
    folder  = &folder    /* data / program location */,
    progName= &progName  /* name of the program that will act on the data  */,
    taskName= &taskName  /*, place holder names for the individual tasks */,
    nprocess= 8          /* number of processes to activate */,
    nboot   = 500        /* total number of bootstrap iterations*/,
    seed    = 837567     /* a seed value for replicability */,
    topseed = 1000000000 /* largest possible seed */
);
 
