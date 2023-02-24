**********************************************************************************************
 PROGRAMMER       : K Wiggins
 DATE INIT        : 02/2023
 PROJECT          : ISP Util
 PURPOSE          : 
 INPUT FILE/S     : 
 OUTPUT FILE/S    : SECTION01 > 
 SPECS            : ISP_Utilization_Analytic_Plan_20221118.docx, 
***********************************************************************************************;
* PROJECT PATHS, MAPPING; 
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_params.sas"; 


* ==== Combine datasets into monthly files ==================================;  
proc sort data = data.qrylong_y15_22 ; by mcaid_id ;   *53384196; 
proc sort data = data.memlist        ; by mcaid_id ; run ; 

* ==== Reduce qrylong to 19-22 only ==========================================;
data  analysis0;
set   data.qrylong_y15_22;
where month ge '01JUL2019'd 
and   month le '30JUN2022'd ;
run; 
* 02/24: [40999955 : 28 variables];

* ==== join isp_key info  =======================================;
proc sort data = analysis0 ; by pcmp_loc_id ;           *[123];
proc sort data = data.isp_key ; by pcmp_loc_id ; run ;

* including the numeric id_pcmp; 
proc sql; 
create table analysis1 as 
select a.*
     , b.id_split
     , b.dt_prac_isp
from analysis0 as a 
left join data.isp_key as b
on a.pcmp_loc_id = b.pcmp_loc_id; 
quit; *NOTE: Table WORK.ANALYSIS1 created, with 41009765 rows and 30 columns.;

proc print data = analysis1 (obs = 1000) ; where id_split ne . ; run ;
proc sort data = analysis1 ; by mcaid_id ; run; 

* set date to numeric 9 FUUUUUUUU; 
data analysis2;
set  analysis1; 
dt_prac_isp2 = input(dt_prac_isp, date9.);
FORMAT dt_prac_isp2 date9.;
DROP   dt_prac_isp;
RENAME dt_prac_isp2 = dt_prac_isp;
RUN; 

* ==== create ind_isp and ind_isp_ever vars =======================================;
DATA analysis3;
SET  analysis2; 
IF   id_split ne . and month >= dt_prac_isp then ind_isp = 1;
ELSE ind_isp = 0; 
IF   id_split ne . then ind_isp_ever = 1;
ELSE ind_isp_ever = 0; 
RUN;
**NOTE: Table WORK.ANALYSIS1 created, with 41009765 rows and 30 columns.;

proc print data = analysis3 (obs = 1000) ; where ind_isp = 0 AND ind_isp_ever = 1 ; run ; *WOOOT!!!  

        * ==== save progress / delete later ===========================================;  
        data tmp.analysis3;
        set  analysis3; 
        run; 

proc sort data = analysis3 ; by mcaid_id month ; run ;

proc sql; 
/*create table data.ind_isp_counts_19_22 as */
select sum (ind_isp) as n_ind_isp
     , sum (ind_isp_ever) as ind_isp_ever
from analysis3;
quit;

* ==== Quarter format / question  ==================================;  
* Number of unique attributed members in calendar quarter – quarterly 3Q2019 – 2Q2022 
(assign members to PCMP with the most months in a quarter and 
if there is an equal number assign to PCMP with attribution in last month eligible in the quarter) ; 

* using a format wouldn't let me sum them (it wouldn't group by them? idk why) ; 
data analysis4;
set  analysis3;
if month in ('01JUL2019'd , '01AUG2019'd , '01SEP2019'd ) then q = 1;
if month in ('01OCT2019'd , '01NOV2019'd , '01DEC2019'd ) then q = 2;
if month in ('01JAN2020'd , '01FEB2020'd , '01MAR2020'd ) then q = 3;
if month in ('01APR2020'd , '01MAY2020'd , '01JUN2020'd ) then q = 4;
if month in ('01JUL2020'd , '01AUG2020'd , '01SEP2020'd ) then q = 5;
if month in ('01OCT2020'd , '01NOV2020'd , '01DEC2020'd ) then q = 6;
if month in ('01JAN2021'd , '01FEB2021'd , '01MAR2021'd ) then q = 7;
if month in ('01APR2021'd , '01MAY2021'd , '01JUN2021'd ) then q = 8;
if month in ('01JUL2021'd , '01AUG2021'd , '01SEP2021'd ) then q = 9;
if month in ('01OCT2021'd , '01NOV2021'd , '01DEC2021'd ) then q = 10;
if month in ('01JAN2022'd , '01FEB2022'd , '01MAR2022'd ) then q = 11;
if month in ('01APR2022'd , '01MAY2022'd , '01JUN2022'd ) then q = 12;
run;

* ==== create quarter variable =======================================;  
* import the csv I made to cheat; 
PROC IMPORT 
     DATAFILE = "S:/FHPC/DATA/HCPF_Data_files_SECURE/Kim/isp/isp_utilization/data/quarter_months_years_analysis.csv"
     OUT      = quarters
     DBMS     = dlm
     REPLACE;
DELIMITER     = ",";
RUN; 


proc sql; 
create table quarters1 as 
select a.mcaid_id 
     , b.sas
     , b.quarter
from data.memlist as a
full join quarters as b
on a.month = b.sas;
quit; 


*NOTE: Table WORK.ANALYSIS1 created, with 41000294 rows and 32 columns.;
proc sort data = analysis1 ; by mcaid_id month ; run; 
proc print data = analysis1 (obs=5000) ; run; 

*NOTE: There were 53384196 observations read from the data set DATA.QRYLONG_Y15_22.
NOTE: There were 1594687 observations read from the data set DATA.MEMLIST.
NOTE: The data set WORK.ANALYSIS_DATA0 has 53384196 observations and 28 variables.;

proc print data = analysis_data0 (obs = 1000) ; run; 

* count unique members in analysis_data0;
proc sql; 
create table n_mem_analysis_data0 as 
select count ( distinct mcaid_id ) as n_mcaid_id 
from analysis_data0; 
quit; 

proc print data = n_mem_analysis_data0 ; run; 

* ==== merge them all ================================================================;
proc sql; 
create table analysis_data1 as 
select a.*
     /* join memlist utilization  */
     , b.pcmp_loc_id
     , b.id_split
     , b.dt_prac_isp
     , b.ind_isp

     /* join memlist utilization  */
     , c.bh_n_er
     , c.bh_n_other
     /* join telehealth utilization  */
     , d.n_tele
     , d.pd_tele
     /* join monthly utilization  */
     , e.clmClass_r
     , e.tot_n_month
     , e.tot_pd_month

FROM analysis_data0 AS a

LEFT JOIN data.memlist as b
ON a.mcaid_id = b.mcaid_id AND a.month = b.month

LEFT JOIN data.bho_fy15_22 AS c
ON a.mcaid_id = c.mcaid_id AND a.month = c.month

LEFT JOIN data.memlist_tele_monthly AS d
ON a.mcaid_id = d.mcaid_id AND a.month = d.month

LEFT JOIN data.util_month_y15_22 AS e
ON a.mcaid_id = e.mcaid_id AND a.month = e.month;

QUIT;   * 53384535 : 31 same when merged on pcmp_loc_id as when not;  

proc print data = analysis_data1 (obs = 10000) ; run; 

proc contents data = analysis_data1 varnum ; run ; 
*NOTE: Table WORK.ANALYSIS_DATA1 created, with 73.000.396 rows and 38 columns.; 

proc print data = ANALYSIS_DATA1 ( obs = 1000 ) ; run; 

proc freq data = analysis_data1 ; tables ind_isp ; run ;

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


