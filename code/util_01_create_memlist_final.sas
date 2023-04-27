*
AUTHOR   : KTW
PROJECT  : ISP Utilization Analysis
PURPOSE  : Gather, Process datasets from analytic subset dir
VERSION  : 2023-04-24 somehow had >1 mcaid_id from budget group_new idk [date last updated]
DEPENDS  : ana subset folder, config file [dependencies]
NEXT     : [left off on row... or what step to do next... ]  ;

%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 
***********************************************************************************************;
%LET raw = &data/_raw;
LIBNAME raw "&raw";
* ==== SECTION01 ==============================================================================

* copy datasets from ana.;
/*PROC CONTENTS DATA = ana.qry_demographics VARNUM ; RUN ; */
/*DATA qry_longitudinal;            SET ana.qry_longitudinal;            RUN; *02/09/23 [1,177,273,652 : 25];*/
/*DATA qry_demographics;            SET ana.qry_demographics;            RUN; *02/09/23 [  3008709     :  7];*/

* **B** subset qrylong to dates within FY's and get var's needed ;  
DATA   raw.qrylong0;
LENGTH mcaid_id $11; 
SET    ana.qry_longitudinal ( DROP = FED_POV: 
                                     DISBLD_IND 
                                     aid_cd:
                                     title19: 
                                     SPLM_SCRTY_INCM_IND
                                     SSI_: 
                                     SS: 
                                     dual
                                     eligGrp
                                     fost_aid_cd
                              ) ; 
* Recode pcmp loc type with format above; 
num_pcmp_type = input(pcmp_loc_type_cd, 7.);
/*pcmp_type     = put(num_pcmp_type, pcmp_type_rc.);     */

format dt_qrtr date9.; * create quarter beginning date to get quarters ; 
dt_qrtr = intnx('quarter', month ,0,'b'); 

WHERE  month ge '01Jul2016'd 
AND    month le '30Jun2022'd 
AND    BUDGET_GROUP not in (16,17,18,19,20,21,22,23,24,25,26,27,-1,)
AND    managedCare = 0
AND    pcmp_loc_id ne ' '
;
RUN;  * 4/26 85514116 : 10;

    ** Set aside pcmp type for now - match it later ; 
    DATA pcmp_type_qrylong ; 
    SET  raw.qrylong0 (KEEP = pcmp_loc_id pcmp_loc_type_cd num_pcmp_type pcmp_loc_type_cd 
                        WHERE = (pcmp_loc_id ne '')) ; 
    pcmp_loc2 = input(pcmp_loc_id, best12.);
    drop pcmp_loc_id;
    rename pcmp_loc2=pcmp_loc_id;
    RUN ; 
    PROC SORT DATA = pcmp_type_qrylong NODUPKEY ; BY _ALL_ ; RUN ; *4/26 1446 obs;

    DATA raw.pcmp_type;
    SET  pcmp_type_qrylong;
    IF pcmp_loc_type_cd in (32 45 61 62) then fqhc = 1 ; else fqhc = 0 ;
    RUN; 

** join with demographics to get required demographics in all years ; 
PROC SQL; 
CREATE TABLE raw.qrylong1 AS
SELECT a.mcaid_id
     , a.pcmp_loc_id
     , a.month
     , a.enr_cnty
     , a.budget_group
     , a.dt_qrtr 
     , b.dob
     , b.gender as sex
     , b.race
     , c.rae_id as rae_person_new
FROM   raw.qrylong0 AS a 
LEFT JOIN ana.qry_demographics AS B ON a.mcaid_id=b.mcaid_id 
LEFT JOIN int.rae              AS C ON a.enr_cnty = c.hcpf_county_code_c
WHERE  pcmp_loc_id ne ' ';
QUIT;   *4-26 72854378 rows and 10 columns ;
 
DATA raw.qrylong2 (DROP = last_day_fy dob rename=(age_end_fy=age)); 
SET  raw.qrylong1;
WHERE SEX IN ('F','M');

FORMAT last_day_fy date9.;
FY  = year(intnx('year.7', month, 0, 'BEGINNING'));
IF      month ge '01Jul2016'd AND month le '30Jun2017'd THEN last_day_fy='30Jun2017'd;
ELSE IF month ge '01Jul2017'd AND month le '30Jun2018'd THEN last_day_fy='30Jun2018'd;
ELSE IF month ge '01Jul2018'd AND month le '30Jun2019'd THEN last_day_fy='30Jun2019'd;
ELSE IF month ge '01Jul2019'd AND month le '30Jun2020'd THEN last_day_fy='30Jun2020'd;
ELSE IF month ge '01Jul2020'd AND month le '30Jun2021'd THEN last_day_fy='30Jun2021'd;
ELSE IF month ge '01Jul2021'd AND month le '30Jun2022'd THEN last_day_fy='30Jun2022'd;
age_end_fy = floor((intck('month', dob, last_day_fy) - (day(last_day_fy) < min(day(dob), day(intnx ('month', last_day_fy, 1) -1)))) /12 );
IF age_end_fy lt 0 or age_end_fy gt 64 THEN delete;

PCMP2 = input(pcmp_loc_id, best12.);
drop pcmp_loc_id; 
rename pcmp2 = pcmp_loc_id; 

RUN; *70204416 : 11;

* Create time variable from dt_qrtr (or month, but dt_qrtr faster bc same); 
%create_qrtr(data=raw.qrylong2, set=raw.qrylong2, var= dt_qrtr, qrtr=time);

DATA  raw.memlist0; 
SET   raw.qrylong2 (WHERE=(rae_person_new ne . AND FY in (2019,2020,2021)));
RUN ;  *4/24 memlist 40958510;

%sort4merge(ds1=raw.memlist0, ds2=raw.qrylong2, by=mcaid_id);

DATA  raw.qrylong3 ; 
MERGE raw.qrylong2 (in=a) raw.memlist0 (in=b KEEP=mcaid_id) ; 
BY    mcaid_id; 
IF    b; 
RUN ; *65420507: 11; 

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
            %check_n_id(ds=budget); *0;
            %check_n_id(ds=county); *0;
            %check_n_id(ds=rae);    *0;

            
%macro concat_id_time(ds=);
DATA &ds;
SET  &ds;
id_time_helper = CATX('_', mcaid_id, time); 
RUN; 
%mend; 
* Created helper var for joins (was taking a long time and creating rows without id, idk why, so did this as quick fix for now); 
%concat_id_time(ds=county);
%concat_id_time(ds=budget);
%concat_id_time(ds=rae);
%concat_id_time(ds=int.memlist_attr_qrtr_1921);

* NOW you can remove the values that were creating duplicates (budget, rae, enr_cnty) and merge the unique ones below after
creating a helper matching function; 

        %macro check_memlist_ids;
            proc sql; 
            create table n_ids_memlist AS 
            select mcaid_id
                 , count(mcaid_id) as n_ids
            FROM raw.memlist0
            GROUP BY mcaid_ID
            having n_ids>12;
            quit; 
        %mend;

        %check_memlist_ids; *1251533 rows so a lot had duplicates due to month of course but also budget group and county 
        (some had >1 per quarter for these variables
        pcmp_loc_id is in memlist_attr_qrtr); 

DATA raw.memlist1;
SET  raw.memlist0 (drop=month dt_qrtr enr_cnty rae_person_new budget_group rename=(pcmp_loc_id=pcmp_og_qrylong));
RUN; *4/27 40958510 : 11; 

PROC SORT DATA = raw.memlist1 NODUPKEY OUT = raw.memlist2; 
BY _ALL_; 
RUN; *4/27 14273091 : 7;

%concat_id_time(ds=raw.memlist2);

* LAST UPDATED 4/26 (all above to here)
JOIN memlist with memlist_attr for pcmps for mcaid_ids in memlist (keep memlist mcaid_ids);
PROC SQL ; 
CREATE TABLE memlist_final AS 
SELECT a.mcaid_id
     , a.FY
     , a.age
     , a.race
     , a.sex
     , a.time
     , a.id_time_helper
     , a.pcmp_og_qrylong
     , a.id_time_helper

     , b.pcmp_loc_id 
     , b.n_months_per_q
     , b.ind_isp AS int

     , c.budget_group
     , d.enr_cnty
     , e.rae_person_new
     , f.fqhc

FROM raw.memlist2                    AS A
LEFT JOIN int.memlist_attr_qrtr_1921 AS B   ON A.id_time_helper = B.id_time_helper
LEFT JOIN budget                     AS C   ON A.id_time_helper = C.id_time_helper
LEFT JOIN county                     AS D   ON A.id_time_helper = D.id_time_helper
LEFT JOIN rae                        AS E   ON A.id_time_helper = E.id_time_helper
LEFT JOIN raw.pcmp_type              AS F   ON B.pcmp_loc_id    = F.pcmp_loc_id   ;
QUIT ; *4/27 14274091 WHY??   4/23 14039876!!! WOOT!! (twice, and second time with the joins) //  4097481 : 12 ; 


        %macro count_ids_memlist_final;
            PROC SQL; 
            SELECT count(distinct mcaid_id)
            FROM int.memlist_final;
            QUIT; 
        %mend;

        %count_ids_memlist_final; *4/27 still got 1593607... ;

******************************************************************************************************
*** PROBLEM : FIX LATER - 27 that are missing. Create qrylong4 where pcmp_ not ne, 
        but come back to qrylong3 when get logic right; 
******************************************************************************************************;
DATA int.memlist_final;
SET  memlist_final (where=(pcmp_loc_id ne .));
RUN; 

DATA int.qrylong1622; 
SET  raw.qrylong3 (where=(pcmp_loc_id ne .)); 
RUN; 

DATA raw.memlist_pcmp_missing;
SET  int.memlist_final ; 
where pcmp_loc_id = . ; 
RUN; 

%sort4merge(ds1=raw.qrylong4, ds2=raw.memlist_pcmp_missing, by=mcaid_id);

DATA raw.memlist_pcmp_find; 
SET  raw.qrylong4 (in=a) raw.memlist_pcmp_missing (in=b);
by   mcaid_id;
IF   a and b;
RUN; 

PROC FREQ data = int.memlist_final;
where pcmp_loc_id = . ; 
tables mcaid_id /out = raw.memlist_pcmp_missing; 
run; 

      
