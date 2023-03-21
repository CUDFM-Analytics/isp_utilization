**********************************************************************************************
 PROJECT       : ISP HCPF Question 5
 PROGRAMMER    : KTW 
 DATE RAN      : 02-21-2023
 PURPOSE       : 5) Number of unique attributed members in calendar quarter – quarterly 3Q2019 – 2Q2022 
                    (assign members to PCMP with the most months in a quarter and if there is an equal 
                    number assign to PCMP with attribution in last month eligible in the quarter)
 INPUT FILE/S  : 
                                  
 OUTPUT FILE/S : 
 NOTES         : 

***********************************************************************************************;
* PROJECT PATHS, MAPPING; 
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_params.sas"; 

***********************************************************************************************;
* UPDATE 2023-03-20: Added for util analysis /
* It's an addition to all below row 30   - was not used for the hcpf attr part, which starts on row 30; 
data int.memlist_attr_qrtr_1921 (KEEP = mcaid_id 
                                        FY
                                        time 
                                        pcmp_loc_id 
                                        n_months_per_q
                                        ind_isp); 
SET  int.memlist_attr_qrtr_1921 (RENAME=(q=time 
                                         n_pcmp_per_q=n_months_per_q)); 
FY      = year(intnx('year.7', max_month, 0, 'BEGINNING')); * create FY variable ; 
RUN ; *14649660 : 6 ; 

***********************************************************************************************;
* HCPF ATTR section that generated above ds; 

data q0;
set  data.qrylong_y19_22; 

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

proc freq data = q0; tables q ; run ;

**********************************************************************
... (assign members to PCMP with the most months in a quarter and 
if there is an equal number assign to PCMP with attribution in last month eligible in the quarter) ; 
**********************************************************************

* a) add count to pcmp and get max month; 
proc sql; 
create table q1 as 
select mcaid_id
     , q
     , pcmp_loc_id
     , count (pcmp_loc_id) as n_pcmp_per_q
     , max ( month ) as max_month format date9.
from q0
group by mcaid_id, q, pcmp_loc_id
order by mcaid_id, q;
quit;  *14890607 : 5; 

proc print data = q1 ( obs = 1000 ) ; run ;

proc print data = q2 ; where mcaid_id in ("A089085", "A005917","A258441") ; run ; 

proc sql; 
create table q2 as 
select mcaid_id
    , q
    , pcmp_loc_id
    , n_pcmp_per_q
    , max_month format date9.
from q1
group by mcaid_id, q
order by mcaid_id, q;
quit;

            * CHECKING) get member count per quarter ;
            proc sql; 
            create table q2 as 
            select mcaid_id
                , q
                , pcmp_loc_id
                , count (pcmp_loc_id) as n_pcmp_per_q
                , max_month format date9.
            from q1
            group by mcaid_id, q
            order by mcaid_id, q;
            quit;

        proc print data = q2 (obs = 500); run ; 

        proc freq data = q2 ; tables n_pcmp_per_q ; run ; 

        proc print data = q2 (obs = 1000) ; 
        where n_pcmp_per_q > 2 ; 
        run ;  * many had 3 - get max month now; 

* b) get max pcmp count; 
proc sql ;
create table q3 as 
select *
from q2
group by mcaid_id, q
having n_pcmp_per_q = max(n_pcmp_per_q);
quit; *14666776: 4;

proc print data = q3 ; where mcaid_id in ("A089085", "A005917","A258441") ; run ; 

* c) now get max month; 
proc sql ;
create table q4 as 
select *
from q3
group by mcaid_id, q
having max_month = max(max_month);
quit; *14649660; 

proc print data = q4 ; where mcaid_id in ("A089085", "A005917","A258441") ; run ; 

* c) check to make sure all pcmp=1// add count for mcaid, q; 
proc sql; 
create table q5 as
select *
    , count ( distinct pcmp_loc_id ) as n_pc
from q4
group by mcaid_id, q; 
quit;

proc freq data = q5 ; tables n_pc ; run ; 

proc sql ;
create table feb.unique_mem_quarter as 
select *
    , pcmp_loc_id in (select pcmp_loc_id from feb.ll_fy1922_pcmp_isp ) as ind_isp
    , pcmp_loc_id in (select pcmp_loc_id from feb.ll_fy1922_pcmp_nonisp ) as ind_nonisp 
from q4; 
quit; 

proc freq data = feb.unique_mem_quarter ; 
tables ind_isp ind_nonisp ; 
run ; 

proc contents data = feb.unique_mem_quarter  ; run ; 

proc freq data = feb.unique_mem_quarter; 
tables q*ind_isp; 
run ; 

proc format ; 
value qrtr_
1 = "2019_Q3"
2 = "2019_Q4"
3 = "2020_Q1"
4 = "2020_Q2"
5 = "2020_Q3"
6 = "2020_Q4"
7 = "2021_Q1"
8 = "2021_Q2"
9 = "2021_Q3"
10 = "2021_Q4"
11 = "2022_Q1"
12 = "2022_Q2";
run ; 

proc format ; 
value ind_isp_
0 = "non-ISP"
1 = "ISP"; 
run ; 

proc sql ; 
create table feb.n_quarter as 
select count ( mcaid_id ) as n_unique_mem
     , ind_isp format ind_isp_.
     , q format qrtr_. 
from feb.unique_mem_quarter
group by ind_isp, q;
quit; 


proc print data = feb.n_quarter noobs ; run ; 

*********  EXPORT  **********************;
ods excel file = "&util/reports_hcpf_pres_march2023/hcpf_attr_quarterly.xlsx"
    options (   sheet_name = "attr_quarter" 
                sheet_interval = "none"
                frozen_headers = "no"
                autofilter = "all");

proc print data = feb.n_quarter noobs ; run ; 

ods excel options ( sheet_interval = "now" sheet_name = "plot") ;

TITLE "Unique Attributed Members per Quarter, ISP / non-ISP: 07/2019-06/2022";
proc sgplot data = feb.n_quarter;
yaxis label = " ";
styleattrs datacontrastcolors =(purple steel); 
series x = q y = n_unique_mem / group = ind_isp ;
refline '_01MAR2020'd / 
        axis = x 
        lineattrs = ( thickness = 2 color=grey pattern=dash ) 
        label = ("March 2020")
        labelloc = inside
        label = "March 2020";
run; 
TITLE; 

ods excel close ; 
