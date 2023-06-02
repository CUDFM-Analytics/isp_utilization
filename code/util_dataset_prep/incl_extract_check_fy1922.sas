*
AUTHOR   : KTW
PROJECT  : ISP Utilization Analysis
PURPOSE  : INCLUDE file that:
            1) extracts unique pcmp_loc_id, budget_group, and rae_id's from qrylong file,
            2) selects max value when n=2 per quarter or most recent when n=1 and k>1 per quarter
            3) Checks that there are no mcaid_id's with >12 records (macro %check_ids_n12)
VERSION  : 2023-05-30
DEPENDS  : raw.final00 
EXPORTS  : work.budget
           work.rae
           int.pcmp_attr_qrtr
           macro results (#3 above)

*Get MAX or most recent PCMP (in case of ties) (there were duplicates where member had > 1 pcmp per quarter) ; 
* 4/26; 
* Get months per quarter: ;
PROC SQL; 
CREATE TABLE int.n_id_months_per_q AS 
SELECT mcaid_id
     , dt_qrtr
     , time
     , count(dt_qrtr) as n_months_per_q
FROM raw.final00
GROUP BY mcaid_id, dt_qrtr, time;
QUIT; 

PROC SQL; 
CREATE TABLE int.pcmp_attr_qrtr AS
SELECT mcaid_id 
     , dt_qrtr
     , pcmp_loc_id
     , time
     , pcmp_loc_id IN (SELECT pcmp_loc_id FROM int.isp_un_pcmp_dtstart) as int
FROM (SELECT *
           , max(month) AS max_month_by_pcmp
      FROM (SELECT *
                 , count(pcmp_loc_id) as n_pcmp
            FROM raw.final00
            GROUP BY mcaid_id 
                   , dt_qrtr
                   , pcmp_loc_id) 
      GROUP BY mcaid_id, dt_qrtr, n_pcmp)  
GROUP BY mcaid_id, dt_qrtr
HAVING max(n_pcmp)=n_pcmp
AND    month=max_month_by_pcmp;
QUIT; * ; 

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
            FROM raw.final00
            GROUP BY mcaid_id 
                   , dt_qrtr
                   , budget_group) 
      GROUP BY mcaid_id, dt_qrtr, n_budget_group)  
GROUP BY mcaid_id, dt_qrtr
HAVING max(n_budget_group)=n_budget_group
AND    month=max_mon_by_budget;
QUIT; *; 

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
            FROM raw.final00
            GROUP BY mcaid_id 
                   , dt_qrtr
                   , rae_person_new) 
      GROUP BY mcaid_id, dt_qrtr, n_rae_person_new)  
GROUP BY mcaid_id, dt_qrtr
HAVING max(n_rae_person_new)=n_rae_person_new
AND    month=max_mon_by_rae;
QUIT; *; 

            *macro to find instances where n_ids >12 (should be 0 // in 00_config); 
            %check_ids_n13(ds=budget); *0;
            %check_ids_n13(ds=rae);    *0;
