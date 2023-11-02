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

*COST_PC // 10/28 ;
*
%parallel(
    folder  = &projRoot/code/util_bootstrap     
    , progName= 02a_model_cost_pc.sas
    , taskName= mytask
    , nprocess= 8
    , nboot   = 500
    , seed    = 837567
    , topseed = 1000000000 
);

* 
COST TOTAL // 10/29/2023 started;
%parallel(
    folder    = &projRoot/code/util_bootstrap     /* data, program location */
    , progName= 02b_model_cost_total.sas          /* name of the program that will act on the data   */
    , taskName= mytask                            /*, place holder names for the individual tasks  */
    , nprocess= 8                                 /* number of processes to activate  */
    , nboot   = 500                               /* total number of bootstrap iterations */
    , seed    = 837567                            /* a seed value for replicability  */
    , topseed = 1000000000                        /* largest possible seed  */
);

*
%parallel(
    folder  = &projRoot/code/util_bootstrap     /* data, program location */
    , progName= 02c_model_cost_rx.sas  /* name of the program that will act on the data  */
    , taskName= mytask                            /*, place holder names for the individual tasks */
    , nprocess= 8                                 /* number of processes to activate */
    , nboot   = 500                               /* total number of bootstrap iterations*/
    , seed    = 837567                            /* a seed value for replicability */
    , topseed = 1000000000                        /* largest possible seed */
);
 

 
