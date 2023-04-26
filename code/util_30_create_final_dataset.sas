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

*** JOIN PCMP TYPE (4/14 ran - don't need to run again, but it's here in case); 
*   Create numeric pcmp_loc_id ; 
/*DATA int.pcmp_types ; */
/*SET  int.pcmp_types ; */
/*LENGTH pcmp 8 ; */
/*pcmp = input(pcmp_loc_id, best12.); */
/*RUN ;*/

* Create a mcaid_id / time var that you can match on more easily / faster
Used after county / budget / rae for joining to memlist_attr_qrtr; 
%macro concat_id_time(ds=);
DATA &ds;
SET  &ds;
id_time_helper = CATX('_', mcaid_id, time); 
RUN; 
%mend; 



***********************************************************************************
*** SECTION TWO : Getting ADJ 1618 VARS & joining them             ****************
***********************************************************************************

** SUBSET int.adj_pt_total_yy (incl. all records in qry_longitudinal and qry_monthlyutil) to int.memlist mcaid_id's only; 
PROC SQL; 
CREATE TABLE int.adj_pd_total_yy_memlist AS 
SELECT *
FROM   int.adj_pd_total_yy
WHERE  mcaid_id IN (SELECT mcaid_id FROM int.memlist_final); 
QUIT;  * FROM 1550644 to 1050185; 

** GET PERCENTILES FOR ALL & TOP CODE DV's FOR MEMBERS ONLY ; 
* 1618; 
%macro pctl_1618(var,out,pctlpre);
proc univariate noprint data=int.adj_pd_total_yy_memlist; 
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
/*    995.665 2999.26 9368.52 18499.59       1011.85 3045.41 9712.56 19963.22       1032.91 3178.07 10435.04 22052.47 */

*FROM ORIGINAL LIST (included entire original util linelist members, not subset - just here for reference);
/*1   921.582 3034.06  10387.39  22590.99    966.845 3173.37 11080.45 25173.98      1011.10 3410.40 12288.92 28563.99 */

* https://stackoverflow.com/questions/60097941/sas-calculate-percentiles-and-save-to-macro-variable;
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

* Made separate ds's for testing but merge if poss later, save final to data/; 
%insert_pctile(ds_in = int.adj_pd_total_yy_memlist, ds_out = adj_final0,         year = 16);
%insert_pctile(ds_in = adj_final0,                  ds_out = adj_final1,         year = 17);
%insert_pctile(ds_in = adj_final1,                  ds_out = int.adj_1618_final, year = 18); *1050185;

/*            PROC FREQ DATA = adj_final2; */
/*            TABLES adj_pd_total_16cat adj_pd_total_17cat adj_pd_total_18cat; */
/*            RUN; */

* ==== Combine datasets with memlist_final ==================================;  
proc sort data = int.memlist_final; by mcaid_id ; run ;  

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
QUIT ; *14039876; 
/**/
/** TESTS: - expecting time*int_imp to have all int_imp=0 for time 1,2*/
/*         - time_start_isp should only be 3> UPDATE 4>*/
/*         - ind_isp*int_imp should have values in both cols for 0 but where ind_isp = 0 all int_imp should be 0;         */
        PROC CONTENTS DATA = int.a1; RUN; 
/**/
/*        PROC FREQ DATA = int.a1 ; */
/*        TABLES time*int_imp time_start_isp*int_imp ind_isp*int_imp; */
/*        RUN ;*/

*; 
DATA int.a2 ; 
SET  int.a1  (DROP = TIME_START_ISP ) ;
RENAME ind_isp=int ; 
RUN ; *14039876 : 11;
                      
*** 
UPDATED 4/25: adj file with actually correct values
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

FROM int.a2 AS a

LEFT JOIN int.adj_1618_final    AS B    ON a.mcaid_id = b.mcaid_id 
LEFT JOIN int.bh_1618           AS C    ON a.mcaid_id = c.mcaid_id 
LEFT JOIN int.bh_1921           AS D    ON a.mcaid_id = d.mcaid_id AND a.time = d.time
;
QUIT;   * 14039876 : 26 ;

PROC SORT DATA = int.a3 NODUPKEY OUT=int.a3a ; BY _ALL_ ; RUN ;  *0; 
      
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
RUN ;  *4/24 14039876 ; 

* Some adj's are blank - weren't on qry_longitudinal for fY 1618 (int.elig1618d comes exclusively from qry_longitudinal records); 
        PROC PRINT DATA = int.a3b (obs=100) ; where adj_pd_total_16cat = .; RUN; 
        PROC FREQ DATA = int.a3b; TABLES adj: ; RUN; 
        * "A001791", "A009133", "A009604","A012277";
        PROC PRINT DATA = int.elig1618d;
        WHERE mcaid_id IN ("A001791", "A009133", "A009604","A012277"); 
        RUN; 
*
ADJ `-1` values below: adj dataset created in util_02_get_prep_ana_util from a full join using all
qry_monthlyutilization and qry_longitudinal values from FYs 16-18
ID's not present in int.a3b were not eligible and can be marked with -1 as they were not present in either ana dataset; 
DATA  int.a3c;
SET   int.a3b;
* make missing = -1 because they weren't eligible (checking with where int.a3b = '' like A001791 etc in zscratch); 
adj_pd_total16 = coalesce(adj_pd_total_16cat,-1);
adj_pd_total17 = coalesce(adj_pd_total_17cat,-1);
adj_pd_total18 = coalesce(adj_pd_total_18cat,-1);
run;


* int.a3c
* ADJ pctile values ; 
PROC PRINT DATA = int.a3c (obs=25); where adj_pd_16a = .; RUN; *(looking to make sure adj_pd_total16 = -1);

*int.a3d
    -can drop values from a3c and rename the complete ones now; 
DATA int.a3d (rename=(adj_pd_total16 = adj_pd_total_16cat
                      adj_pd_total17 = adj_pd_total_17cat
                      adj_pd_total18 = adj_pd_total_18cat)) ; 
SET  int.a3c (drop=adj_pd_16a adj_pd_17a adj_pd_18a adj_pd_total_16cat adj_pd_total_17cat adj_pd_total_18cat);
RUN; *14347065 : 27; 

Proc freq data = int.a3d; tables adj: ; run;

proc contents data = int.util1921_adj; run; 

* Join util 1921 values for cost PMPM total, PMPM rx and util ED visits (to join with BH) 
* Join telehealth  ; 
PROC SQL ; 
CREATE TABLE int.a4 AS 
SELECT a.*
       /* util1921_adj cols: n_pc_q n_er_q pd_rx_q_adj pd_pc_q_adj on cat_qrtr (= time)      */
     , b.n_primary_care_qrtr  
     , b.n_er_qrtr            
     , b.adj_pd_pharmacy_qrtr 
     , b.adj_pd_total_qrtr    
     , b.adj_pd_primary_care_qrtr
     , sum(b.n_er_qrtr, a.sum_q_bh_er) as n_er_total
       /* tele cols:      */
     , c.n_q_tele
FROM int.a3d as a

LEFT JOIN int.util1921_adj as b
    ON a.mcaid_id = b.mcaid_id
    AND a.time    = b.cat_qrtr

LEFT JOIN int.tele_1921 as c
    ON a.mcaid_id = c.mcaid_id
    AND a.time    = c.time ; 
QUIT ; 

DATA int.A5 ; 
SET  int.A4 (DROP = sum_q_bh_er n_er_qrtr ) ;
mu_pd_rx    = adj_pd_pharmacy_qrtr     /n_months_per_q ; 
mu_pd_total = adj_pd_total_qrtr        /n_months_per_q ; 
mu_pd_pc    = adj_pd_Primary_care_qrtr /n_months_per_q ; 
mu_n_pc     = n_Primary_care_qrtr      /n_months_per_q ; 
mu_n_tele   = n_q_tele                 /n_months_per_q ; 
mu_n_er     = n_er_total               /n_months_per_q ; 
mu_n_bh_oth = sum_q_bh_other           /n_months_per_q ; 
RUN ; 

* 3/27 do same for pc (top coded) ; 
DATA int.a6 (DROP = mu_pd_rx
                    mu_pd_total
                    mu_pd_pc
                    mu_n_pc
                    mu_n_tele
                    mu_n_er
                    mu_n_bh_oth
                    ); 
SET  int.a5 (DROP = adj_pd_pharmacy_qrtr 
                    adj_pd_total_qrtr
                    adj_pd_Primary_care_qrtr
                    n_Primary_care_qrtr
                    n_q_tele 
                    n_er_total 
                    sum_q_bh_other 
             );
mu_rx     = coalesce(mu_pd_rx,   0);
mu_ffs    = coalesce(mu_pd_total,0);
mu_pc     = coalesce(mu_pd_pc   ,0);
util_pc   = coalesce(mu_n_pc    ,0);
util_tele = coalesce(mu_n_tele  ,0);
util_er   = coalesce(mu_n_er    ,0);
util_bh_o = coalesce(mu_n_bh_oth,0);
run ; * 14347065 ; 

proc contents data = int.a6 VARNUM; run; 

* Get 95th percentiles;
%macro dv_95pctl(var,out,pctlpre);
proc univariate noprint data = int.a6;
where &var gt 0; 
var   &var;
output out=&out pctlpre=&pctlpre pctlpts=95;
run; 
%mend; 

%dv_95pctl(var     = mu_rx,
           out     = rx_95pctl,
           pctlpre = rx_); 

%dv_95pctl(var     = mu_ffs,
           out     = ffs_95pctl,
           pctlpre = ffs_); 

%dv_95pctl(var     = mu_pc,
           out     = pc_95pctl,
           pctlpre = pc_); 

PROC SQL NOPRINT;   
SELECT rx_95  INTO :rx_95     FROM rx_95pctl ;
SELECT ffs_95 INTO :ffs_95    FROM ffs_95pctl;
SELECT pc_95  INTO :pc_95pctl FROM pc_95pctl ;
QUIT; 

* Get means for where values are > 95th pctile; 
%macro mu_dv_ge95th(var, out, value);
PROC UNIVARIATE DATA = int.a6;
BY   FY;
WHERE &var gt &value;
VAR   &var; 
output out = &out mean=&out;
RUN; 
%mend;


 ***NEXT *** ; 
PROC UNIVARIATE DATA = int.a6;
BY FY; 
WHERE mu_rx gt &rx_95;
VAR   mu_rx; 
output out = mean_rx_gt95 mean=mean_rx_95;
RUN; *3924 - sound right??
;

DATA test ; 
set  int.a6 (keep=mcaid_id adj: mu_pc int int_imp time);
ind_cost_pc = mu_pc>0;
RUN; 

PROC FREQ DATA = test;
TABLES adj:;
RUN; 


DATA int.a7  (rename = ( mu_ffs= cost_ffs_tc 
                         mu_rx = cost_rx_tc
                         mu_pc = cost_pc_tc )); 
SET  int.a6a ; 

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

RUN ; * 14039876 : 35; 

PROC PRINT DATA = int.a7 (obs=100); run; 
PROC CONTENTS DATA = int.a7; run; 

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
RUN; * 4/24 NOTE: There were 14039876 observations read from the data set INT.A7.
NOTE: The data set DATA.ANALYSIS_DATASET has 14039803 observations and 35 variables.

3/30 lost 88 people - all sex unknown? 
* from 14347065 to 14346977 (same as before tho from earlier in the week);

proc contents data = data.analysis_dataset; 
run; 
