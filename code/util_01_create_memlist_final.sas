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

format dt_qrtr date9.; * create quarter beginning date to get quarters ; 
dt_qrtr = intnx('quarter', month ,0,'b'); 

WHERE  month ge '01Jul2016'd 
AND    month le '30Jun2022'd 
AND    BUDGET_GROUP not in (16,17,18,19,20,21,22,23,24,25,26,27,-1,)
AND    managedCare = 0
AND    pcmp_loc_id ne ' '
;
RUN;  * 4/26 85514116 : 10;

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

RUN; *1pm 4/27 70204806 : 11;

* Create time variable from dt_qrtr (or month, but dt_qrtr faster bc same); 
%create_qrtr(data=raw.qrylong2, set=raw.qrylong2, var= dt_qrtr, qrtr=time);

DATA  raw.memlist0 (drop = month dt_qrtr); 
SET   raw.qrylong2 (WHERE=(rae_person_new ne . AND FY in (2019,2020,2021) AND SEX IN ('F','M')));
RUN ;  *4/24 memlist 40958510;

%sort4merge(ds1=raw.memlist0, ds2=raw.qrylong2, by=mcaid_id);

* Keep only columns indicating eligibility // rest are now in from memlist and only need 19-21 values; 
DATA  qrylong1622 (keep= mcaid_id FY time); 
MERGE raw.qrylong2 (in=a) raw.memlist0 (in=b KEEP=mcaid_id) ; 
BY    mcaid_id; 
IF    b; 
RUN ; *65420507: 11; 

%nodupkey(ds=qrylong1622, out=int.qrylong1622); *16485317 w 3 variables

*** ASSERT STATEMENT QRYLONG1622: COUNT of id's for qrylong shouldn't be > 15... ;
 %macro check_ids_n15;
            proc sql; 
            create table n_qrylong1622 AS 
            select mcaid_id
                 , count(mcaid_id) as n_ids
            FROM int.qrylong1622
            GROUP BY mcaid_ID
            having n_ids>15;
            quit; 
 %mend;

 %check_ids_n15; * 0 ROWS!!; 

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

******************************************************************************************************
*** CREATE raw.pcmp_type with var: FQHC (0,1)
    GET pcmp type reference table from unique ID's in qrylong0 to capture all possible, 
        then left join to memlist 
******************************************************************************************************;

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

******************************************************************************************************
*** CREATE int.memlist_final
    JOINS, Unique values, save as int.
******************************************************************************************************;

PROC SQL ; 
CREATE TABLE memlist_final AS 
SELECT a.mcaid_id
     , a.FY
     , a.age
     , a.race
     , a.sex
     , a.time
     , a.id_time_helper

     , b.pcmp_loc_id 
     , b.n_months_per_q
     , b.ind_isp AS int

     , c.budget_group
     , d.enr_cnty
     , e.rae_person_new
     , f.fqhc

     , g.time2 as time_start_isp
     , case WHEN g.time2 ne . 
            AND  a.time >= g.time2
            THEN 1 ELSE 0 end AS int_imp

FROM raw.memlist2                    AS A
LEFT JOIN int.memlist_attr_qrtr_1921 AS B   ON A.id_time_helper = B.id_time_helper
LEFT JOIN budget                     AS C   ON A.id_time_helper = C.id_time_helper
LEFT JOIN county                     AS D   ON A.id_time_helper = D.id_time_helper
LEFT JOIN rae                        AS E   ON A.id_time_helper = E.id_time_helper
LEFT JOIN raw.pcmp_type              AS F   ON B.pcmp_loc_id    = F.pcmp_loc_id   
LEFT JOIN int.isp_un_pcmp_dtstart    AS G   ON b.pcmp_loc_id    = G.pcmp_loc_id    ;
QUIT ; *4/27 14273091 WHY??   4/23 14039876!!! WOOT!! (twice, and second time with the joins) //  4097481 : 12 ; 

* PROBLEM : FIX LATER - 27 that are missing. Create qrylong4 where pcmp_ not ne, 
              but come back to qrylong3 when get logic right; 
DATA  int.memlist_final;
SET   memlist_final   (DROP=time_start_isp WHERE=(pcmp_loc_id ne .)); *FIX THIS LATER!!; 
LABEL pcmp_loc_id     = "PCMP_LOC_ID: src int.memlist_attr_qrtr_1921"
      FY              = "FY: 19, 20, 21"
      age             = "Age: 0-64 only"
      sex             = "Sex"
      time            = "Linearized qrtrs, 1-12"
      id_time_helper  = "interim var for matching"
      n_months_per_q  = "months per quarter, int.memlist_attr_qrtr_1921"
      int             = "ISP Participation: Time Invariant"
      budget_group    = "Budget Group (subsetting var)"
      enr_cnty        = "County (src: qry_longitudinal)"
      rae_person_new  = "RAE ID"
      fqhc            = "FQHC: 0 No, 1 Yes"
      int_imp         = "ISP Participation: Time-Varying"
      ;
RUN; * 14273063 : 17; 

%nodupkey(int.memlist_final, int.memlist_final); *14039776;

        %macro count_ids_memlist_final;
            PROC SQL; 
            SELECT count(distinct mcaid_id)
            FROM int.memlist_final;
            QUIT; 
        %mend;

        %count_ids_memlist_final; *4/27 later  got 1593591 // 4/27am still got 1593607... ;

        %macro check_memlist_final;
            proc sql; 
            create table n_ids_memlist AS 
            select mcaid_id
                 , time
                 , count(mcaid_id) as n_ids
                 , count(time) as n_time
            FROM int.memlist_final
            GROUP BY mcaid_ID
            having n_ids>12 ;
            quit; 
        %mend;

        %check_memlist_final; *0;



******************************************************************************************************
*** FIND ISSUES where pcmp wasn't on attr file; 
******************************************************************************************************;

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

PROC FREQ DATA = int.memlist_final;
WHERE  pcmp_loc_id = . ; 
TABLES mcaid_id / OUT = raw.memlist_pcmp_missing; 
RUN; 

******************************************************************************************************
*** EXPORT PDF FREQUENCIES; 
******************************************************************************************************;

ODS PDF FILE = "&report/eda_memlist_final_20230427.pdf";

%LET memlist = int.memlist_final; 
%LET qrylong = int.qrylong1622; 

PROC CONTENTS DATA = &memlist VARNUM; RUN; 

PROC FREQ DATA = &memlist; 
TABLES FY age race sex time n_months_per_q int int_imp fqhc; 
RUN; 

ods text = "Frequencies for categorical variables by Intervention (non-varying)" ; 

TITLE "Unique Member Count, Final Dataset"; 
PROC SQL ; 
SELECT COUNT (DISTINCT mcaid_id ) 
FROM &memlist ; 
QUIT ; 

Title "Unique PCMP count by Intervention Status (Non-Varying)"; 
PROC SQL ; 
SELECT COUNT(DISTINCT pcmp_loc_id) as n_pcmp
     , int as intervention
FROM &memlist
GROUP BY int;
QUIT; 
TITLE ; 

PROC FREQ DATA = &memlist ; 
TABLES (FY age race sex time n_months_per_q int int_imp fqhc)*int; 
RUN ;   

TITLE "Max Time by Member" ;
PROC SQL ; 
CREATE TABLE data._max_time AS 
SELECT mcaid_id
     , MAX (time) as time
     , MAX (int) as intervention
FROM &memlist
GROUP BY mcaid_id ; 
QUIT; 

Title "Time Frequency by Member" ; 
PROC FREQ DATA = data._max_time ; 
tables time / nopercent norow; 
RUN; 

Title "Time Frequency by Member, Intervention (non-varying)"; 
PROC FREQ DATA = data._max_time ; 
tables time*intervention / plots = freqplot(type=dot scale=percent) nopercent norow; 
RUN; 

PROC FREQ DATA = &memlist; 
TABLES (ind_:)*int ; 
TITLE "Indicator DVs by Intervention" ; 
TITLE2 "If DV eq 0 then indicator = 0, > 0 then indicator = 1";
format ind: comma20. ; 
RUN ; 
TITLE ; 
TITLE2; 

ods pdf text = "int.QRYLONG1622";

PROC CONTENTS DATA = &qrylong; RUN; 

PROC FREQ DATA = &qrylong;
TABLES time FY; 
RUN;

ODS PDF CLOSE; 
