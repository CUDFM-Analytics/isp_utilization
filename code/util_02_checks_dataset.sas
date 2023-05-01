* Check id counts ; 
%macro count_ids_memlist_final;
  PROC SQL; 
  SELECT count(distinct mcaid_id)
  FROM int.memlist_final;
  QUIT; 
%mend;

   %count_ids_memlist_final; *4/27 final run still got 1593591 ;


* Check top coding; 
PROC PRINT DATA = int.final_e (obs=50);
VAR mcaid_id time adj: FY;
where FY = 2019
AND adj_total_pm > 3000; 
RUN; 

PROC PRINT DATA = int.final_e (obs=50);
VAR mcaid_id time adj: FY;
where FY = 2019
AND adj_total_pm > 3000; 
RUN; 

