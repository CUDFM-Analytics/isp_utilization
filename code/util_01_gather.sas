**********************************************************************************************
PROJECT    : ISP Utilization Analysis
PROGRAMMER : KTW
DATE RAN   : 02-24-2022
PURPOSE    : Gather, Process datasets needed to create Final Analysis Datasets  

OUTPUTS 
Section 1  : isp_key

*---- global paths, settings  ----------------------------------------------------------------;
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_params.sas"; 
***********************************************************************************************;

* ---- SECTION 01 ------------------------------------------------------------------------------
Create isp id dataset
 - Need date practice started ISP for the time varying cov
 - Covariate ISP participate pcmp at any time

Inputs      redcap.csv, datasets/isp_master_ids.sas7bdat
Outputs     data/isp_key;

%LET redcap = S:/FHPC/DATA/HCPF_Data_files_SECURE/Kim/isp/isp_utilization/data/isp_redcap.csv;
* select columns and convert id_split to numeric (others??); 
proc import datafile = "&redcap"
    out  = redcap0
    dbms = csv
    replace;
run;

PROC IMPORT 
     DATAFILE = &redcap
     OUT      = redcap0 
     DBMS     = csv
     REPLACE;
RUN; 

PROC FREQ 
     DATA = redcap0;
     TABLES dt_prac_start_isp;* PLOTS = freqplot(type=dotplot scale=percent) out=out_ds;
     TITLE  'Frequency: Date practices started ISP';
RUN; * all started on 01's ; 

DATA   data.redcap; 
SET    redcap0 ( KEEP = id_npi_redcap 
                        id_npi_pcmp
                        id_pcmp
                        id_split 
                        name_practice 
                        dt_prac_start_isp 
                        wave 
                        pr_county
                        fct_county_class   /* county classification of frontier, urban, rural. */
               ); 
* make pcmp numeric ;
num_id_pcmp = input(id_pcmp, 8.);

* reformat date variable to match on qry_longitudinal;
dt_prac_isp = put(dt_prac_start_isp, date9.);
label dt_prac_isp = "Formatted Date Start ISP";
RUN;  * 122, 10 on 02/14;

DATA isp_key0 ( KEEP = id_pcmp splitid ) ;
SET  datasets.isp_masterids;
id_npi = input(practiceNPI, best12.);
id_pcmp = input(pcmp_loc_id, best12.);
RUN; 

PROC SORT DATA = isp_key0    ; BY id_split id_pcmp ; 
PROC SORT DATA = data.redcap ; BY id_split id_pcmp ; RUN; 

DATA redcap;
SET  data.redcap ( KEEP = id_split name_practice dt_prac_isp pr_county fct_county_class ) ;  
RUN; 

PROC SQL;
CREATE TABLE data.isp_key AS 
SELECT coalesce ( a.id_split , b.splitID ) as id_split
     , a.name_practice
     , a.pr_county
     , a.fct_county_class
     , a.dt_prac_isp
     , b.id_pcmp
FROM redcap as A
FULL JOIN isp_key0 as B
ON  a.id_split = b.splitID;
QUIT; * 153 ; 

PROC SORT DATA = data.isp_key NODUPKEY; BY _ALL_ ; RUN; 
* 30 duplicates, 123 remain; 

ods trace on; 
PROC FREQ 
     DATA = data.isp_key NLEVELS ;
     TABLES _all_ ;* PLOTS = freqplot(type=dotplot scale=percent) out=out_ds;
     TITLE  'Frequency isp_key';
RUN; 
TITLE; 
ods trace off;

data data.isp_key; 
set  data.isp_key; 
pcmp_loc_id = put(id_pcmp, best.-L); 
run ;


* ==== SECTION 02 ==============================================================================
Get RAE_ID and county info
Inputs      Kim/county_co_data.csv
Outputs     data/isp_key
Notes       Got from Jake and did all in R, just got the _c var here 
;

DATA data.rae; 
SET  data.rae; 
HCPF_County_Code_C = put(HCPF_County_Code,z2.); 
RUN; 


* ==== SECTION 03 ==============================================================================
get original longitudinal & demographics files 
process: 15_22 dataset, 19_22 dataset, and memlist (S4), join RAE
create vars: FY, last_day_fy, age for subsetting 0-64
Inputs      ana.qry_longitudinal  [1,177,273,652 : 25] 2023-02-09
            ana.qry_demographics  [  3008709     :  7] 2023-02-09
Outputs     data/qrylong_y15_22   [    78680146 : 25]
Notes       Got from Jake and did all in R, just got the _c var here 
;

* copy datasets from ana.;
DATA qry_longitudinal;            SET ana.qry_longitudinal;            RUN; *02/09/23 [1,177,273,652 : 25];
DATA qry_demographics;            SET ana.qry_demographics;            RUN; *02/09/23 [  3008709     :  7];

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
AND    pcmp_loc_id ne ''
AND    rae_assign = 1;
RUN;  * 81494187, 18;

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

DATA qrylong_y15_22b; 
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
  
RUN; * 20230214 [78680146 : 25]
;

proc datasets nolist lib=work; delete qrylong_y15_22; quit; run; 

* join rae info ; 
PROC SQL; 
CREATE TABLE data.qrylong_y15_22 AS 
SELECT a.*
     , b.county_rating_area_id
     , b.rae_id
     , b.hcpf_county_code_c
FROM qrylong_y15_22b AS A
LEFT JOIN data.rae AS b
ON a.enr_cnty = b.hcpf_county_code_c; 
QUIT; 


* ---- SECTION 4 Create memlist ------------------------------------------------------------------------------
Get unique mcaid_id from 15-22 subset
 - At first it copies three columns but then keeps only mcaid_id
 - Gets memlist for 19-22 

Inputs      data.qrylong_y15_22
Outputs     data/memlist
Notes       1594687 members for timeframe 01JUL2019-30JUN2022 (memlist)
;

PROC SORT DATA  = data.qrylong_y15_22 ( KEEP = mcaid_id month pcmp_loc_ID ) 
     NODUPKEY
     OUT        = memlist_0 
     ; 
WHERE pcmp_loc_ID ne ' ' 
AND   month ge '01Jul2019'd 
AND   month le '30Jun2022'd;
BY    mcaid_id month; 
RUN; *1594348;

* kept only mcaid_id
* ( if running again, can go straight from memlist_0 to here - I had in other code that should not have been ); 
DATA data.memlist; 
set  data.memlist ( keep = mcaid_id ) ; 
run; 
* 1594687 members for timeframe 01JUL2019-30JUN2022;   


* ---- SECTION 5 Get BHO Data -------------------------O-----------------------------------------------------
Get from analytic subset, keep ER & other
01JUL2019 >= month < 01JUL022

Inputs      ana.qry_bho_mnothlyutil_working [6405694 : 7] 2023-02-24
Outputs     data.bho                        [4767794 : 7] 2023-02-09
;

DATA qry_bho_monthlyutil_working; SET ana.qry_bho_monthlyutil_working; RUN; *02/09/23 [   6,405,694  :  7];

*convert to a month; 
DATA bho_0;
SET  qry_bho_monthlyutil_working;
month2 = month;
FORMAT month2 date9.;
DROP   month;
RENAME month2 = month; 
run; *6405694 observations and 5 variables;

* subset 2015 - 2022; 
DATA   bho_1  ; 
SET    bho_0 ( DROP = bho_n_hosp ) ; 
WHERE  month ge '01JUL2019'd 
AND    month le '01JUL2022'd;
RUN; *NOTE: The data set WORK.BHO_1 has 4767794 observations and 4 variables.;

* sum by month ; 
PROC SQL; 
 CREATE TABLE data.bho_19_22 AS
 SELECT MCAID_ID
      , month
      , sum(bho_n_er    ) as bh_n_er
      , sum(bho_n_other ) as bh_n_other
from bho_1
group by MCAID_ID, month;
quit; 

* ==== add format FY7 to bho dataset 02/21 =======================; 
data   data.bho_19_22; 
set    data.bho_19_22; 
format month date9.;
fy     = year(intnx('year.7', month, 0, 'BEGINNING')); 
run; 

* ---- SECTION 6 Get Monthly Utilization Data ------------------------------------------------------------------------------
Get monthly n & pd from ana. for 19-22 records

Inputs      ana.qry_monthly_utilization     [111,221,842 : 7] 2023-02-09
Outputs     data.util_month_y15_22          [ 77,273,443 : 7] 2023-02-09
;

DATA  qry_monthly_utilization;     
SET   ana.qry_monthlyutilization ( WHERE = ( month ge '01Jul2019'd and month le '30Jun2022'd ) ) ;  
RUN; 
* 2/27 [33767742 : 5] with 2019july set ;
*02/09/23 [111,221,842   :  7];

* Re-factor clmClass as clmClass_r ;
DATA  util0;
SET   qry_monthly_utilization;  

fy3        = year(intnx('year.7', month, 0, 'B'));
clmClass_r = clmClass ; 

format clmClass_r clmClass_r.;
format month      date9.;
RUN; 
* 2/27 [33767742 : 7] with 2019july set ;

proc sql;
create table data.util_19_22 as
select mcaid_id
     , month
     , sum(case when clmClass = 4 then pd_amt else 0 end) as pd_amt_pc
     , sum(case when clmClass = 2 then pd_amt else 0 end) as pd_amt_rx
     , sum(pd_amt) as pd_amt_total
     , sum(case when clmClass = 4 then count else 0 end) as n_pc
     , sum(case when clmClass = 3 then count else 0 end) as n_er
     , sum(count) as n_total
from util0
group by MCAID_ID, month;
quit; *16700349 : 8 ;

proc print data = data.util_19_22 (obs = 500) ; run ; 

* ---- SECTION 7 Get Telehealth records ---------------------------------------------------------------------

;

* database location ;

libname ana 'S:/FHPC/DATA/HCPF_Data_files_SECURE/HCPF_SqlServer/AnalyticSubset'; * reset to : M:\HCPF_SqlServer\AnalyticSubset ;
option fmtsearch=(ana);

* primary care records ;
data pc;
  set ana.Qry_clm_dim_class;
  where hosp_episode NE 1
    and ER NE 1
    and primCare = 1;
run;* 43044039;


* telehealth records ;
proc format;
 * telehealth eligible visits ;
 invalue teleElig 
 '76801','76802','76805','76811','76812','76813','76814','76815','76816','76817','90791','90792','90832','90833','90834','90836',
'90837','90838','90839','90840','90846','90847','90849','90853','90863','92507','92508','92521','92522','92523','92524','92526',
'92606','92607','92608','92609','92610','92630','92633','96101','96102','96110','96111','96112','96113','96116','96118','96119',
'96121','96125','96130','96131','96132','96133','96136','96137','96138','96139','96146','97110','97112','97129','97130','97140',
'97150','97151','97153','97154','97155','97158','97161','97162','97163','97164','97165','97166','97167','97168','97530','97533',
'97535','97537','97542','97755','97760','97761','97763','97802','97803','97804','98966','98967','98968','99201','99202','99203',
'99204','99205','99211','99212','99213','99214','99215','99382','99383','99384','99392','99393','99394','99401','99402','99403',
'99404','99406','99407','99408','99409','99441','99442','99443','G0108','G0109','G8431','G8510','G9006','H0001','H0002','H0004',
'H0006','H0025','H0031','H0032','H0049','H1005','H2000','H2011','H2015','H2016','S9445','S9485','T1017','V5011'
=1
other=0;
run;

data telecare;
  set ana.Clm_lne_fact_v;

  teleCare = (CLM_TYP_CD in ( 'B','M' ) and POS_CD = '02' ) or 
             (
               CLM_TYP_CD in ( 'C','O' ) and 
               (PROC_MOD_1_CD='GT' or PROC_MOD_2_CD='GT' or PROC_MOD_3_CD='GT' or PROC_MOD_4_CD='GT')
              );

  *eligible for telehealth ;
  teleElig = input(proc_cd, teleElig.);

   * keeping only rows that are ER or primary or urgent or tele care ;
  if teleCare or teleElig;

run;

* indicators of telehealth and tele-eligible care ;
proc sql;
  create table margTele as
    select icn_nbr,
           max(teleCare) as telecare,
           max(teleElig) as teleElig
    from telecare
    group by icn_nbr;
quit;

* telehealth is: primary care, tele eligible and a telehealth service ;
proc sql;

create table teleCare_FINAL as
  select a.*
  from pc as a inner join margTele as b
    on a.icn_nbr = b.icn_nbr 
  where a.primCare = 1 and b.teleCare = 1 and b.teleElig = 1;

quit;

* monthy telehealth encounters and costs, per client ;
proc sql;

create table teleCare_monthly as
  select mcaid_id,
         intnx('month',FRST_SVC_DT, 0, 'beginning') as month,
         count (distinct FRST_SVC_DT) as n_tele,
         sum(pd_amt) as pd_tele
  from teleCare_FINAL
  group by mcaid_id, month;

quit;

DATA  data.teleCare_monthly;
SET   teleCare_monthly;
RUN;

* Get FY7 years ;
DATA  data.teleCare_monthly ;
SET   data.teleCare_monthly ;
WHERE month ge '01Jul2015'd 
AND   month le '30Jun2022'd ; 
format month date9.;
fy7=year(intnx('year.7', month, 0, 'BEGINNING')) ; 
RUN; *932892, 5; 

PROC SQL; 
CREATE TABLE data.memlist_tele_monthly AS
SELECT *
FROM   data.teleCare_monthly
WHERE  mcaid_id IN ( SELECT mcaid_id FROM data.memlist ) ; 
QUIT; 

proc print data = data.memlist_tele_monthly ( obs = 1000) ; run;

PROC FREQ 
     DATA = data.teleCare_monthly;
     TABLES month ;* PLOTS = freqplot(type=dotplot scale=percent) out=out_ds;
     TITLE  'Frequency month';
RUN; 
TITLE; 
