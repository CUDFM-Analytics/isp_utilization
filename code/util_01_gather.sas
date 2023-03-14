**********************************************************************************************
PROJECT    : ISP Utilization Analysis
PROGRAMMER : KTW
UPDATED ON : 03-07-2023 (new config file from MG) 
PURPOSE    : Gather, Process datasets needed to create Final Analysis Datasets  
CHANGES    : tmp is interim files
           : new specs file from Mark / can reduce many files

*---- global paths, settings  ----------------------------------------------------------------;
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 
***********************************************************************************************;

* ---- SECTION01 ------------------------------------------------------------------------------
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

DATA   int.redcap; 
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
id_npi  = input(practiceNPI, best12.);
id_pcmp = input(pcmp_loc_id, best12.);
RUN; 

PROC SORT DATA = isp_key0    ; BY id_split id_pcmp ; 
PROC SORT DATA = int.redcap ; BY id_split id_pcmp ; RUN; 

DATA redcap;
SET  int.redcap ( KEEP = id_split name_practice dt_prac_isp pr_county fct_county_class ) ;  
RUN; 

PROC SQL;
CREATE TABLE int.isp_key AS 
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

PROC SORT DATA = int.isp_key NODUPKEY; BY _ALL_ ; RUN; 
* 30 duplicates, 123 remain; 

ods trace on; 
PROC FREQ 
     DATA = int.isp_key NLEVELS ;
     TABLES _all_ ;* PLOTS = freqplot(type=dotplot scale=percent) out=out_ds;
     TITLE  'Frequency isp_key';
RUN; 
TITLE; 
ods trace off;

data int.isp_key; 
set  int.isp_key; 
pcmp_loc_id = put(id_pcmp, best.-L); 
run ;

* ==== SECTION02 RAE ==============================================================================
Get RAE_ID and county info
Inputs      Kim/county_co_data.csv
Outputs     data/isp_key
Notes       Got from Jake and did all in R, just got the _c var here 
;

DATA int.rae; 
SET  int.rae; 
HCPF_County_Code_C = put(HCPF_County_Code,z2.); 
RUN; 

* ==== SECTION03 ==============================================================================
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

* subset qrylong to dates within FY's and get var's needed ;  
DATA   qrylong_16_22;
LENGTH mcaid_id $11; 
SET    ana.qry_longitudinal ( DROP = FED_POV: 
                                     DISBLD_IND 
                                     aid_cd:
                                     title19: 
                                     SPLM_SCRTY_INCM_IND
                                     SSI_: 
                                     SS: 
                                     dual
                                     eligGrp
                                     fost_aid_cd
                              ) ; 
* Recode pcmp loc type with format above; 
num_pcmp_type = input(pcmp_loc_type_cd, 7.);
pcmp_type     = put(num_pcmp_type, pcmp_type_rc.);        

WHERE  month ge '01Jul2016'd 
AND    month le '30Jun2022'd 
AND    BUDGET_GROUP not in (16,17,18,19,20,21,22,23,24,25,26,27,-1,)
AND    managedCare = 0
AND    pcmp_loc_id ne ''
AND    rae_assign = 1;
RUN;  * 55625167 observations and 10;

* join with demographics to get required demographics in all years ; 
PROC SQL; 
CREATE TABLE qrylong_1621a AS
SELECT a.*, 
       b.dob, 
       b.gender as sex, 
       b.race,
       b.ethnic
FROM   qrylong_16_22 AS a 
LEFT JOIN ana.qry_demographics AS b 
ON     a.mcaid_id=b.mcaid_id ;
QUIT; 
* 55625167, 14;

DATA qrylong_1621b ( DROP = age_end_fy last_day_fy num_pcmp_type rae_assign budget_group ); 
SET  qrylong_1621a;

* create age variable;
  IF      month ge '01Jul2016'd AND month le '30Jun2017'd THEN last_day_fy='30Jun2017'd;
  ELSE IF month ge '01Jul2017'd AND month le '30Jun2018'd THEN last_day_fy='30Jun2018'd;
  ELSE IF month ge '01Jul2018'd AND month le '30Jun2019'd THEN last_day_fy='30Jun2019'd;
  ELSE IF month ge '01Jul2019'd AND month le '30Jun2020'd THEN last_day_fy='30Jun2020'd;
  ELSE IF month ge '01Jul2020'd AND month le '30Jun2021'd THEN last_day_fy='30Jun2021'd;
  ELSE IF month ge '01Jul2021'd AND month le '30Jun2022'd THEN last_day_fy='30Jun2022'd;
  * create FY variable; 
  IF      last_day_fy = '30Jun2017'd then FY = 'FY_1617';
  ELSE IF last_day_fy = '30Jun2018'd then FY = 'FY_1718';
  ELSE IF last_day_fy = '30Jun2019'd then FY = 'FY_1819';
  ELSE IF last_day_fy = '30Jun2020'd then FY = 'FY_1920';
  ELSE IF last_day_fy = '30Jun2021'd then FY = 'FY_2021';
  ELSE IF last_day_fy = '30Jun2022'd then FY = 'FY_2122';

  age_end_fy = floor( (intck('month', dob, last_day_fy) - (day(last_day_fy) < min(day(dob), day(intnx ('month', last_day_fy, 1) -1)))) /12 );

  * remove if age not in range;
  IF age_end_fy lt 0 or age_end_fy gt 64 THEN delete;
  FORMAT last_day_fy date9.;
  FY  = year(intnx('year.7', month, 0, 'BEGINNING'));

  age = age_end_fy;
  format age age_cat_.;
  
  * create categorical variable for budgetgroup and pcmp_type; 
  budget_grp_new = put(BUDGET_GROUP, budget_grp_new_.); 
  pcmp_type      = put(num_pcmp_type, pcmp_type_rc_.); 
  
RUN; *53384196 : 18;

proc datasets nolist lib=work; delete  qrylong_16_22;; quit; run; 

* join rae info ; 
PROC SQL; 
CREATE TABLE int.qrylong_1621 AS 
SELECT a.*
     , b.rae_id as rae_person_new
FROM qrylong_16_22b AS A
LEFT JOIN int.rae AS b
ON a.enr_cnty = b.hcpf_county_code_c; 
QUIT; *53384196 rows and 19 columns.;

DATA int.qrylong_1921 ; 
SET  int.qrylong_1621 ; 
WHERE  month ge '01Jul2019'd 
AND    month le '30Jun2022'd ; 
RUN ; * 40999955 boom ; 

* ---- SECTION04 Create memlist ------------------------------------------------------------------------------
Get unique mcaid_id from 16-22 subset
 - At first it copies three columns but then keeps only mcaid_id
 - Gets memlist for 19-22 

Inputs      data.qrylong_y15_22
Outputs     data/memlist
Notes       1594687 members for timeframe 01JUL2019-30JUN2022 (memlist)
;

PROC SORT DATA  = int.qrylong_16_22 ( KEEP = mcaid_id month pcmp_loc_ID ) 
     NODUPKEY
     OUT        = memlist_0 
     ; 
WHERE pcmp_loc_ID ne ' ' 
AND   month ge '01Jul2019'd 
AND   month le '30Jun2022'd;
BY    mcaid_id month; 
RUN; 

* kept only mcaid_id;
DATA memlist_1; 
set  memlist_0 ( keep = mcaid_id ) ; 
run; 

PROC SORT 
DATA = memlist_1 NODUPKEY
OUT  = int.memlist;
BY   mcaid_id; 
RUN ; 
* 1594348 members for timeframe 01JUL2019-30JUN2022;   

* ---- SECTION05 BHO Data ------------------------------------------------------------------------------
Get BH data from analytic subset: keep all (updated specs on 3/7 to include hosp) 
[bho_n_er, bho_n_hosp, bho_n_other]
Inputs      ana.qry_bho_mothlyutil_working [6405694 : 7] 2023-03-09
Outputs     int.bh_1618, int.bh_1922       [4208734 : 7] 2023-03-09;
 
DATA bho_0;
SET  ana.qry_bho_monthlyutil_working; 
month2 = month;
FORMAT month2 date9.;
DROP   month;
RENAME month2 = month; 
WHERE  month ge '01Jul2016'd
AND    month le '01Jul2022'd;
FY     =year(intnx('year.7', month, 0, 'BEGINNING'));
run; *4208734 observations and 6 variables;

* subset FY16-18 and FY19-21; 
DATA int.bh_1922 bh_1618  ; 
SET  bho_0  ; 
IF   month ge '01JUL2019'd THEN OUTPUT int.bh_1922;
ELSE OUTPUT bh_1618;
RUN; 
*The data set int.bh_1922 has 2277105 observations and 6 variables.
 The data set int.BH_1618 has 1931629 observations and 6 variables.;

* ----  BH_XX16, BH_XX17, BH_XX18  ------------------------------------------------- ; 
PROC SQL; 
CREATE TABLE bh_cat AS 
SELECT mcaid_id
     , FY
     , sum(bho_n_er   ) as bh_er
     , sum(bho_n_hosp ) as bh_hosp
     , sum(bho_n_other) as bh_oth
FROM bh_1618
GROUP BY mcaid_id, FY; 
QUIT ; *3/14 [ 493163 : 5 ] ; 

DATA bh_cat1 ; 
SET  bh_cat ; 
FY   = substr(FY, length(FY)-2,4);
RUN ; 

            * check years are okay...; 
            ODS GRAPHICS ON;
            PROC FREQ 
                 DATA = bh_cat1;
                 TABLES FY / ;* PLOTS = freqplot(type=dotplot scale=percent) out=out_ds;
                 TITLE  'Frequency...';
            RUN; 
            TITLE; 
            ODS GRAPHICS OFF;

PROC TRANSPOSE DATA = bh_cat1 OUT = bh_cat_t ;
by mcaid_id FY;
VAR bh_er bh_hosp bh_oth; 
RUN ; 

DATA int.bh_1618_long ( DROP = Col1); 
SET  bh_cat_t;
BH = col1 > 0; 
RUN ;  

* transpose again to get wide: 1/3 would be 493,163 if everyone had 3 values; 
PROC TRANSPOSE DATA = int.bh_1618_long OUT = bh_1618_final ;
by mcaid_id;
VAR bh ; 
ID _NAME_ FY ; 
RUN ; *326235 obs 11 var; 

* Frequency for variables, just using long; 
PROC SORT DATA = bh_1618_final ; BY _NAME_ ; RUN ; 
PROC FREQ 
     DATA = int.bh_1618_long;
     BY _NAME_; 
     TABLES FY ;
     WHERE BH = 1;
RUN; 

* change missing to 0's (ask too) ; 
PROC STDIZE DATA = bh_1618_final 
     OUT         = int.bh_1618  (DROP = _NAME_)
     REPONLY 
     MISSING     = 0; 
RUN ; *326235 obs 10 var;

*----------------------------------------------------------------------------------------------
SECTION06 Get Monthly Utilization Data
    Need for adj_pd_total_YRcat (16,17,18) and other outcomes
    Inputs      ana.qry_monthly_utilization     [111,221,842 : 7] 2023-02-09
    Outputs     data.util_month_fy6             [ 66,367,624 : 7] 2023-03-08
----------------------------------------------------------------------------------------------;

DATA  qry_monthly_utilization;     
SET   ana.qry_monthlyutilization ( WHERE = ( month ge '01Jul2016'd and month le '30Jun2022'd ) ) ;  
RUN; * 663676624;

DATA  util0;
SET   qry_monthly_utilization;  
format month      date9.;
RUN; 

* COST: rx, pc, total
* UTIL: PC, ED (no total); 
proc sql;
create table int.util_fy6 as
select mcaid_id
     , month
     , sum(case when clmClass = 2 then pd_amt else 0 end) as pd_ffs_rx
     , sum(case when clmClass = 4 then pd_amt else 0 end) as pd_ffs_pc
     , sum(pd_amt)                                        as pd_ffs_total
     , sum(case when clmClass = 4 then count  else 0 end) as n_ffs_pc
     , sum(case when clmClass = 3 then count  else 0 end) as n_ffs_er
from util0
group by MCAID_ID, month;
quit; *Table int.UTIL_FY6 created, with 32830948 rows and 7 columns. ;

proc print data = int.util_fy6 (obs = 50) ; run ; 

* SPLIT INTO 1618 for cat and 19-21 for outcomes ; 

* subset FY16-18 and FY19-21; 
DATA int.util_1921 util_1618 ; 
SET  int.util_fy6 ; 
FY   = year(intnx('year.7', month, 0, 'BEGINNING'));
IF   month ge '01JUL2019'd THEN OUTPUT int.util_1921;
ELSE OUTPUT util_1618;
RUN; 
* NOTE: The data set  INT.UTIL_1921 has 16700349 observations and 7 variables.
  NOTE: The data set WORK.UTIL_1618 has 16130599 observations and 7 variables.
;

* get the last two digits of year for column names ; 
DATA util_1618a ; 
SET  util_1618  ; 
FY   = substr(FY, length(FY)-2,4);
RUN ; 

            * check years are okay...; 
            ODS GRAPHICS ON;
            PROC FREQ 
                 DATA = util_1618a ;
                 TABLES FY / ;* PLOTS = freqplot(type=dotplot scale=percent) out=out_ds;
                 TITLE  'Frequency...';
            RUN; 
            TITLE; 
            ODS GRAPHICS OFF;

            PROC CONTENTS DATA = util_1618a ; RUN ;

* Create quarter variable so it'll match ; 
DATA util_1618b ; 
SET  util_1618a ; 
format dt_qrtr date9.;
/*q2 = put(month, yyq.);*/
dt_qrtr = intnx('quarter', month ,0,'b');
RUN ; 

* Adjust vars ;
PROC SQL ; 
CREATE TABLE int.util_1618c AS 
SELECT a.*
     , b.index_2021_1
FROM util_1618b as a 
LEFT JOIN int.adj as b 
ON a.dt_qrtr = b.date ; 
QUIT ;  * 16130599 ; 

* Create variable ; 
PROC SQL ; 
CREATE TABLE int.util_1618d AS 
SELECT mcaid_id
     , FY 
     , month 
     , dt_qrtr
     , pd_ffs_total * index_2021_1 as adj_pd_total
FROM int.util_1618c; 
QUIT ; *NOTE: Table INT.UTIL_1618D created, with 16130599 rows and 5 columns. ; 

* SUM the year total per member; 
proc sql;
create table util_1618e  as
select mcaid_id
     , FY
     , sum(adj_pd_total) as adj_pd_fy
from int.util_1618d 
group by MCAID_ID, FY;
quit; *NOTE: Table WORK.UTIL_1618E created, with 3252799 rows and 2 columns ;

* Compare to memlist to get 0: Not eligible for HFC during year ; 
DATA  elig_1618 (KEEP = FY mcaid_id); 
SET   int.qrylong_16_22 ; 
WHERE month lt '01JUL2019'd ; 
RUN ; 

PROC FREQ data = int.qrylong_16_22 ;  tables FY ; RUN ; 




PROC RANK DATA = int.util_1618d 
     GROUPS    = 100 
     OUT       = util1618r;
     VAR       adj_pd_total ; 
     BY        FY ; 
     RANKS     adj_pd_rank ;
RUN ; 








PROC TRANSPOSE DATA = util_1618a OUT = util_1618a_t ;
by mcaid_id FY;
VAR bh_er bh_hosp bh_oth; 
RUN ; 

DATA int.bh_1618_long ( DROP = Col1); 
SET  bh_cat_t;
BH = col1 > 0; 
RUN ;  

* transpose again to get wide: 1/3 would be 493,163 if everyone had 3 values; 
PROC TRANSPOSE DATA = int.bh_1618_long OUT = bh_1618_final ;
by mcaid_id;
VAR bh ; 
ID _NAME_ FY ; 
RUN ; *326235 obs 11 var; 

* Frequency for variables, just using long; 
PROC SORT DATA = bh_1618_final ; BY _NAME_ ; RUN ; 
PROC FREQ 
     DATA = int.bh_1618_long;
     BY _NAME_; 
     TABLES FY ;
     WHERE BH = 1;
RUN; 

* change missing to 0's (ask too) ; 
PROC STDIZE DATA = bh_1618_final 
     OUT         = int.bh_1618  (DROP = _NAME_)
     REPONLY 
     MISSING     = 0; 
RUN ; *326235 obs 10 var;

* ---- SECTION07 Get Telehealth records ---------------------------------------------------------------------
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
quit; *52866266 rows and 3 column;

* telehealth is: primary care, tele eligible and a telehealth service ;
proc sql;

create table teleCare_FINAL as
  select a.*
  from pc as a inner join margTele as b
    on a.icn_nbr = b.icn_nbr 
  where a.primCare = 1 and b.teleCare = 1 and b.teleElig = 1;

quit; * 1170229 rows and 25 columns.;

* monthy telehealth encounters and costs, per client ;
proc sql;

create table teleCare_monthly as
  select mcaid_id,
         intnx('month',FRST_SVC_DT, 0, 'beginning') as month,
         count (distinct FRST_SVC_DT) as n_tele,
         sum(pd_amt) as pd_tele
  from teleCare_FINAL
  group by mcaid_id, month;

quit; *1015124 : 4 ; 

* Get FY7 years ;
DATA  int.teleCare_monthly ;
SET   teleCare_monthly ;
WHERE month ge '01Jul2016'd 
AND   month le '30Jun2022'd ; 
format month date9.;
fy7=year(intnx('year.7', month, 0, 'BEGINNING')) ; 
RUN; *932892, 5; 

* Subset to memlist ; 
PROC SQL; 
CREATE TABLE int.memlist_tele_monthly AS
SELECT *
FROM   int.teleCare_monthly
WHERE  mcaid_id IN ( SELECT mcaid_id FROM data.memlist ) ; 
QUIT; *3/9: 908045, 5; 

PROC SORT DATA = int.memlist_tele_monthly ; BY mcaid_id ; RUN ; 
proc print data = int.memlist_tele_monthly ( obs = 15) ; run;



