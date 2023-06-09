* 
[Checking 'budget_group'] ================================================================
Using raw.final_07 since that's the one that was pre-format
===========================================================================================;
PROC FREQ 
     DATA = raw.final_07;
     TABLES budget_group / ;* PLOTS = freqplot(type=dotplot scale=percent) out=out_ds;
     TITLE  'Frequency budget group, pre-formatting';
RUN; 
TITLE; 

PROC FREQ 
     DATA = raw.final_08;
     TABLES budget_group / ;* PLOTS = freqplot(type=dotplot scale=percent) out=out_ds;
     TITLE  'Frequency budget group, post-formatting';
RUN; 
TITLE; 

PROC CONTENTS DATA = data.analysis;
RUN; 

PROC FREQ 
     DATA = data.analysis;
     TABLES budget_group budget_grp_new budget_grp_no_fmt
            budget_grp_no_fmt*budget_group
            budget_grp_no_fmt*budget_grp_new ;* PLOTS = freqplot(type=dotplot scale=percent) out=out_ds;
     TITLE  'Frequency budget group, various views';
RUN; 
TITLE; 

* 
[RAW.FINAL_00] ==============================================================================
Tests
===========================================================================================;
PROC CONTENTS DATA=RAW.FINAL_00 VARNUM;
RUN;

PROC FREQ DATA=raw.final_00; 
table age TIME fy month sex race rae_person_new month; 
RUN; 

PROC SQL;
SELECT count(distinct mcaid_id) FROM raw.final_00;
RUN; 

PROC SQL ; 
SELECT count(mcaid_id) as n
     , mcaid_id 
FROM int.FY1618
GROUP BY mcaid_id
HAVING >12 n;
QUIT; 


* Check id counts in some dataset; 
%macro n_obs_per_id(ds=);
  PROC SQL; 
  CREATE TABLE n_records_per_id AS
  SELECT mcaid_id
       , count(mcaid_id) as n_id
  FROM &ds
  GROUP BY mcaid_id;
  QUIT; 
%mend;

%n_obs_per_id(ds=raw.qrylong_1922_0); 
proc freq data = n_records_per_id;
tables n_id;
run;
%n_obs_per_id(ds=raw.final_03); 


PROC FREQ 
     DATA = n_records_per_id;
     TABLES n_id  ;* PLOTS = freqplot(type=dotplot scale=percent) out=out_ds;
RUN; 

PROC MEANS DATA = raw.util3;
BY fy; 
VAR adj:;
WHERE mcaid_id in ("A000405");
RUN; 



/*  Row 380 ish in util_01_create dataset, checking percentiles for 1618*/
        **   checking percentiles ; 
        PROC RANK DATA =  raw.fy1618_2 out=int.ranked_adj_FY16 
             (keep=mcaid_id elig2016 adj_pd_16pm adj_pd_16pm_rank)  groups =100;
        VAR   adj_pd_16pm;
        RANKS adj_pd_16pm_rank;
        WHERE adj_pd_16pm gt 0 ;
        RUN; 

        PROC RANK DATA =  raw.fy1618_2 out=int.ranked_adj_FY17 
             (keep=mcaid_id elig2017 adj_pd_16pm adj_pd_17pm_rank) 
            groups =100;
        VAR   adj_pd_17pm;
        RANKS adj_pd_17pm_rank;
        WHERE adj_pd_17pm gt 0;
        RUN; 

        PROC RANK DATA =  raw.fy1618_2 out=int.ranked_adj_FY18 
             (keep=mcaid_id elig2018 adj_pd_16pm adj_pd_18pm_rank) groups =100;
        VAR   adj_pd_18pm;
        RANKS adj_pd_18pm_rank;
        WHERE adj_pd_18pm gt 0;
        RUN; 

* Check to see if top coding macro worked, rows 556+; 
PROC PRINT DATA = int.final_e (obs=50);
VAR mcaid_id time adj: FY;
where FY = 2019
AND adj_total_pm > 3000; 
RUN; 

PROC PRINT DATA = int.final_e (obs=50);
VAR mcaid_id time adj: FY;
where FY = 2020
AND adj_total_pm > 3000; 
RUN; 

PROC PRINT DATA = int.final_e (obs=50);
VAR mcaid_id time adj: FY;
where FY = 2021
AND adj_rx_pm > 1157; 
RUN; 


* Create elig by year table; 
PROC SQL;
CREATE TABLE int.elig1622 AS 
SELECT mcaid_id
     , max(case WHEN FY=2016 THEN 1 ELSE 0 end) AS elig_2016
     , max(case WHEN FY=2017 THEN 1 ELSE 0 end) AS elig_2017
     , max(case WHEN FY=2018 THEN 1 ELSE 0 end) AS elig_2018
     , max(case WHEN FY=2019 THEN 1 ELSE 0 end) AS elig_2019
     , max(case WHEN FY=2020 THEN 1 ELSE 0 end) AS elig_2020
     , max(case WHEN FY=2021 THEN 1 ELSE 0 end) AS elig_2021
FROM elig1622
GROUP BY mcaid_id;
QUIT;

