**********************************************************************************************
AUTHOR   : KTW
PROJECT  : ISP Utilization Analysis
PURPOSE  : Gather, Process datasets from analytic subset dir
VERSION  : 2023-03-16 [date last updated]
DEPENDS  : ana subset folder, config file [dependencies]
    Need 16-18 for adj_pd_total_YRcat (16,17,18) and 19-21 for outcome vars
    Inputs      ana.qry_monthly_utilization     [111,221,842 : 7] 2023-02-09
    Outputs     data.util_month_fy6             [ 66,367,624 : 7] 2023-03-08;

%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 
***********************************************************************************************;
/*libname ana clear ; */
*----------------------------------------------------------------------------------------------
SECTION 01d.1 Get Monthly Utilization Data 16-21 for memlist
----------------------------------------------------------------------------------------------;
PROC SQL ; 
CREATE TABLE util AS 
SELECT * 
FROM   ana.qry_monthlyutilization 
WHERE  month ge '01Jul2016'd 
AND    month le '30Jun2022'd;  
QUIT; *66382081 4/24 //  663676624;

data util_0; 
set util; 
where month ge '01Jul2016'd and month le '30Jun2022'd;
quarter_beg=intnx('QTR', month, 0, 'BEGINNING'); 
format quarter_beg date9.;
run;

proc sql;
create table int.util_1622_0 as
select a.*, (a.pd_amt/b.index_2021_1) as adj_pd_amount  /*divBY has no missing values*/
from util_0 as a
left join int.adj as b on a.quarter_beg=b.date;
quit; *66382081 : 7 cols; 


proc sort data=int.util_1622_0; by MCAID_ID month; run;

proc sql;
 create table int.util_1622_1 as
 select
 MCAID_ID,month,
  sum(case when clmClass=1 then count else 0 end) as n_Hospitalizations,
  sum(case when clmClass=4 then count else 0 end) as n_Primary_care,
  sum(case when clmClass=3 then count else 0 end) as n_ER,
  sum(case when clmClass=2 then count else 0 end) as n_Pharmacy,
  sum(case when clmClass=5 then count else 0 end) as n_FFS_BH,
  sum(case when clmClass=6 then count else 0 end) as n_Ancillary,
  sum(case when clmClass=7 then count else 0 end) as n_HH_Therapy,
  sum(case when clmClass=8 then count else 0 end) as n_Diagnostic_Procedures,
  sum(case when clmClass=9 then count else 0 end) as n_Transportation,
  sum(case when clmClass=10 then count else 0 end) as n_EE_Services,
  sum(case when clmClass=10000 then count else 0 end) as n_Other,

  sum(adj_pd_amount) as adj_pd_total,
  sum(case when clmClass=1 then adj_pd_amount else 0 end) as adj_pd_Hospitalizations,
  sum(case when clmClass=4 then adj_pd_amount else 0 end) as adj_pd_Primary_care,
  sum(case when clmClass=3 then adj_pd_amount else 0 end) as adj_pd_ER,
  sum(case when clmClass=2 then adj_pd_amount else 0 end) as adj_pd_Pharmacy,
  sum(case when clmClass=5 then adj_pd_amount else 0 end) as adj_pd_FFS_BH,
  sum(case when clmClass=6 then adj_pd_amount else 0 end) as adj_pd_Ancillary,
  sum(case when clmClass=7 then adj_pd_amount else 0 end) as adj_pd_HH_Therapy,
  sum(case when clmClass=8 then adj_pd_amount else 0 end) as adj_pd_Diagnostic_Procedures,
  sum(case when clmClass=9 then adj_pd_amount else 0 end) as adj_pd_Transportation,
  sum(case when clmClass=10 then adj_pd_amount else 0 end) as adj_pd_EE_Services,
  sum(case when clmClass=10000 then adj_pd_amount else 0 end) as adj_pd_Other
  
from int.util_1622_0
group by MCAID_ID,month;
quit; *32835706, 25; 

PROC CONTENTS DATA = int.util_1622_1; RUN; 

* Create FY variable, get beginning of quarter from month variables to match to adj ; 
DATA int.util1622_month; 
SET  int.util_1622_1 ; 
FY   = year(intnx('year.7', month, 0, 'BEGINNING')); * create FY variable ; 
format dt_qrtr date9.; * create quarter beginning date to get quarters ; 
dt_qrtr = intnx('quarter', month ,0,'b');
RUN; *32835706 rows and 27 columns. ;

* Sum by quarters ; 
proc sql;
create table int.util1622_qrtr as
select mcaid_id
     , FY
     , dt_qrtr
     , sum(adj_pd_pharmacy)     as adj_pd_pharmacy_qrtr
     , sum(adj_pd_Primary_care) as adj_pd_Primary_care_qrtr
     , sum(adj_pd_total       ) as adj_pd_total_qrtr                      
     , sum(n_Primary_care)      as n_Primary_care_qrtr
     , sum(n_ER)                as n_ER_qrtr
from util1622
group by MCAID_ID, dt_qrtr; 
quit; *Table int.UTIL_1621 created, with 32835706 rows and 8 columns. ;

PROC SORT DATA = int.util1622_qrtr NODUPKEY ; BY _ALL_ ; RUN ; * 16692009 : 8 ; 

* SPLIT INTO 1618 for cat and 19-21 for outcomes ; 
DATA util_1921 util_1618 (keep = mcaid_id FY dt_qrtr adj_pd_total_qrtr); 
SET  int.util1622_qrtr ; 
IF   FY in ('2019','2020','2021') THEN OUTPUT util_1921;
ELSE OUTPUT util_1618;
RUN; 
* NOTE: The data set WORK.UTIL_1921 has 8430032 observations and 8 variables.
  NOTE: The data set WORK.UTIL_1618 has 8261977 observations and 4 variables;

*----------------------------------------------------------------------------------------------
SECTION 01d.2 16-18 categorical variables 
----------------------------------------------------------------------------------------------;
* SUM the year total per member ; 
proc sql;
create table int.util_1618_FY as
select mcaid_id
     , FY
     , sum(adj_pd_total_qrtr) as adj_pd_total_FY
from util_1618
group by MCAID_ID, FY;
quit; *3252795 : 3 - reduced to approx 1/5th, should have 0 values still  ;

PROC TRANSPOSE DATA=int.util_1618_FY OUT=util_1618_FY_wide (DROP=_NAME_); 
     BY   mcaid_id ; 
     ID   FY ; 
     VAR  adj_pd_total_FY ; 
RUN ; * 2065238 : 4 ; 

****
03/22  SOMEWHERE I CREATED int.util_memlist_elig1618 but it's lost!! 
Computer disconnected and I think I lost the code :( 
total obs after doing sort nodupkey was 1594348 
Ran checks and it looked good ;

*** RECREATING HERE TO CHECK MY LIST UGH 3/30; 
DATA int.elig1618a; 
SET  ANA.QRY_LONGITUDINAL (KEEP= mcaid_ID month pcmp_loc_id);
FY   = year(intnx('year.7', month, 0, 'BEGINNING')); * create FY variable ; 
ind = 1 ; 
WHERE month ge '01JUL2016'd 
AND   month le '30JUN2019'd ; 
RUN ; 
* WORK.ELIG1618_MEMLIST0 has 50603704 obs and 4 variables.;

PROC SORT DATA = int.elig1618a nodupkey out=int.elig1618b (KEEP=mcaid_id FY ind); 
BY mcaid_id FY ; 
RUN ; 
* WORK.ELIG1618_MEMLIST1 has 5011888 observations and 3 variables; 

PROC TRANSPOSE DATA=int.elig1618b prefix=ind_elig OUT=int.elig1618c (DROP=_NAME_); 
     BY   mcaid_id ; 
     ID   FY ; 
     VAR  ind ; 
RUN ; * 2065238 : 4 ; 

* 4/24; 
DATA int.elig1618d (DROP=ind_elig2016
                         ind_elig2017
                         ind_elig2018); 
SET  int.elig1618c; 
ind_elig16 = coalesce(ind_elig2016,0);
ind_elig17 = coalesce(ind_elig2017,0);
ind_elig18 = coalesce(ind_elig2018,0);
RUN ; *2065238 ; 

* Combine eligibility indicator (from qry_longitudinal) and costs from utilization; 
PROC SQL; 
CREATE TABLE elig_and_util AS 
SELECT a.*
     , b.*
FROM int.elig1618d AS A
INNER JOIN int.util_1618_fy_wide as B
ON a.mcaid_id=b.mcaid_id 
; 
QUIT; * nobs 2066673 : matches the largest one and has all members from eligd; 

PROC SQL ; 
CREATE TABLE int.adj_pd_total_YY AS 
SELECT mcaid_id
     , case when (_2016 = . AND ind_elig16 = 0) then -1
            when (_2016 = . AND ind_elig16 = 1) then 0
            else _2016
            end as adj_pd_total_16_cost
     , case when (_2017 = . AND ind_elig17 = 0) then -1
            when (_2017 = . AND ind_elig17 = 1) then 0
            else _2017
            end as adj_pd_total_17_cost
     , case when (_2018 = . AND ind_elig18 = 0) then -1
            when (_2018 = . AND ind_elig18 = 1) then 0
            else _2018
            end as adj_pd_total_18_cost
     , ind_elig16
     , ind_elig17
     , ind_elig18
     , _2016
     , _2017
     , _2018
FROM elig_and_util; 
QUIT ; *2066673; 

PROC PRINT DATA = int.adj_pd_total_yy (obs=20); run; 


*----------------------------------------------------------------------------------------------
SECTION 01d.3 19-21 
1) Create quarter variable in util1921
2) Join quarter memlist attrib   
3) get n_months denominator from 
4) create PMPM avgs
----------------------------------------------------------------------------------------------;

* 1a Create quarter variable in 1921 util ds ; 
* macro in util_00_config ; 
%create_qrtr(data = util1921a,
             set  = util_1921,
             var  = dt_qrtr,
             qrtr = cat_qrtr
             ); 

* join quarter memlist attrib ; 
PROC SQL ; 
CREATE TABLE int.util1921_adj AS 
SELECT a.*
     , b.pcmp_loc_id
     , b.n_months_per_q
     , b.ind_isp
FROM util1921a as a
inner join int.memlist_attr_qrtr_1921 as b 
on a.mcaid_id=b.mcaid_id and a.cat_qrtr = b.time ; 
QUIT ; *04/24 7982472;

PROC SORT DATA = int.util1921_adj ; BY FY ; RUN ; 

** GET PERCENTILES FOR ALL & TOP CODE DV's ; 
* 1618; 
%macro pctl_1618(var,out,pctlpre);
proc univariate noprint data=int.adj_pd_total_yy; 
where &var gt 0; 
var &var; 
output out=&out pctlpre=&pctlpre pctlpts= 50, 75, 90, 95; 
run;
%mend; 

%pctl_1618(var     = adj_pd_total_16_cost,
           out     = pd16pctle,
           pctlpre = p16_); 

%pctl_1618(var     = adj_pd_total_17_cost,
           out     = pd17pctle,
           pctlpre = p17_); 

%pctl_1618(var     = adj_pd_total_18_cost,
           out     = pd18pctle,
           pctlpre = p18_); 

data int.pctile_vals; merge pd16pctle pd17pctle pd18pctle ; run;

PROC PRINT DATA = int.pctile_vals; RUN; 
/*Obs p16_50  p16_75   p16_90    p16_95      p17_50  p17_75  p17_90   p17_95        p18_50  p18_75  p18_90  p18_95 */
/*1   921.582 3034.06  10387.39  22590.99    966.845 3173.37 11080.45 25173.98      1011.10 3410.40 12288.92 28563.99 */

proc sql noprint;
  select 
    name, 
    cats(':',name)
  into 
    :COL_NAMES separated by ',', 
    :MVAR_NAMES separated by ','
  from sashelp.vcolumn 
  where 
    libname = "INT" 
    and memname = "PCTILE_VALS"
  ;
  select &COL_NAMES into &MVAR_NAMES
  from int.pctile_vals;
quit;

%put &col_names; 
%put &mvar_names; 


%macro insert_pctile(ds_in,ds_out,year);
DATA &ds_out; 
SET  &ds_in;

* For values 0, -1, retain original value; 
IF      adj_pd_total_&year._cost le 0 
                                                THEN adj_pd_total_&year.cat = adj_pd_total_&year._cost;
* Values > 0 but <= 50th p = category 1; 
ELSE IF adj_pd_total_&year._cost gt 0 
    AND adj_pd_total_&year._cost le &&p&year._50 THEN adj_pd_total_&year.cat=1;

* Values > 50thp but <= 75th p = category 2; 
ELSE IF adj_pd_total_&year._cost gt &&p&year._50 
    AND adj_pd_total_&year._cost le &&p&year._75 THEN adj_pd_total_&year.cat=2;

* Values > 75thp but <= 90th p = category 3; 
ELSE IF adj_pd_total_&year._cost gt &&p&year._75 
    AND adj_pd_total_&year._cost le &&p&year._90 THEN adj_pd_total_&year.cat=3;

* Values > 90thp but <= 95th p = category 4; 
ELSE IF adj_pd_total_&year._cost gt &&p&year._90 
    AND adj_pd_total_&year._cost le &&p&year._95 THEN adj_pd_total_&year.cat=4;

* Values > 95thp = category 5; 
ELSE IF adj_pd_total_&year._cost gt &&p&year._95 THEN adj_pd_total_&year.cat=5;

RUN; 
;
%mend;

* Made separate ds's for testing but merge if poss later; 
%insert_pctile(ds_in = int.adj_pd_total_yy, ds_out = adj_final0, year = 16);
%insert_pctile(ds_in = adj_final0,          ds_out = adj_final1, year = 17);
%insert_pctile(ds_in = adj_final1,          ds_out = adj_final2, year = 18);

PROC FREQ DATA = adj_final2; 
TABLES adj_pd_total_16cat adj_pd_total_17cat adj_pd_total_18cat; 
RUN; 

PROC PRINT DATA = adj_final (obs=100) ; where adj_pd_total_16cat = . ; RUN;

PROC UNIVARIATE DATA = int.adj_pd_total_yy;
VAR  _2016 _2017 _2018;
RUN; 

