**** GET RAE; 

* PROJECT PATHS, MAPPING; 
%LET ROOT = S:/FHPC/DATA/HCPF_Data_files_SECURE/Kim/isp/isp_utilization;
%INCLUDE "&ROOT./code/00_global.sas";

* RAE; 
DATA data.rae; 
SET  data.rae; 
HCPF_County_Code_C = put(HCPF_County_Code,z2.); 
RUN; 
