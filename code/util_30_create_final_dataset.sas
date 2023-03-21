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

* ==== Combine datasets with memlist  ==================================;  
proc sort data = int.memlist        ; by mcaid_id ; run ;  *1594686; 

PROC SQL ; 
CREATE TABLE a0 as 
SELECT a.mcaid_id
     , a.FY

     , b.time
     , b.pcmp_loc_id
     , b.n_months_per_q
     , b.ind_isp as intervention

FROM int.memlist as A 

/* has to be left join because b isn't age-subset  */
LEFT JOIN int.memlist_attr_qrtr_1921 AS b 
ON   a.mcaid_id = b.mcaid_id 
AND  a.FY       = b.FY  

QUIT ; 
*14053953 : 6 ; 

** Add demographic info last > start with the outcome values then we'll add them ; 
PROC SQL ; 
CREATE TABLE data.a1 as 
SELECT a.*
     , b.time_start_isp 
     , case when b.time_start_isp ne . AND a.time >= b.time_start_isp 
            then 1 
            else 0 end 
            as int_imp
FROM a0 as a
LEFT JOIN int.isp_un_pcmp_dtstart as b
ON   a.pcmp_loc_id = b.pcmp_loc_id ; 
QUIT ; 

*** Joining adj_pd_YYcat, BH 1618 cat, BH 1921;
proc sql; 
create table data.a2 as 
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

FROM data.a1 AS a

/*only needs to be joined on mcaid_id bc the cat's are wide not long */
LEFT JOIN int.util_1618_cat AS b
ON a.mcaid_id = b.mcaid_id 

/*only needs to be joined on mcaid_id bc the cols are wide not long */
LEFT JOIN int.bh_1618 AS c
ON a.mcaid_id = c.mcaid_id 

/*needs to be joined on qrtr and mcaid_id */
LEFT JOIN int.bh_1921 AS d
ON a.mcaid_id = d.mcaid_id AND a.time = d.time;

QUIT;   *14053953 : 24 ;  
      
* replace bh_1618 cat var's where . with 0 ; 
DATA  data.a3;
SET   data.a2 (DROP = time_start_isp 
                      sum_q_bh_hosp); 
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
RUN ;  *14053953 : 21 ; 

* Join util 1921 values for cost PMPM total, PMPM rx and util ED visits (to join with BH) 
* Join telehealth  ; 

PROC SQL ; 
CREATE TABLE data.a4 AS 
SELECT a.*
       /* util1921_adj cols: n_pc_q n_er_q pd_rx_q_adj pd_pc_q_adj on cat_qrtr (= time)      */
     , b.n_pc_q 
     , b.n_er_q 
     , b.pd_rx_q_adj 
     , b.pd_pc_q_adj
     , sum(b.n_er_q, a.sum_q_bh_er) as n_er_total
    
       /* tele cols:      */
     , c.n_q_tele

FROM data.a3 as a

LEFT JOIN int.util1921_adj as b
ON a.mcaid_id = b.mcaid_id
AND a.time    = b.cat_qrtr 

LEFT JOIN int.tele_1921 as c
ON a.mcaid_id = c.mcaid_id
AND a.time    = c.time ; 

QUIT ; 

* replace missings with 0, then 
                ****************************;  
* when joining rae ... 
LEFT JOIN int.rae as b
on a.enr_cnty = b.hcpf_county_code_c  ;


* Add month count per quarter (to create pmpm n's, amt's) ;
proc sql; 
create table analysis3 as 
select *
     , count (month) as n_month
from tmp.analysis2
group by mcaid_id, q ; 
quit;  *40999955; 

proc freq data = analysis3 ; tables n_month ; run ; 

* add dt_prac_isp from isp to feb.unique_mem_quarter; 
* get unique values for ISP pcmp_loc_id's and then remove where . ; 


* left join unique_mem_quarter (don't want all attr, only the memlist) 
* left join isp_un_pcmp for dt_prac_isp; 
PROC SQL; 
CREATE TABLE analysis4 AS 
SELECT a.*
     , b.pcmp_loc_id AS pcmp_attr_qrtr
     , b.ind_isp AS ind_isp_ever
FROM analysis3 AS a
LEFT JOIN feb.unique_mem_quarter AS b
ON a.mcaid_id = b.mcaid_id AND a.q = b.q ;
QUIT ; 

PROC SQL; 
CREATE TABLE analysis5 as 
SELECT a.*
     , b.dt_prac_isp 
FROM analysis4 AS a
LEFT JOIN data.isp_un_pcmp AS b
ON a.pcmp_attr_qrtr = b.pcmp_loc_id; 
QUIT; *40999955 : 42; 

            proc print data = analysis5 (obs=250) ; 
            var dt_prac_isp ind_isp_ever mcaid_id; 
            where ind_isp_ever = 1 ; 
            run ; 

            proc print data = analysis5 ;
            var  mcaid_id dt_prac_isp ind_isp_ever pcmp_loc_id pcmp_attr_qrtr month; 
            where mcaid_id in ("P861019", "L155867"); 
            run ; 


* ==== create ind_isp and ind_isp_ever vars =======================================;
DATA analysis6;
SET  analysis5; 
IF   ind_isp_ever = 1 and month >= dt_prac_isp then ind_isp_dtd = 1;
ELSE ind_isp_dtd = 0; 
RUN;

        * ==== save progress / delete later ===========================================;  
        data tmp.analysis6;
        set  analysis6; 
        run; 
                
proc print data = analysis6 (obs = 100) ; run ;           
proc contents data = analysis6 varnum; run ; 

proc sql; 
create table data.analytic_dataset as 
select *
     , case when ind_isp_ever = 1 then max(ind_isp_dtd) else 0 end as ind_isp_dtd_qrtr
from analysis6
group by mcaid_id, q;
quit;  

proc print data = data.analytic_dataset (obs = 1000) ; 
var mcaid_id pcmp:  ind_isp_ever dt_prac_isp month q ind_isp_dtd ind_isp_dtd_qrtr n_: ; 
where mcaid_id = "A005156";   *was dt_prac_isp ne . ; 
run ; * Looks good!! 

* Combine capitated and FFS er, Roll up quarters, add labels and save:; 
data data.analytic_dataset ;
set  data.analytic_dataset ;

if pd_amt_pc    = . then pd_amt_pc = 0;
if pd_amt_rx    = . then pd_amt_rx = 0;
if pd_amt_total = . then pd_amt_total = 0;
if n_pc         = . then n_pc = 0;
if n_er         = . then n_er = 0;
if n_total      = . then n_total = 0;
if bh_n_er      = . then bh_n_er = 0;
if bh_n_other   = . then bh_n_other = 0;
if n_tele       = . then n_tele = 0;
if pd_tele      = . then pd_tele = 0;
if dt_prac_isp  = . then dt_prac_isp = 0; 

fy3=year(intnx('year.7', month, 0, 'BEGINNING'));

label FY           = "Fiscal Year"
      RAE_ID       = "RAE ID" 
      age_end_fy   = "Age on Last Day FY"
      bh_n_er      = "BH visits: ER"
      bh_n_other   = "BH visits: Other"
      dob          = "Date of Birth" 
      dt_prac_isp  = "Date ISP Enrollment"
      ind_isp_dtd  = "ISP: Time-Varying"
      ind_isp_ever = "ISP: Time-Invariant"
      last_day_fy  = "Last Day of FY"
      n_er         = "Visits: ER"
      n_pc         = "Visits: PC"
      n_tele       = "Visits: Tele"
      n_total      = "Visits: Total in Monthly File"
      pcmp_type    = "PCMP type, recoded"
      pd_amt_pc    = "Cost: PC"
      pd_amt_rx    = "Cost: Prescriptions"
      pd_tele      = "Cost: Telehealth"
      q            = "Quarter"
      pd_amt_total = "Total FFS Cost of Care"
      ;
RUN; 

        * find examples ; 
        proc print data = data.analytic_dataset (obs = 500) ; 
        var mcaid_id month q ind_isp_dtd_qrtr ind_isp_dtd ind_isp_ever ; 
        where ind_isp_dtd_qrtr = 1 and ind_isp_dtd = 0;
        run ; 

        proc print data = data.analytic_dataset;
        where mcaid_id in ("A020536","A023159", "A027267", "A044973","A027267"); 
        var mcaid_id month q ind_isp_dtd_qrtr ind_isp_dtd ind_isp_ever pcmp_loc_id ; 
        run ; 

        * appears fixed: 2674 A023159 01JUL2021 9 1 0 1 117507 
                         2675 A023159 01AUG2021 9 1 1 1 117507 
                         2676 A023159 01SEP2021 9 1 1 1 117507 ;

proc contents data = data.analytic_dataset VARNUM; 
run ; 

proc freq data = data.analytic_dataset ; tables fy3; run ; 

proc print data = data.analytic_dataset (obs = 10) ; run; 

proc sql; 
create table n_un_pcmp as 
select count ( distinct pcmp_attr_qrtr ) as n_unique_pcmp 
from   data.analytic_dataset;
quit; 
