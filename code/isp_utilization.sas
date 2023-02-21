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

* Combine datasets into monthly files;  
proc sort data = data.qrylong_y15_22 ; by mcaid_id ;   *53384196; 
proc sort data = data.memlist        ; by mcaid_id ; run ; 

* ==== reduce qrylong to memlist ids =======================================;
data  analysis_data0;
merge data.qrylong_y15_22 ( in = a ) data.memlist ( in = b keep = mcaid_id ) ; 
by    mcaid_id ; 
run ;
*NOTE: There were 53384196 observations read from the data set DATA.QRYLONG_Y15_22.
NOTE: There were 1594687 observations read from the data set DATA.MEMLIST.
NOTE: The data set WORK.ANALYSIS_DATA0 has 53384196 observations and 28 variables.;

data analysis_data0; 
set  analysis_data0; 
format month date9.;
fy7=year(intnx('year.7', month, 0, 'BEGINNING')); 
run; 

proc contents data = analysis_data0 varnum ; run; 



* ==== merge ================================================================;
proc sql; 
create table analysis_data1 as 
select a.*
/*     join memlist variables */
     , b.pcmp_loc_id
     , b.id_split
     , b.dt_prac_isp
     , b.ind_isp
/*     join bh utilization  */
     , c.bh_n_er
     , c.bh_n_other
/*     join telehealth utilization  */
     , d.
from analysis_data0 as a
left join data.memlist as b
on a.mcaid_id = b.mcaid_id and a.month = b.month
left join 
quit;  

PROC SQL; 
CREATE TABLE tmp.util_monthly_fy7_2 AS 
SELECT a.*
    , b.*
FROM tmp.util_monthly_fy7_0 as a
LEFT JOIN data.telecare_monthly as b
on a.mcaid_id = b.mcaid_id;
QUIT; *NOTE: Table TMP.FINALSUBJ_MONTHLY_UTIL_1 created, with 66272914 rows and 9 columns.;

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


