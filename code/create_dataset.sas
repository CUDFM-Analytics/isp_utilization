*
AUTHOR   : KTW
PROJECT  : ISP Utilization Analysis
PURPOSE  : Gather, Process datasets from analytic subset dir, Create final analysis dataset and mini dataset
VERSION  : 2023-10-18 Get updated datasets, up to and including June 2023 (less than July 01, 2023)
            - 10-18 Details: Updated raw.time_dim to include q's through 16
            - 09-08 manually renamed data.analysis as data.analysis_prev, created minimized length data.utilization look for #UPDATE[09-08-2023] approx row 948
            - 06-06 to check on the BH's: added total var maybe some are wrong as I'm still getting Hessian errors
            - 06-05 to combine bh cat variables into 1 bh cat var
            - 06-02 bc ana.long & ana.demo were missing months
            - 05-30 due to issues in the hcpf file and to get Sept 2022 since it's available now (cs email re: hcpf)

DEPENDS  : -ana subset folder, config file, 
           -%include helper file in code/util_dataset_prep/incl_extract_check_fy19210.sas
           -other macro code referenced is stored in the util_00_config.sas file
OUTPUT
SECTION1 : data.analysis
SECTION2 : data.analysis_allcols
SECTION3 : data.mini_ds (test set with only 500000 records) 

SEE excel file with comparison outcomes / results/ nobs analytic_ds_previous_results.xlsx (or something);

%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/config.sas"; 

* [RAW.time_dim] 10-17-2023 ===============================================================
NB: Update might be needed (last updated to include through June 2023 / FYQ4 2023
Import a .csv file I made with months, FY, FY quarters, and the linearized time var
===========================================================================================;
PROC IMPORT FILE="&util./data/_raw/fy_q_dts_dim.csv"
    OUT = raw.time_dim
    DBMS=csv
    REPLACE;
run; 

* [QRYLONG_00] ==============================================================================
1. SUBSET qry_longitudinal to timeframe (months le/ge) AND:
   -- budget_groups
   -- sex not Unknown
   -- pcmp_loc_id not missing
   -- managedCare not 0
   NB: Can't subset to records with an RAE yet since that would exclude FY16-18 records
2. Create dt_qrtr: the first month of the quarter that the record was in
===========================================================================================;
DATA   int.qrylong_00 (DROP=managedCare);
LENGTH mcaid_id $11; 
SET    ana.qry_longitudinal (WHERE=(month ge '01Jul2016'd AND month lt '01Jul2023'd
                                    AND BUDGET_GROUP not in (16,17,18,19,20,21,22,23,24,25,26,27,-1,)
                                    AND managedCare = 0
                                    AND pcmp_loc_id ne ' ') 
                             DROP = FED_POV: DISBLD_IND aid_cd: title19: SPLM_SCRTY_INCM_IND
                                    SSI_: SS: dual eligGrp fost_aid_cd) ;  
format dt_qrtr date9.; 
dt_qrtr = intnx('quarter', month ,0,'b'); 
FY      = year(intnx('year.7', month, 0, 'BEGINNING'));
PCMP2   = input(pcmp_loc_id, best12.); DROP pcmp_loc_id; RENAME pcmp2 = pcmp_loc_id; 
RUN; 

* INT.PCMP_DIM ==============================================================================
DESCR: Extract unique pcmp_loc_ids and their dimensions, stored as a reference table, that:
1. Reduces qrylong for interim processing steps,
2. Reduces pcmp_loc_ids to unique records for faster calculations:
    2a: convert pcmp_loc_id to numeric
3. Create binary covariate FQHC from pcmp_loc_type_cd values (rather than formats) 
===========================================================================================;
DATA pcmp_type_qrylong ; 
SET  int.qrylong_00   (KEEP = pcmp_loc_id  pcmp_loc_type_cd pcmp_loc_type_cd 
                       WHERE= (pcmp_loc_id ne .));
num_pcmp_type = input(pcmp_loc_type_cd, 7.);
RUN ; 

PROC SORT DATA = pcmp_type_qrylong NODUPKEY ; BY _ALL_ ; RUN ; 

DATA int.pcmp_dim;
SET  pcmp_type_qrylong;
IF pcmp_loc_type_cd in (32 45 61 62) then fqhc = 1 ; else fqhc = 0 ;
RUN; 

* [int.qrylong_01]======================================================================
Joins ana.qry_demographics, raw.age_dim, and rae_dim
Purpose:
1. Get rae_person_new on enr_county (from qrylong)
2. Demographic vars: dob(for calculating age/subsetting members 0-64), gender, race
3. Subset sex M, F
4. Get dob to calculate ages (subsetting var)
===========================================================================================;
PROC SQL; 
CREATE TABLE int.qrylong_01 AS
SELECT a.mcaid_id
     , a.pcmp_loc_id
     , a.month
     , a.enr_cnty
     , a.budget_group
     , a.dt_qrtr 
     , a.FY
     , b.dob
     , b.gender as sex
     , b.race
     , c.rae_id as rae_person_new
     , d.time
     , d.fy_qrtr
FROM int.qrylong_00             AS A 
LEFT JOIN ana.qry_demographics  AS B ON a.mcaid_id = b.mcaid_id 
LEFT JOIN int.rae_dim           AS C ON a.enr_cnty = c.hcpf_county_code_c
LEFT JOIN raw.time_dim          AS D on a.dt_qrtr  = d.month
WHERE  pcmp_loc_id ne .
AND    SEX IN ('F','M');
QUIT;   *06-07 75690836 : 10 cols;

* [RAW.AGE_DIM] ==============================================================================
Extract dob to get age as of the 2nd month in each quarter
1. Used in subsetting dataset
2. Used to create age_cat
Will have to inner join these variables on qrylong eventually unless you subset it by this earlier
===========================================================================================;
* Get distinct mcaid_id and dob;
PROC SQL;
CREATE TABLE raw.age_dim_00 AS 
SELECT distinct(mcaid_id) as mcaid_id
     , dob
     , time
FROM int.qrylong_01
WHERE FY in (2019, 2020, 2021, 2022)
AND   rae_person_new ne .;
QUIT; * 6/7 15719759 obs 2 col; 

* Find / List all 13 2nd month of quarter values; 
PROC SQL NOPRINT;
SELECT month INTO :qm2 separated by ' '
FROM  raw.time_dim
WHERE month_qrtr = 2;
QUIT; 

%PUT &qm2;
* I could not for the life of me find a way to do this from the macro values and had to get moving but I'm sure there's a better way to do this? ;
%LET m2q1  = 01Aug2019; %LET m2q2  = 01Nov2019; %LET m2q3  = 01Feb2020; %LET m2q4  = 01May2020;
%LET m2q5  = 01Aug2020; %LET m2q6  = 01Nov2020; %LET m2q7  = 01Feb2021; %LET m2q8  = 01May2021;
%LET m2q9  = 01Aug2021; %LET m2q10 = 01Nov2021; %LET m2q11 = 01Feb2022; %LET m2q12 = 01May2022;
%LET m2q13 = 01Aug2022; %LET m2q14 = 01Nov2022; %LET m2q15 = 01Feb2023; %LET m2q16 = 01May2023;
 
DATA raw.age_dim_01;
SET  raw.age_dim_00 (where=(time ne .));
IF time = 1 then do;  age = floor((intck('month', dob, "&m2q1"d)-(day("&m2q1"d)   < min(day(dob), day(intnx('month', "&m2q1"d, 1) -1))))  /12); END;
IF time = 2 then do;  age = floor((intck('month', dob, "&m2q2"d)-(day("&m2q2"d)   < min(day(dob), day(intnx('month', "&m2q2"d, 1) -1))))  /12); END;
IF time = 3 then do;  age = floor((intck('month', dob, "&m2q3"d)-(day("&m2q3"d)   < min(day(dob), day(intnx('month', "&m2q3"d, 1) -1))))  /12); END;
IF time = 4 then do;  age = floor((intck('month', dob, "&m2q4"d)-(day("&m2q4"d)   < min(day(dob), day(intnx('month', "&m2q4"d, 1) -1))))  /12); END;
IF time = 5 then do;  age = floor((intck('month', dob, "&m2q5"d)-(day("&m2q5"d)   < min(day(dob), day(intnx('month', "&m2q5"d, 1) -1))))  /12); END;
IF time = 6 then do;  age = floor((intck('month', dob, "&m2q6"d)-(day("&m2q6"d)   < min(day(dob), day(intnx('month', "&m2q6"d, 1) -1))))  /12); END;
IF time = 7 then do;  age = floor((intck('month', dob, "&m2q7"d)-(day("&m2q7"d)   < min(day(dob), day(intnx('month', "&m2q7"d, 1) -1))))  /12); END;
IF time = 8 then do;  age = floor((intck('month', dob, "&m2q8"d)-(day("&m2q8"d)   < min(day(dob), day(intnx('month', "&m2q8"d, 1) -1))))  /12); END;
IF time = 9 then do;  age = floor((intck('month', dob, "&m2q9"d)-(day("&m2q9"d)   < min(day(dob), day(intnx('month', "&m2q9"d, 1) -1))))  /12); END;
IF time = 10 then do; age = floor((intck('month', dob, "&m2q10"d)-(day("&m2q10"d) < min(day(dob), day(intnx('month', "&m2q10"d, 1) -1)))) /12); END;
IF time = 11 then do; age = floor((intck('month', dob, "&m2q11"d)-(day("&m2q11"d) < min(day(dob), day(intnx('month', "&m2q11"d, 1) -1)))) /12); END;
IF time = 12 then do; age = floor((intck('month', dob, "&m2q12"d)-(day("&m2q12"d) < min(day(dob), day(intnx('month', "&m2q12"d, 1) -1)))) /12); END;
IF time = 13 then do; age = floor((intck('month', dob, "&m2q13"d)-(day("&m2q13"d) < min(day(dob), day(intnx('month', "&m2q13"d, 1) -1)))) /12); END;
IF time = 14 then do; age = floor((intck('month', dob, "&m2q14"d)-(day("&m2q14"d) < min(day(dob), day(intnx('month', "&m2q14"d, 1) -1)))) /12); END;
IF time = 15 then do; age = floor((intck('month', dob, "&m2q15"d)-(day("&m2q15"d) < min(day(dob), day(intnx('month', "&m2q15"d, 1) -1)))) /12); END;
IF time = 16 then do; age = floor((intck('month', dob, "&m2q16"d)-(day("&m2q16"d) < min(day(dob), day(intnx('month', "&m2q16"d, 1) -1)))) /12); END;

IF (0 <= age < 65) then keep = 1;  
ELSE keep =0; 
RUN; 

PROC FREQ DATA = raw.age_dim_01; tables keep; RUN; 

DATA int.age_dim    (DROP=KEEP); 
SET  raw.age_dim_01 (WHERE=(KEEP=1)); 
RUN; 

PROC PRINT DATA = raw.age_dim_01 (obs=100); where age ge 65; run; 
PROC PRINT DATA = raw.age_dim_01 ; where mcaid_id = "A005875"; RUN; 

* [int.final_00] ==============================================================================
Start final list where age in range based on FY's 19-22 and rae_ not missing
===========================================================================================;
PROC SQL;
CREATE TABLE int.final_00 AS 
SELECT a.mcaid_id
     , a.time
     , a.FY
     , a.dt_qrtr
     , a.month
     , a.pcmp_loc_id
     , a.budget_group
     , a.sex
     , a.race
     , a.rae_person_new
     , b.age
FROM int.qrylong_01    AS A 
INNER JOIN int.age_dim AS B ON (a.mcaid_id=b.mcaid_id AND a.time=b.time)
WHERE rae_person_new ne . 
AND FY IN (2019, 2020, 2021, 2022) ;
QUIT;  *see zzz_scratch for unique ID count; 

* [INT.QRYLONG_02] ==============================================================================
Limit ds to members id's found in age_dim
===========================================================================================;
PROC SQL;
CREATE TABLE int.qrylong_02 AS 
SELECT mcaid_id
     , time
     , FY
     , dt_qrtr
     , month
FROM int.qrylong_01
WHERE mcaid_id IN (SELECT mcaid_id FROM int.final_00);
QUIT; * no dupkey checked; 

* [int.final_00] & [RAW.DEMO_1922] =========================================================
Subset to mcaid_id's that have an rae_assigned in FY's 19-22
===========================================================================================;
DATA int.final_01  (KEEP = mcaid_id month dt_qrtr FY time age)
     int.demo      (KEEP = mcaid_id month dt_qrtr FY time sex race rae_person_new pcmp_loc_id budget_group);
SET  int.final_00 ; 
RUN;  
PROC SORT DATA=int.final_01; BY MCAID_ID FY TIME; RUN; 

* %INCLUDE ==============================================================================
Creates table with max months' pcmp. In case of ties, takes most recent 
1. MACRO for other demo vars
2. output: int.pcmp_attr_qrtr
===========================================================================================;
%LET ds = int.demo;
%INCLUDE "&util/code/util_dataset_pre/incl_extract_check_fy1922.sas"; * creates int.pcmp_attr_qrtr too; 
%demo(var=budget_group,   ds=&ds);
%demo(var=rae_person_new, ds=&ds);
%demo(var=sex,            ds=&ds);
%demo(var=race,           ds=&ds);   * all have 15104152 rows; 

*macro to find instances where n_ids >16 (should be 0 // in 00_config) VERY fast!; 
%check_ids_n16(ds=budget_group);      *0;
%check_ids_n16(ds=rae_person_new);    *0;

%macro concat_id_time(ds=);
DATA &ds;
SET  &ds;
id_time_helper = CATX('_', mcaid_id, time); 
RUN; 
%mend; 

* Created helper var for joins (was taking a long time and creating rows without id, 
idk why, so did this as quick fix for now); 
%concat_id_time(ds=int.final_01);
%concat_id_time(ds=int.age_dim);

* int.final_02 ==============================================================================
Joins final_01 with the calculated demo variables as well as int, int_imp
===========================================================================================;
PROC SQL ; 
CREATE TABLE int.final_02 AS 
SELECT a.mcaid_id
     , a.dt_qrtr
     , a.month
     , a.FY
     , a.time
     , a.id_time_helper
     , a.age
     , b.budget_group
     , c.rae_person_new
     , d.pcmp_loc_id
     , d.int
     , e.fqhc
     , f.time2 as time_start_isp
     , case WHEN f.time2 ne . 
            AND  a.time >= f.time2
            THEN 1 ELSE 0 end AS int_imp
     , g.race
     , h.sex
FROM int.final_01                    AS A
LEFT JOIN budget_group               AS B   ON A.id_time_helper = B.id_time_helper
LEFT JOIN rae_person_new             AS C   ON A.id_time_helper = C.id_time_helper
LEFT JOIN int.pcmp_attr_qrtr         AS D   ON A.id_time_helper = D.id_time_helper
LEFT JOIN int.pcmp_dim               AS E   ON D.pcmp_loc_id    = E.pcmp_loc_id   
LEFT JOIN int.isp_un_pcmp_dtstart    AS F   ON D.pcmp_loc_id    = F.pcmp_loc_id    
LEFT JOIN race                       AS G   ON A.id_time_helper = G.id_time_helper
LEFT JOIN sex                        AS H   ON A.id_time_helper = H.id_time_helper;
QUIT ;  

* int.final_03 ==============================================================================
drops some vars no longer needed so you can remove duplicates
===========================================================================================;
DATA  int.final_03;
SET   int.final_02   (DROP=time_start_isp month id_time_helper);
RUN; *44202204 ;

* int.util3  ==============================================================================
Gets utilization dv's
===========================================================================================;
DATA    int.util_0; 
SET     ana.qry_monthlyutilization (WHERE=(month ge '01Jul2016'd AND month lt '01Jul2023'd));
FORMAT  dt_qrtr date9.;
dt_qrtr =intnx('QTR', month, 0, 'BEGINNING'); 
FY      =year(intnx('year.7', month, 0, 'BEGINNING'));
run; *;

PROC SQL;
CREATE TABLE int.util_1 as
SELECT a.*
     , (a.pd_amt/b.index_2021_1) AS adj_pd_amount 
FROM   int.util_0    AS A
LEFT JOIN int.adj   AS b    ON a.dt_qrtr=b.date
WHERE mcaid_id IN (SELECT mcaid_id FROM int.final_03);
quit; *58207623; 

PROC SQL;
CREATE TABLE int.util_2 AS
SELECT MCAID_ID
      , FY
      , month
      , sum(case when clmClass=4     then count else 0 end) as n_pc
      , sum(case when clmClass=3     then count else 0 end) as n_er
      , sum(case when clmClass=2     then count else 0 end) as n_rx
      , sum(case when clmClass=5     then count else 0 end) as n_ffs_bh
        
      , sum(adj_pd_amount) as adj_pd_total
      , sum(case when clmClass=4     then adj_pd_amount else 0 end) as adj_pd_pc
      , sum(case when clmClass=3     then adj_pd_amount else 0 end) as adj_pd_er
      , sum(case when clmClass=2     then adj_pd_amount else 0 end) as adj_pd_rx
      , sum(case when clmClass=5     then adj_pd_amount else 0 end) as adj_pd_ffs_bh
FROM  int.util_1
GROUP BY MCAID_ID,month;
quit; *6/7 58207623; 

%nodupkey(ds=int.util_2, out=int.util_3); *6/7 28628763, 12; 

* 
RAW.BH1 ==============================================================================
Gets BH vars
===========================================================================================;
DATA raw.bh_0;
SET  ana.qry_bho_monthlyutilization; 
format dt_qrtr month2 date9.; 
dt_qrtr = intnx('quarter', month ,0,'b');
month2  = month; DROP month; RENAME month2 = month; /* make numeric, for some reason month coming in as character*/
WHERE   month ge '01Jul2016'd AND  month le '01Jul2023'd;
FY      = year(intnx('year.7', month, 0, 'BEGINNING'));
run; 

%create_qrtr(data=int.bh, set=raw.bh_0, var = dt_qrtr, qrtr=time);

**RUN / exec 02_get_prep_telehealth to get int.tel here; 

* INT.QRYLONG_04 ==============================================================================
join bh and util to qrylong to get averages (all utils - monthly, bho, telehealth) to qrylong4
===========================================================================================;
PROC SQL; 
CREATE TABLE int.qrylong_03 AS 
SELECT a.mcaid_id, a.month, a.dt_qrtr, a.FY, a.time
     , b.bho_n_hosp
     , b.bho_n_er
     , b.bho_n_other
     , c.n_pc
     , c.n_er
     , c.n_rx
     , c.n_ffs_bh
     , c.adj_pd_total
     , c.adj_pd_pc
     , c.adj_pd_er
     , c.adj_pd_rx
     , c.adj_pd_ffs_bh
     , d.n_tele
FROM int.qrylong_02            AS A
LEFT JOIN int.bh               AS B    ON a.mcaid_id=B.mcaid_id AND a.month=B.month
LEFT JOIN int.util_3           AS C    ON a.mcaid_id=C.mcaid_id AND a.month=C.month
LEFT JOIN int.tel              AS D    ON a.mcaid_id=D.mcaid_id AND a.month=D.month;
QUIT;  

* [int.qrylong_pre] ==============================================================================
[Descr]
1. [Step 1]
2. [Step 2]
===========================================================================================;
DATA int.qrylong_pre_0; 
SET  int.qrylong_03;
WHERE month lt '01Jul2019'd; 
RUN;  

PROC SQL;
CREATE TABLE int.qrylong_pre_1 as
SELECT mcaid_id
     , max(case when FY = 2016 then 1 else 0 end) as elig2016
     , max(case when FY = 2017 then 1 else 0 end) as elig2017
     , max(case when FY = 2018 then 1 else 0 end) as elig2018

     , avg(case when FY = 2016 then adj_pd_total else . end) as adj_pd_16pm
     , avg(case when FY = 2017 then adj_pd_total else . end) as adj_pd_17pm
     , avg(case when FY = 2018 then adj_pd_total else . end) as adj_pd_18pm

     , avg(case when FY = 2016 then bho_n_hosp  else . end) as bho_n_hosp_16pm
     , avg(case when FY = 2017 then bho_n_hosp  else . end) as bho_n_hosp_17pm 
     , avg(case when FY = 2018 then bho_n_hosp  else . end) as bho_n_hosp_18pm
     , avg(case when FY = 2016 then bho_n_er    else . end) as bho_n_er_16pm
     , avg(case when FY = 2017 then bho_n_er    else . end) as bho_n_er_17pm 
     , avg(case when FY = 2018 then bho_n_er    else . end) as bho_n_er_18pm
     , avg(case when FY = 2016 then bho_n_other else . end) as bho_n_other_16pm 
     , avg(case when FY = 2017 then bho_n_other else . end) as bho_n_other_17pm 
     , avg(case when FY = 2018 then bho_n_other else . end) as bho_n_other_18pm

FROM int.qrylong_pre_0
GROUP BY mcaid_id;
QUIT; 

* change adj to if elig = 0, then adj var = -1 and set bh variables to 0 where .; 
DATA int.qrylong_pre_2;
SET  int.qrylong_pre_1;

IF      elig2016 = 0 THEN adj_pd_16pm = -1; 
ELSE IF elig2016 = 1 AND  adj_pd_16pm = .   THEN adj_pd_16pm = 0;
ELSE adj_pd_16pm = adj_pd_16pm; 

IF      elig2017 = 0 THEN adj_pd_17pm = -1; 
ELSE IF elig2017 = 1 AND  adj_pd_17pm = .   THEN adj_pd_17pm = 0;
ELSE adj_pd_17pm = adj_pd_17pm; 

IF      elig2018 = 0 THEN adj_pd_18pm = -1; 
ELSE IF elig2018 = 1 AND  adj_pd_18pm = .   THEN adj_pd_18pm = 0;
ELSE adj_pd_18pm = adj_pd_18pm; 

ARRAY bh(*) bho_n_hosp_16pm  bho_n_hosp_17pm  bho_n_hosp_18pm
            bho_n_er_16pm    bho_n_er_17pm    bho_n_er_18pm
            bho_n_other_16pm bho_n_other_17pm bho_n_other_18pm;

DO i=1 to dim(bh);
    IF bh(i)=. THEN bh(i)=0; 
    ELSE bh(i)=bh(i);
    END;
DROP i; 

RUN; *6/8 1138252 : 16;

** GET PERCENTILES FOR ALL & TOP CODE DV's FOR MEMBERS ONLY ; 
* 1618; 
%macro pctl_1618(var,out,pctlpre);
proc univariate noprint data=int.qrylong_pre_2; 
where &var gt 0; 
var &var; 
output out=&out pctlpre=&pctlpre pctlpts= 50, 75, 90, 95; 
run;
%mend; 

** SEE UTIL_02_CHECKS for code to investigate the values and check percentiles; 
%pctl_1618(var = adj_pd_16pm, out = pd16pctle, pctlpre = p16_); 
%pctl_1618(var = adj_pd_17pm, out = pd17pctle, pctlpre = p17_); 
%pctl_1618(var = adj_pd_18pm, out = pd18pctle, pctlpre = p18_); 

data int.pctl1618; merge pd16pctle pd17pctle pd18pctle ; run;

PROC PRINT DATA = int.pctl1618; RUN; 

* https://stackoverflow.com/questions/60097941/sas-calculate-percentiles-and-save-to-macro-variable;
proc sql noprint;
  select 
    name, 
    cats(':',name)
  into 
    :COL_NAMES separated by ',', 
    :MVAR_NAMES separated by ','
  from sashelp.vcolumn 
  where 
    libname = "INT" 
    and memname = "PCTL1618"
  ;
  select &COL_NAMES into &MVAR_NAMES
  from int.pctl1618;
quit;

%macro insert_pctile(ds_in,ds_out,year);
DATA &ds_out; 
SET  &ds_in;
    * For values 0, -1, retain original value; 
    IF      adj_pd_&year.pm le 0            THEN adj_pd_total_&year.cat = adj_pd_&year.pm;

    * Values > 0 but <= 50th p = category 1; 
    ELSE IF adj_pd_&year.pm gt 0 
        AND adj_pd_&year.pm le &&p&year._50 THEN adj_pd_total_&year.cat=1;

    * Values > 50thp but <= 75th p = category 2; 
    ELSE IF adj_pd_&year.pm gt &&p&year._50 
        AND adj_pd_&year.pm le &&p&year._75 THEN adj_pd_total_&year.cat=2;

    * Values > 75thp but <= 90th p = category 3; 
    ELSE IF adj_pd_&year.pm gt &&p&year._75 
        AND adj_pd_&year.pm le &&p&year._90 THEN adj_pd_total_&year.cat=3;

    * Values > 90thp but <= 95th p = category 4; 
    ELSE IF adj_pd_&year.pm gt &&p&year._90 
        AND adj_pd_&year.pm le &&p&year._95 THEN adj_pd_total_&year.cat=4;

    * Values > 95thp = category 5; 
    ELSE IF adj_pd_&year.pm gt &&p&year._95 THEN adj_pd_total_&year.cat=5;
RUN; 
%mend;

* Made separate ds's for testing but merge if poss later, save final to int/; 
%insert_pctile(ds_in = int.qrylong_pre_2, ds_out = adj0,             year = 16);
%insert_pctile(ds_in = adj0,              ds_out = adj1,             year = 17);
%insert_pctile(ds_in = adj1,              ds_out = int.qrylong_1618, year = 18); *1138579;

* [int.final_04] ==============================================================================
Combine final_03 with the final 1618 outcomes
===========================================================================================;
PROC SQL;
CREATE TABLE int.final_04 AS 
SELECT a.*
     , b.*
FROM int.final_03           AS A
LEFT JOIN int.qrylong_1618  AS B ON a.mcaid_id=b.mcaid_id;
QUIT; 

%nodupkey(ds = int.final_04, out=int.final_04); *15124679, 31; 

* INT.qrylong_1922 ======================================================================
DVs (n=7)
--VISITS (n=4): 1) n_ed = n_er+bho_n_er, 2) n_pc, 3) n_ffs_bh (rename to n_ffsbh later), 4) n_tele
--COST (n=3): 1) adj_pd_total, 2) adj_pd_pc, 3_ adj_pd_rx
========================================================================================;
DATA int.qrylong_post_0 (KEEP = mcaid_id month time FY n_ed n_pc n_ffs_bh n_tele adj_pd_total adj_pd_pc adj_pd_rx);
SET  int.qrylong_03     (KEEP = mcaid_id    month   dt_qrtr     time       FY
                                bho_n_er    n_er    n_pc        n_ffs_bh   n_tele   
                                adj_pd_total        adj_pd_pc   adj_pd_rx
                         WHERE = (month ge '01JUL2019'd)); 
ARRAY dv(*) n_pc  n_er  n_ffs_bh  bho_n_er  n_tele adj_pd_total   adj_pd_pc	adj_pd_rx;
DO i=1 to dim(dv);
IF dv(i)=. THEN dv(i)=0; ELSE dv(i)=dv(i);
END;
* Get n_ed as sum of ffs and bh ed visits; 
n_ed = sum(n_er, bho_n_er); 
RUN; 

DATA int.qrylong_post_1 (DROP=i);
SET  int.qrylong_post_0; 
length month time FY n: adj: 3.; 
* Create multiplier for visits so you have integers when dividing;
ARRAY mult(*) n_ed n_pc n_ffs_bh n_tele;
DO i=1 to dim(mult); mult(i)=mult(i)*6; 
END;
RUN; 

** AVERAGE the quarter PM costs, then get 95th percentiles for FY's ; 
PROC SQL;
CREATE TABLE int.qrylong_post_2 as
SELECT mcaid_id
     , count(*) as n_months
     , time
     , FY
     , avg(n_pc)          AS n_pc_pmpq
     , avg(n_ed)          AS n_ed_pmpq
     , avg(n_ffs_bh)      AS n_ffsbh_pmpq
     , avg(n_tele)        AS n_tel_pmpq
     , avg(adj_pd_total)  AS adj_total_pmpq
     , avg(adj_pd_pc)     AS adj_pc_pmpq
     , avg(adj_pd_rx)     AS adj_rx_pmpq
FROM int.qrylong_post_1
GROUP BY mcaid_id, time;
QUIT; 

%nodupkey(ds=int.qrylong_post_2, out=int.qrylong_1922); 
* IT's OK THAT ITs HIGHER bc didn't subset bh, tele to memlist yet!!!; 

* [INT.FINAL_05];
PROC SQL; 
CREATE TABLE int.final_05 AS 
SELECT a.*
     , b.*
FROM int.final_04            AS A
LEFT JOIN int.qrylong_1922   AS B ON a.mcaid_id=b.mcaid_id AND a.time=b.time;
QUIT; 

* setting to 0 where . for variables not using elig category (adj 16-18 vars) 
Create indicator variables for DV's where >0 (use when creating pctiles or just in gee but needed eventually anyway);
DATA int.final_06 (DROP = dt_qrtr elig: adj_pd_16pm adj_pd_17pm adj_pd_18pm);
SET  int.final_05; 
ARRAY dv(*) bho_n_hosp_16pm     bho_n_hosp_17pm     bho_n_hosp_18pm
            bho_n_er_16pm       bho_n_er_17pm       bho_n_er_18pm
            bho_n_other_16pm    bho_n_other_17pm    bho_n_other_18pm
            n_pc_pmpq           n_ed_pmpq           n_ffsbh_pmpq     n_tel_pmpq   
            adj_total_pmpq      adj_pc_pmpq         adj_rx_pmpq;
DO i=1 to dim(dv);
    IF dv(i)=. THEN dv(i)=0; 
    ELSE dv(i)=dv(i);
    END;
DROP i; 

* adj vars for 16-18cat, if not in ds then set to -1; 
adj_pd_total_16cat = coalesce(adj_pd_total_16cat, -1);
adj_pd_total_17cat = coalesce(adj_pd_total_17cat, -1);
adj_pd_total_18cat = coalesce(adj_pd_total_18cat, -1);

ind_visit_pv    = n_pc_pmpq      > 0;
ind_visit_ed    = n_ed_pmpq      > 0;
ind_visit_ffsbh = n_ffsbh_pmpq   > 0;
ind_visit_tel   = n_tel_pmpq     > 0;
ind_cost_total  = adj_total_pmpq > 0;
ind_cost_pc     = adj_pc_pmpq    > 0;
ind_cost_rx     = adj_rx_pmpq    > 0;
RUN;  

PROC SORT DATA = int.final_06; BY FY; run; 

* INT.PCTL_1922 ===========================================================================
Identifying 95th percentile and replacing values gt x w/mean
===========================================================================================;
%macro pctl_1922(var, out, pctlpre, t_var);
PROC UNIVARIATE DATA = int.final_06;
BY FY; 
WHERE &VAR gt 0; 
VAR   &VAR;
OUTPUT OUT=&out pctlpre=&pctlpre pctlpts=95;
RUN; 

PROC TRANSPOSE DATA = &out  
OUT=&out._a (DROP   = _name_ _label_
             RENAME = (col1 = &t_var.p_19
                       col2 = &t_var.p_20
                       col3 = &t_var.p_21
                       col4 = &t_var.p_22));
var &t_var ; 
RUN; 
%mend; 

%pctl_1922(var = adj_total_pmpq,   out = int.adj_total_pctl,   pctlpre = adj_total_,  t_var = adj_total_95); 
%pctl_1922(var = adj_pc_pmpq,      out = int.adj_pc_pctl,      pctlpre = adj_pc_,     t_var = adj_pc_95); 
%pctl_1922(var = adj_rx_pmpq,      out = int.adj_rx_pctl,      pctlpre = adj_rx_,     t_var = adj_rx_95); 

data int.pctl1922; merge int.adj_total_pctl_a int.adj_pc_pctl_a int.adj_rx_pctl_a ; run;

PROC PRINT DATA = int.pctl1922; RUN; 

* https://stackoverflow.com/questions/60097941/sas-calculate-percentiles-and-save-to-macro-variable;
proc sql noprint;
  select name, cats(':',name)
  into 
    :COL_NAMES separated by ',', 
    :MVAR_NAMES separated by ','
  from sashelp.vcolumn 
  where libname = "INT" 
    and memname = "PCTL1922";
  select &COL_NAMES into &MVAR_NAMES
  from int.pctl1922;
quit;

%MACRO means_95p(fy=,var=,gt=,out=,mean=);
PROC UNIVARIATE NOPRINT DATA = int.final_06; 
WHERE FY=&FY 
AND   &VAR gt &gt;
VAR   &VAR;
OUTPUT OUT=&out MEAN=&mean; RUN; 
%MEND;

* tried with proc means to compare to macro and got exact same results; 
%means_95p(FY=2019, var=adj_total_pmpq, gt=&adj_total_95p_19, out=mu_total_19, MEAN=Mu_total19);
%means_95p(FY=2020, var=adj_total_pmpq, gt=&adj_total_95p_20, out=mu_total_20, MEAN=Mu_total20);
%means_95p(FY=2021, var=adj_total_pmpq, gt=&adj_total_95p_21, out=mu_total_21, MEAN=Mu_total21);
%means_95p(FY=2022, var=adj_total_pmpq, gt=&adj_total_95p_22, out=mu_total_22, MEAN=Mu_total22);

%means_95p(FY=2019, var=adj_pc_pmpq,    gt=&adj_pc_95p_19,    out=mu_pc_19,    MEAN=Mu_pc19);
%means_95p(FY=2020, var=adj_pc_pmpq,    gt=&adj_pc_95p_20,    out=mu_pc_20,    MEAN=Mu_pc20);
%means_95p(FY=2021, var=adj_pc_pmpq,    gt=&adj_pc_95p_21,    out=mu_pc_21,    MEAN=Mu_pc21);
%means_95p(FY=2022, var=adj_pc_pmpq,    gt=&adj_pc_95p_22,    out=mu_pc_22,    MEAN=Mu_pc22);

%means_95p(FY=2019, var=adj_rx_pmpq,    gt=&adj_rx_95p_19,    out=mu_rx_19,    MEAN=Mu_rx19);
%means_95p(FY=2020, var=adj_rx_pmpq,    gt=&adj_rx_95p_20,    out=mu_rx_20,    MEAN=Mu_rx20);
%means_95p(FY=2021, var=adj_rx_pmpq,    gt=&adj_rx_95p_21,    out=mu_rx_21,    MEAN=Mu_rx21);
%means_95p(FY=2022, var=adj_rx_pmpq,    gt=&adj_rx_95p_22,    out=mu_rx_22,    MEAN=Mu_rx22);

data int.mu_pctl_1922; 
merge mu_total_19       mu_total_20     mu_total_21     mu_total_22
      mu_pc_19          mu_pc_20        mu_pc_21        mu_pc_22
      mu_rx_19          mu_rx_20        mu_rx_21        mu_rx_22
      int.adj_total_pctl_a  int.adj_pc_pctl_a   int.adj_rx_pctl_a;
RUN; 
PROC PRINT DATA = int.mu_pctl_1922; RUN; 

proc sql noprint;
  select name, cats(':',name)
  into 
    :COL_NAMES separated by ',', 
    :MVAR_NAMES separated by ','
  from sashelp.vcolumn 
  where libname = "INT" 
    and memname = "MU_PCTL_1922";
  select &COL_NAMES into &MVAR_NAMES
  from int.mu_pctl_1922;
quit;

DATA int.final_07;
SET  int.final_06;

* replace values >95p with mu95;
IF      FY = 2019 AND adj_total_pmpq gt &adj_total_95p_19 THEN adj_pd_total_tc = &mu_total19; 
ELSE IF FY = 2020 AND adj_total_pmpq gt &adj_total_95p_20 THEN adj_pd_total_tc = &mu_total20; 
ELSE IF FY = 2021 AND adj_total_pmpq gt &adj_total_95p_21 THEN adj_pd_total_tc = &mu_total21; 
ELSE IF FY = 2022 AND adj_total_pmpq gt &adj_total_95p_22 THEN adj_pd_total_tc = &mu_total22; 
ELSE adj_pd_total_tc= adj_total_pmpq;

IF FY = 2019 AND adj_pc_pmpq         gt &adj_pc_95p_19    THEN adj_pd_pc_tc    = &mu_pc19;    
ELSE IF FY = 2020 AND adj_pc_pmpq    gt &adj_pc_95p_20    THEN adj_pd_pc_tc    = &mu_pc20;    
ELSE IF FY = 2021 AND adj_pc_pmpq    gt &adj_pc_95p_21    THEN adj_pd_pc_tc    = &mu_pc21;    
ELSE IF FY = 2022 AND adj_pc_pmpq    gt &adj_pc_95p_22    THEN adj_pd_pc_tc    = &mu_pc22; 
ELSE adj_pd_pc_tc= adj_pc_pmpq;

IF      FY = 2019 AND adj_rx_pmpq    gt &adj_rx_95p_19    THEN adj_pd_rx_tc    = &mu_rx19;    
ELSE IF FY = 2020 AND adj_rx_pmpq    gt &adj_rx_95p_20    THEN adj_pd_rx_tc    = &mu_rx20;    
ELSE IF FY = 2021 AND adj_rx_pmpq    gt &adj_rx_95p_21    THEN adj_pd_rx_tc    = &mu_rx21; 
ELSE IF FY = 2022 AND adj_rx_pmpq    gt &adj_rx_95p_22    THEN adj_pd_rx_tc    = &mu_rx22;    
ELSE adj_pd_rx_tc= adj_rx_pmpq;
RUN; 
PROC SORT DATA = int.final_07; by mcaid_id time; run; 


* ANALYSIS_DATASET_ALLCOLS ==================================================================
===========================================================================================;
*** Add quarter variables, one with text for readability ; 
DATA int.final_08 ;
SET  int.final_07 (DROP = adj_total_pmpq adj_pc_pmpq adj_rx_pmpq
                   RENAME=(bho_n_hosp_16pm  = BH_Hosp16
                           bho_n_hosp_17pm  = BH_Hosp17
                           bho_n_hosp_18pm  = BH_Hosp18
                           bho_n_er_16pm    = BH_ER16
                           bho_n_er_17pm    = BH_ER17
                           bho_n_er_18pm    = BH_ER18
                           bho_n_other_16pm = BH_Oth16
                           bho_n_other_17pm = BH_Oth17
                           bho_n_other_18pm = BH_Oth18
                           ind_visit_pv     =ind_visit_pc /** somewhere I named it pv by mistake; */
                           ));
* make binary; 
ARRAY bh(*) BH_Hosp16 BH_Hosp17 BH_Hosp18 BH_ER16 BH_ER17 BH_ER18 BH_Oth16 BH_Oth17 BH_Oth18;
DO i=1 to dim(bh); IF bh(i)>0 THEN bh(i)=1; ELSE bh(i)=bh(i); END; DROP i; 

fyqrtr_txt = put(time,   fyqrtr_cat.); 
fyqrtr     = input(time, fyqrtr_num.);
IF fyqrtr  = 1 THEN season1 = 1; ELSE IF fyqrtr = 4 THEN season1 = -1; ELSE season1 = 0; 
IF fyqrtr  = 2 THEN season2 = 1; ELSE IF fyqrtr = 4 THEN season2 = -1; ELSE season2 = 0;  
IF fyqrtr  = 3 THEN season3 = 1; ELSE IF fyqrtr = 4 THEN season3 = -1; ELSE season3 = 0;  
RUN; 

PROC SORT DATA = int.final_08; BY mcaid_id time; RUN; 

* DATA.ANALYSIS ===========================================================================
===========================================================================================;
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/config_formats.sas"; 

* Get col names by starting string and the rando-strings... for setting to 3, but only for integers w 4 values... ; 
%LET len08 = FY time age pcmp_loc_id int int_imp fqhc int_imp budget_group rae_person_new fyqrtr season1 season2 season3
             adj_pd_total_16cat adj_pd_total_17cat adj_pd_total_18cat 
             ind_visit_pc ind_visit_ed ind_visit_ffsbh ind_visit_tel ind_cost_total ind_cost_pc ind_cost_rx 
             n_months n_pc_pmpq n_ed_pmpq n_ffsbh_pmpq n_tel_pmpq ; 

%colstring(into=bhcols,  memname="FINAL_08", nchar=2, string='BH'); * case sensitive!;

DATA   data.analysis_allcols;
LENGTH &len08 &bhcols 3. ;
SET    int.final_08; 

budget_grp_r = input(put(budget_group, budget_grp_r.), 12.);
FORMAT budget_grp_r budget_grp_new_. ; 
* testing; 

adj_pd_total_16cat = adj_pd_total_16cat + 1; 
adj_pd_total_17cat = adj_pd_total_17cat + 1; 
adj_pd_total_18cat = adj_pd_total_18cat + 1; 

IF            age <   5 THEN age_cat = 1;
ELSE IF  6 <= age <= 10 THEN age_cat = 2;
ELSE IF 11 <= age <= 15 THEN age_cat = 3;
ELSE IF 16 <= age <= 20 THEN age_cat = 4;
ELSE IF 21 <= age <= 44 THEN age_cat = 5;
ELSE                         age_cat = 6;

FORMAT race $race_rc_. age_cat age_cat_.; 
RUN; 

PROC FREQ DATA = data.analysis_allcols; tables budget: ; run; 

*[DATA.UTILIZATION];
%LET drop   = n_months fyqrtr_txt age FY budget_group fyqrtr pcmp_loc_id;
%LET retain = mcaid_id time int int_imp season1 season2 season3 ind_cost_total cost_total ind_cost_pc cost_pc ind_cost_rx cost_rx 
              ind_visit_pc visits_pc ind_visit_ed visits_ed ind_visit_ffsbh visits_ffsbh ind_visit_tel visits_tel
              bh_hosp16 bh_hosp17 bh_hosp18 bh_er16 bh_er17 bh_er18 bh_oth16 bh_oth17 bh_oth18 adj_pd_total_16cat adj_pd_total_17cat adj_pd_total_18cat
              fqhc budget_grp_new age_cat rae_person_new  race sex  ;

* previous version had 39 cols; 
DATA data.utilization ;
RETAIN &retain;
LENGTH budget_grp_new age_cat 3. mcaid_id $7. sex $1.;
SET    data.analysis_allcols (RENAME=(budget_grp_r    = budget_grp_new
                                      adj_pd_total_tc = cost_total
                                      adj_pd_pc_tc    = cost_pc
                                      adj_pd_rx_tc    = cost_rx
                                      n_pc_pmpq       = visits_pc
                                      n_ed_pmpq       = visits_ed
                                      n_ffsbh_pmpq    = visits_ffsbh
                                      n_tel_pmpq      = visits_tel)
                              DROP= &drop);
RUN; 


** CREATE META DS  ====================================;
PROC SQL; 
CREATE TABLE data.UTILIZATION_meta AS 
SELECT name as variable
     , type
     , length
     , label
     , format
     , informat
FROM sashelp.vcolumn
WHERE LIBNAME = 'DATA' 
AND   MEMNAME = 'UTILIZATION';
quit;

* 
DATA.MINI_DS ==============================================================================
VERSION 08-24
Reduced, testing dataset of 500k records from data.analysis with same int proportion
Step 1: ds has to be sorted on grouping var
Step 2: specify nrow, allocation, and strata
Step 3: Check frequency to test
===========================================================================================;
* Step 1;
proc sort data = data.analysis;
by int ;
run;

* Step 2;
PROC SURVEYSELECT 
DATA = data.analysis
n    = 500000
OUT  = data.mini;
STRATA int / alloc=prop;
RUN;

* Step 3; 
PROC FREQ DATA = data.mini;
tables int; 
run;
* int=0 pct 87.48%
  int=1 pct 12.52% (100-87.48%); 


