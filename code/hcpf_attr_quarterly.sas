**********************************************************************************************
 PROJECT       : ISP HCPF Question 5
 PROGRAMMER    : KTW 
 DATE RAN      : 02-21-2023
 PURPOSE       : 5)	Number of unique attributed members in calendar quarter – quarterly 3Q2019 – 2Q2022 
                    (assign members to PCMP with the most months in a quarter and if there is an equal 
                    number assign to PCMP with attribution in last month eligible in the quarter)
 INPUT FILE/S  : 
                                  
 OUTPUT FILE/S : 
 NOTES         : 

***********************************************************************************************;
* PROJECT PATHS, MAPPING; 
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_params.sas"; 

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

* b) get member count per quarter ;
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

* b) now get max month from group by mcaid, q; 
proc sql ;
create table n3 as 
select mcaid_id
     , q
     , pcmp_loc_id
     , max_month format date9.
from n2
group by mcaid_id, q
having max_month = max(max_month);
quit; *14053127 : 4;

proc print data = n3 (obs = 10000) ; run ; 

* c) check to make sure all pcmp=1// add count for mcaid, q; 
proc sql; 
create table n4 as
select *
    , count ( distinct pc ) as n_pc
from fake3
group by mc, q; 
quit;

proc print data = fake4 ; run ; 

proc sort data = fake4 ; by mc q pc ; run ;

proc sql;
create table fake5 as 
select mc, q, pc, month 
from fake4
group by mc, q
having max(month)=month;
quit; 


proc print data = fake5; run ; 
