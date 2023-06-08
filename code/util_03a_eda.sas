**********************************************************************************************
AUTHOR   : KTW
PROJECT  : ISP Utilization 
PURPOSE  : Run file for exporting EDA tables on final analysis dataset, exporting results to pdf and saving log
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

PROC FREQ DATA = &dat;
TABLE time*(int_imp int);
RUN;

* 
bh_2016-2018 var tests ====================================================================
===========================================================================================;
* Trying to find any errors in new bh values; 
DATA eda.check_new_bh_vals;
set  data.analysis (keep = mcaid_id time bh: ) ;
bh_sum16 = sum(of bh_er16 bh_oth16 bh_hosp16);
bh_sum17 = sum(of bh_er17 bh_oth17 bh_hosp17);
bh_sum18 = sum(of bh_er18 bh_oth18 bh_hosp18);

* If bh_sumYY >= 1 and bh_YYYY = 1 or if they both equal 0 then they're correct;
IF (bh_sum16 ge 1 AND bh_2016 eq 1) OR (bh_sum16 eq 0 AND bh_2016 eq 0) then bh_check16 = 1;
IF (bh_sum17 ge 1 AND bh_2017 eq 1) OR (bh_sum17 eq 0 AND bh_2017 eq 0) then bh_check17 = 1;
IF (bh_sum18 ge 1 AND bh_2018 eq 1) OR (bh_sum18 eq 0 AND bh_2018 eq 0) then bh_check18 = 1;

RUN; 

PROC FREQ 
     DATA = eda.check_new_bh_vals;
     * Test 1
     06/06: Passed;
     TABLES bh_check: ; * ;
     * Test 2: do all 0's OR 1's, ge 1's match (save output freqs)
     06/06 Passed; 
     TABLES bh_sum16*bh_2016 / out=eda.check_new_bh_results16;
     TABLES bh_sum17*bh_2017 / out=eda.check_new_bh_results17;
     TABLES bh_sum18*bh_2018 / out=eda.check_new_bh_results18;
RUN; 
TITLE; 

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

