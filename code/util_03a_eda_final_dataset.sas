%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 
%let dat = data.analysis; 
%let all = data.analysis_allcols; 

* MACRO VARS created: &nobs (records in &dat), &nmem (unique member n) ; 
PROC SQL NOPRINT;
SELECT count(*) into :nobs from &dat;
QUIT; 

PROC SQL; 
SELECT COUNT (DISTINCT mcaid_id ) into :nmem
FROM &dat ; 
QUIT ; 

PROC FREQ DATA = &dat NOPRINT;
TABLES time / out = freq_time ; 
RUN; 

DATA int.eda_time_freq;
SET  freq_time (drop=percent rename=(count=n_time)); 
n_mem = &nmem;
pct_time_mem = n_time/n_mem;
pct_time_missing = 1-pct_time_mem; 
RUN; 

DATA int.eda_FY1618;
SET  int.fy1618;
array bh{*} bho_n_er_16pm--bho_n_other_18pm;
do i = 1 to dim(bh);
    bh{i} = round(bh{i}, 0.001);
end;
drop i;
RUN; 

%macro n_obs_per_id(ds=);
  PROC SQL; 
  CREATE TABLE int.eda_n_ids AS
  SELECT mcaid_id
       , count(mcaid_id) as n_id
  FROM &ds
  GROUP BY mcaid_id;
  QUIT; 
%mend;

%n_obs_per_id(ds=&dat); *4/27 final run still got 1593591 ;



******************************************************************************************************
*** FIND ISSUES where pcmp wasn't on attr file; 
******************************************************************************************************;
