proc sql; select count(distinct mcaid_id) as n_un_mcaid from int.final_00; QUIT; 
proc sql; select count(distinct mcaid_id) as n_un_mcaid from int.qrylong_02; QUIT; 
PROC CONTENTS DATA = int.qrylong_03 VARNUM; RUN;
PROC CONTENTS DATA = int.qrylong_post_0 VARNUM; RUN;
PROC PRINT DATA = int.qrylong_post_1 (obs=100); RUN; 

PROC SQL; 
SELECT mcaid_id
     , time
     , avg(n_pc) as n_pc_pmpq
     , avg(n_er) as n_er_pmpq
     , avg(n_ffs_bh) as n_ffsbh_pmpq
FROM int.qrylong_03
WHERE mcaid_id in ("A000405")
GROUP BY mcaid_id, time;
QUIT; 
PROC PRINT DATA = int.qrylong_1922; where mcaid_id="A000405"; RUN; 

PROC PRINT DATA = int.final_05 (obs=100); RUN; 
PROC CONTENTS DATA = int.final_05 VARNUM; RUN;

PROC FREQ DATA = int.final_05; tables n_months; RUN; 
PROC FREQ DATA = int.final_05; tables time; run; 

PROC CONTENTS DATA = int.final_05 VARNUM; RUN;

PROC CONTENTS DATA = int.final_07 VARNUM; RUN;
PROC FREQ DATA = int.final_07; tables fy time age fqhc budget_group rae_person_new race sex bh: ind: ; RUN; 

PROC CONTENTS DATA = int.final_08 VARNUM; RUN;
proc print data = int.final_08 (obs=25); run; 
PROC FREQ DATA = int.final_08; tables fy time budget:  ; RUN; 

PROC CONTENTS DATA = data.analysis_allcols VARNUM; RUN;

PROC PRINT DATA = data.analysis_allcols (obs=25); RUN; 

** CHECKS; 
PROC SORT DATA = int.final_05; by fy mcaid_id; run; 
PROC CONTENTS DATA = int.final_05 VARNUM; run; 
 
PROC CONTENTS DATA = &dat VARNUM; RUN; 
