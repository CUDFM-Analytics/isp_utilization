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
libname ana clear ; 
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
create table int.util_1618_long as
select mcaid_id
     , FY
     , sum(adj_pd_total_qrtr) as adj_pd_total_FY
from util_1618
group by MCAID_ID, FY;
quit; *3252795 : 3 - reduced to approx 1/5th ;

PROC SORT DATA = int.util_1618_long; by FY; RUN; 

*https://support.sas.com/kb/22/759.html shows to use rank and groups=100; 
PROC RANK DATA = int.util_1618_long
     GROUPS    = 100 
     OUT       = util1618r;
     VAR       adj_pd_total_FY ; 
     BY        FY ; 
     RANKS     adj_pd_FY_rank ;
RUN ; 

PROC SORT DATA = util1618r ; by mcaid_id ; RUN ;  

PROC TRANSPOSE DATA = util1618r 
     OUT = util1618r2 (DROP= _NAME_ _LABEL_);
by mcaid_id ;
ID FY ; 
VAR adj_pd_FY_rank; 
RUN;  * 1552079 : 4 ; 
     
* Make cats but keep the original vals to check ; 
DATA int.util_1618_cat  ; 
SET  util1618r2     ; 
adj_pd_total_16cat_A = put(_2016, adj_pd_total_YRcat_.);
adj_pd_total_17cat_A = put(_2017, adj_pd_total_YRcat_.);
adj_pd_total_18cat_A = put(_2018, adj_pd_total_YRcat_.);
RUN ; *1552079: 7 ; 

PROC MEANS DATA = int.util_1618_cat MEAN MIN MAX; 
CLASS  adj_pd_total_16cat_A ;
VAR _2016;
RUN; 

PROC MEANS DATA = int.util_1618_cat MEAN MIN MAX; 
CLASS  adj_pd_total_17cat_A ;
VAR _2017;
RUN; 

PROC MEANS DATA = int.util_1618_cat MEAN MIN MAX; 
CLASS  adj_pd_total_18cat_A ;
VAR _2018;
RUN; 


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

/*proc delete data=int.elig1618_memlist1; */
/*RUN ; */

PROC SQL ; 
CREATE TABLE adj_cat AS 
SELECT COALESCE (a.mcaid_id, b.mcaid_id) as mcaid_id
     , a.*
     , b.*
FROM int.elig1618c as a
FULL JOIN int.util_1618_cat as b
on a.mcaid_id = b.mcaid_id ; 
QUIT ; * 2066673 ; 

PROC FREQ DATA = adj_cat; 
tables adj: ; 
RUN; 

DATA adj_cat2; 
SET  adj_cat ; 
ind_elig16 = coalesce(ind_elig2016,0);
ind_elig17 = coalesce(ind_elig2017,0);
ind_elig18 = coalesce(ind_elig2018,0);
RUN ; *2066673 ; 

PROC FREQ DATA = adj_cat2; 
tables adj: ; 
RUN; 

PROC PRINT DATA = adj_cat2 (obs =30);
run; 

PROC SQL ; 
CREATE TABLE int.adj_pd_total_YYcat AS 
SELECT mcaid_id
     , case when (_2016 = . AND ind_elig16 = 0) then '-1'
            when (_2016 = . AND ind_elig16 = 1) then '0'
            else adj_pd_total_16cat_A
            end as adj_pd_total_16cat
     , case when (_2017 = . AND ind_elig17 = 0) then '-1'
            when (_2017 = . AND ind_elig17 = 1) then '0'
            else adj_pd_total_17cat_A
            end as adj_pd_total_17cat
     , case when (_2018 = . AND ind_elig18 = 0) then '-1'
            when (_2018 = . AND ind_elig18 = 1) then '0'
            else adj_pd_total_18cat_A
            end as adj_pd_total_18cat
     , adj_pd_total_16cat_A
     , adj_pd_total_17cat_A
     , adj_pd_total_18cat_A
     , ind_elig16
     , ind_elig17
     , ind_elig18
     , _2016
     , _2017
     , _2018
FROM adj_cat2 ; 
QUIT ; *2066673; 

PROC FREQ DATA = int.adj_pd_total_YYcat; 
tables adj: ;
RUN ; 



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

/** join quarter memlist attrib ; */
/*PROC SQL ; */
/*CREATE TABLE int.util1921_adj AS */
/*SELECT a.**/
/*     , b.pcmp_loc_id*/
/*     , b.n_months_per_q*/
/*     , b.ind_isp*/
/*FROM util1921a as a*/
/*left join int.memlist_attr_qrtr_1921 as b */
/*on a.mcaid_id=b.mcaid_id and a.cat_qrtr = b.time ; */
/*QUIT ; *04/24 8430032, 12*/
/*7681680 rows and 13 columns;*/

PROC SORT DATA = int.util1921_adj ; BY FY ; RUN ; 
