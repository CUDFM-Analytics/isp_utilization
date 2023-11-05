*RAW.TIME_DIM==; 
   PROC PRINT DATA = raw.time_dim; RUN; 
*  Checks: time, fy_qrtr should have n=3, fy n=12 (12 months per FY), month_qrtr n=16, month (n=1, cumul_n=48 - 12*4); 
   proc freq data = raw.time_dim; run; 

*RAW.QRYLONG_00a;
   PROC CONTENTS DATA = raw.qrylong_00 VARNUM; RUN; 
   PROC CONTENTS DATA = tmp.bh VARNUM; run;
      PROC CONTENTS DATA = tmp.tel VARNUM; run;
   PROC CONTENTS DATA = tmp.util VARNUM; run;

   PROC PRINT DATA = raw.qrylong_00a (obs=25); RUN; 
   PROC FREQ DATA = raw.qrylong_00a; tables MONTH; where month ge '01JAN2023'd; run; 
   PROC FREQ DATA = raw.qrylong_00a; tables FY; RUN; 
   PROC FREQ DATA = raw.qrylong_00a; tables fqhc; RUN; 
   PROC FREQ DATA = raw.qrylong_00a; tables pcmp_loc_type_cd; RUN; 
   PROC SQL; SELECT count(distinct mcaid_id) FROM raw.qrylong_00a; QUIT; 

%LET check = int.qrylong_02; 
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

%LET check = int.util_0; 
TITLE "&check"; 
    PROC MEANS DATA =&check n nmiss; RUN; 
    PROC FREQ DATA = &check nlevels; TABLES month clmClass count fy dt_qrtr; RUN; 
   PROC PRINT DATA = &check (obs=200); RUN; 
TITLE; 

PROC PRINT DATA = int.util_1; WHERE mcaid_id = "A000405"; RUN;

%LET check = int.util_1; 
TITLE "&check"; 
    PROC MEANS DATA =&check nmiss; RUN; 
    PROC FREQ DATA = &check nlevels; TABLES month*dt_qrtr fy clmClass; RUN; 
   PROC PRINT DATA = &check (obs=200); RUN; 
TITLE; 


%LET check = int.util; 
TITLE "&check"; 
   PROC PRINT DATA = &check (obs=200); RUN; 

TITLE; 


%LET check = int.qrylong_pre_0; 
TITLE "&check"; 
   PROC CONTENTS DATA = &check VARNUM; RUN; 
TITLE; 

%LET check = int.qrylong_post_1; 
TITLE "&check"; 
   PROC PRINT DATA    = &check (obs=25); RUN; 
TITLE; 

%LET check = int.final_06; 
title "&check"; 
   PROC CONTENTS DATA = &check VARNUM; RUN; 
   PROC PRINT DATA    = &check (obs=25); RUN; 
   PROC FREQ DATA     = &check; tables ind_: ; RUN; 
   PROC SQL; SELECT count(distinct mcaid_id) FROM &check; QUIT; 
TITLE; 

%LET check = int.final_08; 
title "&check"; 
   PROC CONTENTS DATA = &check VARNUM; RUN; 
   PROC PRINT DATA    = &check (obs=25); RUN; 
   PROC FREQ DATA     = &check; tables ind_: ; RUN; 
   PROC SQL; SELECT count(distinct mcaid_id) FROM &check; QUIT; 
TITLE; 

%LET check = data.utilization_large; 
title "&check"; 
   PROC CONTENTS DATA = &check VARNUM; RUN; 
   PROC PRINT DATA    = &check (obs=25); RUN; 
   * SAS keeps freezing doing too many tables so broke it up: 
     * DEMO vars; 
     PROC FREQ DATA = &check; tables time ; RUN; 
     PROC FREQ DATA = &check; tables age: race sex ; RUN; 
     PROC FREQ DATA = &check; tables budget_group*budget_grp_r; RUN; 
     PROC FREQ DATA = &check; tables ind: ; RUN; 
     PROC FREQ DATA = &check; tables adj_pd_total_17cat adj_pd_total_18cat adj_pd_total_19cat ; RUN; 
     PROC FREQ DATA = &check; tables FY*time; RUN; 

     LIBNAME eda "&data/out_eda_checks"; 

PROC CONTENTS DATA = int.final_07; RUN; 

PROC SQL; 
     CREATE TABLE eda.cost_pc_tc_prepost AS
     SELECT FY
           , min(adj_pc_pmpq)  as min_pre_tc
           , max(adj_pc_pmpq)  as max_pre_tc
           , mean(adj_pc_pmpq) as mean_pre_tc
           , std(adj_pc_pmpq) as sd_pre_tc
           , min(adj_pd_pc_tc) as min_post_tc
           , max(adj_pd_pc_tc) as max_post_tc
           , mean(adj_pd_pc_tc) as mean_post_tc
           , std(adj_pd_pc_tc) as sd_post_tc
     FROM int.final_07
     GROUP BY FY; 
QUIT; 

PROC SQL; 
     CREATE TABLE eda.cost_pc_tc_prepost_gt0 AS
     SELECT FY
           , min(adj_pc_pmpq)  as min
           , max(adj_pc_pmpq)  as max_pre_tc
           , mean(adj_pc_pmpq) as mean_pre_tc
           , std(adj_pc_pmpq) as sd_pre_tc
           , max(adj_pd_pc_tc) as max_post_tc
           , mean(adj_pd_pc_tc) as mean_post_tc
           , std(adj_pd_pc_tc) as sd_post_tc
     FROM int.final_07
     WHERE adj_pc_pmpq >0
     GROUP BY FY; 
QUIT; 

     PROC SQL; 
     CREATE TABLE eda.cost_RX_tc_prepost AS
     SELECT FY
             , min(adj_rx_pmpq)  as min_pre_tc
             , max(adj_rx_pmpq)  as max_pre_tc
             , mean(adj_rx_pmpq) as mean_pre_tc
             , std(adj_rx_pmpq) as sd_pre_tc
             , min(adj_pd_rx_tc) as min_post_tc
             , max(adj_pd_rx_tc) as max_post_tc
             , mean(adj_pd_rx_tc) as mean_post_tc
             , std(adj_pd_rx_tc) as sd_post_tc
     FROM int.final_07
     GROUP BY FY; 
     QUIT; 

PROC SQL; 
     CREATE TABLE eda.cost_rx_tc_prepost_gt0 AS
     SELECT FY
           , min(adj_rx_pmpq)  as min
           , max(adj_rx_pmpq)  as max_pre_tc
           , mean(adj_rx_pmpq) as mean_pre_tc
           , std(adj_rx_pmpq) as sd_pre_tc
           , max(adj_pd_rx_tc) as max_post_tc
           , mean(adj_pd_rx_tc) as mean_post_tc
           , std(adj_pd_rx_tc) as sd_post_tc
     FROM int.final_07
     WHERE adj_rx_pmpq >0
     GROUP BY FY; 
QUIT; 

     PROC SQL; 
     CREATE TABLE eda.cost_total_tc_prepost AS
     SELECT FY
             , min(adj_total_pmpq)  as min_pre_tc
             , max(adj_total_pmpq)  as max_pre_tc
             , mean(adj_total_pmpq) as mean_pre_tc
             , std(adj_total_pmpq) as sd_pre_tc
             , min(adj_pd_total_tc) as min_post_tc
             , max(adj_pd_total_tc) as max_post_tc
             , mean(adj_pd_total_tc) as mean_post_tc
             , std(adj_pd_total_tc) as sd_post_tc
     FROM int.final_07
     GROUP BY FY; 
     QUIT; 

 PROC SQL; 
     CREATE TABLE eda.cost_total_tc_prepost_gt0 AS
     SELECT FY
           , min(adj_total_pmpq)  as min
           , max(adj_total_pmpq)  as max_pre_tc
           , mean(adj_total_pmpq) as mean_pre_tc
           , std(adj_total_pmpq) as sd_pre_tc
           , max(adj_pd_total_tc) as max_post_tc
           , mean(adj_pd_total_tc) as mean_post_tc
           , std(adj_pd_total_tc) as sd_post_tc
     FROM int.final_07
     WHERE adj_total_pmpq >0
     GROUP BY FY; 
QUIT;     


PROC PRINT DATA = eda.cost_total_tc_prepost noobs; RUN; 
PROC PRINT DATA = eda.cost_rx_tc_prepost noobs; RUN; 
PROC PRINT DATA = eda.cost_pc_tc_prepost noobs; RUN; 

PROC PRINT DATA = eda.cost_total_tc_prepost_gt0 noobs; RUN; 
PROC PRINT DATA = eda.cost_rx_tc_prepost_gt0 noobs; RUN; 
PROC PRINT DATA = eda.cost_pc_tc_prepost_gt0 noobs; RUN; 

PROC CONTENTS DATA = data.utilization_large VARNUM; RUN; 


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


PROC PRINT DATA = data.utilization; where mcaid_id="A005875"; RUN; 
PROC PRINT DATA = ana.qry_monthlyutilization; where mcaid_id="A005875"; RUN; 


LIBNAME int "&projRoot/data/interim"; 
PROC CONTENTS DATA = int.qrylong_03 VARNUM; run; 
PROC FREQ DATA = int.qrylong_03; tables fy; run;
PROC SQL; 
CREATE TABLE zz_final_03 AS 
SELECT mcaid_id, month, dt_qrtr, FY, time, adj_total
FROM int.qrylong_03
WHERE month ge '01JUL2019'd and month lt '01JUL2020'd; 
QUIT; * matched what i got by fy freqs so that was right; 

PROC SQL; 
CREATE TABLE zz_qrylong_03b AS 
SELECT mcaid_id, dt_qrtr, time, avg(adj_total) as pmpq_total
FROM zz_final_03
GROUP BY mcaid_id, time; 

