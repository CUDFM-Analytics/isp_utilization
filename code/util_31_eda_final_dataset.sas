%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config_formats.sas"; 

PROC FREQ DATA = data.analysis_dataset; 
TABLES age race sex ; 
RUN ; 

PROC SORT DATA = data.analysis_dataset ; by mcaid_id time ; RUN ; 

/*DATA ind ; */
/*SET  data.analysis_dataset (KEEP = mcaid_id time ind: )  ; */

PROC FREQ DATA = data.analyis_dataset ; 
TABLES int*ind_: ; 
TITLE "Indicator Variable if DV 0 or >0 by Intervention" ; 
format ind: comma20. ; 
RUN ; 
TITLE ; 

PROC FREQ DATA = data.analysis_dataset ; 
TABLES int*util: ; 
RUN ; 

proc univariate data = data.analysis_dataset ; 
VAR = int*cost: ; 
RUN; 
