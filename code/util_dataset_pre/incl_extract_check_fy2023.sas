*
AUTHOR   : KTW
PROJECT  : ISP Utilization Analysis
PURPOSE  : INCLUDE file that:
            1) extracts unique pcmp_loc_id, budget_group, and rae_id's from qrylong file,
            2) selects max value when n=2 per quarter or most recent when n=1 and k>1 per quarter
VERSION  : 2023-05-30
DEPENDS  : raw.final00 
EXPORTS  : work.budget
           work.rae
           int.pcmp_attr_qrtr;  

%macro demo(var=, ds=);
PROC SQL; 
CREATE TABLE &var AS
SELECT mcaid_id 
     , dt_qrtr
     , &var
     , time
     , CATX('_', mcaid_id, time) AS id_time_helper
FROM (SELECT *
           , max(month) AS max_month
      FROM (SELECT *
                 , count(&var) as n_&var
            FROM &ds
            GROUP BY mcaid_id 
                   , dt_qrtr
                   , &var) 
      GROUP BY mcaid_id, dt_qrtr, n_&var)  
GROUP BY mcaid_id, dt_qrtr
HAVING max(n_&var)=n_&var
AND    month=max_month;
QUIT;  
%mend;

PROC SQL; 
CREATE TABLE data.pcmp_attr_qrtr AS
SELECT mcaid_id 
     , dt_qrtr
     , pcmp_loc_id
     , time
     , CATX('_', mcaid_id, time) AS id_time_helper
     , pcmp_loc_id IN (SELECT pcmp_loc_id FROM int.isp_un_pcmp_dtstart) as int
FROM (SELECT *
           , max(month) AS max_month_by_pcmp
      FROM (SELECT *
                 , count(pcmp_loc_id) as n_pcmp
            FROM &ds
            GROUP BY mcaid_id 
                   , dt_qrtr
                   , pcmp_loc_id) 
      GROUP BY mcaid_id, dt_qrtr, n_pcmp)  
GROUP BY mcaid_id, dt_qrtr
HAVING max(n_pcmp)=n_pcmp
AND    month=max_month_by_pcmp;
QUIT; * ; 



