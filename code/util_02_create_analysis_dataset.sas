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
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_params.sas"; 

* ==== Combine datasets into monthly files ==================================;  
proc sort data = data.qrylong_y15_22 ; by mcaid_id ;   *53384196; 
proc sort data = data.memlist        ; by mcaid_id ; run ; 

* ==== Reduce qrylong to 19-22 only ==========================================;
data  analysis0 ( drop = fy ) ;
set   data.qrylong_y15_22;
where month ge '01JUL2019'd 
and   month le '30JUN2022'd ;
run; 
* 02/24: [40999955 : 28 variables];

* ==== Subset memlist (just to see) ==========================================;
* Probaby don't need to do this but IDK; 
proc sql; 
create table analysis1 as 
select *
from analysis0
where mcaid_id in (select mcaid_id from data.memlist) ; 
quit; *2/27 > 40999955 : 28 ;

                * count unique members in analysis1;
                proc sql; 
                create table n_mem_analysis1 as 
                select count ( distinct mcaid_id ) as n_mcaid_id 
                from analysis1; 
                quit; 

                proc print data = n_mem_analysis1 ; run; * 1594348; 

* ==== Join the three utilization files ==========================================;
proc contents data = data.util_19_22;
proc contents data = data.bho_19_22 ; 
proc contents data = data.memlist_tele_monthly; 
run ; 

proc sql; 
create table analysis2 as 
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

FROM analysis1 AS a

LEFT JOIN data.util_19_22 AS b
ON a.mcaid_id = b.mcaid_id AND a.month = b.month

LEFT JOIN data.bho_19_22 AS c
ON a.mcaid_id = c.mcaid_id AND a.month = c.month

LEFT JOIN data.memlist_tele_monthly AS d
ON a.mcaid_id = d.mcaid_id AND a.month = d.month;

QUIT;   * 40999955: 36 same when merged on pcmp_loc_id as when not;  

proc print data = analysis2 (obs = 5000) ; run ; 

*********** SAVE PROGRESS **********************; 
            data tmp.analysis2;
            set  analysis2; 
            run ; 
************************************************;

* ==== join isp_key info  =======================================;
proc sort data = tmp.analysis2 ;
BY pcmp_loc_id ;      

* get unique values for ISP pcmp_loc_id's and then remove where .; 
PROC SORT DATA = data.isp_key NODUPKEY out =isp (KEEP = dt_prac_isp pcmp_loc_id); 
BY pcmp_loc_id dt_prac_isp ; 
RUN ;

DATA isp;
SET  isp (WHERE = (pcmp_loc_id ne '.' )) ; 
dt_prac_isp2 = input(dt_prac_isp, date9.);
FORMAT dt_prac_isp2 date9.;
DROP   dt_prac_isp;
RENAME dt_prac_isp2 = dt_prac_isp;
RUN  ;  *118;

* there was a duplicate pcmp_loc_id with two different start dates: pcmp 162015 
* kids first id_split 3356 dt_start 01Mar2020 & their brighton high school id_split 3388 start date 01Jul2020
* I chose the 01Mar one for this and will ask Mark;
data isp;
set  isp;
if   pcmp_loc_id = "162015" and dt_prac_isp = '01JUL2020'd then delete ; 
run ; *117;

* join to analysis2; 
proc sql; 
create table analysis3 as 
select a.*
     , b.dt_prac_isp
     , b.pcmp_loc_id in (select pcmp_loc_id from isp ) as ind_isp_ever
from tmp.analysis2 as a 
left join isp as b
on a.pcmp_loc_id = b.pcmp_loc_id; 
quit; *BOOM same number PHEW!;


* ==== create ind_isp and ind_isp_ever vars =======================================;
DATA analysis4;
SET  analysis3; 
IF   ind_isp_ever = 1 and month >= dt_prac_isp then ind_isp_dtd = 1;
ELSE ind_isp_dtd = 0; 
RUN;

        proc print data = analysis4 (obs = 1000) ; 
        var mcaid_id month dt_prac_isp ind_isp_ever ind_isp_dtd;
        where dt_prac_isp ne . ;
        run ; 

        * ==== save progress / delete later ===========================================;  
        data tmp.analysis_draft;
        set  analysis4; 
        run; 
                
                * WHAat was this? probably remove later?? ; 
                proc sql; 
                create table data.ind_isp_counts_19_22 as 
                select sum (ind_isp) as n_ind_isp
                     , sum (ind_isp_ever) as ind_isp_ever
                from analysis3;
                quit;

                proc print data = data.ind_isp_counts_19_22 ; run ; 

* ==== Add q var  ==================================;  

data analysis5;
set  analysis4;
if month in ('01JUL2019'd , '01AUG2019'd , '01SEP2019'd ) then q = 1;
if month in ('01OCT2019'd , '01NOV2019'd , '01DEC2019'd ) then q = 2;
if month in ('01JAN2020'd , '01FEB2020'd , '01MAR2020'd ) then q = 3;
if month in ('01APR2020'd , '01MAY2020'd , '01JUN2020'd ) then q = 4;
if month in ('01JUL2020'd , '01AUG2020'd , '01SEP2020'd ) then q = 5;
if month in ('01OCT2020'd , '01NOV2020'd , '01DEC2020'd ) then q = 6;
if month in ('01JAN2021'd , '01FEB2021'd , '01MAR2021'd ) then q = 7;
if month in ('01APR2021'd , '01MAY2021'd , '01JUN2021'd ) then q = 8;
if month in ('01JUL2021'd , '01AUG2021'd , '01SEP2021'd ) then q = 9;
if month in ('01OCT2021'd , '01NOV2021'd , '01DEC2021'd ) then q = 10;
if month in ('01JAN2022'd , '01FEB2022'd , '01MAR2022'd ) then q = 11;
if month in ('01APR2022'd , '01MAY2022'd , '01JUN2022'd ) then q = 12;
run;


proc contents data = analysis5 ; run ; 

* add labels and save:; 
data data.analytic_dataset ;
set  data.analytic_dataset ; 

if n_pc = . then n_pc = 0;
if n_er = . then n_er = 0;
if n_total = . then n_total = 0;
if bh_n_er = . then bh_n_er = 0;
if bh_n_other = . then bh_n_other = 0;
if n_tele = . then n_tele = 0;
if pd_tele = . then pd_tele = 0;
if pd_amt_pc = . then pd_amt_pc = 0;
if pd_amt_rx = . then pd_amt_rx = 0;
if pd_amt_total = . then pd_amt_total = 0;

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

* join the `unique_mem_quarter` to get the pcmp used there: ; 
proc sql; 
create table analysis6 as 
select a.*
     , b.pcmp_loc_id as pcmp_id_qrtr
from  data.analytic_dataset as a
left join feb.unique_mem_quarter as b
on a.mcaid_id = b.mcaid_id and a.q = b.q; 
quit;

* NEXT GET MAX for ind_isp_quarter if it's in the month; 
/*proc sql; */
/*create table analysis7 as */
/*select **/
/*     , max(ind_isp_dtd) as ind_isp_dtd_qrtr*/
/*from analysis6*/
/*group by mcaid_id, q;*/
/*quit; */
* ABOVE DIDN"T WORK because if member switched mid-quarter to a NONISP practice= see example A020536; 
*row  mcaid_id month    q ind_isp_dtd_qrtr ind_isp_dtd ind_isp_ever pcmp_loc_id pcmp_id_qrtr
*2175 A020536 01AUG2021 9  1 1 1 118862 118862  --ISSUE HERE
 2176 A020536 01SEP2021 9  1 0 0 19358 118862 
 2177 A020536 01DEC2021 10 0 0 0 19358 19358 ; 

proc sql; 
create table analysis7 as 
select *
     , case when ind_isp_ever = 1 then max(ind_isp_dtd) else 0 end as ind_isp_dtd_qrtr
from analysis6
group by mcaid_id, q;
quit;  


        * find examples ; 
        proc print data = analysis7 (obs = 500) ; 
        var mcaid_id month q ind_isp_dtd_qrtr ind_isp_dtd ind_isp_ever ; 
        where ind_isp_dtd_qrtr = 1 and ind_isp_dtd = 0;
        run ; 

        proc print data = analysis7;
        where mcaid_id in ("A020536", "A020916", "A023159","A027267"); 
        var mcaid_id month q ind_isp_dtd_qrtr ind_isp_dtd ind_isp_ever pcmp_loc_id ; 
        run ; 

        proc print data = analysis7;
        where mcaid_id in ("A020536","A023159", "A027267", "A044973","A027267"); 
        var mcaid_id month q ind_isp_dtd_qrtr ind_isp_dtd ind_isp_ever pcmp_loc_id ; 
        run ; 

        * appears fixed: 2674 A023159 01JUL2021 9 1 0 1 117507 
                         2675 A023159 01AUG2021 9 1 1 1 117507 
                         2676 A023159 01SEP2021 9 1 1 1 117507 ;

