*****************************************************************************************
DATE CREATED: 3/29/2023

PROGRAMMER  : Carter Sevick

PURPOSE     : run the defined parallel process

NOTES       :

UPDATES     :

*****************************************************************************************;

%let projRoot = X:\Jake\other\IBH\cost and utilization;

* include macro programs ;
%include "&projRoot\bootstrap and macro code\MACRO_parallel.sas";
 
* kick off the processes ;
%parallel(
    folder=  &projRoot\bootstrap and macro code /* data / program location */,
    progName= program_to_boot_ibh_Genmod_N_BHOother.sas /* name of the program that will act on the data  */,
    taskName= mytask /*, place holder names for the individual tasks */,
    nprocess = 8 /* number of processes to activate */,
    nboot    = 500 /* total number of bootstrap iterations*/,
    seed     = 837567 /* a seed value for replicability */,
    topseed = 1000000000 /* largest possible seed */
);
