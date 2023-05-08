* Code commented out didn't need to be run > 1 time - was used in report.; 

/*%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; */
/*%let dat = data.analysis_dataset; */
/*%let allcols = data.analysis_dataset_allcols; */

* MACRO VARS created: &nobs (records in &dat), &nmem (unique member n) ; 
PROC SQL NOPRINT;
SELECT count(*) into :nobs from &dat;
QUIT; 

PROC SQL; 
SELECT COUNT (DISTINCT mcaid_id ) into :nmem
FROM &dat ; 
QUIT ; 

%macro univar_gt0(var, title);
PROC UNIVARIATE DATA = &dat;
TITLE &TITLE; 
VAR &var; 
WHERE &var gt 0 ;
HISTOGRAM; 
RUN; 
TITLE; 
%mend; 

%macro univar(var, title);
PROC UNIVARIATE DATA = &dat;
TITLE &TITLE; 
VAR &var; 
HISTOGRAM; 
RUN; 
TITLE; 
%mend; 

/*PROC SQL; */
/*CREATE TABLE data.analysis_dat_cols AS */
/*SELECT name as variable*/
/*     , type*/
/*     , length*/
/*     , label*/
/*     , format*/
/*     , informat*/
/*FROM sashelp.vcolumn*/
/*WHERE LIBNAME = 'DATA' */
/*AND   MEMNAME = 'ANALYSIS_DATASET';*/
/*quit;*/
/**/
PROC FREQ DATA = &dat NOPRINT;
TABLES time / out = freq_time ; 
RUN; 

DATA freq_time2;
SET  freq_time (drop=percent rename=(count=n_time)); 
n_mem = &nmem;
pct_time_mem = n_time/n_mem;
pct_time_missing = 1-pct_time_mem; 
RUN; 

DATA FY1618;
SET  int.fy1618;
array bh{*} bho_n_er_16pm--bho_n_other_18pm;
do i = 1 to dim(bh);
    bh{i} = round(bh{i}, 0.001);
end;
drop i;
RUN; 


******************************************************************************************************
*** FIND ISSUES where pcmp wasn't on attr file; 
******************************************************************************************************;
