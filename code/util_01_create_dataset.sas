*
AUTHOR   : KTW
PROJECT  : ISP Utilization Analysis
PURPOSE  : Gather, Process datasets from analytic subset dir
VERSION  : 2023-04-24 somehow had >1 mcaid_id from budget group_new idk [date last updated]
DEPENDS  : ana subset folder, config file [dependencies]
NEXT     : [left off on row... or what step to do next... ]  ;

%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 
***********************************************************************************************;

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
 
DATA raw.qrylong2 (DROP = dob dt_end_19 dt_end_fy age_end_19 rename=(age_end_fy=age)); 
SET  raw.qrylong1;
FORMAT dt_end_fy dt_end_19 date9.;

FY          = year(intnx('year.7', month, 0, 'BEGINNING'));
dt_end_fy   = mdy(6,30,(FY+1));
dt_end_19   = mdy(6,30,2019);
age_end_FY  = floor( (intck('month', dob, dt_end_fy) - (day(dt_end_fy) < min(day(dob), day(intnx ('month', dt_end_fy, 1) -1)))) /12 );
age_end_19  = floor( (intck('month', dob, dt_end_19) - (day(dt_end_19) < min(day(dob), day(intnx ('month', dt_end_19, 1) -1)))) /12 );
IF age_end_FY ge 65 then delete;
IF age_end_19 ge 65 then delete;

PCMP2 = input(pcmp_loc_id, best12.);
drop pcmp_loc_id; 
rename pcmp2 = pcmp_loc_id; 

RUN; *4/27 70039138: 11;

%nodupkey(ds=raw.qrylong2, out=raw.qrylong3);

* Create time variable from dt_qrtr (or month, but dt_qrtr faster bc same); 
%create_qrtr(data=raw.qrylong3, set=raw.qrylong3, var= dt_qrtr, qrtr=time);

* DO NOT DROP dt_qrtr or month until you have removed the vars and gotten unique group max / if thens; 
DATA  raw.FY1921_0 ; 
SET   raw.qrylong3 (WHERE=(rae_person_new ne . AND FY in (2019,2020,2021) AND SEX IN ('F','M')));
RUN ;  *4/24 40958510;

* subset raw.qrylong by the mcaid_id's in FY1921_0; 
PROC SQL; 
CREATE TABLE raw.qrylong4 AS 
SELECT *
FROM raw.qrylong3
WHERE mcaid_id IN (SELECT mcaid_id FROM raw.fy1921_0);
QUIT; 

************************************************************************************
***  Creates work.budget, work.county, work.rae, and check that no mcaid_id n>12;
%INCLUDE "&util/code/incl_extract_check_fy19210.sas";
************************************************************************************

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

*keep month and dt_qrtr so you can merge util vars in later; 
DATA raw.FY1921_1;
SET  raw.FY1921_0 (drop=enr_cnty rae_person_new budget_group);
RUN; *4/27 40958510 : 11; 

%concat_id_time(ds=raw.FY1921_1);

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
     , b.pcmp_loc_id 
     , b.n_months_per_q
     , b.ind_isp AS int
     , c.budget_group
/*     , d.enr_cnty*/
     , e.rae_person_new
     , f.fqhc
     , g.time2 as time_start_isp
     , case WHEN g.time2 ne . 
            AND  a.time >= g.time2
            THEN 1 ELSE 0 end AS int_imp

FROM raw.FY1921_1                    AS A
LEFT JOIN int.memlist_attr_qrtr_1921 AS B   ON A.id_time_helper = B.id_time_helper
LEFT JOIN budget                     AS C   ON A.id_time_helper = C.id_time_helper
/*LEFT JOIN county                     AS D   ON A.id_time_helper = D.id_time_helper*/
LEFT JOIN rae                        AS E   ON A.id_time_helper = E.id_time_helper
LEFT JOIN raw.pcmp_type              AS F   ON B.pcmp_loc_id    = F.pcmp_loc_id   
LEFT JOIN int.isp_un_pcmp_dtstart    AS G   ON b.pcmp_loc_id    = G.pcmp_loc_id    ;
QUIT ;  *4/27 pm 40958510 : 18 ; 

proc freq data = raw.final0;
tables dt_qrtr*time;
RUN; 

* PROBLEM : FIX LATER - 27 that are missing. Create qrylong4 where pcmp_ not ne, 
              but come back to qrylong3 when get logic right; 
DATA  raw.final1;
SET   raw.final0   (DROP=time_start_isp month WHERE=(pcmp_loc_id ne .)); *FIX THIS LATER!!; 
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
RUN; *4/27 pm 40958444 : 18 ;

* REMOVE DUPLICATES, then merge with int.qrylong1622;
%nodupkey(raw.final1, raw.final1); *14039776;

***********************************************************************************************
***  SECTION01 Get Monthly Utilization Data
***********************************************************************************************;
DATA    raw.util0; 
SET     ana.qry_monthlyutilization (WHERE=(month ge '01Jul2016'd AND month le '30Jun2022'd));
FORMAT  dt_qrtr date9.;
dt_qrtr =intnx('QTR', month, 0, 'BEGINNING'); 
FY      =year(intnx('year.7', month, 0, 'BEGINNING'));
run;

PROC SQL;
CREATE TABLE raw.util1 as
SELECT a.*
     , (a.pd_amt/b.index_2021_1) AS adj_pd_amount 
FROM   raw.util0        AS A
LEFT JOIN int.adj   AS b    ON a.dt_qrtr=b.date;
quit; *66382081 : 7 cols; 

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
quit; *66382081 : 12; 

%nodupkey(ds=util2, out=raw.util3); *32835706, 12; 

*----------------------------------------------------------------------------------------------
SECTION 02 GET BH monthly utilization 
----------------------------------------------------------------------------------------------;
DATA raw.bh0;
SET  ana.qry_bho_monthlyutilization; 
format dt_qrtr month2 date9.; 
dt_qrtr = intnx('quarter', month ,0,'b');
month2 = month; DROP month; RENAME month2 = month; /* make numeric, for some reason month coming in as character*/
WHERE  month ge '01Jul2016'd AND  month le '01Jul2022'd;
FY     =year(intnx('year.7', month, 0, 'BEGINNING'));
run; *4208734 observations and 7 variables;

%create_qrtr(data=raw.bh1, set=raw.bh0, var = dt_qrtr, qrtr=time);

***************************************************************************
* raw.qrylong5
    join bh and util to qrylong to get averages (all utils - monthly, bho, telehealth) to qrylong4
    drop the demo vars because the good ones are on raw.final1
***************************************************************************; 
PROC SQL; 
CREATE TABLE raw.qrylong5 AS 
SELECT a.mcaid_id, a.month, a.dt_qrtr, a.FY, a.time
     , b.*
     , c.*
     , d.n_q_tele
FROM raw.qrylong4       AS A
LEFT JOIN raw.bh1       AS B    ON a.mcaid_id=B.mcaid_id AND a.month=B.month
LEFT JOIN raw.util3     AS C    ON a.mcaid_id=C.mcaid_id AND a.month=C.month
LEFT JOIN int.tele_1921 AS D    ON a.mcaid_id=D.mcaid_id AND a.time =D.time;
QUIT;  * 65420507 rows and 21 columns.;

***************************************************************************
* JOIN TO FY1618_0, KEEPING 1618 var values
    These will be averaged by FY
***************************************************************************; 
DATA raw.FY1618_0; 
SET  raw.qrylong5;
WHERE month lt '01Jul2019'd; 
RUN; *24441787; 

* WHOA TOTALLY DIFFERENT!!! ; 
PROC SQL;
CREATE TABLE raw.FY1618_1 as
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

FROM raw.FY1618_0
GROUP BY mcaid_id;
QUIT; * 1148294;

* change adj to if elig = 0, then adj var = -1 and set bh variables to 0 where .; 
DATA raw.FY1618_2;
SET  raw.FY1618_1;

IF   elig2016 = 0    THEN adj_pd_16pm = -1; 
ELSE IF elig2016 = 1 AND  adj_pd_16pm = .   THEN adj_pd_16pm = 0;
ELSE adj_pd_16pm = adj_pd_16pm; 

IF   elig2017 = 0    THEN adj_pd_17pm = -1; 
ELSE IF elig2017 = 1 AND  adj_pd_17pm = .   THEN adj_pd_17pm = 0;
ELSE adj_pd_17pm = adj_pd_17pm; 

IF   elig2018 = 0    THEN adj_pd_18pm = -1; 
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

RUN; 

** GET PERCENTILES FOR ALL & TOP CODE DV's FOR MEMBERS ONLY ; 
* 1618; 
%macro pctl_1618(var,out,pctlpre);
proc univariate noprint data=raw.FY1618_2; 
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
/*Obs 2=p16_50  3=p16_75   4=p16_90+   5=p16_95+      p17_50  p17_75  p17_90   p17_95      2=p18_50  3=p18_75  4=p18_90  5=p18_95 */
/*      265.816 510.805    1191.77     2079.20        268.108 516.322 1231.88  2254.61      279.017  555.933   1382.46   2633.40 */

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
;
%mend;

* Made separate ds's for testing but merge if poss later, save final to int/; 
%insert_pctile(ds_in = raw.fy1618_2,    ds_out = adj0,          year = 16);
%insert_pctile(ds_in = adj0,            ds_out = adj1,          year = 17);
%insert_pctile(ds_in = adj1,            ds_out = int.FY1618,    year = 18); *1148294;

* Join to FY1618 to final in int.final_a ;
PROC SQL;
CREATE TABLE int.final_a AS 
SELECT a.*
     , b.*
FROM raw.final1 AS A
LEFT JOIN int.FY1618    AS B    ON a.mcaid_id=b.mcaid_id;
QUIT;

********************************************************************
1921
********************************************************************;
DATA raw.FY1921_0;
SET  raw.qrylong5;
WHERE month ge '01JUL2019'd;
RUN; *5/1 40978720 // prev 4/28 41962377;

*** 1921 DV's *** ; 
** AVERAGE the quarter PM costs, then get 95th percentiles for FY's ; 
PROC SQL;
CREATE TABLE raw.FY1921_1 as
SELECT mcaid_id
     , count(*) as n_months_per_q
     , time
     , FY
     , avg(n_pc)                as n_pc_pm
     , avg(sum(n_er, bho_n_er)) as n_ed_pm
     , avg(n_ffs_bh)            as n_ffs_bh_pm
     , avg(n_q_tele)            as n_tel_pm
     , avg(adj_pd_total)        as adj_total_pm
     , avg(adj_pd_pc)           as adj_pc_pm
     , avg(adj_pd_rx)           as adj_rx_pm

FROM raw.FY1921_0
GROUP BY mcaid_id, time;
QUIT; * 40978720 : 11; 

%nodupkey(ds=raw.FY1921_1, out=int.FY1921); * 14045957; 

* JOIN TO FINAL as int.final_b;
PROC SQL; 
CREATE TABLE int.final_b AS 
SELECT a.*
     , b.*
FROM int.final_a AS A
LEFT JOIN raw.fy1921_2 AS B ON a.mcaid_id=b.mcaid_id AND a.time=b.time;
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

****see 02_checks for elig table creation ; 

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

