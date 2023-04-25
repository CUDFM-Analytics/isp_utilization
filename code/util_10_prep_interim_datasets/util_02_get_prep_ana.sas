**********************************************************************************************
AUTHOR   : KTW
PROJECT  : ISP Utilization Analysis
PURPOSE  : Gather, Process datasets from analytic subset dir
VERSION  : 2023-04-24 somehow had >1 mcaid_id from budget group_new idk [date last updated]
DEPENDS  : ana subset folder, config file [dependencies]
NEXT     : [left off on row... or what step to do next... ]  ;

%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 
***********************************************************************************************;

* ==== SECTION01 ==============================================================================

* copy datasets from ana.;
PROC CONTENTS DATA = ana.qry_demographics VARNUM ; RUN ; 
DATA qry_longitudinal;            SET ana.qry_longitudinal;            RUN; *02/09/23 [1,177,273,652 : 25];
DATA qry_demographics;            SET ana.qry_demographics;            RUN; *02/09/23 [  3008709     :  7];

* **B** subset qrylong to dates within FY's and get var's needed ;  
DATA   qrylong_1621;
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
/*pcmp_type     = put(num_pcmp_type, pcmp_type_rc.);     */

format dt_qrtr date9.; * create quarter beginning date to get quarters ; 
dt_qrtr = intnx('quarter', month ,0,'b'); 

WHERE  month ge '01Jul2016'd 
AND    month le '30Jun2022'd 
AND    BUDGET_GROUP not in (16,17,18,19,20,21,22,23,24,25,26,27,-1,);
RUN;  * 95582030 4/24 : 95609204  observations and 10;

** Set aside pcmp type for now - match it to memlist_qrtr and memlist; 
/*DATA int.pcmp_type_qrylong ; */
/*SET  int.qrylong_1621 (KEEP = pcmp_loc_id pcmp_loc_type_cd num_pcmp_type pcmp_type) ; */
/*RUN ; */

PROC SORT DATA = int.pcmp_type_qrylong NODUPKEY ; BY _ALL_ ; RUN ; 

** join with demographics to get required demographics in all years ; 
PROC SQL; 
CREATE TABLE qrylong_1621a AS
SELECT a.mcaid_id
     , a.pcmp_loc_id
     , a.month
     , a.enr_cnty
     , a.budget_group
     , a.dt_qrtr 

     , b.dob
     , b.gender as sex
     , b.race

     , c.rae_id as rae_person_new

FROM   qrylong_1621 AS a 

LEFT JOIN ana.qry_demographics AS b 
ON        a.mcaid_id=b.mcaid_id 

LEFT JOIN int.rae as c
on        a.enr_cnty = c.hcpf_county_code_c

WHERE  managedcare = 0;
QUIT; 
* 85514116 : 10 on 4/24
85536949, 14
  NB Some RAE ID and enr-county will be missing bc rae's not assigned until 2018 so it's okay in this set for now;
 
DATA int.qrylong_1622 ( DROP = age_end_fy last_day_fy dob ); 
SET  qrylong_1621a    ;

* create age variable;
  IF      month ge '01Jul2016'd AND month le '30Jun2017'd THEN last_day_fy='30Jun2017'd;
  ELSE IF month ge '01Jul2017'd AND month le '30Jun2018'd THEN last_day_fy='30Jun2018'd;
  ELSE IF month ge '01Jul2018'd AND month le '30Jun2019'd THEN last_day_fy='30Jun2019'd;
  ELSE IF month ge '01Jul2019'd AND month le '30Jun2020'd THEN last_day_fy='30Jun2020'd;
  ELSE IF month ge '01Jul2020'd AND month le '30Jun2021'd THEN last_day_fy='30Jun2021'd;
  ELSE IF month ge '01Jul2021'd AND month le '30Jun2022'd THEN last_day_fy='30Jun2022'd;

  age_end_fy = floor( (intck('month', dob, last_day_fy) - (day(last_day_fy) < min(day(dob), day(intnx ('month', last_day_fy, 1) -1)))) /12 );

  * remove if age not in range;
  IF age_end_fy lt 0 or age_end_fy gt 64 THEN delete;
  FORMAT last_day_fy date9.;

  FY  = year(intnx('year.7', month, 0, 'BEGINNING'));

  age = age_end_fy;
RUN; *82160141;

PROC CONTENTS DATA = int.qrylong_1622 varnum; run; 

DATA  int.memlist; 
SET   int.qrylong_1622;
WHERE pcmp_loc_ID ne ' ' 
AND   rae_person_new ne .
AND   month ge '01JUL2019'd
AND   month le '30JUN2022'd;
RUN ;  *4/24 memlist 40958727, memlist = n40974871 ;

* add time to memlit ; 
%create_qrtr(data=int.memlist, set=int.memlist, var= dt_qrtr, qrtr=time);

PROC SORT DATA = int.qrylong_1622 ; BY mcaid_id ; 
PROC SORT DATA = int.memlist      ; BY mcaid_id ; RUN ; 

DATA  int.qrylong_1622_memlist ; 
MERGE int.qrylong_1622 (in=a) int.memlist (in=b KEEP=mcaid_id) ; 
BY    mcaid_id; 
IF    a and b; 
RUN ; *73404937: 11; 

%create_qrtr(data=int.qrylong_1622_memlist, set=int.qrylong_1622_memlist, var=dt_qrtr,qrtr=time);

PROC SORT DATA = int.qrylong_1622_month NODUPKEY ; BY _ALL_ ; RUN ; 
*32115823 observations on 4/25; 
*NOTE: There were 82160141 observations read from the data set INT.QRYLONG_1622_TIME.
NOTE: 51565316 observations with duplicate key values were deleted.
NOTE: The data set INT.QRYLONG_1622_TIME has 30594825 observations and 10 variables.;

PROC PRINT DATA = int.qrylong_1622_time (obs = 100); RUN; 
PROC CONTENTS DATA = int.qrylong_1921              ; RUN;
PROC CONTENTS DATA = int.memlist ; RUN; 

* Get MAX COUNTY (there were duplicates where member had > 1 county per quarter) ; 
PROC SQL; 
CREATE TABLE county AS
SELECT mcaid_id
     , dt_qrtr
     , enr_cnty
     , time
FROM (SELECT *
           , max(month) AS max_mon_by_cnty 
      FROM (SELECT *
                 , count(enr_cnty) as n_county 
            FROM int.memlist
            GROUP BY mcaid_id 
                   , dt_qrtr
                   , enr_cnty) 
      GROUP BY mcaid_id, dt_qrtr, n_county)  
GROUP BY mcaid_id, dt_qrtr
HAVING max(n_county)=n_county
AND    month=max_mon_by_cnty;
QUIT; *14039876; 

PROC SQL; 
CREATE TABLE budget AS
SELECT mcaid_id
     , dt_qrtr
     , budget_group
     , time
FROM (SELECT *
           , max(month) AS max_mon_by_budget
      FROM (SELECT *
                 , count(budget_group) as n_budget_group 
            FROM int.memlist
            GROUP BY mcaid_id 
                   , dt_qrtr
                   , budget_group) 
      GROUP BY mcaid_id, dt_qrtr, n_budget_group)  
GROUP BY mcaid_id, dt_qrtr
HAVING max(n_budget_group)=n_budget_group
AND    month=max_mon_by_budget;
QUIT; *14039876; 

PROC SQL; 
CREATE TABLE rae AS
SELECT mcaid_id
     , dt_qrtr
     , rae_person_new
     , time
FROM (SELECT *
           , max(month) AS max_mon_by_rae
      FROM (SELECT *
                 , count(rae_person_new) as n_rae_person_new 
            FROM int.memlist
            GROUP BY mcaid_id 
                   , dt_qrtr
                   , rae_person_new) 
      GROUP BY mcaid_id, dt_qrtr, n_rae_person_new)  
GROUP BY mcaid_id, dt_qrtr
HAVING max(n_rae_person_new)=n_rae_person_new
AND    month=max_mon_by_rae;
QUIT; *14039876; 

proc sql; 
create table n_ids_budget AS 
select mcaid_id
	 , count(mcaid_id) as n_ids
FROM budget
GROUP BY mcaid_ID;
quit; 

*macro will pull ids >12; 
%macro check_n_id(ds=);
proc sql; 
create table n_ids_&ds AS 
select mcaid_id
	 , count(mcaid_id) as n_ids
FROM &ds
GROUP BY mcaid_ID
having n_ids>12;
quit; 
%mend;

%check_n_id(ds=budget); *0;
%check_n_id(ds=county); *0;
%check_n_id(ds=rae);    *0;

* LAST UPDATED 4/24 (all above to here)
JOIN memlist with memlist_attr for pcmps for mcaid_ids in memlist (keep memlist mcaid_ids);
PROC SQL ; 
CREATE TABLE int.memlist_final AS 
SELECT a.mcaid_id
     , a.age
     , a.sex
     , a.race
     , a.FY
     , a.time 
     , b.pcmp_loc_id 
     , b.n_months_per_q
     , b.ind_isp
     , c.budget_group
     , d.enr_cnty
     , e.rae_person_new
FROM int.memlist as a

LEFT JOIN int.memlist_attr_qrtr_1921 as b
ON a.mcaid_id=b.mcaid_id AND a.time = b.time 

LEFT JOIN budget AS c
ON a.mcaid_id=c.mcaid_id AND a.time = c.time 

LEFT JOIN county AS d
ON a.mcaid_id=d.mcaid_id AND a.time = d.time 

LEFT JOIN rae AS e
ON a.mcaid_id=e.mcaid_id AND a.time = e.time ;
QUIT ; *4/24 40958727 (twice, and second time with the joins) //  4097481 : 12 ; 

PROC SORT DATA = int.memlist_final NODUPKEY; BY _ALL_; RUN; *14039876; 
%check_n_id(var=budget); *0;

PROC SQL; 
CREATE TABLE n_mcaid_ID AS 
SELECT mcaid_id
     , count(mcaid_id) as n
FROM int.memlist_final
GROUP by mcaid_id; 
QUIT; 

PROC FREQ DATA = n_mcaid_id; tables n; run; 

PROC PRINT DATA = n_mcaid_ID (obs = 100) ; where n>12; run; 

PROC PRINT DATA = int.memlist_final; where mcaid_id = "A066638"; run; 

**************************************************************************
* ---- SECTION03 BH Capitated --------------------------------------------
Get BH data from analytic subset: keep all (updated 3/7 to include hosp) 
**************************************************************************;
 
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

PROC SQL ; 
CREATE TABLE memlist_bh_1621 AS 
SELECT *
FROM   bho_0 
WHERE  mcaid_id IN (SELECT mcaid_id FROM int.memlist) ; 
QUIT ; *3617805 just to get fewer records, subset to memlist ; 

* get FY1618 and FY1921 - 1618 will be binary, simpler outcomes ; 
DATA bh_1921 bh_1618  ; 
SET  memlist_bh_1621  ; 
IF   month ge '01JUL2019'd THEN OUTPUT int.bh_1921;
ELSE OUTPUT bh_1618;
RUN; 
* The data set INT.BH_1921 has 2065126 observations and 7 variables.
  The data set WORK.BH_1618 has 1552679 observations and 7 variables;

data BH_1921 ; 
set  bh_1921 ; 
FY   = year(intnx('year.7', month, 0, 'BEGINNING')); * create FY variable ; 
format dt_qrtr date9.; * create quarter beginning date to get quarters ; 
dt_qrtr = intnx('quarter', month ,0,'b');
RUN ; 

%create_qrtr(data=bh_1921a, set=bh_1921,var = dt_qrtr, qrtr=time);

PROC SQL ; 
CREATE TABLE int.bh_1921 AS 
SELECT mcaid_id
     , sum(bho_n_hosp) as sum_q_bh_hosp 
     , sum(bho_n_er)   as sum_q_bh_er
     , sum(bho_n_other) as sum_q_bh_other
     , time
FROM bh_1921a 
GROUP BY mcaid_id, time ; 
QUIT ; 

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
QUIT ; *3/14 [ 386384 : 5 ] ; 

PROC TRANSPOSE DATA = bh_cat OUT = bh_cat_t ;
by mcaid_id FY;
VAR bh_er bh_hosp bh_oth; 
RUN ; 

DATA int.bh_1618_long (DROP = Col1); 
SET  bh_cat_t (RENAME=(_NAME_=bh_util));
BH = col1 > 0; 
label bh_util = "BH Visit Type" ; 
RUN ;  *1159152 : 4 ; 

        * Frequency ; 
        ODS GRAPHICS ON ; 
        PROC FREQ 
             DATA = int.bh_1618_long;
             TABLES bh_util*bh*FY / nopercent PLOTS = freqplot;
        RUN; 
        ODS GRAPHICS OFF ; 

* transpose again to get wide: 1/3 would be 493,163 if everyone had 3 values; 
PROC TRANSPOSE DATA = int.bh_1618_long OUT = bh_1618_final (DROP = _NAME_);
by mcaid_id;
VAR bh ; 
ID bh_util FY ; 
RUN ; *250297 obs 11 var; 

* change missing to 0's ; 
PROC STDIZE DATA = bh_1618_final 
     OUT         = int.bh_1618 
     REPONLY 
     MISSING     = 0; 
RUN ; *250297 obs 10 var;



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

DATA tele_1921 ; 
SET  int.memlist_tele_monthly (DROP = pd_tele fy7); 
format dt_qrtr date9.; * create quarter beginning date to get quarters ; 
dt_qrtr = intnx('quarter', month ,0,'b');
WHERE month ge '01JUL2019'd 
AND   month le '30JUN2022'd;
RUN ; * 903721 : 4; 

%create_qrtr(data= tele_1921a, set=tele_1921,var = dt_qrtr, qrtr=time); *903721 : 5;

PROC SQL ; 
CREATE TABLE int.tele_1921 AS 
SELECT mcaid_id
     , time
     , sum(n_tele) as n_q_tele 
FROM tele_1921a
GROUP BY mcaid_id, time ; 
QUIT ; 

PROC SORT DATA = int.tele_1921 ; by mcaid_id time ; RUN ; 
