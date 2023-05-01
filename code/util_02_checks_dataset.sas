* Check id counts ; 
%macro count_ids_memlist_final;
  PROC SQL; 
  SELECT count(distinct mcaid_id)
  FROM int.memlist_final;
  QUIT; 
%mend;

   %count_ids_memlist_final; *4/27 final run still got 1593591 ;

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
