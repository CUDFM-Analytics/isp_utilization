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
where mc = "A363167";
run ; 

* a) add count to pcmp and get max month; 
proc sql; 
create table fake2 as 
select mc
    , q
    , pc
    , count (pc) as n_pc
    , max (month ) as month format date9. 
from fake
group by mc, q, pc
order by mc, q;
quit;

proc print data = fake2; run ; 

* b) get max n_pc ; 
proc sql ;
create table fake3 as 
select mc
     , max(q) as q
     , pc
     , max(month) as month format date9.
from fake2
group by mc, q, month
having n_pc=max(n_pc);
quit;

proc print data = fake3 ; run ; 

* c) count pcmp by id and quarter again to get the ones with multiple values
where 1 means it was the pcmp sole winner, 
where two or three means take max month; 
proc sql; 
create table fake4 as
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


data have;
  input id date :mmddyy10. value;
  format date date9.;
datalines;
1      1/20/2018            45
1      1/31/2018           100
1      2/20/2018            20
1      2/25/2018            87
2      1/17/2018            36
2      1/27/2018             45
2      2/02/2018             54
2      2/28/2018             68
run;

data want (drop=nxt_date);
  set have nobs=nrecs;
  by id;
  if _n_<nrecs then set have (firstobs=2 keep=date rename=(date=nxt_date));
  if last.id or intck('month',date,nxt_date)>0;
run;


data _null_;
if _n_=1 then do;
if 0 then set have;
dcl hash H (ordered:'y') ;
   h.definekey  ("id","month") ;
   h.definedata ("id","date","value") ;
   h.definedone () ;
end;
set have end=last;
month=month(date);
h.replace();
if last then h.output(dataset:'want');
run;
