**********************************************************************************************
 PROGRAMMER       : K Wiggins
 DATE INIT        : 02/2023
 PROJECT          : ISP Util
 PURPOSE          : 
 INPUT FILE(S)    : 
 OUTPUT FILE(S)   : 
 LAST RAN/STATUS  : 20230209
 SPECS            : ISP_Utilization_Analytic_Plan_20221118.docx, 

***********************************************************************************************;
* PROJECT PATHS, MAPPING; 
%LET ROOT = S:/FHPC/DATA/HCPF_Data_files_SECURE/Kim/isp/isp_utilization;
%INCLUDE "&ROOT./code/00_global.sas";

* source utilization file; 
DATA qry_monthly_utilization;     SET ana.qry_monthlyutilization;      RUN; *02/09/23 [111,221,842   :  7];

* Re-factor clmClass as clmClass_r ;
proc format;
value clmClass_recode  
  1 = 'Pharmacy' 
  2 ='Hospitalizations' 
  3 = 'ER' 
  4 = 'Primary care'  
  100='Other';
run;

DATA  util_monthly_fy7_0;
SET   qry_monthly_utilization;  
WHERE month ge '01Jul2015'd and month le '30Jun2022'd; 
IF      clmClass = 1 then clmClass_r = 1;
ELSE IF clmClass = 2 then clmClass_r = 2;
ELSE IF clmClass = 3 then clmClass_r = 3;
ELSE IF clmClass = 4 then clmClass_r = 4;
ELSE                      clmClass_r = 100; 
format clmClass_r clmClass_recode.;
RUN; 

proc freq data = util_monthly_fy7_0;
tables clmclass_r; 
run; 

data util_monthly_fy7_1; 
set  util_monthly_fy7_0; 
format month date9.;
fy7=year(intnx('year.7', month, 0, 'BEGINNING')); 
run;  * 77273443, 7;

* sum months by clmClass_r, mcaid_id; 
PROC SQL;
CREATE TABLE data.util_month_y15_22 as
SELECT mcaid_id
     , month
     , clmClass_r
     , sum(count ) as tot_n_month
     , sum(pd_amt) as tot_pd_month
     , fy7
FROM util_monthly_fy7_1
WHERE mcaid_id in ( SELECT mcaid_id FROM data.memlist ) 
GROUP BY mcaid_id, clmClass_r, month;
QUIT;  

proc print data = data.util_month_y15_22 (obs = 5000) ; run; 
proc freq data = data.util_month_y15_22 ; tables month*fy7 ; run; 
/**/
/**/
/**/
/**/
/**/
/** Get unique number of client ID's per pcmp_loc_id;*/
/*proc sql; */
/*create table n_un_members as */
/*select pcmp_loc_id*/
/*    , count(distinct mcaid_id) as n_mcaid_id*/
/*from tmp.util_monthly_fy7_2*/
/*GROUP BY pcmp_loc_id;*/
/*run;*/
/**/
/*PROC PRINT DATA = n_un_mcaidid;*/
/*RUN; */
/**/
/*proc sql;*/
/*create table n_members_cu as*/
/*select pcmp_cu*/
/*    , month*/
/*    , count(distinct mcaid_id) as n_mcaid_id*/
/*from qrylong_y19_y22_4 group by pcmp_cu, month;*/
/*quit; *01/20: 396, 4;*/
/**/
/*PROC PRINT DATA = n_members_cu;*/
/*RUN; */
/**/
/*proc transpose DATA = n_members_cu*/
/*                out = n_members_cu_1 (drop=_name_);*/
/*by pcmp_cu; */
/*id month; */
/*var n_mcaid_id;*/
/*run;*/
/**/
/*PROC SQL ;*/
/*CREATE TABLE attr_mrnfile0 AS */
/*SELECT a.pcmp_cu*/
/*    , a.n_mcaid_id as n_total*/
/*    , b.**/
/*FROM n_un_mcaidid as a*/
/*JOIN n_members_cu_1 as b*/
/*ON   a.pcmp_cu = b.pcmp_cu;*/
/*QUIT; */
/**/
/*PROC SQL;*/
/*CREATE TABLE attr_mrnfile AS */
/*SELECT a.pcmp_loc_id*/
/*    , a.name_location as practice_name*/
/*    , b.**/
/*FROM out.cu_pcmp AS a*/
/*FULL JOIN attr_mrnfile0 as b*/
/*ON a.pcmp_loc_id = b.pcmp_cu;*/
/*QUIT; */
/**/
/*DATA out.attr_mrn_cls;*/
/*SET  attr_mrnfile (DROP = pcmp_loc_id);*/
/*RUN; */
/**/
/**/
