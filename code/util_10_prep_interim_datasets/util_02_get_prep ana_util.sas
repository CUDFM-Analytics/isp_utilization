**********************************************************************************************
AUTHOR   : KTW
PROJECT  : ISP Utilization Analysis
PURPOSE  : Gather, Process datasets from analytic subset dir
VERSION  : 2023-03-16 [date last updated]
DEPENDS  : ana subset folder, config file [dependencies]
    Need 16-18 for adj_pd_total_YRcat (16,17,18) and 19-21 for outcome vars
    Inputs      ana.qry_monthly_utilization     [111,221,842 : 7] 2023-02-09
    Outputs     data.util_month_fy6             [ 66,367,624 : 7] 2023-03-08

%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 
***********************************************************************************************;

*----------------------------------------------------------------------------------------------
SECTION 01d.1 Get Monthly Utilization Data 16-21 for memlist
----------------------------------------------------------------------------------------------;
PROC SQL ; 
CREATE TABLE util AS 
SELECT * 
FROM   ana.qry_monthlyutilization 
WHERE  month ge '01Jul2016'd 
AND    month le '30Jun2022'd
AND    mcaid_id IN  (SELECT mcaid_id FROM int.memlist);  
QUIT; * 663676624;

* COST: rx, pc, total
* UTIL: PC, ED (no total) > summed months in case there was > 1 month? ; 
proc sql;
create table int.util_1621 as
select mcaid_id
     , month
     , sum(case when clmClass = 2 then pd_amt else 0 end) as pd_ffs_rx
     , sum(case when clmClass = 4 then pd_amt else 0 end) as pd_ffs_pc
     , sum(pd_amt)                                        as pd_ffs_total
     , sum(case when clmClass = 4 then count  else 0 end) as n_ffs_pc
     , sum(case when clmClass = 3 then count  else 0 end) as n_ffs_er
from util
group by MCAID_ID, month ; 
quit; *Table int.UTIL_1621 created, with 27092342 rows and 7 columns. ;

* Create FY variable, get beginning of quarter from month variables to match to adj ; 
DATA util1621a     ; 
SET  int.util_1621 ; 
FY   = year(intnx('year.7', month, 0, 'BEGINNING')); * create FY variable ; 
format dt_qrtr date9.; * create quarter beginning date to get quarters ; 
dt_qrtr = intnx('quarter', month ,0,'b');
RUN; *27092342 rows and 7 columns. ;

* Sum by quarters ; 
proc sql;
create table util1621b as
select mcaid_id
     , FY
     , dt_qrtr
     , sum(pd_ffs_rx) as pd_rx_q
     , sum(pd_ffs_pc) as pd_pc_q
     , sum(pd_ffs_total) as pd_tot_q                           
     , sum(n_ffs_pc) as n_pc_q
     , sum(n_ffs_er) as n_er_q
from util1621a
group by MCAID_ID, dt_qrtr; 
quit; *Table int.UTIL_1621 created, with 27092342 rows and 7 columns. ;

PROC SORT DATA = util1621b NODUPKEY ; BY _ALL_ ; RUN ; * 13941142 ; 

* Join price adj index ; 
PROC SQL ; 
CREATE TABLE util1621_adj AS
SELECT a.*
     , b.index_2021_1
FROM util1621b as a 
LEFT JOIN int.adj as b 
ON a.dt_qrtr = b.date ; 
QUIT ; *13941142 ; 

* calculate adjusted costs; 
DATA int.util1621_adj (DROP=pd_rx_q pd_pc_q pd_tot_q index_2021_1); 
SET  util1621_adj ;
pd_rx_q_adj = index_2021_1 * pd_rx_q;
pd_pc_q_adj = index_2021_1 * pd_pc_q;
pd_tot_q_adj = index_2021_1 * pd_tot_q;
RUN; *13941142 ; 

* SPLIT INTO 1618 for cat and 19-21 for outcomes ; 
DATA util_1921 util_1618 (keep = mcaid_id FY dt_qrtr pd_tot_q_adj ); 
SET  int.util1621_adj ; 
IF   FY in ('2019','2020','2021') THEN OUTPUT util_1921;
ELSE OUTPUT util_1618;
RUN; 
* NOTE: The data set WORK.UTIL_1921 has 7681680 observations and 8 variables.
  NOTE: The data set WORK.UTIL_1618 has 6259462 observations and 4 variables;

*----------------------------------------------------------------------------------------------
SECTION 01d.2 16-18 categorical variables 
----------------------------------------------------------------------------------------------;
* SUM the year total per member ; 
proc sql;
create table int.util_1618_long as
select mcaid_id
     , FY
     , sum(pd_tot_q_adj) as pd_tot_fy_adj
from util_1618
group by MCAID_ID, FY;
quit; *2396891 : 3 - reduced to approx 1/5th ;

PROC RANK DATA = int.util_1618_long
     GROUPS    = 100 
     OUT       = util1618r;
     VAR       pd_tot_fy_adj ; 
     BY        FY ; 
     RANKS     adj_pd_rank ;
RUN ; 

PROC SORT DATA = util1618r ; by mcaid_id ; RUN ;  
PROC TRANSPOSE DATA = util1618r 
     OUT = util1618r2 (DROP= _NAME_ _LABEL_);
by mcaid_id ;
ID FY ; 
VAR adj_pd_rank; 
RUN;  * 105841 : 4 ; 
     
* Make cats but keep the original vals to check ; 
DATA int.util_1618_cat  ; 
SET  util1618r2     ; 
adj_pd_total_16cat_A = put(_2016, adj_pd_total_YRcat_.);
adj_pd_total_17cat_A = put(_2017, adj_pd_total_YRcat_.);
adj_pd_total_18cat_A = put(_2018, adj_pd_total_YRcat_.);
RUN ; *1051841 ; 

****
03/22  SOMEWHERE I CREATED int.util_memlist_elig1618 but it's lost!! 
Computer disconnected and I think I lost the code :( 
total obs after doing sort nodupkey was 1594348 
Ran checks and it looked good ;

*** RECREATING HERE TO CHECK MY LIST UGH 3/30; 
DATA elig1618_memlist0 ; 
SET  ANA.QRY_LONGITUDINAL (KEEP= mcaid_ID month pcmp_loc_id);
FY   = year(intnx('year.7', month, 0, 'BEGINNING')); * create FY variable ; 
WHERE pcmp_loc_ID ne ' ' 
AND   month ge '01JUL2016'd 
AND   month le '30JUN2019'd ; 
RUN ; 
* WORK.ELIG1618_MEMLIST0 has 30167936 observations and 4 variables.;

PROC SORT DATA = elig1618_memlist0 nodupkey out=elig1618_memlist1 (KEEP=mcaid_id FY pcmp_loc_id); 
BY mcaid_id FY ; 
RUN ; 
* WORK.ELIG1618_MEMLIST1 has  3169382 observations and 3 variables; 

PROC SQL ; 
CREATE TABLE elig1618_memlist2 AS 
SELECT mcaid_id
     , FY
FROM elig1618_memlist1 
WHERE mcaid_id IN (SELECT mcaid_id FROM int.memlist_attr_qrtr_1921) ;
QUIT; * 2534025 : 3 ;

PROC SORT DATA = elig1618_memlist2 ; BY FY ; RUN ; 

PROC TRANSPOSE 
DATA = elig1618_memlist2 
OUT  = elig1618_memlist ; 
BY   FY ; 
ID   mcaid_id ; 
VAR  FY ; 
RUN ; 

**** ; 

PROC SQL ; 
CREATE TABLE adj_cat AS 
SELECT COALESCE (a.mcaid_id, b.mcaid_id) as mcaid_id
     , a.*
     , b.*
FROM elig1618_memlist  as a
FULL JOIN int.util_1618_cat as b
on a.mcaid_id = b.mcaid_id ; 
QUIT ; *2564034 ; 

/*PROC SQL ; */
/*CREATE TABLE adj_cat AS */
/*SELECT COALESCE (a.mcaid_id, b.mcaid_id) as mcaid_id*/
/*     , a.**/
/*     , b.**/
/*FROM int.util_memlist_elig1618  as a*/
/*FULL JOIN util_1618_cat as b*/
/*on a.mcaid_id = b.mcaid_id ; */
/*QUIT ; *1594348 ; */

PROC SQL ; 
CREATE TABLE int.adj_pd_total_YYcat_final_v2 AS 
SELECT mcaid_id
     , case when ind_elig16 = 0 then '-1'
            when (ind_elig16 = 1 AND _2016 = .) then '0'
            else adj_pd_total_16cat_A
            end as adj_pd_total_16cat
     , case when ind_elig17 = 0 then '-1'
            when (ind_elig17 = 1 and _2017 = .) then '0'
            else adj_pd_total_17cat_A
            end as adj_pd_total_17cat
     , case when ind_elig18 = 0 then '-1'
            when (ind_elig18 = 1 AND _2018 = .) then '0'
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
FROM adj_cat ; 
QUIT ; 

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
     , b.n_pcmp_per_q
     , b.ind_isp
     , b.ind_nonisp
FROM util1921a as a
left join int.memlist_attr_qrtr_1921 as b 
on a.mcaid_id=b.mcaid_id and a.cat_qrtr = b.q ; 
QUIT ; *7681680 rows and 13 columns;

PROC SORT DATA = int.util1921_adj ; BY FY ; RUN ; 
