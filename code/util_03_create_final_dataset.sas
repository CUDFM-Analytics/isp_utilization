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

* ==== Combine datasets into monthly files ==================================;  
proc sort data = data.qrylong_y15_22 ; by mcaid_id ;       *53384196; 
proc sort data = data.memlist        ; by mcaid_id ; run ;  *1594686; 

* Join final datasets > RAE, 

* ==== Reduce qrylong to 19-22 only ==========================================;
data  analysis0 ( drop = fy ) ;
set   data.qrylong_y15_22;
where month ge '01JUL2019'd 
and   month le '30JUN2022'd ;
run; 
* 02/24: [40999955 : 28 variables];

                * count unique members in analysis1;
                proc sql; 
                create table n_mem_analysis1 as 
                select count ( distinct mcaid_id ) as n_mcaid_id 
                from analysis0; 
                quit; 

                proc print data = n_mem_analysis1 ; run; * 1594348 2/28; 

* ==== Join the three utilization files ==========================================;
proc sql; 
create table analysis1 as 
select a.*
     /* join monthly */
     , b.pd_amt_pc
     , b.pd_amt_rx
     , b.pd_amt_total
     , b.n_pc
     , b.n_er
     , b.n_total

     /* join bho  */
     , c.bh_n_er
     , c.bh_n_other

     /* join telehealth utilization  */
     , d.n_tele
     , d.pd_tele

FROM analysis0 AS a

LEFT JOIN data.util_19_22 AS b
ON a.mcaid_id = b.mcaid_id AND a.month = b.month

LEFT JOIN data.bho_19_22 AS c
ON a.mcaid_id = c.mcaid_id AND a.month = c.month

LEFT JOIN data.memlist_tele_monthly AS d
ON a.mcaid_id = d.mcaid_id AND a.month = d.month;

QUIT;   * 40999955: 36 same when merged on pcmp_loc_id as when not;  
      
        * CHECK counts to see if all = 12; 
        proc sql; 
        create table check_mcaid_n as 
        select count(mcaid_id) as n_mcaid_id
        from data.memlist
        group by mcaid_id; 
        quit ; * 1594348 ; 

        proc freq data = check_mcaid_n ; tables n_mcaid_id ; run ; * all had 12!! ;

                ****** save progress ****** ;
                data tmp.analysis2; 
                set  analysis2; 
                run ; 
                ****************************;  

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

PROC SORT DATA = data.isp_key (WHERE = (pcmp_loc_id ne '.' ))  
     NODUPKEY out =isp (KEEP = dt_prac_isp pcmp_loc_id)    ; 
BY pcmp_loc_id dt_prac_isp ; 
RUN ; *119; 

DATA isp;
SET  isp ; 
dt_prac_isp2 = input(dt_prac_isp, date9.);
FORMAT dt_prac_isp2 date9.;
DROP   dt_prac_isp;
RENAME dt_prac_isp2 = dt_prac_isp;
RUN  ;  *118;

* there was a duplicate pcmp_loc_id with two different start dates: pcmp 162015 
* kids first id_split 3356 dt_start 01Mar2020 & their brighton high school id_split 3388 start date 01Jul2020
* I chose the 01Mar one for this
PER MARK G 2/28 = OK;
data data.isp_un_pcmp;
set  data.isp_un_pcmp ;
if   pcmp_loc_id = "162015" and dt_prac_isp = '01JUL2020'd then delete ; 
pcmp2 = input(pcmp_loc_id, 8.); 
drop pcmp_loc_id;
rename pcmp2 = pcmp_loc_id; 
run ; *117;

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
