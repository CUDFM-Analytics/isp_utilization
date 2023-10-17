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
 
*Expectation Checks: ;
/*libname out "&projRoot\data_boot_processed";*/
/** location of input data to boot ;*/
/*libname in "&projRoot\data";*/
/** get formats; */
/*OPTIONS FMTSEARCH=(in);*/
/**/
/** data to boot ;*/
/*%let data = in.utilization;*/
/**/
/*PROC CONTENTS DATA = &data; RUN; */
/*PROC FREQ DATA = &data; TABLES int; RUN; *INT = 0 13231202, 1=1893477;*/
/**/
/*PROC SQL; */
/*SELECT int*/
/*     , count(distinct mcaid_id) as n_un_id*/
/*FROM &data*/
/*GROUP BY int;*/
/*QUIT; */
* Unique ID INT=0 > 1476464
  Unique ID INT=1 > 282511
  Unique BootUnit in out._resample_1*replicate = 577804, which matches .2(1476464)+282511; 

/*PROC SQL; */
/*SELECT int_imp*/
/*     , count(distinct mcaid_id) as n_unique_ids*/
/*FROM &data*/
/*GROUP BY int_imp;*/
/*QUIT; */

LIBNAME hout "&projRoot/data/out_hurdle";

%macro mu_dv(dv=);
Title "Means &dv";
PROC MEANS data = hout.&dv._mean;
by   exposed;
var  p_prob p_cost a_cost; 
RUN;  
%mend; 

%mu_dv(dv=cost_pc);
%mu_dv(dv=cost_rx);
%mu_dv(dv=cost_total);


%macro mu_dv_visit(dv=);
Title "Means &dv";
PROC MEANS data = hout.&dv._mean;
by   exposed;
var  p_prob p_visit a_visit; 
RUN;  
%mend; 

%mu_dv_visit(dv=visits_ed);
%mu_dv_visit(dv=visits_pc);
%mu_dv_visit(dv=visits_tel);

DATA all_avp;
SET  hout.cost_rx_avp(in=a) 
     hout.cost_pc_avp(in=b)
     hout.cost_total_avp(in=c);
IF a THEN dataset = 'cost_rx';
IF b THEN dataset = 'cost_pc';
IF c THEN dataset = 'cost_total'; 
RUN; 

