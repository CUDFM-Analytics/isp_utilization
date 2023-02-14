**********************************************************************************************
 PROGRAMMER       : K Wiggins
 DATE INIT        : 
 PROJECT          : ISP Util
 PURPOSE          : 
 INPUT FILE(S)    : 
 OUTPUT FILE(S)   : 
 LAST RAN/STATUS  : 20230209
 SPECS            : ISP_Utilization_Analytic_Plan_20221118.docx, 
 OTHER            : Reference: Jake's cost anal_part1, cost anal_part2
                  : 
 CHANGE LOG
 20230209 KW 
***********************************************************************************************;
* PROJECT PATHS, MAPPING; 
  %LET data = S:/FHPC/DATA/HCPF_Data_files_SECURE/Kim/isp/isp_utilization/data;
  LIBNAME data "&data"; 

  %LET raw = C:/Data/isp_util2/data_raw;
  LIBNAME raw "&raw"; 

  * for intermediate files - files that are just for creating future tables but still want to keep
  proc contents, freqs too: ;
  %LET data_interim = C:/Data/isp_util2/data/data_interim;
  LIBNAME interim "&data_interim"; 

  %LET results = C:/Data/isp_util2/data/results;
  LIBNAME results "&results"; 

  %LET hcpf     = S:/FHPC/DATA/HCPF_Data_files_SECURE;
  %LET ana = S:/FHPC/DATA/HCPF_Data_files_SECURE/HCPF_SqlServer/AnalyticSubset;
  LIBNAME ana "&ana"; 

* VARLEN; 
  %LET varlen = \\data.ucdenver.pvt\dept\SOM\FHPC\DATA\HCPF_Data_files_SECURE\HCPF_SqlServer\queries\DBVarLengths;
  LIBNAME varlen "&varlen";
  %INCLUDE "&varlen\MACRO_charLenMetadata.sas";
  %getlen(library=varlen, data=AllVarLengths);

* OPTIONS ---------------------------; 
  OPTIONS NOFMTERR
          MPRINT MLOGIC SYMBOLGEN
          FMTSEARCH =(ana, data, interim, raw, varlen, work);

* ### SEARCH TERM #DO for questions and do tasks ###

******************************************************
FORMATS addt'l, from Jake's file cost anal_part1 as of 01/30 
(check to see if updated #DO)
******************************************************;

proc format;
value agecat  1="0-19" 2="20-64" 3="65+";
value agehcpf 1="0-3" 2="4-6" 3="7-12" 4="13-20" 5="21-64" 6="65+";
value age7cat 1="0-5" 2="6-10" 3="11-15" 4="16-20" 5="21-44" 6="45-64" 7="65+";
value fy      1="7/1/18 - 6/30/19" 2="7/1/19 - 6/30/20" 3="7/1/20 - 6/30/21";
value nserve  1="1" 2="2" 3="3" 4="4" 5="5" 6="6" 7="7+";
/*value fhqc  0="No services" 1="Only FQHC" 2="Only non-FQHC" 3="Both FQHC and non-FQHC";*/
value capvsh  1="Same month" 2="Short term first" 3="Cap first" 4="Short term only" 5="Cap only" 6="Neither";
/*value matchn  1="Both match" 2="Billing match" 3="Rendering match" 4="Neither match";*/
run;

******************************************************
DATASETS : for provenance see readme file in #DO
orig                    Primary Key/s, Fmt    Cols/Notes        
----------------------  ------------------    -------------------------------------------      
isp.csv                 id_npi_pcmp           other ids: id_split id_npi_redcap
qry_longitudinal        
qry_qry_demographics
qry_monthly_utilization
******************************************************;
* RAE; 
DATA data.rae; 
SET  data.rae; 
HCPF_County_Code_C = put(HCPF_County_Code,z2.); 
RUN; 

* Dynamic Files, sourced from analytic subset --------------------------; 
DATA qry_longitudinal;            SET ana.qry_longitudinal;            RUN; *02/09/23 [1,177,273,652 : 25];
DATA qry_demographics;            SET ana.qry_demographics;            RUN; *02/09/23 [  3008709     :  7];
DATA qry_monthly_utilization;     SET ana.qry_monthlyutilization;      RUN; *02/09/23 [111,221,842   :  7];

******************************************************
Initial Datasteps before merging
******************************************************;
proc format ; 
value pcmp_type_rc
32 = "FQHC"
45 = "RHC" 
51 = "SHS"
61 = "IHS"
62 = "IHS"
Other = "Other"; 
run; 
* ;

DATA   qrylong_y15_22   ( DROP = managedCare ); 
LENGTH mcaid_id $11; 
SET    qry_longitudinal ( DROP = aid_cd_1-aid_cd_5 title19: FED_POV_LVL_PC ) ; 

* Recode pcmp loc type with format above; 
num_pcmp_type = input(pcmp_loc_type_cd, 7.);
pcmp_type     = put(num_pcmp_type, pcmp_type_rc.);        

WHERE  month ge '01Jul2015'd 
AND    month le '30Jun2022'd 
AND    BUDGET_GROUP not in (16,17,18,19,20,21,22,23,24,25,26,27,-1,)
AND    managedCare = 0
AND    pcmp_loc_id ne '';
RUN;  * 81494187, 18;

PROC FREQ 
     DATA = qrylong_y15_22;
     TABLES pcmp_type / ;* PLOTS = freqplot(type=dotplot scale=percent) out=out_ds;
     TITLE  'Frequency pcmp_type all records';
RUN; 
TITLE; 

PROC FREQ 
     DATA = qry_longitudinal;
     TABLES pcmp_loc_type_cd ;
RUN; 

* ; 
PROC SQL; 
CREATE TABLE qrylong_y15_22a AS
SELECT a.*, 
       b.dob, 
       b.gender, 
       b.race,
       b.ethnic
FROM   qrylong_y15_22 AS a 
LEFT JOIN qry_demographics AS b 
ON     a.mcaid_id=b.mcaid_id ;
QUIT; 
* 81494187, 22;

DATA data.qrylong_y15_22; 
SET  qrylong_y15_22a;

  * create age variable;
  IF      month ge '01Jul2015'd AND month le '30Jun2016'd THEN last_day_fy='30Jun2016'd;
  ELSE IF month ge '01Jul2016'd AND month le '30Jun2017'd THEN last_day_fy='30Jun2017'd;
  ELSE IF month ge '01Jul2017'd AND month le '30Jun2018'd THEN last_day_fy='30Jun2018'd;
  ELSE IF month ge '01Jul2018'd AND month le '30Jun2019'd THEN last_day_fy='30Jun2019'd;
  ELSE IF month ge '01Jul2019'd AND month le '30Jun2020'd THEN last_day_fy='30Jun2020'd;
  ELSE IF month ge '01Jul2020'd AND month le '30Jun2021'd THEN last_day_fy='30Jun2021'd;
  ELSE IF month ge '01Jul2021'd AND month le '30Jun2022'd THEN last_day_fy='30Jun2022'd;
  * create FY variable; 
  IF      last_day_fy = '30Jun2016'd then FY = 'FY_1516';
  ELSE IF last_day_fy = '30Jun2017'd then FY = 'FY_1617';
  ELSE IF last_day_fy = '30Jun2018'd then FY = 'FY_1718';
  ELSE IF last_day_fy = '30Jun2019'd then FY = 'FY_1819';
  ELSE IF last_day_fy = '30Jun2020'd then FY = 'FY_1920';
  ELSE IF last_day_fy = '30Jun2021'd then FY = 'FY_2021';
  ELSE IF last_day_fy = '30Jun2022'd then FY = 'FY_2122';

  age_end_fy = floor( (intck('month', dob, last_day_fy) - (day(last_day_fy) < min(day(dob), day(intnx ('month', last_day_fy, 1) -1)))) /12 );
  * remove if age not in range;
  IF age_end_fy lt 0 or age_end_fy gt 64 THEN delete;
  FORMAT last_day_fy date9.;
  
RUN; * 20230214 FEB.QRYLONG_Y15_22 has 78680146 observations and 25 variables.
;

proc datasets nolist lib=work; delete qrylong_y15_22; quit; run; 

PROC CONTENTS 
     DATA = data.qrylong_y15_22 VARNUM;
RUN;

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

* ---------------Export --------------------------;
ods excel file = "&results/MonthlyAttr_CTLP_MRN_Matches.xlsx"
    options (   sheet_name = "fy2019_2022" 
                sheet_interval = "none"
                frozen_headers = "yes"
                autofilter = "all");

proc print DATA = out.attr_mrn_cls;
run;

ods excel close; 
run;

proc print data = data.isp;
run;
