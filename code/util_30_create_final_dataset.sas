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
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 


* ==== Combine datasets with memlist_final ==================================;  
proc sort data = int.memlist_final; by mcaid_id ; run ;  *1594686; 

** Get isp info  ; 
PROC SQL ; 
CREATE TABLE data.a1 as 
SELECT a.*
     , b.time_start_isp 
     , case when b.time_start_isp ne . AND a.time >= b.time_start_isp 
            then 1 
            else 0 end 
            as int_imp
FROM int.memlist_final as a
LEFT JOIN int.isp_un_pcmp_dtstart as b
ON   a.pcmp_loc_id = b.pcmp_loc_id ; 
QUIT ; * 40974871 : 14 ; 

* TESTS: - expecting time*int_imp to have all int_imp=0 for time 1,2
         - time_start_isp should only be 3>
         - ind_isp*int_imp should have values in both cols for 0 but where ind_isp = 0 all int_imp should be 0;         
PROC FREQ DATA = data.a1 ; 
TABLES time*int_imp time_start_isp*int_imp ind_isp*int_imp; 
RUN ;

*** JOIN PCMP TYPE ; 
*   Create numeric pcmp_loc_id ; 
DATA int.pcmp_types ; 
SET  int.pcmp_types ; 
LENGTH pcmp 8 ; 
pcmp = input(pcmp_loc_id, best12.); 
RUN ;

PROC SQL ; 
CREATE TABLE data.a2 AS 
SELECT a.*
     , b.pcmp_loc_type_cd
FROM data.a1 as a
LEFT JOIN int.pcmp_types as b
ON   a.pcmp_loc_id = b.pcmp ; 
QUIT ; *40974871; 

* tidy up ; 
DATA data.a2a ; 
SET  data.a2  (DROP = ENR_CNTY 
                      TIME_START_ISP ) ;
RENAME ind_isp=int ; 
RUN ; *40974871 : 13; 
                      
*** UPDATED 3/30 
new adj file with all (no missing yay) and changed lib to int;
proc sql; 
create table int.a3 as 
select a.*

     /* join monthly */
     , b.adj_pd_total_16cat
     , b.adj_pd_total_17cat
     , b.adj_pd_total_18cat

     /* join bh_cat  */
     , c.bh_er2016
     , c.bh_er2017
     , c.bh_er2018
     , c.bh_hosp2016
     , c.bh_hosp2017
     , c.bh_hosp2018
     , c.bh_oth2016
     , c.bh_oth2017
     , c.bh_oth2018

     /* join bh_1921  */
     , d.sum_q_bh_hosp
     , d.sum_q_bh_er
     , d.sum_q_bh_other

FROM int.a2a AS a

/*only needs to be joined on mcaid_id bc the cat's are wide not long */
LEFT JOIN int.adj_pd_total_YYcat AS b
ON a.mcaid_id = b.mcaid_id 

/*only needs to be joined on mcaid_id bc the cols are wide not long */
LEFT JOIN int.bh_1618 AS c
ON a.mcaid_id = c.mcaid_id 

/*needs to be joined on qrtr and mcaid_id */
LEFT JOIN int.bh_1921 AS d
ON a.mcaid_id = d.mcaid_id AND a.time = d.time;

QUIT;   * 40974871 : 28 ;

PROC SORT DATA = int.a3 NODUPKEY OUT=int.a3a ; BY _ALL_ ; RUN ;  *14347065 : 28 ; 
      
* replace bh_1618 cat var's where . with 0 ; 
DATA  int.a3b;
SET   int.a3a  (DROP = sum_q_bh_hosp); 
ARRAY bher bh_er2016-bh_er2018;
        do over bher;
        if bher=. then bher=0;
      end;
ARRAY bhhosp bh_hosp2016-bh_hosp2018;
        do over bhhosp;
        if bhhosp=. then bhhosp=0;
      end;
ARRAY bhoth bh_oth2016-bh_oth2018;
        do over bhoth;
        if bhoth=. then bhoth=0;
      end;
RUN ;  * 3/30 14347065 : 27 ; 

DATA  int.a3c;
SET   int.a3b;
format adj_pd_16a adj_pd_17a adj_pd_18a 3. ;
* make numeric; 
adj_pd_16a = input(adj_pd_total_16cat, 3.);
adj_pd_17a = input(adj_pd_total_17cat, 3.);
adj_pd_18a = input(adj_pd_total_18cat, 3.);
* make missing = -1 because they weren't eligible (checking with where int.a3b = '' like A001791); 
adj_pd_total16 = coalesce(adj_pd_16a,-1);
adj_pd_total17 = coalesce(adj_pd_17a,-1);
adj_pd_total18 = coalesce(adj_pd_18a,-1);
run;
 
DATA int.a3d (rename=(adj_pd_total16 = adj_pd_total_16cat
                      adj_pd_total17 = adj_pd_total_17cat
                      adj_pd_total18 = adj_pd_total_18cat)) ; 
SET  int.a3c (drop=adj_pd_16a adj_pd_17a adj_pd_18a adj_pd_total_16cat adj_pd_total_17cat adj_pd_total_18cat);
RUN; *14347065 : 27; 

Proc freq data = int.a3d; tables adj: ; run;

* Join util 1921 values for cost PMPM total, PMPM rx and util ED visits (to join with BH) 
* Join telehealth  ; 
PROC SQL ; 
CREATE TABLE int.a4 AS 
SELECT a.*
       /* util1921_adj cols: n_pc_q n_er_q pd_rx_q_adj pd_pc_q_adj on cat_qrtr (= time)      */
     , b.n_pc_q 
     , b.n_er_q 
     , b.pd_rx_q_adj as pd_rx_q_adj
     , b.pd_tot_q_adj as pd_tot_q_adj
     , b.pd_pc_q_adj 
     , sum(b.n_er_q, a.sum_q_bh_er) as n_er_total
    
       /* tele cols:      */
     , c.n_q_tele
FROM int.a3d as a

LEFT JOIN int.util1921_adj as b
    ON a.mcaid_id = b.mcaid_id
    AND a.time    = b.time

LEFT JOIN int.tele_1921 as c
    ON a.mcaid_id = c.mcaid_id
    AND a.time    = c.time ; 
QUIT ; 


DATA int.A5 ; 
SET  int.A4 (DROP = sum_q_bh_er n_er_q ) ;
mu_pd_rx    = pd_rx_q_adj    /n_months_per_q ; 
mu_pd_total = pd_tot_q_adj   /n_months_per_q ; 
mu_pd_pc    = pd_pc_q_adj    /n_months_per_q ; 
mu_n_pc     = n_pc_q         /n_months_per_q ; 
mu_n_tele   = n_q_tele       /n_months_per_q ; 
mu_n_er     = n_er_total     /n_months_per_q ; 
mu_n_bh_oth = sum_q_bh_other /n_months_per_q ; 
RUN ; 

* 3/27 do same for pc (top coded) ; 
DATA int.a6 (DROP = pd_rx_q_adj pd_tot_q_adj pd_pc_q_adj n_pc_q n_q_tele n_er_total sum_q_bh_other mu_pd_pc); 
SET  int.a5 ;
mu_rx     = coalesce(mu_pd_rx, 0);
mu_ffs    = coalesce(mu_pd_total,0);
mu_pc   = coalesce(mu_pd_pc   ,0);
util_pc   = coalesce(mu_n_pc    ,0);
util_tele = coalesce(mu_n_tele  ,0);
util_er   = coalesce(mu_n_er    ,0);
util_bh_o = coalesce(mu_n_bh_oth,0);
run ; * 14347065 ; 

*** TOP CODE cost vars ; 
PROC SORT DATA = int.a6 ; BY FY ; RUN ; 

PROC RANK DATA = int.a6
     GROUPS    = 100 
     OUT       = int.a6a ;
     VAR       mu_rx mu_ffs mu_pc; 
     BY        FY ; 
     RANKS     mu_rx_pctile mu_ffs_pctile mu_pc_pctile;
RUN ; 

* Get mean for FY percentiles > 95 ; 
PROC MEANS DATA = int.a6a ; 
VAR   mu_pd_rx ; 
BY    FY ; 
WHERE mu_rx_pctile > 95 ; 
OUTPUT OUT = int.mu_rx_topcode (DROP=_TYPE_ _FREQ_); 
RUN ; 

PROC MEANS DATA = int.a6a ; 
VAR   mu_ffs ; 
BY    FY ; 
WHERE mu_ffs_pctile > 95 ; 
OUTPUT OUT = int.mu_ffs_topcode (DROP=_TYPE_ _FREQ_); 
RUN ; 

PROC MEANS DATA = int.a6a ; 
VAR   mu_pc ; 
BY    FY ; 
WHERE mu_pc_pctile > 95 ; 
OUTPUT OUT = int.mu_pc_topcode (DROP=_TYPE_ _FREQ_); 
RUN ; 

PROC PRINT DATA = int.mu_rx_topcode ; 
PROC PRINT DATA = int.mu_ffs_topcode;  
PROC PRINT DATA = int.mu_pc_topcode ; RUN ; 


%LET ffsmin19 = 2092.41; %LET ffsmu19  = 6565.38; 
%LET ffsmin20 = 2068.44; %LET ffsmu20  = 6620.08; 
%LET ffsmin21 = 2119.57; %LET ffsmu21  = 6877.58; 

%LET rxmin19 = 305.24; %LET rxmu19  = 1686.94; 
%LET rxmin20 = 317.11; %LET rxmu20  = 1759.34; 
%LET rxmin21 = 333.34; %LET rxmu21  = 1873.25; 

%LET pcmin19 = 191.60; %LET pcmu19  = 320.68; 
%LET pcmin20 = 189.62; %LET pcmu20  = 328.85; 
%LET pcmin21 = 193.03; %LET pcmu21  = 332.67; 


DATA int.a7  (rename = (mu_ffs= cost_ffs_tc 
                         mu_rx = cost_rx_tc
                         mu_pc = cost_pc_tc)); 
SET  int.a6a (DROP= mu_pd_rx mu_pd_total mu_n_pc mu_n_tele mu_n_er mu_n_bh_oth) ; 

* ffs total : Replace 96th percentile & up with mean ; 
IF mu_ffs >= &ffsmin19 & FY = 2019 then mu_ffs = &ffsmu19 ; 
IF mu_ffs >= &ffsmin20 & FY = 2020 then mu_ffs = &ffsmu20 ; 
IF mu_ffs >= &ffsmin21 & FY = 2021 then mu_ffs = &ffsmu21 ; 

* ffs rx   : Replace 96th percentile & up with mean ; 
IF mu_rx >= &rxmin19 & FY = 2019 then mu_rx = &rxmu19 ; 
IF mu_rx >= &rxmin20 & FY = 2020 then mu_rx = &rxmu20 ; 
IF mu_rx >= &rxmin21 & FY = 2021 then mu_rx = &rxmu21 ; 

* ffs pc  : Replace 96th percentile & up with mean ; 
IF mu_pc >= &pcmin19 & FY = 2019 then mu_pc = &pcmu19 ; 
IF mu_pc >= &pcmin20 & FY = 2020 then mu_pc = &pcmu20 ; 
IF mu_pc >= &pcmin21 & FY = 2021 then mu_pc = &pcmu21 ; 

RUN ; 


DATA int.a8 (DROP = pcmp_loc_type_cd FY); 
SET  int.a7 (DROP = n_months_per_q mu_rx_pctile mu_ffs_pctile mu_pc_pctile) ; 

FORMAT race race_rc_. ; 

ind_cost_rx   = cost_rx_tc  > 0 ;
ind_cost_ffs  = cost_ffs_tc > 0 ;
ind_cost_pc   = cost_pc_tc  > 0 ;
ind_util_pc   = util_pc     > 0 ;
ind_util_er   = util_er     > 0 ;
ind_util_bh_o = util_bh_o   > 0 ; 
ind_util_tel  = util_tele   > 0 ;

IF SEX =: 'U' then delete ; 

IF pcmp_loc_type_cd in (32 45 61 62) then fqhc = 1 ; else fqhc = 0 ;

LABEL age          = "Age (cat)"
      sex          = "Sex (M, F)"
      race         = "Race"
      rae_person_new = "RAE ID" 
      budget_grp_new = "Budget Group"
      pcmp_loc_id  = "PCMP attr qrtr logic"
      time         = "Quarters 1-12 (FY19-21)"
      int_imp      = "ISP: Time-Varying"
      int          = "ISP: Time-Invariant"
      util_er      = "Visits: ER (q avg)"
      util_pc      = "Visits: PC (q avg)"
      util_tele    = "Visits: Tele (q avg)"
      util_bh_o    = "Visits: BH Other (q avg)"
      cost_rx_tc   = "Cost FFS Rx: top-coded infl-adj qrtr avg"
      cost_ffs_tc  = "Cost FFS total: top-coded infl-adj qrtr avg"
      cost_pc_tc   = "Cost FFS Primary Care: top-coded infl-adj qrtr avg"
      bh_er2016    = "BH 2016, ER (0,1)"
      bh_er2017    = "BH 2017, ER (0,1)"
      bh_er2018    = "BH 2018, ER (0,1)"
      bh_oth2016   = "BH 2016, Other (0,1)"
      bh_oth2017   = "BH 2017, Other (0,1)"
      bh_oth2018   = "BH 2017, Other (0,1)"
      bh_hosp2016  = "BH 2016, Hosp (0,1)"
      bh_hosp2017  = "BH 2017, Hosp (0,1)"
      bh_hosp2018  = "BH 2018, Hosp (0,1)"
      adj_pd_total_16cat = "Adj FFS total, 2016: Categorical"
      adj_pd_total_17cat = "Adj FFS total, 2017: Categorical"
      adj_pd_total_18cat = "Adj FFS total, 2018: Categorical"
      ;
RUN; * lost 88 people - all sex unknown? 
* from 14347065 to 14346977;

* Updated 3/29 per new spec file: 
    - include new categories for FQHC (binary 0,1), race
    - make sure age = age_cat_. format
    - remove sex observations where sex = unknown; 

DATA data.analysis_dataset (drop=pcmp_loc_type_cd FY) ; 
SET  int.a8 ;  
ind_cost_rx   = cost_rx_tc  > 0 ;
ind_cost_ffs  = cost_ffs_tc > 0 ;
ind_cost_pc   = cost_pc_tc  > 0 ;
ind_util_pc   = util_pc     > 0 ;
ind_util_er   = util_er     > 0 ;
ind_util_bh_o = util_bh_o   > 0 ; 
ind_util_tel  = util_tele   > 0 ;
IF SEX =: 'U' then delete ; 
IF pcmp_loc_type_cd in (32 45 61 62) then fqhc = 1 ;
    else fqhc = 0 ;
RUN ;
*NOTE: There were 14347065 observations read from the data set DATA.A8.
NOTE: The data set DATA.ANALYSIS_DATASET has 14346977 observations and 39 variables;


PROC PRINTTO; 
RUN ; 
