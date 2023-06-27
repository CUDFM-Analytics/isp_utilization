*
AUTHOR   : KTW
PROJECT  : ISP Utilization Analysis
PURPOSE  : BHO, 
VERSION  : 2023-04-24 somehow had >1 mcaid_id from budget group_new idk [date last updated]
DEPENDS  : ana subset folder, config file [dependencies]
NEXT     : [left off on row... or what step to do next... ]  ;

%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 
***********************************************************************************************;


PROC SQL ; 
CREATE TABLE memlist_bh_1621 AS 
SELECT *
FROM   bho_0 
WHERE  mcaid_id IN (SELECT mcaid_id FROM int.memlist_final) ; 
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
