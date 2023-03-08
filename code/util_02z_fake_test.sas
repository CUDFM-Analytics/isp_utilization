**********************************************************************************************
 PROJECT       : ISP utilization
 PROGRAMMER    : KTW
 DATE RAN      : 03/07/2023
 PURPOSE       : Create sample dataset for calculations for quarters, randomize mcaid_id
 INPUT FILE/S  : data.analytic_dataset                  
 OUTPUT FILE/S : 
 NOTES         : Date / Note
***********************************************************************************************;

proc print data = ;

data test_sum (KEEP = mcaid_id pcmp_type pcmp_attr_qrtr ind_isp_ever ind_isp_dtd ind_isp_dtd_qrtr pd: n_: bh_: month  q ); 
set  data.analytic_dataset (obs = 50000) ; 
n_er_total = sum(bh_n_er, n_er);  * combine the ER / capitated visits) ; 
run ;  *50000 : 12 ; 

* SUM pd_amt_pc
      pd_amt_rx
      pd_tele 
      n_tele
      n_pc
      n_er_total
      bh_n_other; 
     
PROC SQL ; 
CREATE TABLE test2 AS 
SELECT mcaid_id
     , pcmp_type
     , pcmp_attr_qrtr
     , q
     , ind_isp_ever
     , ind_isp_dtd_qrtr
     , sum (pd_amt_pc )/n_month as q_avg_cost_pc
     , sum (pd_amt_rx )/n_month as q_avg_cost_rx
     , sum (pd_tele   )/n_month as q_avg_cost_th
     , sum (n_pc      )/n_month as q_avg_util_pc
     , sum (n_er_total)/n_month as q_avg_util_er
     , sum (n_tele    )/n_month as q_avg_util_th
     , sum (bh_n_other)/n_month as q_avg_util_bh_other
FROM test_sum
GROUP BY mcaid_id, q ; 
QUIT; 

proc sort data = test2 nodupkey ; by _all_ ; run ; 

proc print data = test2 (obs = 10) noobs; run ; 

proc sql; 
create table n_un_mem_test as 
select count (distinct mcaid_id ) as n_id
from test2 ;
quit ; 

* Create completely random id's ; 
/* Generate N random 4-character strings (remove words on denylist) */
%let N = 1778; 
proc iml;
letters = 'A':'Z';                    /* all English letters */
L3 = expandgrid(letters, letters, letters); /* 26^4 combinations */
strings = rowcat(L3);                 /* concatenate into strings */
free L3;                              /* done with matrix; delete */
 
deny = {'CRAP','DAMN','DUMB','HELL','PUKE','SCUM','SLUT','SPAZ'}; /* add F**K, S**T, etc*/
idx = loc( ^element(strings, deny) ); /* indices of strings NOT on denylist */
ALLID = strings[idx];
 
call randseed(1234);
ID = sample(strings, &N, "WOR");      /* random sample without replacement */
create RandPerm var "ID"; append; close; /* write IDs to data set */
QUIT;

proc sort data = test2 (KEEP = mcaid_id ) out = un_id nodupkey ; by mcaid_id ; run ; 
 
/* merge data and random ID values */
data test3;  merge un_id RandPerm;  run;

proc sql; 
create table test4 as 
select a.*
     , b.id
from test2 as a
left join test3 as b
on a.mcaid_id = b.mcaid_id ; 
QUIT; 

data test5 ; 
set  test4 (DROP = mcaid_id ) ; 
RUN ; 
 
proc print data=test3(obs=25) noobs label;
run;
