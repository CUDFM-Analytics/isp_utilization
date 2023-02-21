
******************************************************
Create member list from qrylong_y15_22
******************************************************;

PROC SORT 
DATA  = data.qrylong_y15_22 ( keep= mcaid_id month pcmp_loc_ID ) NODUPKEY
OUT   = memlist_0; 
WHERE pcmp_loc_ID ne ' ' 
AND   month ge '01Jul2019'd 
AND   month le '30Jun2022'd;
BY    mcaid_id; 
RUN; *1594348;

* create a numeric pcmp id, but keep the char one in case; 
DATA memlist_1;
SET  memlist_0;
id_pcmp = input(pcmp_loc_id, 12.);
RUN; 

* Apply Time-Varying Covariate: Identifying member attribution to an ISP prac for analysis on: 
•   memlist_0$month >= isp$dt_prac_isp
•   isp_keys$id_pcmp == memlist_0$pcmp_loc_id
I used all of a because didn't know if a.* would work with the ind_ var new;

proc sort data = memlist_1; by id_pcmp ; 
proc sort data = data.isp_key ; by id_pcmp ; run; 

PROC SQL;
CREATE TABLE memlist_2 AS 
    SELECT a.*
         , b.id_split
         , b.dt_prac_isp
         , b.id_pcmp
FROM memlist_1 as a
LEFT JOIN data.isp_key as b
ON a.id_pcmp = b.id_pcmp;
QUIT; *1594687, 6;

PROC SORT DATA = memlist_2 NODUPKEY ; BY _ALL_    ; RUN; * no duplicates so why did it add records? ;
PROC SORT DATA = memlist_2          ; BY mcaid_id ; RUN; * no duplicates so why did it add records? ;

PROC PRINT DATA = memlist_2 (OBS = 10000) ; RUN; 

* format date so it'll match format and you can join; 
DATA memlist_3;
SET  memlist_2;
dt_prac_isp2 = input(dt_prac_isp, date9.);
FORMAT dt_prac_isp2 date9.;
DROP   dt_prac_isp;
RENAME dt_prac_isp2 = dt_prac_isp;
RUN; 

PROC CONTENTS 
     DATA = memlist_3 VARNUM;
RUN;

proc print data = memlist_3 (obs = 5000); run;

* ==== CREATE TIME-VARYING COVARIATE for ISP MEMBERSHIP ============;
* if we don't filter `id_split = .` then we'll get all months that are > than dt_prac_isp as ind_isp = 1;
DATA data.memlist;
SET  memlist_3; 
IF   id_split ne . and month >= dt_prac_isp then ind_isp = 1;
ELSE ind_isp = 0; 
RUN;

proc sort data = data.memlist ; by mcaid_id month ; run; 

PROC PRINT DATA = data.memlist (OBS = 10000) ;  RUN;  
