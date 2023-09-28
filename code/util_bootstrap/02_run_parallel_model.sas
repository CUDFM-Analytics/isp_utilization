**********************************************************************************************
AUTHOR   : Carter Sevick (adapted: KW)
PROJECT  : ISP Utilization Analysis
PURPOSE  : bootstrap specs
VERSION  : 2023-08-30
HISTORY  : copied on 08-24-2023 from Carter/Examples/boot total cost/
***********************************************************************************************;
/*proc options option=memsize value; run;*/
%LET projRoot = S:\FHPC\DATA\HCPF_DATA_files_SECURE\Kim\isp\isp_utilization; 

*include macro program ;
%INCLUDE "&projRoot./code/util_bootstrap/MACRO_parallel.sas";

* kick off the processes for cost_pc - RAN 09/2023 SUCCESSFUL, commented out to run next one
-- Renamed after running to shorten and put in order in dir - now is 02a_model_cost_pc.sas.
/*%parallel(*/
/*    folder  = &projRoot/code/util_bootstrap     /* data, program location */,*/
/*    progName= program_to_boot_costpc_model.sas  /* name of the program that will act on the data  */,*/
/*    taskName= mytask                            /*, place holder names for the individual tasks */,*/
/*    nprocess= 8                                 /* number of processes to activate */,*/
/*    nboot   = 500                               /* total number of bootstrap iterations*/,*/
/*    seed    = 837567                            /* a seed value for replicability */,*/
/*    topseed = 1000000000                        /* largest possible seed */*/
/*);*/;
 
* kick off the processes, cost_total;
%parallel(
    folder  = &projRoot/code/util_bootstrap     /* data, program location */,
    progName= 02b_model_cost_total.sas  /* name of the program that will act on the data  */,
    taskName= mytask                            /*, place holder names for the individual tasks */,
    nprocess= 8                                 /* number of processes to activate */,
    nboot   = 500                               /* total number of bootstrap iterations*/,
    seed    = 837567                            /* a seed value for replicability */,
    topseed = 1000000000                        /* largest possible seed */
);
 
