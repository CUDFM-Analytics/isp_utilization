*
AUTHOR   : KTW
PROJECT  : ISP Utilization Analysis
PURPOSE  : Gather, Process datasets from analytic subset dir, Create final analysis dataset and mini dataset
VERSION  : 2023-06-06
           - updated 5/30 due to issues in the hcpf file and to get Sept 2022 since it's available now (cs email re: hcpf)
           - updated 06/01-02 bc ana.long & ana.demo were missing months
           - updated 6/5 to combine bh cat variables into 1 bh cat var
           - updated 6/6 to check on the BH's by adding a total var and seeing
                if any of them are wrong as I'm still getting Hessian errors
DEPENDS  : -ana subset folder, config file, 
           -%include helper file in code/util_dataset_prep/incl_extract_check_fy19210.sas
           -other macro code referenced is stored in the util_00_config.sas file
OUTPUT
SECTION1 : data.analysis
SECTION2 : data.analysis_allcols
SECTION3 : data.mini_ds (test set with only 500000 records) ;

%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 

* 
[RAW.time_dim] ==============================================================================
Import a .csv file I made with months, FY, FY quarters, and the linearized time var
===========================================================================================;
PROC IMPORT FILE="&util./data/_raw/fy_q_dts_dim.csv"
    OUT = raw.time_dim
    DBMS=csv
    REPLACE;
run; 

* 
[QRYLONG_00] ==============================================================================
1. SUBSET qry_longitudinal to timeframe (months le/ge) AND:
   -- budget_groups
   -- sex not Unknown
   -- pcmp_loc_id not missing
   -- managedCare not 0
   NB: Can't subset to records with an RAE yet since that would exclude FY16-18 records
2. Create dt_qrtr: the first month of the quarter that the record was in
===========================================================================================;
DATA   raw.qrylong_00 (DROP=managedCare);
LENGTH mcaid_id $11; 
SET    ana.qry_longitudinal (WHERE=(month ge '01Jul2016'd AND month le '30Sep2022'd 
							 		AND BUDGET_GROUP not in (16,17,18,19,20,21,22,23,24,25,26,27,-1,)
                             		AND managedCare = 0
							 		AND pcmp_loc_id ne ' ') 
							 DROP = FED_POV: DISBLD_IND aid_cd: title19: SPLM_SCRTY_INCM_IND
                                    SSI_: SS: dual eligGrp fost_aid_cd) ;  
format dt_qrtr date9.; 
dt_qrtr = intnx('quarter', month ,0,'b'); 
FY      = year(intnx('year.7', month, 0, 'BEGINNING'));
PCMP2   = input(pcmp_loc_id, best12.); DROP pcmp_loc_id; RENAME pcmp2 = pcmp_loc_id; 
RUN;  *6/07 75691244;

* 
INT.PCMP_DIM ==============================================================================
DESCR: Extract unique pcmp_loc_ids and their dimensions, stored as a reference table, that:
1. Reduces qrylong for interim processing steps,
2. Reduces pcmp_loc_ids to unique records for faster calculations:
    2a: convert pcmp_loc_id to numeric
3. Create binary covariate FQHC from pcmp_loc_type_cd values (rather than formats) 
===========================================================================================;
DATA pcmp_type_qrylong ; 
SET  raw.qrylong_00   (KEEP = pcmp_loc_id  pcmp_loc_type_cd pcmp_loc_type_cd 
                       WHERE= (pcmp_loc_id ne .));
num_pcmp_type = input(pcmp_loc_type_cd, 7.);
RUN ; 

PROC SORT DATA = pcmp_type_qrylong NODUPKEY ; BY _ALL_ ; RUN ; 

DATA int.pcmp_dim;
SET  pcmp_type_qrylong;
IF pcmp_loc_type_cd in (32 45 61 62) then fqhc = 1 ; else fqhc = 0 ;
RUN; *1462;

* 
[RAW.QRYLONG_01]======================================================================
Joins ana.qry_demographics, raw.age_dim, and rae_dim
Purpose:
1. Get rae_person_new on enr_county (from qrylong)
2. Demographic vars: dob(for calculating age/subsetting members 0-64), gender, race
3. Subset sex M, F
4. Get dob to calculate ages (subsetting var)
===========================================================================================;
PROC SQL; 
CREATE TABLE raw.qrylong_01 AS
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
FROM raw.qrylong_00             AS A 
LEFT JOIN ana.qry_demographics  AS B ON a.mcaid_id = b.mcaid_id 
LEFT JOIN int.rae_dim           AS C ON a.enr_cnty = c.hcpf_county_code_c
LEFT JOIN raw.time_dim			AS D on a.dt_qrtr  = d.month
WHERE  pcmp_loc_id ne .
AND    SEX IN ('F','M');
QUIT;   *06-07 75690836 : 10 cols;

* 
RAW.AGE_DIM ==============================================================================
Extract dob to get age as of the 2nd month in each quarter
1. Used in subsetting dataset
2. Used to create age_cat
Will have to inner join these variables on qrylong eventually unless you subset it by this earlier
===========================================================================================;
* Get distinct mcaid_id and dob;
PROC SQL;
CREATE TABLE age_dim0 AS 
SELECT distinct(mcaid_id) as mcaid_id
	 , dob
FROM raw.qrylong_01
WHERE FY in (2019, 2020, 2021, 2022)
AND   rae_person_new ne .
AND   rae_assign eq 1;
QUIT; * 6/7 1675741 obs 2 col; 

* Find / List all 13 2nd month of quarter values; 
PROC SQL NOPRINT;
SELECT month INTO :qm2 separated by ' '
FROM  raw.time_dim
WHERE month_qrtr = 2;
QUIT; 

%PUT &qm2;

* I could not for the life of me find a way to do this from the macro values and had to get moving
but I'm sure there's a better way to do this? 
Need age at month 2 of each quarter ;
%LET m2q1 = 01Aug2019;
%LET m2q2 = 01Nov2019;
%LET m2q3 = 01Feb2020;
%LET m2q4 = 01May2020;
%LET m2q5 = 01Aug2020;
%LET m2q6 = 01Nov2020;
%LET m2q7 = 01Feb2021;
%LET m2q8 = 01May2021;
%LET m2q9 = 01Aug2021;
%LET m2q10 = 01Nov2021;
%LET m2q11 = 01Feb2022;
%LET m2q12 = 01May2022;
%LET m2q13 = 01Aug2022;
 
DATA age_dim1 (DROP=m2q:);
SET  age_dim0;
m2q1 = MDY(8,1,2019);
m2q2 = MDY(11,1,2019);
m2q3 = MDY(2,1,2020);
m2q4 = MDY(5,1,2020);
m2q5 = MDY(8,1,2020);
m2q6 = MDY(11,1,2020);
m2q7 = MDY(2,1,2021);
m2q8 = MDY(5,1,2021);
m2q9 = MDY(8,1,2021);
m2q10 = MDY(11,1,2021);
m2q11 = MDY(2,1,2022);
m2q12 = MDY(5,1,2022);
m2q13 = MDY(8,1,2022);

/*age  = floor((intck('month', dob, dt_end_fy)-(day(dt_end_fy) < min(day(dob), day(intnx('month', dt_end_fy, 1) -1)))) /12);*/
age_m2q1   = floor((intck('month', dob, "&m2q1"d)-(day("&m2q1"d) < min(day(dob), day(intnx('month', "&m2q1"d, 1) -1)))) /12);
age_m2q2   = floor((intck('month', dob, "&m2q2"d)-(day("&m2q2"d) < min(day(dob), day(intnx('month', "&m2q2"d, 1) -1)))) /12);
age_m2q3   = floor((intck('month', dob, "&m2q3"d)-(day("&m2q3"d) < min(day(dob), day(intnx('month', "&m2q3"d, 1) -1)))) /12);
age_m2q4   = floor((intck('month', dob, "&m2q4"d)-(day("&m2q4"d) < min(day(dob), day(intnx('month', "&m2q4"d, 1) -1)))) /12);
age_m2q5   = floor((intck('month', dob, "&m2q5"d)-(day("&m2q5"d) < min(day(dob), day(intnx('month', "&m2q5"d, 1) -1)))) /12);
age_m2q6   = floor((intck('month', dob, "&m2q6"d)-(day("&m2q6"d) < min(day(dob), day(intnx('month', "&m2q6"d, 1) -1)))) /12);
age_m2q7   = floor((intck('month', dob, m2q7)-(day(m2q7) < min(day(dob), day(intnx('month', m2q7, 1) -1)))) /12);
age_m2q8   = floor((intck('month', dob, m2q8)-(day(m2q8) < min(day(dob), day(intnx('month', m2q8, 1) -1)))) /12);
age_m2q9   = floor((intck('month', dob, m2q9)-(day(m2q9) < min(day(dob), day(intnx('month', m2q9, 1) -1)))) /12);
age_m2q10  = floor((intck('month', dob, m2q10)-(day(m2q10) < min(day(dob), day(intnx('month', m2q10, 1) -1)))) /12);
age_m2q11  = floor((intck('month', dob, m2q11)-(day(m2q11) < min(day(dob), day(intnx('month', m2q11, 1) -1)))) /12);
age_m2q12  = floor((intck('month', dob, m2q12)-(day(m2q12) < min(day(dob), day(intnx('month', m2q12, 1) -1)))) /12);
age_m2q13  = floor((intck('month', dob, m2q13)-(day(m2q13) < min(day(dob), day(intnx('month', m2q13, 1) -1)))) /12);
RUN; *06/07 1675741;

* Transpose to long format, subset age 0-64;
DATA age_dim2 (WHERE=(age ge 0 AND age lt 65));
SET  age_dim1;
ARRAY aage(1:13) age_m2q1-age_m2q13;
DO time = 1 to 13;
	age = aage(time);
	OUTPUT;
END; 
DROP dob age_m2q1-age_m2q13;
RUN; *20292320;

PROC SQL; 
CREATE TABLE raw.age_dim AS
SELECT a.*
	 , b.FY
FROM age_dim2 				AS A
LEFT JOIN raw.time_dim AS B ON a.time=b.time;
QUIT; *6/7 60876960;

%nodupkey(ds = raw.age_dim, out=raw.age_dim); *20292320; 

* 
[RAW.FINAL_00] ==============================================================================
Start final list where age in range based on FY's 19-22 and rae_ not missing
===========================================================================================;
PROC SQL;
CREATE TABLE raw.final_00 AS 
SELECT mcaid_id
	 , time
	 , FY
	 , dt_qrtr
	 , month
	 , pcmp_loc_id
	 , enr_cnty
	 , budget_group
	 , sex
	 , race
	 , rae_person_new
FROM raw.qrylong_01
WHERE rae_person_new ne . 
AND FY IN (2019, 2020, 2021, 2022) 
AND mcaid_id IN (SELECT mcaid_id FROM raw.age_dim);
QUIT; *44600909; 

* 
[RAW.QRYLONG_02] ==============================================================================
Limit ds to members id's found in age_dim
===========================================================================================;
PROC SQL;
CREATE TABLE raw.qrylong_02 AS 
SELECT mcaid_id
	 , time
	 , FY
	 , dt_qrtr
	 , month
FROM raw.qrylong_01
WHERE mcaid_id IN (SELECT mcaid_id FROM raw.final_00);
QUIT; *06/07 68762434;

* 
[RAW.FINAL_00 & RAW.DEMO_1922]=======================================================================
Subset to mcaid_id's that have an rae_assigned in FY's 19-22
===========================================================================================;
DATA raw.final_01  (KEEP = mcaid_id month dt_qrtr FY time)
     raw.demo_1922 (KEEP = mcaid_id month dt_qrtr FY time sex race rae_person_new pcmp_loc_id budget_group);
SET  raw.final_00 ;
RUN; *06/07: both have 44600909
06/05 both have 44102611; 

PROC SORT DATA=raw.final_01; BY MCAID_ID FY TIME; RUN; 

*
%INCLUDE ==============================================================================
Creates table with max months' pcmp. In case of ties, takes most recent 
1. MACRO for other demo vars
2. output: int.pcmp_attr_qrtr
===========================================================================================;
%LET dv1922 = raw.demo_1922;
%INCLUDE "&util/code/util_dataset_prep/incl_extract_check_fy1922.sas";

%demo(var=budget_group,   ds=&dv1922);
%demo(var=rae_person_new, ds=&dv1922);
%demo(var=sex,            ds=&dv1922);
%demo(var=race,           ds=&dv1922);   * all have 15104152 rows; 

*macro to find instances where n_ids >13 (should be 0 // in 00_config); 
%check_ids_n13(ds=budget_group); *0;
%check_ids_n13(ds=rae_person_new);    *0;

%macro concat_id_time(ds=);
DATA &ds;
SET  &ds;
id_time_helper = CATX('_', mcaid_id, time); 
RUN; 
%mend; 

* Created helper var for joins (was taking a long time and creating rows without id, 
idk why, so did this as quick fix for now); 
%concat_id_time(ds=raw.final_01);
%concat_id_time(ds=raw.age_dim);

* 
RAW.Final_02 ==============================================================================
Joins final_01 with the calculated demo variables as well as int, int_imp
===========================================================================================;
PROC SQL ; 
CREATE TABLE raw.final_02 AS 
SELECT a.mcaid_id
     , a.dt_qrtr
     , a.month
     , a.FY
     , a.time
     , a.id_time_helper
	 , i.age
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
FROM raw.final_01                    AS A
LEFT JOIN budget_group               AS B   ON A.id_time_helper = B.id_time_helper
LEFT JOIN raw.age_dim				 AS I   ON a.id_time_helper = I.id_time_helper
LEFT JOIN rae_person_new             AS C   ON A.id_time_helper = C.id_time_helper
LEFT JOIN int.pcmp_attr_qrtr         AS D   ON A.id_time_helper = D.id_time_helper
LEFT JOIN int.pcmp_dim               AS E   ON D.pcmp_loc_id    = E.pcmp_loc_id   
LEFT JOIN int.isp_un_pcmp_dtstart    AS F   ON D.pcmp_loc_id    = F.pcmp_loc_id    
LEFT JOIN race                       AS G   ON A.id_time_helper = G.id_time_helper
LEFT JOIN sex                        AS H   ON A.id_time_helper = H.id_time_helper;
QUIT ;  *6/7 44600909; 

* 
RAW.Final_03 ==============================================================================
drops some vars no longer needed, adds labels
remove duplicates
===========================================================================================;
DATA  raw.final_03;
SET   raw.final_02   (DROP=time_start_isp month id_time_helper);
LABEL pcmp_loc_id     = "pcmp_loc_ID"
      FY              = "FY 19, 20, 21, and FYQ1 of 2023"
      age             = "Age: 0-64 only"
      sex             = "Sex (M,F)"
      time            = "Linearized qrtrs, 1-13"
      int             = "ISP Participation: Time Invariant"
      budget_group    = "Budget Group (subsetting var)"
      rae_person_new  = "RAE ID"
      fqhc            = "FQHC: 0 No, 1 Yes"
      int_imp         = "ISP Participation: Time-Varying"
      ;
RUN; * ;

%nodupkey(raw.final_03, raw.final_03); *6/02 15104152;

* 
RAW.UTIL3 ==============================================================================
Gets utilization dv's
===========================================================================================;
DATA    raw.util0; 
SET     ana.qry_monthlyutilization (WHERE=(month ge '01Jul2016'd AND month le '30Sep2022'd));
FORMAT  dt_qrtr date9.;
dt_qrtr =intnx('QTR', month, 0, 'BEGINNING'); 
FY      =year(intnx('year.7', month, 0, 'BEGINNING'));
run; *69554550;

PROC SQL;
CREATE TABLE raw.util1 as
SELECT a.*
     , (a.pd_amt/b.index_2021_1) AS adj_pd_amount 
FROM   raw.util0    AS A
LEFT JOIN int.adj   AS b    ON a.dt_qrtr=b.date
WHERE mcaid_id IN (SELECT mcaid_id FROM raw.final_03);
quit; *58207623; 

PROC SQL;
CREATE TABLE raw.util2 AS
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
FROM  raw.util1
GROUP BY MCAID_ID,month;
quit; *6/7 58207623; 

%nodupkey(ds=raw.util2, out=raw.util3); *6/7 28628763, 12; 

* 
RAW.BH1 ==============================================================================
Gets BH vars
===========================================================================================;
DATA raw.bh0;
SET  ana.qry_bho_monthlyutilization; 
format dt_qrtr month2 date9.; 
dt_qrtr = intnx('quarter', month ,0,'b');
month2  = month; DROP month; RENAME month2 = month; /* make numeric, for some reason month coming in as character*/
WHERE   month ge '01Jul2016'd AND  month le '30Sep2022'd;
FY      = year(intnx('year.7', month, 0, 'BEGINNING'));
run; *4618851 observations and 8 variables;

%create_qrtr(data=raw.bh1, set=raw.bh0, var = dt_qrtr, qrtr=time);

* 
RAW.QRYLONG_04 ==============================================================================
join bh and util to qrylong to get averages (all utils - monthly, bho, telehealth) to qrylong4
    drop the demo vars because the good ones are on raw.final1
===========================================================================================;
PROC SQL; 
CREATE TABLE raw.qrylong_03 AS 
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
FROM raw.qrylong_02            AS A
LEFT JOIN raw.bh1              AS B    ON a.mcaid_id=B.mcaid_id AND a.month=B.month
LEFT JOIN raw.util3            AS C    ON a.mcaid_id=C.mcaid_id AND a.month=C.month
LEFT JOIN int.tel_fact_1922_m  AS D    ON a.mcaid_id=D.mcaid_id AND a.month=D.month;
QUIT;  *06/07 nrow 68762424 //  68079369 rows and 18 columns.;

* 
[RAW.QRYLONG_1618] ==============================================================================
[Descr]
1. [Step 1]
2. [Step 2]
===========================================================================================;
DATA raw.fy_1618_0; 
SET  raw.qrylong_03;
WHERE month lt '01Jul2019'd; 
RUN; *23976758; 

PROC SQL;
CREATE TABLE raw.fy_1618_1 as
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

FROM raw.fy_1618_0
GROUP BY mcaid_id;
QUIT; * 6/01 1131492;

* change adj to if elig = 0, then adj var = -1 and set bh variables to 0 where .; 
DATA raw.fy_1618_2;
SET  raw.fy_1618_1;

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

RUN; *1131492 : 16;

** GET PERCENTILES FOR ALL & TOP CODE DV's FOR MEMBERS ONLY ; 
* 1618; 
%macro pctl_1618(var,out,pctlpre);
proc univariate noprint data=raw.fy_1618_2; 
where &var gt 0; 
var &var; 
output out=&out pctlpre=&pctlpre pctlpts= 50, 75, 90, 95; 
run;
%mend; 

** SEE UTIL_02_CHECKS for code to investigate the values and check percentiles; 

%pctl_1618(var     = adj_pd_16pm,
           out     = pd16pctle,
           pctlpre = p16_); 

%pctl_1618(var     = adj_pd_17pm,
           out     = pd17pctle,
           pctlpre = p17_); 

%pctl_1618(var     = adj_pd_18pm,
           out     = pd18pctle,
           pctlpre = p18_); 

data int.pctl1618; merge pd16pctle pd17pctle pd18pctle ; run;

PROC PRINT DATA = int.pctl1618; RUN; 
* 06/07
    p16_50 	p16_75  p16_90 	p16_95 		p17_50 	p17_75 	p17_90 	p17_95 		p18_50 	p18_75 	p18_90 	p18_95
    266.394 512.837 1198.18 2094.02 	268.937 519.215 1242.00 2278.18 	280.262 560.325 1398.62 2667.85 

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
%insert_pctile(ds_in = raw.fy_1618_2,	  ds_out = adj0,             year = 16);
%insert_pctile(ds_in = adj0,              ds_out = adj1,             year = 17);
%insert_pctile(ds_in = adj1,              ds_out = int.qrylong_1618, year = 18); *1138579;

*  ;
PROC SQL;
CREATE TABLE raw.final_04 AS 
SELECT a.*
     , b.*
FROM raw.final_03           AS A
LEFT JOIN int.qrylong_1618  AS B ON a.mcaid_id=b.mcaid_id;
QUIT; *Table RAW.FINAL_04 created, with 15280002 rows and 31 columns.;

* 
FYs 19-22 ==============================================================================
===========================================================================================;
DATA raw.fy_1922_0;
SET  raw.qrylong_03 (where=(month ge '01JUL2019'd)); 
RUN; * 44102611; 

** AVERAGE the quarter PM costs, then get 95th percentiles for FY's ; 
PROC SQL;
CREATE TABLE raw.fy_1922_1 as
SELECT mcaid_id
     , count(*) as n_months_per_q
     , time
     , FY
     , avg(n_pc)                as n_pc_pm
     , avg(sum(n_er, bho_n_er)) as n_ed_pm
     , avg(n_ffs_bh)            as n_ffs_bh_pm
     , avg(n_tele)              as n_tel_pm
     , avg(adj_pd_total)        as adj_total_pm
     , avg(adj_pd_pc)           as adj_pc_pm
     , avg(adj_pd_rx)           as adj_rx_pm
FROM raw.fy_1922_0
GROUP BY mcaid_id, time;
QUIT; *6/7 44630012 // 6/2 44102611 rows and 11 columns.; 

%nodupkey(ds=raw.fy_1922_1, out=raw.fy_1922_2); * 15288939
IT's OK THAT ITs HIGHER bc didn't subset bh, tele to memlist!!!; 

* JOIN TO FINAL as int.final_b;
PROC SQL; 
CREATE TABLE raw.final_05 AS 
SELECT a.*
     , b.*
FROM raw.final_04            AS A
LEFT JOIN raw.fy_1922_2 AS B ON a.mcaid_id=b.mcaid_id AND a.time=b.time;
QUIT;

* setting to 0 where . for variables not using elig category (adj 16-18 vars) 
    create indicator variables for DV's where >0 
    (use when creating pctiles or just in gee but needed eventually anyway);
DATA raw.final_06 (DROP = dt_qrtr elig: adj_pd_16pm adj_pd_17pm adj_pd_18pm);
SET  raw.final_05; 
ARRAY dv(*) bho_n_hosp_16pm     bho_n_hosp_17pm     bho_n_hosp_18pm
            bho_n_er_16pm       bho_n_er_17pm       bho_n_er_18pm
            bho_n_other_16pm    bho_n_other_17pm    bho_n_other_18pm
            n_pc_pm       n_ed_pm     n_ffs_bh_pm     n_tel_pm    
            adj_total_pm  adj_pc_pm   adj_rx_pm;
DO i=1 to dim(dv);
    IF dv(i)=. THEN dv(i)=0; 
    ELSE dv(i)=dv(i);
    END;
DROP i; 

* adj vars for 16-18cat, if not in ds then set to -1; 
adj_pd_total_16cat = coalesce(adj_pd_total_16cat, -1);
adj_pd_total_17cat = coalesce(adj_pd_total_17cat, -1);
adj_pd_total_18cat = coalesce(adj_pd_total_18cat, -1);

ind_pc_visit       = n_pc_pm      > 0;
ind_ed_visit       = n_ed_pm      > 0;
ind_ffs_bh_visit   = n_ffs_bh_pm  > 0;
ind_tel_visit      = n_tel_pm     > 0;
ind_total_cost     = adj_total_pm > 0;
ind_pc_cost        = adj_pc_pm    > 0;
ind_rx_cost        = adj_rx_pm    > 0;
RUN;  *6/7 15280002 observations and 46 variables;

proc sort data = raw.final_06; BY FY; run; 

*
INT.PCTL1922 ==============================================================================
Identifying 95th percentile and replacing values gt x w/mean
===========================================================================================;
%macro pctl_1922(var, out, pctlpre, t_var);
PROC UNIVARIATE DATA = raw.final_06;
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

%pctl_1922(var = adj_total_pm,   out = int.adj_total_pctl,   pctlpre = adj_total_,  t_var = adj_total_95); 
%pctl_1922(var = adj_pc_pm,      out = int.adj_pc_pctl,      pctlpre = adj_pc_,     t_var = adj_pc_95); 
%pctl_1922(var = adj_rx_pm,      out = int.adj_rx_pctl,      pctlpre = adj_rx_,     t_var = adj_rx_95); 

data int.pctl1922; merge int.adj_total_pctl_a int.adj_pc_pctl_a int.adj_rx_pctl_a ; run;

PROC PRINT DATA = int.pctl1922; RUN; 
/*adj_total_95p_19    adj_total_95p_20   adj_total_95p_21    adj_total_95p_22
6/1 3971.63           3734.90             3649.42             3907.58 
6/7 4004.88 		  3783.73 			 3717.50 			 3984.28 

  		adj_pc_95p_19       adj_pc_95p_20      adj_pc_95p_21       adj_pc_95p_22 
  		365.616             352.994            343.009             329.151 
6/7		365.425 			352.932 		   341.358 			   324.069 

  		adj_rx_95p_19       adj_rx_95p_20      adj_rx_95p_21       adj_rx_95p_22 
  		1075.92             1147.51            1158.32             1227.72 
6/7		1078.70 			1152.43 		   1162.93 			   1239.26 
*/
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
PROC UNIVARIATE NOPRINT DATA = raw.final_06; 
WHERE FY=&FY 
AND   &VAR gt &gt;
VAR   &VAR;
OUTPUT OUT=&out MEAN=&mean; RUN; 
%MEND;

* tried with proc means to compare to macro and got exact same results; 
%means_95p(FY=2019, var=adj_total_pm, gt=&adj_total_95p_19, out=mu_total_19, MEAN=Mu_total19);
%means_95p(FY=2020, var=adj_total_pm, gt=&adj_total_95p_20, out=mu_total_20, MEAN=Mu_total20);
%means_95p(FY=2021, var=adj_total_pm, gt=&adj_total_95p_21, out=mu_total_21, MEAN=Mu_total21);
%means_95p(FY=2022, var=adj_total_pm, gt=&adj_total_95p_22, out=mu_total_22, MEAN=Mu_total22);

%means_95p(FY=2019, var=adj_pc_pm,    gt=&adj_pc_95p_19,    out=mu_pc_19,    MEAN=Mu_pc19);
%means_95p(FY=2020, var=adj_pc_pm,    gt=&adj_pc_95p_20,    out=mu_pc_20,    MEAN=Mu_pc20);
%means_95p(FY=2021, var=adj_pc_pm,    gt=&adj_pc_95p_21,    out=mu_pc_21,    MEAN=Mu_pc21);
%means_95p(FY=2022, var=adj_pc_pm,    gt=&adj_pc_95p_22,    out=mu_pc_22,    MEAN=Mu_pc22);

%means_95p(FY=2019, var=adj_rx_pm,    gt=&adj_rx_95p_19,    out=mu_rx_19,    MEAN=Mu_rx19);
%means_95p(FY=2020, var=adj_rx_pm,    gt=&adj_rx_95p_20,    out=mu_rx_20,    MEAN=Mu_rx20);
%means_95p(FY=2021, var=adj_rx_pm,    gt=&adj_rx_95p_21,    out=mu_rx_21,    MEAN=Mu_rx21);
%means_95p(FY=2022, var=adj_rx_pm,    gt=&adj_rx_95p_22,    out=mu_rx_22,    MEAN=Mu_rx22);

data int.mu_pctl_1922; 
merge mu_total_19       mu_total_20     mu_total_21     mu_total_22
      mu_pc_19          mu_pc_20        mu_pc_21        mu_pc_22
      mu_rx_19          mu_rx_20        mu_rx_21        mu_rx_22
      int.adj_total_pctl_a  int.adj_pc_pctl_a   int.adj_rx_pctl_a;
RUN; 

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

    *(see util_02_checks_dataset for checking value replacement); 
DATA raw.final_07;
SET  raw.final_06;
* replace values >95p with mu95;
IF      FY = 2019 AND adj_total_pm gt &adj_total_95p_19 THEN adj_pd_total_tc = &mu_total19; 
ELSE IF FY = 2020 AND adj_total_pm gt &adj_total_95p_20 THEN adj_pd_total_tc = &mu_total20; 
ELSE IF FY = 2021 AND adj_total_pm gt &adj_total_95p_21 THEN adj_pd_total_tc = &mu_total21; 
ELSE IF FY = 2022 AND adj_total_pm gt &adj_total_95p_22 THEN adj_pd_total_tc = &mu_total22; 
ELSE adj_pd_total_tc = adj_total_pm;

IF FY = 2019 AND adj_pc_pm         gt &adj_pc_95p_19    THEN adj_pd_pc_tc    = &mu_pc19;    
ELSE IF FY = 2020 AND adj_pc_pm    gt &adj_pc_95p_20    THEN adj_pd_pc_tc    = &mu_pc20;    
ELSE IF FY = 2021 AND adj_pc_pm    gt &adj_pc_95p_21    THEN adj_pd_pc_tc    = &mu_pc21;    
ELSE IF FY = 2022 AND adj_pc_pm    gt &adj_pc_95p_22    THEN adj_pd_pc_tc    = &mu_pc22; 
ELSE adj_pd_pc_tc = adj_pc_pm;

IF FY = 2019 AND adj_rx_pm         gt &adj_rx_95p_19    THEN adj_pd_rx_tc    = &mu_rx19;    
ELSE IF FY = 2020 AND adj_rx_pm    gt &adj_rx_95p_20    THEN adj_pd_rx_tc    = &mu_rx20;    
ELSE IF FY = 2021 AND adj_rx_pm    gt &adj_rx_95p_21    THEN adj_pd_rx_tc    = &mu_rx21; 
ELSE IF FY = 2022 AND adj_rx_pm    gt &adj_rx_95p_22    THEN adj_pd_rx_tc    = &mu_rx22;    
ELSE adj_pd_rx_tc = adj_rx_pm;

RUN; 

PROC SORT DATA = raw.final_07; by mcaid_id time; run; 

* 
ANALYSIS_DATASET_ALLCOLS ==================================================================
===========================================================================================;
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config_formats.sas"; 

DATA raw.final_08; 
SET  raw.final_07 (DROP = adj_total_pm adj_pc_pm adj_rx_pm) ; 
FORMAT budget_group budget_grp_new_.
       race         $race_rc_.;
age_cat = put(age, age_cat_.);
RUN; 

*** Add quarter variables, one with text for readability ; 
DATA raw.final_08 ;
SET  raw.final_07 (DROP = adj_total_pm adj_pc_pm adj_rx_pm
				   RENAME=(bho_n_hosp_16pm = BH_Hosp16
                           bho_n_hosp_17pm = BH_Hosp17
                           bho_n_hosp_18pm = BH_Hosp18
                           bho_n_er_16pm   = BH_ER16
                           bho_n_er_17pm   = BH_ER17
                           bho_n_er_18pm   = BH_ER18
                           bho_n_other_16pm= BH_Oth16
                           bho_n_other_17pm= BH_Oth17
                           bho_n_other_18pm= BH_Oth18
                           ));

ARRAY bh(*) BH_Hosp16  BH_Hosp17  BH_Hosp18
            BH_ER16    BH_ER17    BH_ER18
            BH_Oth16   BH_Oth17   BH_Oth18;

DO i=1 to dim(bh);
    IF bh(i)>0 THEN bh(i)=1; 
    ELSE bh(i)=bh(i);
    END;
DROP i; 

FORMAT budget_group budget_grp_new_.
       race         $race_rc_.;

age_cat = put(age, age_cat_.);
fyqrtr_txt = put(time,   fyqrtr_cat.); 
fyqrtr     = input(time, fyqrtr_num.);

IF      fyqrtr  = 1  THEN season1 = 1 ;
ELSE IF fyqrtr  = 4  THEN season1 = -1;
ELSE    season1 = 0; 

IF      fyqrtr  = 2  THEN season2 = 1 ;
ELSE IF fyqrtr  = 4  THEN season2 = -1;
ELSE    season2 = 0;  

IF      fyqrtr  = 3  THEN season3 = 1 ;
ELSE IF fyqrtr  = 4  THEN season3 = -1;
ELSE    season3 = 0;  

RUN; 

PROC SORT DATA = raw.final_08;
BY mcaid_id time; 
RUN; 

PROC FREQ 
     DATA = raw.final_08;
     TABLES age*age_cat ;* PLOTS = freqplot(type=dotplot scale=percent) out=out_ds;
RUN; 

PROC PRINT DATA= raw.final_08 (obs=25);
WHERE age_cat eq ' ';
RUN; * MANY missing age - WTF??';

PROC PRINT DATA=raw.FINAL_09_V1;
WHERE mcaid_id = "A005875";
RUN; * Not present in old one; 

* 
DATA.ANALYSIS ==============================================================================
with effect coding
===========================================================================================;
DATA data.analysis_allcols (DROP = i); 
SET  raw.final_09 (DROP = pcmp_loc_id
                          n_months_per_q
                          fyqrtr_txt
                          FY);

bh_2016 = 0; bh_2017=0; bh_2018=0;

ARRAY bh16(*) bh_hosp16 bh_er16 bh_oth16;
    DO i=1 to dim(bh16);
    IF bh16(i) = 1 then bh_2016 = 1;
END; 

ARRAY bh17(*) bh_hosp17 bh_er17 bh_oth17;
    DO i=1 to dim(bh17);
    IF bh17(i) = 1 then bh_2017 = 1;
END; 

ARRAY bh18(*) bh_hosp18 bh_er18 bh_oth18;
    DO i=1 to dim(bh18);
    IF bh18(i) = 1 then bh_2018 = 1;
END; 

RUN;

DATA data.analysis;
SET  data.analysis_allcols (DROP = bh_hosp:
                                   bh_er: 
                                   bh_oth:
                                   fyqrtr
                            );
LABEL adj_pd_total_16cat = 'Categorical pd_total FFS FY2016'
      adj_pd_total_17cat = 'Categorical pd_total FFS FY2017'
      adj_pd_total_18cat = 'Categorical pd_total FFS FY2018'
      n_pc_pm            = 'PC Visits PMPQ'
      n_ed_pm            = 'ED Visits PMPQ'
      n_ffs_bh_pm        = 'FFS BH Visits PMPQ'
      ind_pc_visit       = 'FFS PC Visit Count Positive'
      ind_ed_visit       = 'BH plus FFS ED Visit Count Positive'
      ind_ffs_bh_visit   = 'FFS BH Visit Count Positive'
      ind_tel_visit      = 'Telehealth Visit Count Positive'
      ind_total_cost     = 'FFS Total Cost Positive'
      ind_pc_cost        = 'PC Cost Positive'
      ind_rx_cost        = 'Rx Cost Positive'
      adj_pd_total_tc    = 'FFS total Cost PMPQ'
      adj_pd_pc_tc       = 'PC Cost PMPQ'
      adj_pd_rx_tc       = 'Rx Cost PMPQ'
      season1            = 'Effect Coding FYQ1'
      season2            = 'Effect Coding FYQ2'
      season3            = 'Effect Coding FYQ3'
      bh_2016            = 'FY16 Indicator of any bh_other bh_er bh_hosp'
      bh_2017            = 'FY17 Indicator of any bh_other bh_er bh_hosp'
      bh_2018            = 'FY18 Indicator of any bh_other bh_er bh_hosp';
RUN; * down to 33 variables; 

* 
DATA.MINI_DS ==============================================================================
VERSION 06/05 
Reduced, testing dataset of 500k records from data.analysis with same int proportion
Step 1: ds has to be sorted on grouping var
Step 2: specify nrow, allocation, and strata
Step 3: Check frequency to test

06/05 Passed check
===========================================================================================;
* Step 1;
proc sort data = data.analysis;
by int ;
run;

* Step 2;
PROC SURVEYSELECT 
DATA = data.analysis
n    = 500000
OUT  = data.mini_ds;
STRATA int / alloc=prop;
RUN;

* Step 3; 
PROC FREQ DATA = data.mini_ds;
tables int; 
run;


