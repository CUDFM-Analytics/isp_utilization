**********************************************************************************************
AUTHOR   : KTW
PROJECT  : ISP Utilization Analysis
PURPOSE  : config for boot
VERSION  : 2023-08-24
***********************************************************************************************;
* projRoot ------------------------------------------------------------------------------------; 
%LET projRoot = S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization;
* location for bootstrap products -------------------------------------------------------------;
LIBNAME out "&projRoot/data/out_boot";
* location of input data to boot- -------------------------------------------------------------;
LIBNAME in "&projRoot/data";
%LET data = in.mini; 

* Get formats from libnames; 
OPTIONS fmtsearch=(in);


