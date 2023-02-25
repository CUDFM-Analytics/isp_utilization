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
set  sub2 ( keep = mcaid_id pcmp_loc_id q month ) ; 
run ;

* imported fake via import in toolbar;
data fake ; 
set  fake ; 
format month date9. ; 
run ; 

* a; 
proc sql; 
create table fake2 as 
select mc
    , max(q) as q
    , pc
    , count (pc) as n_pc
    , max (month ) as month format date9. 
from fake
group by mc, q, pc
order by mc, q
having n_pc=max(n_pc);
quit;

proc print data = fake2; run ; 

* b ; 
proc sql ;
create table fake3 as 
select mc
     , max(q) as max_q
     , pc
     , max(month) as max_month format date9.
from fake2
group by mc, q
having n_pc=max(n_pc);
quit;

proc print data = fake3 ; run ; 

* c ; 
proc sql; 
create table fake4 as
select *
    , count ( distinct pc ) as n_pc
from fake3
group by mc, max_q; 
quit;

proc print data = fake4 ; run ; 


data sample; 
    input id x; 
datalines; 
18  1 
18  1 
18  2 
18  1 
18  2 
369 2 
369 3 
369 3 
361 1 
; 
run; 

data want;
  do until(last.ID);
    set sample;
    by ID;
    xmax = max(x, xmax);
  end;
  x = xmax;
  drop xmax;
run;

proc means data=sample noprint max nway missing; 
   class id;
   var x;
   output out=sample_max (drop=_type_ _freq_) max=;
run; 
