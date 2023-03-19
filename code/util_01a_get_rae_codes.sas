**********************************************************************************************
AUTHOR   : KTW
PROJECT  : ISP Utilization Analysis
PURPOSE  : Gather, Process datasets from analytic subset dir
VERSION  : 2023-03-16 [date last updated]
DEPENDS  : ana subset folder, config file [dependencies]
NEXT     : [left off on row... or what step to do next... ]  ;

%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 
***********************************************************************************************;

* ==== RAE ===============================================
Get RAE_ID and county info
Inputs      Kim/county_co_data.csv
Outputs     data/isp_key
Notes       Got from Jake and did all in R, just got the _c var here 
;

DATA int.rae; 
SET  int.rae; 
HCPF_County_Code_C = put(HCPF_County_Code,z2.); 
RUN; 
