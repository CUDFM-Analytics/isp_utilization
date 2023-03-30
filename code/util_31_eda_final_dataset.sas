/*%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; */

pROC PRINT DATA  = &dat ; 
where adj_pd_total_16cat = ' ' ; 
RUN ; 

ods pdf file = "&report./eda_freq_20230329.pdf";

%let dat = data.analysis_dataset ; 

PROC CONTENTS DATA = &dat VARNUM ; RUN ;  

ods text "Frequencies for categorical variables by Intervention (non-varying)" ; 

TITLE "Unique Member Count, Final Dataset"; 
PROC SQL ; 
SELECT COUNT (DISTINCT mcaid_id ) 
FROM &dat ; 
QUIT ; 

Title "Unique PCMP count by Intervention Status (Non-Varying)"; 
PROC SQL ; 
SELECT COUNT(DISTINCT pcmp_loc_id) as n_pcmp
     , int as intervention
FROM &dat
GROUP BY int;
QUIT; 
TITLE ; 

PROC FREQ DATA = &dat ; 
TABLES age--time int_imp adj: bh_: ind: fqhc; 
RUN ;  

PROC FREQ DATA = &dat ; 
TABLES (age--time int_imp adj: bh_: ind: fqhc)*int; 
RUN ;   

TITLE "Max Time by Member" ;
PROC SQL ; 
CREATE TABLE data._max_time AS 
SELECT mcaid_id
     , MAX (time) as time
     , MAX (int) as intervention
FROM &dat
GROUP BY mcaid_id ; 
QUIT; 

Title "Time Frequency by Member" ; 
PROC FREQ DATA = data._max_time ; 
tables time / nopercent norow; 
RUN; 

Title "Time Frequency by Member, Intervention (non-varying)"; 
PROC FREQ DATA = data._max_time ; 
tables time*intervention / plots = freqplot(type=dot scale=percent) nopercent norow; 
RUN; 

PROC FREQ DATA = &dat; 
TABLES (ind_:)*int ; 
TITLE "Indicator DVs by Intervention" ; 
TITLE2 "If DV eq 0 then indicator = 0, > 0 then indicator = 1";
format ind: comma20. ; 
RUN ; 
TITLE ; 
TITLE2; 

PROC UNIVARIATE DATA = &dat ; 
TABLES (util:)*int ; 
RUN ; 

proc univariate data = &dat ; 
VAR cost_rx_tc cost_ffs_tc cost_pc_tc ; 
RUN; 
ods text "By intervention: univariates"; 
proc univariate data = &dat ; 
by int ; 
VAR cost_rx_tc cost_ffs_tc cost_pc_tc ; 
RUN; 

ods pdf close ; 
