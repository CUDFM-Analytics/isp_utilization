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
*----------------------------------------------------------------------------------------------
SECTION Get Monthly Utilization Data
----------------------------------------------------------------------------------------------;
DATA    util_0; 
SET     ana.qry_monthlyutilization (WHERE=(month ge '01Jul2016'd AND month le '30Jun2022'd));
FORMAT  dt_qrtr date9.;
dt_qrtr =intnx('QTR', month, 0, 'BEGINNING'); 
FY      =year(intnx('year.7', month, 0, 'BEGINNING'));
run;

PROC SQL;
CREATE TABLE util_1 as
SELECT a.*
     , (a.pd_amt/b.index_2021_1) AS adj_pd_amount  /*divBY has no missing values*/
FROM   util_0       AS A
LEFT JOIN int.adj   AS b    ON a.dt_qrtr=b.date;
quit; *66382081 : 7 cols; 

PROC SQL;
CREATE TABLE util_2 AS
SELECT MCAID_ID
      , FY
      , month
      , sum(case when clmClass=1     then count else 0 end) as n_hosp
      , sum(case when clmClass=4     then count else 0 end) as n_pc
      , sum(case when clmClass=3     then count else 0 end) as n_er
      , sum(case when clmClass=2     then count else 0 end) as n_rx
      , sum(case when clmClass=5     then count else 0 end) as n_ffs_bh
      , sum(case when clmClass=6     then count else 0 end) as n_ancillary
      , sum(case when clmClass=7     then count else 0 end) as n_hh_therapy
      , sum(case when clmClass=8     then count else 0 end) as n_dx
      , sum(case when clmClass=9     then count else 0 end) as n_transport
      , sum(case when clmClass=10    then count else 0 end) as n_eeserv
      , sum(case when clmClass=10000 then count else 0 end) as n_other
        
      , sum(adj_pd_amount) as adj_pd_total
      , sum(case when clmClass=1     then adj_pd_amount else 0 end) as adj_pd_hosp
      , sum(case when clmClass=4     then adj_pd_amount else 0 end) as adj_pd_pc
      , sum(case when clmClass=3     then adj_pd_amount else 0 end) as adj_pd_er
      , sum(case when clmClass=2     then adj_pd_amount else 0 end) as adj_pd_rx
      , sum(case when clmClass=5     then adj_pd_amount else 0 end) as adj_pd_ffs_bh
      , sum(case when clmClass=6     then adj_pd_amount else 0 end) as adj_pd_ancillary
      , sum(case when clmClass=7     then adj_pd_amount else 0 end) as adj_pd_hh_therapy
      , sum(case when clmClass=8     then adj_pd_amount else 0 end) as adj_pd_dx
      , sum(case when clmClass=9     then adj_pd_amount else 0 end) as adj_pd_transport
      , sum(case when clmClass=10    then adj_pd_amount else 0 end) as adj_pd_eeserv
      , sum(case when clmClass=10000 then adj_pd_amount else 0 end) as adj_pd_other
FROM  util_1
GROUP BY MCAID_ID,month;
quit; *32835706, 25; 

%nodupkey(ds=util_2, out=util_3); *32835706, 26; 

PROC CONTENTS DATA = util_3 VARNUM; RUN; 

*----------------------------------------------------------------------------------------------
SECTION 02 GET BH monthly utilization 
----------------------------------------------------------------------------------------------;
DATA bh0;
SET  ana.qry_bho_monthlyutilization; 

format dt_qrtr month2 date9.; * create quarter beginning date to get quarters ; 
dt_qrtr = intnx('quarter', month ,0,'b');

month2 = month;
DROP   month;
RENAME month2 = month; 

WHERE  month ge '01Jul2016'd
AND    month le '01Jul2022'd;

FY     =year(intnx('year.7', month, 0, 'BEGINNING'));
run; *4208734 observations and 7 variables;

%create_qrtr(data=bh1, set=bh0, var = dt_qrtr, qrtr=time);

* JOIN BH and util on memlist final where FY 2016-18; 
PROC SQL; 
CREATE TABLE util_all_memlist AS 
SELECT a.*
     , b.*
     , c.month
     , c.n_hosp
     , c.n_pc
     , c.n_er
     , c.n_rx
     , c.adj_pd_total
     , c.adj_pd_hosp
     , c.adj_pd_pc
     , c.adj_pd_er
     , c.adj_pd_rx
     , c.adj_pd_ffs_bh
     , d.n_q_tele
FROM int.memlist_final AS A
LEFT JOIN util_3 AS B ON a.mcaid_id=b.mcaid_id AND a.FY=b.FY
LEFT JOIN bh1    AS C ON a.mcaid_id=c.mcaid_id AND a.FY=c.FY;
QUIT; 


data int.util_1618_0; 
set  int.util_1622_1 
     (KEEP = mcaid_id FY month adj_pd_total adj_pd_pharmacy pdj_pd_primary_care bho_n_hosp bho_n_er bho_n_other); 
where month lt '01Jul2019'd; run;
proc sql;
 create table firstyears2 as
 select
 clnt_id,
 max(case when FY=2016 then 1 else 0 end) as health_1st_CO16t, 
 max(case when FY=2017 then 1 else 0 end) as health_1st_CO17t,
 max(case when FY=2018 then 1 else 0 end) as health_1st_CO18t,

 avg(case when fy6=2016 then adj_pd_total else 0 end) as adj_pd_total_16pm, 
 avg(case when fy6=2017 then adj_pd_total else 0 end) as adj_pd_total_17pm, 
 avg(case when fy6=2018 then adj_pd_total else 0 end) as adj_pd_total_18pm,

 avg(case when fy6=2016 then bho_n_hosp else 0 end) as bho_n_hosp_16pm, 
 avg(case when fy6=2017 then bho_n_hosp else 0 end) as bho_n_hosp_17pm, 
 avg(case when fy6=2018 then bho_n_hosp else 0 end) as bho_n_hosp_18pm,
 avg(case when fy6=2016 then bho_n_er else 0 end) as bho_n_er_16pm, 
 avg(case when fy6=2017 then bho_n_er else 0 end) as bho_n_er_17pm, 
 avg(case when fy6=2018 then bho_n_er else 0 end) as bho_n_er_18pm,
 avg(case when fy6=2016 then bho_n_other else 0 end) as bho_n_other_16pm, 
 avg(case when fy6=2017 then bho_n_other else 0 end) as bho_n_other_17pm, 
 avg(case when fy6=2018 then bho_n_other else 0 end) as bho_n_other_18pm
 from firstyears1
 group by clnt_id;
quit; 


PROC PRINT DATA = int.util_1622_1;
WHERE mcaid_id IN ("A003219")
;
RUN; 

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



PROC PRINT DATA = ana.qry_longitudinal;
WHERE mcaid_id IN ("A003219")
AND   month ge "01JUL2016"d
AND   month le "30JUN2017"d;
RUN; 
