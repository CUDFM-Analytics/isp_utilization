**********************************************************************************************
 PROGRAMMER       : K Wiggins
 DATE INIT        : 02/2023
 PROJECT          : ISP Util
 PURPOSE          : merges all day
 INPUT FILE(S)    : 
 OUTPUT FILE(S)   : 
 LAST RAN/STATUS  : 20230209
 SPECS            : ISP_Utilization_Analytic_Plan_20221118.docx, 
***********************************************************************************************;
* PROJECT PATHS, MAPPING; 
%LET ROOT = S:/FHPC/DATA/HCPF_Data_files_SECURE/Kim/isp/isp_utilization;
%INCLUDE "&ROOT./code/00_global.sas";  

* Requests in Analysis_Specifications_ISP-v2.xlsx
  Trends in Monthly Attribution:
  - Number of unique individuals attributed at any time in fiscal year
  - Number of unique individuals attributed 6 months or more in fiscal year
  - Number of unique individuals attributed 6 months or more in all fiscal years;


