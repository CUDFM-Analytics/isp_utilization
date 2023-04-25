**********************************************************************************************
 PROGRAMMER       : K Wiggins
 DATE INIT        : 02/2023
 PROJECT          : ISP Util
 PURPOSE          : 
 INPUT FILE/S     : 
 OUTPUT FILE/S    : SECTION01 > 
 SPECS            : ISP_Utilization_Analytic_Plan_20221118.docx, 
 VERSION          : 04/24/2023 re-ran all - updated time2 variable from int.isp_un_pcmp_dtstart and 
                                            updated adj variables from int.adj_pd_total_yycat;
***********************************************************************************************;
* PROJECT PATHS, MAPPING; 
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 


* ==== Combine datasets with memlist_final ==================================;  
proc sort data = int.memlist_final; by mcaid_id ; run ;  *1594686; 

** Get isp info  ; 
PROC SQL ; 
CREATE TABLE int.a1 as 
SELECT a.*
     , b.time2 as time_start_isp
     , case when b.time2 ne . AND a.time >= b.time2
            then 1 
            else 0 end 
            as int_imp
FROM int.memlist_final as a
LEFT JOIN int.isp_un_pcmp_dtstart as b
ON   a.pcmp_loc_id = b.pcmp_loc_id ; 
QUIT ; * 40974871 : 14 ; 

* TESTS: - expecting time*int_imp to have all int_imp=0 for time 1,2
         - time_start_isp should only be 3> UPDATE 4>
         - ind_isp*int_imp should have values in both cols for 0 but where ind_isp = 0 all int_imp should be 0;         
PROC CONTENTS DATA = int.a1; RUN; 

PROC FREQ DATA = int.a1 ; 
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
CREATE TABLE int.a2 AS 
SELECT a.*
     , b.pcmp_loc_type_cd
FROM int.a1 as a
LEFT JOIN int.pcmp_types as b
ON   a.pcmp_loc_id = b.pcmp ; 
QUIT ; *40974871; 

* tidy up ; 
DATA int.a2a ; 
SET  int.a2  (DROP = ENR_CNTY 
                      TIME_START_ISP ) ;
RENAME ind_isp=int ; 
RUN ; *40974871 : 13; 
                      
*** 
UPDATED 4/24: adj file with actually correct values
UPDATED 3/30: new adj file with all (no missing yay) and changed lib to int;
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

* Some adj's are blank - weren't eligible / not in file? ; 
PROC PRINT DATA = int.a3b (obs=100) ; where adj_pd_total_16cat = ''; RUN; 

* int.a3c
ADJ `-1` values below: adj dataset created in util_02_get_prep_ana_util from a full join using all
qry_monthlyutilization and qry_longitudinal values from FYs 16-18
ID's not present in int.a3b were not eligible and can be marked with -1 as they were not present in either ana dataset; 
DATA  int.a3c;
SET   int.a3b;
format adj_pd_16a adj_pd_17a adj_pd_18a 3. ;
* make numeric; 
adj_pd_16a = input(adj_pd_total_16cat, 3.);
adj_pd_17a = input(adj_pd_total_17cat, 3.);
adj_pd_18a = input(adj_pd_total_18cat, 3.);
* make missing = -1 because they weren't eligible (checking with where int.a3b = '' like A001791 etc in zscratch); 
adj_pd_total16 = coalesce(adj_pd_16a,-1);
adj_pd_total17 = coalesce(adj_pd_17a,-1);
adj_pd_total18 = coalesce(adj_pd_18a,-1);
run;

PROC PRINT DATA = int.a3c (obs=25); where adj_pd_16a = .; RUN; *(looking to make sure adj_pd_total16 = -1);

*int.a3d
    -can drop values from a3c and rename the complete ones now; 
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
mu_pc     = coalesce(mu_pd_pc   ,0);
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

%macro mu_ge95(var, where_var, output);
PROC MEANS DATA = int.a6a;
VAR &var; 
BY  FY; 
WHERE &where_var > 95; 
OUTPUT OUT = &output (DROP=_TYPE_ _FREQ_); 
RUN; 
%mend; 

%mu_ge95(mu_pd_rx, mu_rx_pctile,  int.mu_rx_topcode ); 
%mu_ge95(mu_ffs,   mu_ffs_pctile, int.mu_ffs_topcode); 
%mu_ge95(mu_pc,    mu_pc_pctile, int.mu_pc_topcode); 

title; 

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

RUN ; * 14347065 : 35; 


DATA data.analysis_dataset (DROP = pcmp_loc_type_cd FY); 
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

LABEL age            = "Age (cat)"
      sex            = "Sex (M, F)"
      race           = "Race"
      rae_person_new = "RAE ID" 
      budget_grp_new = "Budget Group"
      pcmp_loc_id    = "PCMP attr qrtr logic"
      time           = "Quarters 1-12 (FY19-21)"
      int_imp        = "ISP: Time-Varying"
      int            = "ISP: Time-Invariant"
      util_er        = "Visits: ER, FFS+Capd (qrtr, mu)"
      util_pc        = "Visits: Primary Care (qrtr, mu)"
      util_tele      = "Visits: Telehealth (qrtr, mu)"
      util_bh_o      = "Visits: BH Other (qrtr, mu)"
      cost_rx_tc     = "Cost FFS Rx: top-coded infl-adj qrtr avg"
      cost_ffs_tc    = "Cost FFS total: top-coded infl-adj qrtr avg"
      cost_pc_tc     = "Cost FFS Primary Care: top-coded infl-adj qrtr avg"
      bh_er2016      = "Indicator: BH ER 2016 n>0"
      bh_er2017      = "Indicator: BH ER 2017 n>0"
      bh_er2018      = "Indicator: BH ER 2018 n>0"
      bh_oth2016     = "Indicator: BH Other 2016 n>0"
      bh_oth2017     = "Indicator: BH Other 2017 n>0"
      bh_oth2018     = "Indicator: BH Other 2018 n>0"
      bh_hosp2016    = "Indicator: BH Hosp 2016 n>0"
      bh_hosp2017    = "Indicator: BH Hosp 2017 n>0"
      bh_hosp2018    = "Indicator: BH Hosp 2018 n>0"
      adj_pd_total_16cat = "Adj FFS total, 2016 Categorical"
      adj_pd_total_17cat = "Adj FFS total, 2017: Categorical"
      adj_pd_total_18cat = "Adj FFS total, 2018: Categorical"
      fqhc = "FQHC (FQHC|IHS|RHS), Binary"
      ind_cost_ffs = "Indicator, Cost: FFS Total > 0"
      ind_cost_pc = "Indicator, Cost: Primary Care > 0"
      ind_cost_rx = "Indicator, Cost: Rx > 0"
      ind_util_bh_o = "Indicator, Util: BH Other n > 0"
      ind_util_er   = "Indicator, Util: ER (Cap+FFS) n > 0"
      ind_util_pc = "Indicator, Util: PC n > 0"
      ind_util_tel = "Indicator, Util: Telehealth n > 0"
      ;
RUN; * 3/30 lost 88 people - all sex unknown? 
* from 14347065 to 14346977 (same as before tho from earlier in the week);
