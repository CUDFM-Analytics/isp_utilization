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


* ### SEARCH TERM #DO for questions and do tasks ###
******************************************************
FORMATS addt'l, from Jake's file cost anal_part1 as of 01/30 
(check to see if updated #DO)
******************************************************;

* RAE; 
DATA data.rae; 
SET  data.rae; 
HCPF_County_Code_C = put(HCPF_County_Code,z2.); 
RUN; 

* Dynamic Files, sourced from analytic subset --------------------------; 
DATA qry_monthly_utilization;     SET ana.qry_monthlyutilization;      RUN; *02/09/23 [111,221,842   :  7];

******************************************************
Get monthly utilization
******************************************************;

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
run;

* join members and monthly util - monthly util is 2015-2022, memlist is 19-22; 
PROC SQL;
CREATE TABLE util_monthly_fy7_2 as
SELECT a.*
    , b.*
FROM memlist as A
LEFT JOIN util_monthly_fy7_1 as b
ON a.mcaid_id = b.mcaid_id;
QUIT;  

PROC SQL; 
CREATE TABLE tmp.util_monthly_fy7_2 AS 
SELECT a.*
    , b.*
FROM tmp.util_monthly_fy7_0 as a
LEFT JOIN data.telecare_monthly as b
on a.mcaid_id = b.mcaid_id;
QUIT; *NOTE: Table TMP.FINALSUBJ_MONTHLY_UTIL_1 created, with 66272914 rows and 9 columns.;

* add rae info; 
/*PROC SQL; */
/*CREATE TABLE tmp.finalSubj_monthly_util_2 AS */
/*SELECT a.**/
/*    , b.**/
/*FROM tmp.finalSubj_monthly_util_1 as a*/
/*LEFT JOIN data.rae as b*/
/*on a.enr_county = b.county;*/
/*QUIT;*/

        * HOLD on this - Sum the month? What about clmclass then? ;
        proc sql;
         create table util_monthly_fy7_2 as
         select MCAID_ID
              , month
              , sum(pd_amt) as tot_pd_amt
              , sum(count ) as tot_count
        from util_monthly_fy7_1
        group by MCAID_ID, month;
        quit; 

* Get unique number of client ID's per pcmp_loc_id;
proc sql; 
create table n_un_members as 
select pcmp_loc_id
    , count(distinct mcaid_id) as n_mcaid_id
from tmp.util_monthly_fy7_2
GROUP BY pcmp_loc_id;
run;

PROC PRINT DATA = n_un_mcaidid;
RUN; 

proc sql;
create table n_members_cu as
select pcmp_cu
    , month
    , count(distinct mcaid_id) as n_mcaid_id
from qrylong_y19_y22_4 group by pcmp_cu, month;
quit; *01/20: 396, 4;

PROC PRINT DATA = n_members_cu;
RUN; 

proc transpose DATA = n_members_cu
                out = n_members_cu_1 (drop=_name_);
by pcmp_cu; 
id month; 
var n_mcaid_id;
run;

PROC SQL ;
CREATE TABLE attr_mrnfile0 AS 
SELECT a.pcmp_cu
    , a.n_mcaid_id as n_total
    , b.*
FROM n_un_mcaidid as a
JOIN n_members_cu_1 as b
ON   a.pcmp_cu = b.pcmp_cu;
QUIT; 

PROC SQL;
CREATE TABLE attr_mrnfile AS 
SELECT a.pcmp_loc_id
    , a.name_location as practice_name
    , b.*
FROM out.cu_pcmp AS a
FULL JOIN attr_mrnfile0 as b
ON a.pcmp_loc_id = b.pcmp_cu;
QUIT; 

DATA out.attr_mrn_cls;
SET  attr_mrnfile (DROP = pcmp_loc_id);
RUN; 


