**********************************************************************************************
AUTHOR   : KTW
PROJECT  : ISP Utilization 
PURPOSE  : EDA export to pdf, final dataset
VERSION  : [2023-05-18] (added season frequency)
DEPENDS  : ;

%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 
***********************************************************************************************;
* data.analysis_meta has meta for analysis ds; 
PROC SQL; 
CREATE TABLE data.analysis_meta AS 
SELECT name as variable
     , type
     , length
     , label
     , format
     , informat
FROM sashelp.vcolumn
WHERE LIBNAME = 'DATA' 
AND   MEMNAME = 'ANALYSIS';
quit;

PROC PRINT DATA = data.analysis_meta NOOBS; RUN; 

%let dat = data.analysis; 
%let all = data.analysis_allcols; 


* MACRO VARS created: &nobs (records in &dat), &nmem (unique member n) ; 

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
SET  int.QRYLONG_1618;
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

%n_obs_per_id(ds=&dat); *06/02 1613033 WOOT ;

