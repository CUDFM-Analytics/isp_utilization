*
AUTHOR   : KTW
PROJECT  : ISP Utilization Analysis
PURPOSE  : INCLUDE file that:
            1) extracts unique county, budget_group, and rae_id's from qrylong file,
            2) selects max value when n=2 per quarter or most recent when n=1 and k>1 per quarter
            3) Checks that there are no mcaid_id's with >12 records (macro %check_ids_n12)
VERSION  : 2023-04-26
DEPENDS  : RAW.MEMLIST0 
EXPORTS  : work.budget
           work.rae
           work.county
           macro results (#3 above)

*Get MAX COUNTY (there were duplicates where member had > 1 county per quarter) ; 
* 4/26; 
PROC SQL; 
CREATE TABLE county AS
SELECT mcaid_id 
     , dt_qrtr
     , enr_cnty
     , time
FROM (SELECT *
           , max(month) AS max_mon_by_cnty 
      FROM (SELECT *
                 , count(enr_cnty) as n_county 
            FROM raw.memlist0
            GROUP BY mcaid_id 
                   , dt_qrtr
                   , enr_cnty) 
      GROUP BY mcaid_id, dt_qrtr, n_county)  
GROUP BY mcaid_id, dt_qrtr
HAVING max(n_county)=n_county
AND    month=max_mon_by_cnty;
QUIT; * 4/24 14039876; 

* 4/26; 
PROC SQL; 
CREATE TABLE budget AS
SELECT mcaid_id
     , dt_qrtr
     , budget_group
     , time
FROM (SELECT *
           , max(month) AS max_mon_by_budget
      FROM (SELECT *
                 , count(budget_group) as n_budget_group 
            FROM raw.memlist0
            GROUP BY mcaid_id 
                   , dt_qrtr
                   , budget_group) 
      GROUP BY mcaid_id, dt_qrtr, n_budget_group)  
GROUP BY mcaid_id, dt_qrtr
HAVING max(n_budget_group)=n_budget_group
AND    month=max_mon_by_budget;
QUIT; *14039876; 

* 4/26; 
PROC SQL; 
CREATE TABLE rae AS
SELECT mcaid_id
     , dt_qrtr
     , rae_person_new
     , time
FROM (SELECT *
           , max(month) AS max_mon_by_rae
      FROM (SELECT *
                 , count(rae_person_new) as n_rae_person_new 
            FROM raw.memlist0
            GROUP BY mcaid_id 
                   , dt_qrtr
                   , rae_person_new) 
      GROUP BY mcaid_id, dt_qrtr, n_rae_person_new)  
GROUP BY mcaid_id, dt_qrtr
HAVING max(n_rae_person_new)=n_rae_person_new
AND    month=max_mon_by_rae;
QUIT; *14039876; 

            *macro to find instances where n_ids >12 (should be 0 // in 00_config); 
            %check_ids_n12(ds=budget); *0;
            %check_ids_n12(ds=county); *0;
            %check_ids_n12(ds=rae);    *0;
