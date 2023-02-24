data subset;
set  data.qrylong_y19_22;
if _N_ <= 10000 then output;
run; 

data sub2;
set  subset;
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
if month in ('01APR2022'd , '01MAY2022'd , '01JUN2022'd ) then q = 11;
run;

data test ;
set  sub2 ( keep = mcaid_id pcmp_loc_id q ) ; 
run ;

* imported fake2;
proc sql; 
create table fake as 
select mc
    , q
    , count (distinct pc) as n_pc
from fake2
group by mc, q
order by mc, q;
quit;

proc sql; 
create table test2 as 
select mcaid_id
    , q
    , count (distinct pcmp_loc_id) as n_pcmp_per_q
from test
group by mcaid_id, q
order by mcaid_id, q;
quit;
