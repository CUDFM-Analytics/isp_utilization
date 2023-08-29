**********************************************************************************************
AUTHOR   : KTW
PROJECT  : ISP 
PURPOSE  : bootstrapping configs
VERSION  : 2023-08-26
***********************************************************************************************;
%LET projRoot = S:\FHPC\DATA\HCPF_DATA_files_SECURE\Kim\isp\isp_utilization;

* location for bootstrap products ;
libname in  "&projRoot\data";
libname out "&projRoot\data_boot_processed";

* Dataset  ; 
%LET data = in.mini;

OPTIONS FMTSEARCH = (in, ana); 

