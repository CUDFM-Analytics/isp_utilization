*RAW.TIME_DIM==; 
   PROC PRINT DATA = raw.time_dim; RUN; 
*  Checks: time, fy_qrtr should have n=3, fy n=12 (12 months per FY), month_qrtr n=16, month (n=1, cumul_n=48 - 12*4); 
   proc freq data = raw.time_dim; run; 

*RAW.QRYLONG_00a;
   PROC CONTENTS DATA = raw.qrylong_00 VARNUM; RUN; 
   PROC PRINT DATA = raw.qrylong_00a (obs=25); RUN; 
   PROC FREQ DATA = raw.qrylong_00a; tables MONTH; where month ge '01JAN2023'd; run; 
   PROC FREQ DATA = raw.qrylong_00a; tables FY; RUN; 
   PROC FREQ DATA = raw.qrylong_00a; tables fqhc; RUN; 
   PROC FREQ DATA = raw.qrylong_00a; tables pcmp_loc_type_cd; RUN; 
   PROC SQL; SELECT count(distinct mcaid_id) FROM raw.qrylong_00a; QUIT; 

%LET check = int.qrylong_01; 
   PROC CONTENTS DATA = &check VARNUM; RUN; 
   PROC PRINT DATA = &check (obs=25); RUN; 
   PROC FREQ DATA = &check; tables time; RUN; 
   PROC SQL; SELECT count(distinct mcaid_id) FROM &check; QUIT; 

%LET check = int.age_dim; 
   PROC CONTENTS DATA = &check VARNUM; RUN; 
   PROC PRINT DATA = &check (obs=25); RUN; 
   PROC FREQ DATA = &check; tables age age*age_cat; RUN; 
   PROC SQL; SELECT count(distinct mcaid_id) FROM &check; QUIT; 

%LET check = int.final_00; 
%LET title = "&check"; 
   PROC CONTENTS DATA = &check VARNUM; RUN; 
   PROC PRINT DATA    = &check (obs=25); RUN; 
   PROC FREQ DATA     = &check; tables fy time age_cat; RUN; 
   PROC SQL; SELECT count(distinct mcaid_id) FROM &check; QUIT; 
TITLE; 

%LET check = int.final_00; 
title "&check"; 
   PROC CONTENTS DATA = &check VARNUM; RUN; 
   PROC PRINT DATA    = &check (obs=25); RUN; 
   PROC FREQ DATA     = &check; tables fy time age_cat; RUN; 
   PROC SQL; SELECT count(distinct mcaid_id) FROM &check; QUIT; 
TITLE; 

%LET check = int.final_01; 
TITLE "&check"; 
   PROC CONTENTS DATA = &check VARNUM; RUN; 
   PROC PRINT DATA    = &check (obs=25); RUN; 
TITLE; 

%LET check = int.qrylong_pre_0; 
TITLE "&check"; 
   PROC CONTENTS DATA = &check VARNUM; RUN; 
TITLE; 

%LET check = int.qrylong_post_1; 
TITLE "&check"; 
   PROC PRINT DATA    = &check (obs=25); RUN; 
TITLE; 

%LET check = int.qrylong_post_2; 
TITLE "&check"; 
   PROC CONTENTS DATA = &check VARNUM; RUN; 
   PROC PRINT DATA    = &check (obs=25); RUN; 
   PROC FREQ DATA = &check; tables month fy time n_: ; RUN; 
TITLE; 

%LET check = int.qrylong_2023; 
TITLE "&check"; 
   PROC CONTENTS DATA = &check VARNUM; RUN; 
   PROC PRINT DATA    = &check (obs=25); RUN; 
   PROC FREQ DATA = &check; tables month fy time n_: ; RUN; 
TITLE; 

PROC PRINT DATA = ana.qry_monthlyutilization;
WHERE mcaid_id="A000405" 
AND   month ge '01JAN2023'd; 
RUN; 






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
