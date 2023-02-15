

DATA qry_bho_monthlyutil_working; SET ana.qry_bho_monthlyutil_working; RUN; *02/09/23 [   6,405,694  :  7];

******************************************************
Get BHO
******************************************************;
*convert to a month; 
DATA bho_0;
SET  qry_bho_monthlyutil_working;
month2 = month;
FORMAT month2 date9.;
DROP   month;
RENAME month2 = month; 
run; 

* subset 2015 - 2022; 
DATA   bho_1  ; 
SET    bho_0 ( DROP = bho_n_hosp ) ; 
WHERE  month ge '01Jul2015'd 
AND    month le '30Jun2022'd;
RUN; *NOTE: The data set WORK.BHO_1 has 4767794 observations and 4 variables.;

* sum by month ; 
PROC SQL; 
 CREATE TABLE data.bho_fy15_22 AS
 SELECT MCAID_ID
      , month
      , sum(bho_n_er    ) as bh_n_er
      , sum(bho_n_other ) as bh_n_other
from bho_1
group by MCAID_ID, month;
quit; 
