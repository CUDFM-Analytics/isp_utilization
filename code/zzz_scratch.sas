proc sql; select count(distinct mcaid_id) as n_un_mcaid from int.final_00; QUIT; 
proc sql; select count(distinct mcaid_id) as n_un_mcaid from int.qrylong_02; QUIT; 
PROC CONTENTS DATA = int.qrylong_03 VARNUM; RUN;
PROC CONTENTS DATA = int.qrylong_post_0 VARNUM; RUN;
PROC PRINT DATA = int.qrylong_post_1 (obs=100); RUN; 

PROC PRINT DATA = int.qrylong_03; where mcaid_id = "A000405"; RUN; 
