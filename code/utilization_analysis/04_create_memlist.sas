
******************************************************
Create member list from qrylong_y15_22
******************************************************;
PROC SORT 
DATA  = data.qrylong_y15_22 ( keep= mcaid_id month pcmp_loc_ID ) NODUPKEY
OUT   = memlist_0; 
WHERE pcmp_loc_ID ne ' ' 
AND   month ge '01Jul2019'd 
AND   month le '30Jun2022'd;
BY    mcaid_id month; 
RUN; *1594348;

* ==== remove all except mcaid_id ==============================; 
* the rest are misleading, only keep mcaid_id; 
* if running again, just save memlist_0 to data.memlist - I put other code in here that should not have been; 
DATA data.memlist; 
set  data.memlist ( keep = mcaid_id ) ; 
run; 

* 1594687 members for timeframe 01JUL2019-30JUN2022; 
