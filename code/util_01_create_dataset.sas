*
AUTHOR   : KTW
PROJECT  : ISP Utilization Analysis
PURPOSE  : Gather, Process datasets from analytic subset dir, Create final analysis dataset and mini dataset
VERSION  : 2023-06-01
           - updated 5/30 due to issues in the hcpf file and to get Sept 2022 since it's available now (cs email re: hcpf)
           - updated 06-01 bc ana.long & ana.demo were missing months
DEPENDS  : -ana subset folder, config file, 
           -%include helper file in code/util_dataset_prep/incl_extract_check_fy19210.sas
           -other macro code referenced is stored in the util_00_config.sas file
OUTPUT
SECTION1 : data.analysis
SECTION2 : data.analysis_allcols
SECTION3 : data.mini_ds (test set with only 500000 records) ;

%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 
***********************************************************************************************;

* QRYLONG_1622_0 ==============================================================================
* 1. SUBSET qry_longitudinal to timeframe (months le/ge) AND:
     -- budget_groups
     -- sex not Unknown
     -- pcmp_loc_id not missing
     -- managedCare not 0
     NB: Can't subset to records with an RAE yet since that would exclude FY16-18 records
  3. Create dt_qrtr: the first month of the quarter that the record was in; 
 
DATA   raw.qrylong_1622_0;
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


format dt_qrtr date9.; 
dt_qrtr = intnx('quarter', month ,0,'b'); 

WHERE  month ge '01Jul2016'd 
AND    month le '30Sep2022'd 
AND    BUDGET_GROUP not in (16,17,18,19,20,21,22,23,24,25,26,27,-1,)
AND    managedCare = 0
AND    pcmp_loc_id ne ' '
;
RUN;  *6/01 75691244;

* INT.PCMP_DIM ==============================================================================
DESCR: Extract unique pcmp_loc_ids and their dimensions, stored as a reference table, that:
1. Reduces qrylong for interim processing steps,
2. Reduces pcmp_loc_ids to unique records for faster calculations:
    2a: convert pcmp_loc_id to numeric
3. Create binary covariate FQHC from pcmp_loc_type_cd values (rather than formats) 
********************************************************************************************;
DATA pcmp_type_qrylong ; 
SET  raw.qrylong_1622_0 (KEEP = pcmp_loc_id  pcmp_loc_type_cd  num_pcmp_type  pcmp_loc_type_cd 
                         WHERE= (pcmp_loc_id ne ' ')
                         ) ;
num_pcmp_type = input(pcmp_loc_type_cd, 7.);
pcmp_loc2     = input(pcmp_loc_id, best12.); DROP pcmp_loc_id; RENAME pcmp_loc2=pcmp_loc_id;
RUN ; 

PROC SORT DATA = pcmp_type_qrylong NODUPKEY ; BY _ALL_ ; RUN ; *4/26 1446 obs;

DATA int.pcmp_dim;
SET  pcmp_type_qrylong;
IF pcmp_loc_type_cd in (32 45 61 62) then fqhc = 1 ; else fqhc = 0 ;
RUN; *1449;

** join with demographics to get required demographics in all years 
join on enr_county then can remove; 
PROC SQL; 
CREATE TABLE raw.qrylong_1622_1 AS
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
FROM raw.qrylong_1622_0         AS A 
LEFT JOIN ana.qry_demographics  AS B ON a.mcaid_id=b.mcaid_id 
LEFT JOIN int.rae_dim           AS C ON a.enr_cnty = c.hcpf_county_code_c
WHERE  pcmp_loc_id ne ' '
AND    SEX IN ('F','M');
QUIT;   *06-01 75690836 : 10 cols;
 
DATA raw.qrylong_1622_2 (DROP = enr_cnty dob dt_end_19 dt_end_fy age_end_19 rename=(age_end_fy=age)); 
SET  raw.qrylong_1622_1;
FORMAT dt_end_fy dt_end_19 date9.;
FY          = year(intnx('year.7', month, 0, 'BEGINNING'));
dt_end_fy   = mdy(6,30,(FY+1));
dt_end_19   = mdy(6,30,2019);
age_end_FY  = floor((intck('month', dob, dt_end_fy)-(day(dt_end_fy) < min(day(dob), day(intnx('month', dt_end_fy, 1) -1)))) /12);
age_end_19  = floor((intck('month', dob, dt_end_19)-(day(dt_end_19) < min(day(dob), day(intnx('month', dt_end_19, 1) -1)))) /12);
IF age_end_FY ge 65 then delete;
IF age_end_19 ge 65 then delete;
PCMP2 = input(pcmp_loc_id, best12.); DROP pcmp_loc_id; RENAME pcmp2 = pcmp_loc_id; 
RUN; *6/01 72764997;

%nodupkey(ds=raw.raw.qrylong_1622_2, out=raw.qrylong_1622_2); *none;

* Create time variable from dt_qrtr (or month, but dt_qrtr faster bc same); 
%create_qrtr(data=raw.qrylong_1622_2, set=raw.qrylong_1622_2, var=dt_qrtr, qrtr=time);


* 1 Get final member list (final00), where:
    -- FY = 19-22 (via time ne .), and 
    -- an RAE is assigned (rae's didn't exist prior to 2019, so all rae values are . for FYs 16-18)
  NB: don't drop dt_qrtr or month yet 
    (still need to be extracted, filtered to max or most recent if tied), and re-joined)

  2 Will use final00 mcaid_ids to subset the qrylong_xx_x
  ----NB: * DO NOT DROP dt_qrtr or month ; 

DATA  raw.final00 ; 
SET   raw.qrylong_1622_2 (WHERE=(rae_person_new ne . AND time ne .));
RUN ;  *6/1 44079193;

* subset raw.qrylong_1622_3 by the mcaid_id's in raw.qrylong_1622_2; 
PROC SQL; 
CREATE TABLE raw.qrylong_1622_3 AS 
SELECT *
FROM raw.qrylong_1622_2
WHERE mcaid_id IN (SELECT mcaid_id FROM raw.final00);
QUIT; *6/1 68079369 (removes about 4685628 records); 

************************************************************************************
Creates --int.n_id_months_per_q (which you don't need yet but to confirm / check if you want:
           this is calculated in rows 450+)
        --int.pcmp_att_qrtr,
        --work.budget, 
        --work.rae,
    and checks that no mcaid_id n>13
-- Depends on raw.qrylong_1922_0;

%INCLUDE "&util/code/util_dataset_prep/incl_extract_check_fy1922.sas";

* all have 15104152 rows; 
************************************************************************************;
%macro concat_id_time(ds=);
DATA &ds;
SET  &ds;
id_time_helper = CATX('_', mcaid_id, time); 
RUN; 
%mend; 

* Created helper var for joins (was taking a long time and creating rows without id, idk why, so did this as quick fix for now); 
%concat_id_time(ds=budget            );
%concat_id_time(ds=rae               );
%concat_id_time(ds=int.pcmp_attr_qrtr);
%concat_id_time(ds=raw.final00       );

******************************************************************************************************
*** CREATE raw.final0
    JOINS, Unique values, save as int.
******************************************************************************************************;
PROC SQL ; 
CREATE TABLE raw.final0 AS 
SELECT a.mcaid_id
     , a.dt_qrtr
     , a.month
     , a.FY
     , a.age
     , a.race
     , a.sex
     , a.time
     , a.id_time_helper
     , b.budget_group
     , c.rae_person_new
     , d.pcmp_loc_id
     , d.int
     , e.fqhc
     , f.time2 as time_start_isp
     , case WHEN f.time2 ne . 
            AND  a.time >= f.time2
            THEN 1 ELSE 0 end AS int_imp

FROM raw.final00               AS A
LEFT JOIN budget                     AS B   ON A.id_time_helper = B.id_time_helper
LEFT JOIN rae                        AS C   ON A.id_time_helper = C.id_time_helper
LEFT JOIN int.pcmp_attr_qrtr         AS D   ON A.id_time_helper = D.id_time_helper
LEFT JOIN int.pcmp_dim               AS E   ON D.pcmp_loc_id    = E.pcmp_loc_id   
LEFT JOIN int.isp_un_pcmp_dtstart    AS F   ON D.pcmp_loc_id    = F.pcmp_loc_id    ;
QUIT ;  *6/1 44079193 : 16 ; 
 
DATA  raw.final1;
SET   raw.final0   (DROP=time_start_isp month);
LABEL pcmp_loc_id     = "pcmp_loc_ID"
      FY              = "FY 19, 20, 21, and FYQ1 of 2023"
      age             = "Age: 0-64 only"
      sex             = "Sex"
      time            = "Linearized qrtrs, 1-13"
      id_time_helper  = "interim var for matching"
      int             = "ISP Participation: Time Invariant"
      budget_group    = "Budget Group (subsetting var)"
      rae_person_new  = "RAE ID"
      fqhc            = "FQHC: 0 No, 1 Yes"
      int_imp         = "ISP Participation: Time-Varying"
      ;
RUN; * ;

* REMOVE DUPLICATES, then merge with int.qrylong1622;
%nodupkey(raw.final1, raw.final1); *6/01 15104152;

***********************************************************************************************
***  SECTION01 Get Monthly Utilization Data
***********************************************************************************************;
DATA    raw.util0; 
SET     ana.qry_monthlyutilization (WHERE=(month ge '01Jul2016'd AND month le '30Sep2022'd));
FORMAT  dt_qrtr date9.;
dt_qrtr =intnx('QTR', month, 0, 'BEGINNING'); 
FY      =year(intnx('year.7', month, 0, 'BEGINNING'));
run;

PROC SQL;
CREATE TABLE raw.util1 as
SELECT a.*
     , (a.pd_amt/b.index_2021_1) AS adj_pd_amount 
FROM   raw.util0    AS A
LEFT JOIN int.adj   AS b    ON a.dt_qrtr=b.date
WHERE mcaid_id IN (SELECT mcaid_id FROM raw.final1);
quit; *57668708 : 8 cols; 

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
quit; *6/1 57668708 : 12; 

%nodupkey(ds=raw.util2, out=raw.util3); *6/1 28391654, 12; 

*----------------------------------------------------------------------------------------------
SECTION 02 GET BH monthly utilization 
----------------------------------------------------------------------------------------------;
DATA raw.bh0;
SET  ana.qry_bho_monthlyutilization; 
format dt_qrtr month2 date9.; 
dt_qrtr = intnx('quarter', month ,0,'b');
month2  = month; DROP month; RENAME month2 = month; /* make numeric, for some reason month coming in as character*/
WHERE   month ge '01Jul2016'd AND  month le '30Sep2022'd;
FY      = year(intnx('year.7', month, 0, 'BEGINNING'));
run; *4618851 observations and 8 variables;

%create_qrtr(data=raw.bh1, set=raw.bh0, var = dt_qrtr, qrtr=time);

***************************************************************************
* raw.qrylong4
    join bh and util to qrylong to get averages (all utils - monthly, bho, telehealth) to qrylong4
    drop the demo vars because the good ones are on raw.final1
***************************************************************************; 
PROC SQL; 
CREATE TABLE raw.qrylong_1622_4 AS 
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
FROM raw.qrylong_1622_3        AS A
LEFT JOIN raw.bh1              AS B    ON a.mcaid_id=B.mcaid_id AND a.month=B.month
LEFT JOIN raw.util3            AS C    ON a.mcaid_id=C.mcaid_id AND a.month=C.month
LEFT JOIN int.tel_fact_1922_m  AS D    ON a.mcaid_id=D.mcaid_id AND a.month=D.month;
QUIT;  * 68079369 rows and 18 columns.;

***************************************************************************
* JOIN TO FY1618_0, KEEPING 1618 var values
    These will be averaged by FY
***************************************************************************; 
DATA raw.qrylong_1618_0; 
SET  raw.qrylong_1622_4;
WHERE month lt '01Jul2019'd; 
RUN; *23976758; 

PROC SQL;
CREATE TABLE raw.qrylong_1618_1 as
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

FROM raw.qrylong_1618_0
GROUP BY mcaid_id;
QUIT; * 6/01 1131492;

* change adj to if elig = 0, then adj var = -1 and set bh variables to 0 where .; 
DATA raw.qrylong_1618_2;
SET  raw.qrylong_1618_1;

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
proc univariate noprint data=raw.qrylong_1618_2; 
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
* From 5/31
/*Obs 2=p16_50  3=p16_75   4=p16_90+   5=p16_95+      p17_50  p17_75  p17_90   p17_95      2=p18_50  3=p18_75  4=p18_90  5=p18_95 */
/*      265.823 510.293     1189.74     2075.47     268.400   516.613 1232.43  2254.97     279.660   557.247   1386.54   2640.50 */

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
%insert_pctile(ds_in = raw.qrylong_1618_2,ds_out = adj0,             year = 16);
%insert_pctile(ds_in = adj0,              ds_out = adj1,             year = 17);
%insert_pctile(ds_in = adj1,              ds_out = int.qrylong_1618, year = 18); *1131492;

* Join to FY1618 to final --prev raw.final2 was int.final2 ;
PROC SQL;
CREATE TABLE raw.final2 AS 
SELECT a.*
     , b.*
FROM raw.final1             AS A
LEFT JOIN int.qrylong_1618  AS B ON a.mcaid_id=b.mcaid_id;
QUIT;

********************************************************************
FYs 19-22
********************************************************************;
DATA raw.qrylong_1922_0;
SET  raw.qrylong_1622_4 (where=(time ne .)); 
RUN; 
** AVERAGE the quarter PM costs, then get 95th percentiles for FY's ; 
PROC SQL;
CREATE TABLE raw.dvs_1922 as
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
FROM raw.qrylong_1622_4
GROUP BY mcaid_id, time
WHERE time ne . ;
QUIT; * 6/1 44079193 rows and 11 columns.; 

%nodupkey(ds=raw.qrylong_1922_1, out=raw.qrylong_1922_2); * 15111321; 

PROC SORT DATA = raw.final2;         BY mcaid_id time; 
PROC SORT DATA = raw.qrylong_1922_2; BY mcaid_id time; RUN;

data  mismatch;
merge raw.final2 (in=in1 keep=mcaid_id time) raw.qrylong_1922_2 (in=in2 keep=mcaid_id time);
by mcaid_id time;
if in2 and not in1 then output mismatch;
run; 

WHERE mcaid_id NOT IN (SELECT mcaid_id FROM raw.final2)
AND   time  NOT IN (SELECT time from raw.final1)
GROUP BY mcaid_id, time;
QUIT; 

* JOIN TO FINAL as int.final_b;
PROC SQL; 
CREATE TABLE raw.final3 AS 
SELECT a.*
     , b.*
FROM raw.final2 AS A
LEFT JOIN raw.qrylong_1922_2 AS B ON a.mcaid_id=b.mcaid_id AND a.time=b.time;
QUIT: 

* might need to grab the mcaid_id's to confirm they're -1?? Print 200 ... ; 
PROC PRINT DATA = int.final_b (obs=200); WHERE adj_pd_total_16cat = .; RUN; 

* setting to 0 where . for variables not using elig category (adj 16-18 vars) 
    create indicator variables for DV's where >0 
    (use when creating pctiles or just in gee but needed eventually anyway);
DATA int.final_c;
SET  int.final_b; 
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
RUN;  *14039776 : 48 ; 

* Keep final_c but remove some cols for final_d; 
DATA int.final_d;
SET  int.final_c (DROP = dt_qrtr id_time_helper elig: adj_pd_16pm adj_pd_17pm adj_pd_18pm);
RUN;

proc sort data = int.final_d; BY FY; run; 

** GET PERCENTILES FOR ALL & TOP CODE DV's FOR member linelist ONLY ; 

%macro pctl_1921(var, out, pctlpre, t_var);
PROC UNIVARIATE DATA = int.final_d;
BY FY; 
WHERE &VAR gt 0; 
VAR   &VAR;
OUTPUT OUT=&out pctlpre=&pctlpre pctlpts=95;
RUN; 

PROC TRANSPOSE DATA = &out  
OUT=&out._a (DROP   = _name_ _label_
             RENAME = (col1 = &t_var.p_19
                       col2 = &t_var.p_20
                       col3 = &t_var.p_21));
var &t_var ; 
RUN; 
%mend; 

%pctl_1921(var = adj_total_pm,   out = int.adj_total_pctl,   pctlpre = adj_total_,  t_var = adj_total_95); 
%pctl_1921(var = adj_pc_pm,      out = int.adj_pc_pctl,      pctlpre = adj_pc_,     t_var = adj_pc_95); 
%pctl_1921(var = adj_rx_pm,      out = int.adj_rx_pctl,      pctlpre = adj_rx_,     t_var = adj_rx_95); 

data int.pctl1921; merge int.adj_total_pctl_a int.adj_pc_pctl_a int.adj_rx_pctl_a ; run;

PROC PRINT DATA = int.pctl1921; RUN; 
/*Obs   adj_total_95p_19    adj_total_95p_20   adj_total_95p_21    adj_pc_95p_19    adj_pc_95p_20   adj_pc_95p_21     adj_rx_95p_19   adj_rx_95p_20   adj_rx_95p_21 
/*      3956.               3726               3643                 365.496         352.932         342.476             1075.19         1146.91         1157.65 */

* https://stackoverflow.com/questions/60097941/sas-calculate-percentiles-and-save-to-macro-variable;
proc sql noprint;
  select name, cats(':',name)
  into 
    :COL_NAMES separated by ',', 
    :MVAR_NAMES separated by ','
  from sashelp.vcolumn 
  where libname = "INT" 
    and memname = "PCTL1921";
  select &COL_NAMES into &MVAR_NAMES
  from int.pctl1921;
quit;

%MACRO means_95p(fy=,var=,gt=,out=,mean=);
PROC UNIVARIATE NOPRINT DATA = int.final_d; 
WHERE FY=&FY 
AND   &VAR gt &gt;
VAR   &VAR;
OUTPUT OUT=&out MEAN=&mean; RUN; 
%MEND;

* tried with proc means to compare to macro and got exact same results; 
%means_95p(FY=2019, var=adj_total_pm, gt=&adj_total_95p_19, out=mu_total_19, MEAN=Mu_total19);
%means_95p(FY=2020, var=adj_total_pm, gt=&adj_total_95p_20, out=mu_total_20, MEAN=Mu_total20);
%means_95p(FY=2021, var=adj_total_pm, gt=&adj_total_95p_21, out=mu_total_21, MEAN=Mu_total21);

%means_95p(FY=2019, var=adj_pc_pm,    gt=&adj_pc_95p_19,    out=mu_pc_19,    MEAN=Mu_pc19);
%means_95p(FY=2020, var=adj_pc_pm,    gt=&adj_pc_95p_20,    out=mu_pc_20,    MEAN=Mu_pc20);
%means_95p(FY=2021, var=adj_pc_pm,    gt=&adj_pc_95p_21,    out=mu_pc_21,    MEAN=Mu_pc21);

%means_95p(FY=2019, var=adj_rx_pm,    gt=&adj_rx_95p_19,    out=mu_rx_19,    MEAN=Mu_rx19);
%means_95p(FY=2020, var=adj_rx_pm,    gt=&adj_rx_95p_20,    out=mu_rx_20,    MEAN=Mu_rx20);
%means_95p(FY=2021, var=adj_rx_pm,    gt=&adj_rx_95p_21,    out=mu_rx_21,    MEAN=Mu_rx21);

data int.mu_pctl_1921; 
merge mu_total_19       mu_total_20     mu_total_21
      mu_pc_19          mu_pc_20        mu_pc_21
      mu_rx_19          mu_rx_20        mu_rx_21
      int.adj_total_pctl_a  int.adj_pc_pctl_a   int.adj_rx_pctl_a;
RUN; 

proc sql noprint;
  select name, cats(':',name)
  into 
    :COL_NAMES separated by ',', 
    :MVAR_NAMES separated by ','
  from sashelp.vcolumn 
  where libname = "INT" 
    and memname = "MU_PCTL_1921";
  select &COL_NAMES into &MVAR_NAMES
  from int.mu_pctl_1921;
quit;

    *(see util_02_checks_dataset for checking value replacement); 
DATA int.final_e;
SET  int.final_d;
* replace values >95p with mu95;
IF      FY = 2019 AND adj_total_pm gt &adj_total_95p_19 THEN adj_pd_total_tc = &mu_total19; 
ELSE IF FY = 2020 AND adj_total_pm gt &adj_total_95p_20 THEN adj_pd_total_tc = &mu_total20; 
ELSE IF FY = 2021 AND adj_total_pm gt &adj_total_95p_21 THEN adj_pd_total_tc = &mu_total21; 
ELSE adj_pd_total_tc = adj_total_pm;

IF FY = 2019 AND adj_pc_pm         gt &adj_pc_95p_19    THEN adj_pd_pc_tc    = &mu_pc19;    
ELSE IF FY = 2020 AND adj_pc_pm    gt &adj_pc_95p_20    THEN adj_pd_pc_tc    = &mu_pc20;    
ELSE IF FY = 2021 AND adj_pc_pm    gt &adj_pc_95p_21    THEN adj_pd_pc_tc    = &mu_pc21;    
ELSE adj_pd_pc_tc = adj_pc_pm;

IF FY = 2019 AND adj_rx_pm         gt &adj_rx_95p_19    THEN adj_pd_rx_tc    = &mu_rx19;    
ELSE IF FY = 2020 AND adj_rx_pm    gt &adj_rx_95p_20    THEN adj_pd_rx_tc    = &mu_rx20;    
ELSE IF FY = 2021 AND adj_rx_pm    gt &adj_rx_95p_21    THEN adj_pd_rx_tc    = &mu_rx21;    
ELSE adj_pd_rx_tc = adj_rx_pm;

RUN; 

PROC SORT DATA = int.final_e; by mcaid_id time; run; 

****see 02_checks for elig table creation 
START ANALYSIS_ALLCOLS; 

DATA analysis_dataset_allcols; 
SET  int.final_e (DROP = adj_total_pm adj_pc_pm adj_rx_pm enr_cnty) ; 
FORMAT budget_group budget_grp_new_.
       race         $race_rc_.
       age          age_cat_. ;
RUN; 

PROC CONTENTS DATA = data.analysis_dataset_allcols VARNUM; 
RUn; 

*** UPDATE 05/10 add quarter variables, one with text for readability ; 
proc format; 
value fyqrtr_cat
1  = "Q1"
2  = "Q2"
3  = "Q3"
4  = "Q4"
5  = "Q1"
6  = "Q2"
7  = "Q3"
8  = "Q4"
9  = "Q1"
10 = "Q2"
11 = "Q3"
12 = "Q4";

invalue fyqrtr_num
1  = 1
2  = 2
3  = 3
4  = 4
5  = 1
6  = 2
7  = 3
8  = 4
9  = 1
10 = 2
11 = 3
12 = 4;
RUN;

DATA data.analysis_allcols;
SET  analysis_dataset_allcols (RENAME=(bho_n_hosp_16pm = BH_Hosp16
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

fyqrtr_txt = put(time,   fyqrtr_cat.); 
fyqrtr     = input(time, fyqrtr_num.);

RUN; 

PROC SORT DATA = data.analysis_allcols;
BY mcaid_id time; 
RUN; 

PROC FREQ DATA = data.analysis_allcols;
TABLES fyqrtr;
RUN; 


*** UPDATE 05-15-2023: Effect coding, creating season: for time via fyqrtr; 
* Remove some columns you won't use in analysis - if running frequencies, use the allcols ds ; 
DATA data.analysis; 
SET  data.analysis_allcols (DROP = pcmp_loc_id
                                   n_months_per_q
                                   fyqrtr_txt
                                   FY);
* Effect coding > Create seasonal effect indicator values; 
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


*** Create mini_ds; 
* Extract 500000 records for testing / running bootstrap programs 

* Get about a 1:10 ratio just so you make sure you have all variables
100000 with intervention, 900000 without; 
proc sort data = data.analysis;
by int ;
run;

PROC SURVEYSELECT 
DATA = data.analysis
n    = 500000
OUT  = data.mini_ds;
STRATA int / alloc=prop;
RUN;

PROC FREQ DATA = mini;
tables int; 
run;


