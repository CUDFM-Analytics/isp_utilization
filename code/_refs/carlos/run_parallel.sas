*****************************************************************************************
DATE CREATED: 3/29/2023

PROGRAMMER  : Carter Sevick

PURPOSE     : run the defined parallel process

NOTES       :

UPDATES     : Change the arguments in %parallel() to run program_to_boot_sim.sas

*****************************************************************************************;
* PART 2 of 3 in Carter's parallel processing framework.
    - set project root directory
    - set path to PART 1 file name (program_to_boot.sas)
    - set nprocess, which will determine the num of output dataset
    - set nboot
    - set seed for replicability;

*%let projRoot = M:\Carter\Examples\boot total cost;
%let projRoot = V:/Research/DFM analytic group/sim_utilization/05_models/01_allowed_amt;

* Loads the macro program into the environment. Equivalent of source() in R.;
%include "V:/Research/DFM analytic group/sim_utilization/02_code/MACRO_parallel.sas";
 
* Create a format to identify the CMHC values -------------------------------------------;
* Needed to overcome formatting warnings with sim data;
proc format;
	value cmhc
	1='CRC'	
	2='JCMH'	
	3='MHP'	
	4='SHG'
	0='nonCMHC';
run;

* Kick off the processes ----------------------------------------------------------------;
* This is the code that was been adapted to function on the SIM data set;
* The only thing changed here is the name of the program to boot and the 
number of bootstrap iterations, and the number or processes;
%parallel(
    folder=  &projRoot/Code /* data / program location */,
    progName= program_to_boot_sim.sas /* name of the program that will act on the data  */,
    taskName= mytask /*, place holder names for the individual tasks */,
    nprocess = 8 /* number of processes to activate /datasets to create */,
    nboot    = 10 /* total number of bootstrap iterations maps to N or rep in program_to_boot...*/,
    seed     = 837567 /* a seed value for replicability */,
    topseed = 1000000000 /* largest possible seed */
);
 