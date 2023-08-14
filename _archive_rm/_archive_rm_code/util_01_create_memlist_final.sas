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

%sort4merge(ds1=raw.FY1921_0, ds2=raw.qrylong2, by=mcaid_id);

* subset raw.qrylong by the mcaid_id's in FY1921_0; 
PROC SQL; 
CREATE TABLE raw.qrylong4 AS 
SELECT *
FROM raw.qrylong3
WHERE mcaid_id IN (SELECT mcaid_id FROM raw.fy1921_0);
QUIT; 

************************************************************************************
***  RUNFILE HERE (need downstream) 
***  Creates work.budget, work.county, work.rae, and check that no mcaid_id n>12;

%INCLUDE "&util/code/incl_extract_check_memlist0.sas";
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
*** CREATE int.memlist_final
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
     , d.enr_cnty
     , e.rae_person_new
     , f.fqhc
     , g.time2 as time_start_isp
     , case WHEN g.time2 ne . 
            AND  a.time >= g.time2
            THEN 1 ELSE 0 end AS int_imp

FROM raw.FY1921_1                    AS A
LEFT JOIN int.memlist_attr_qrtr_1921 AS B   ON A.id_time_helper = B.id_time_helper
LEFT JOIN budget                     AS C   ON A.id_time_helper = C.id_time_helper
LEFT JOIN county                     AS D   ON A.id_time_helper = D.id_time_helper
LEFT JOIN rae                        AS E   ON A.id_time_helper = E.id_time_helper
LEFT JOIN raw.pcmp_type              AS F   ON B.pcmp_loc_id    = F.pcmp_loc_id   
LEFT JOIN int.isp_un_pcmp_dtstart    AS G   ON b.pcmp_loc_id    = G.pcmp_loc_id    ;
QUIT ;  *4/27 pm 40958510 : 18 ; 

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

        %macro count_ids_memlist_final;
            PROC SQL; 
            SELECT count(distinct mcaid_id)
            FROM int.memlist_final;
            QUIT; 
        %mend;

        %count_ids_memlist_final; *4/27 final run still got 1593591 ;


%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 
***********************************************************************************************;

***********************************************************************************************
***  SECTION01 Get Monthly Utilization Data
***********************************************************************************************;
DATA    util0; 
SET     ana.qry_monthlyutilization (WHERE=(month ge '01Jul2016'd AND month le '30Jun2022'd));
FORMAT  dt_qrtr date9.;
dt_qrtr =intnx('QTR', month, 0, 'BEGINNING'); 
FY      =year(intnx('year.7', month, 0, 'BEGINNING'));
run;

PROC SQL;
CREATE TABLE util1 as
SELECT a.*
     , (a.pd_amt/b.index_2021_1) AS adj_pd_amount 
FROM   util0       AS A
LEFT JOIN int.adj   AS b    ON a.dt_qrtr=b.date;
quit; *66382081 : 7 cols; 

PROC SQL;
CREATE TABLE util2 AS
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
FROM  util1
GROUP BY MCAID_ID,month;
quit; *66382081 : 12; 

%nodupkey(ds=util2, out=raw.util3); *32835706, 12; 

*----------------------------------------------------------------------------------------------
SECTION 02 GET BH monthly utilization 
----------------------------------------------------------------------------------------------;
DATA raw.bh0;
SET  ana.qry_bho_monthlyutilization; 

format dt_qrtr month2 date9.; * create quarter beginning date to get quarters ; 
dt_qrtr = intnx('quarter', month ,0,'b');

month2 = month;
DROP   month;
RENAME month2 = month; 

WHERE  month ge '01Jul2016'd
AND    month le '01Jul2022'd;

FY     =year(intnx('year.7', month, 0, 'BEGINNING'));
run; *4208734 observations and 7 variables;

%create_qrtr(data=raw.bh1, set=raw.bh0, var = dt_qrtr, qrtr=time);

*Join bh, utilmonthly, and tele on memlist; 
PROC SQL; 
CREATE TABLE raw.util1622a AS 
SELECT a.*
     , b.*
     , c.*
     , d.n_q_tele
FROM int.qrylong1622    AS A
LEFT JOIN raw.bh1       AS B    ON a.mcaid_id=b.mcaid_id AND a.month=b.month
LEFT JOIN raw.util3     AS C    ON a.mcaid_id=c.mcaid_id AND a.month=c.month
LEFT JOIN int.tele_1921 AS D    ON a.mcaid_id=d.mcaid_id AND a.time =d.time;
QUIT;  * 65420507 rows and 21 columns.;

***************************************************************************
* JOIN TO MEMLIST FINAL, THEN GET 1618 var values
***************************************************************************; 
DATA raw.FY1618_0; 
SET  raw.util1622a
     (KEEP = mcaid_id FY dt_qrtr month adj_pd_total bho_n_hosp bho_n_er bho_n_other); 
WHERE month lt '01Jul2019'd; 
RUN; *24441787; 

PROC SQL;
CREATE TABLE raw.FY1618_1 as
SELECT mcaid_id
     , max(case when FY = 2016 then 1 else 0 end) as elig2016
     , max(case when FY = 2017 then 1 else 0 end) as elig2017
     , max(case when FY = 2018 then 1 else 0 end) as elig2018

     , avg(case when FY = 2016 then adj_pd_total else 0 end) as adj_pd_16pm
     , avg(case when FY = 2017 then adj_pd_total else 0 end) as adj_pd_17pm
     , avg(case when FY = 2018 then adj_pd_total else 0 end) as adj_pd_18pm

     , avg(case when FY = 2016 then bho_n_hosp  else 0 end) as bho_n_hosp_16pm
     , avg(case when FY = 2017 then bho_n_hosp  else 0 end) as bho_n_hosp_17pm 
     , avg(case when FY = 2018 then bho_n_hosp  else 0 end) as bho_n_hosp_18pm
     , avg(case when FY = 2016 then bho_n_er    else 0 end) as bho_n_er_16pm
     , avg(case when FY = 2017 then bho_n_er    else 0 end) as bho_n_er_17pm 
     , avg(case when FY = 2018 then bho_n_er    else 0 end) as bho_n_er_18pm
     , avg(case when FY = 2016 then bho_n_other else 0 end) as bho_n_other_16pm 
     , avg(case when FY = 2017 then bho_n_other else 0 end) as bho_n_other_17pm 
     , avg(case when FY = 2018 then bho_n_other else 0 end) as bho_n_other_18pm
FROM raw.FY1618_0
GROUP BY mcaid_id;
QUIT; 

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


**   checking percentiles ; 
PROC RANK DATA =  raw.fy1618_1 out=ranked_FY16 groups =100;
VAR adj_pd_16pm;
RANKS adj_pd_16pm_rank a;
WHERE adj_pd_16pm gt 0 ;
RUN; 

PROC RANK DATA =  raw.fy1618_1 out=ranked_FY17 groups =100;
VAR adj_pd_17pm;
RANKS adj_pd_17pm_rank;
WHERE adj_pd_17pm gt 0;
RUN; 

PROC RANK DATA =  raw.fy1618_1 out=ranked_FY18 groups =100;
VAR adj_pd_18pm;
RANKS adj_pd_18pm_rank;
WHERE adj_pd_18pm gt 0;
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
/*     >44.1008  >121.726   >332.824   >606.266     43.1492 117.327 341.071  659.856        >=100.590  >=293.408 >=773.223   >=1555.70 */

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
IF      adj_pd_&year.pm le 0           THEN adj_pd_total_&year.cat = adj_pd_&year.pm;

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

* Made separate ds's for testing but merge if poss later, save final to data/; 
%insert_pctile(ds_in = raw.fy1618_2,    ds_out = adj0,          year = 16);
%insert_pctile(ds_in = adj0,            ds_out = adj1,          year = 17);
%insert_pctile(ds_in = adj1,            ds_out = int.FY1618,    year = 18); *1050185;

********************************************************************
1921
********************************************************************;
DATA raw.FY1921_0;
SET  raw.util1622a
     (KEEP = mcaid_id month FY time bho_n_other bho_n_er n: adj: );
WHERE month ge '01JUL2019'd;
RUN; *41962377;

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

%nodupkey(ds=raw.FY1921_1, out=raw.FY1921_2); * 14045957; 

* setting to 0 where . and create indicator variables if >0 for pmodel and pctile95>=;
DATA raw.FY1921_3;
SET  raw.FY1921_2; 
ARRAY dv(*) n_pc_pm       n_ed_pm     n_ffs_bh_pm     n_tel_pm    
            adj_total_pm  adj_pc_pm   adj_rx_pm;
DO i=1 to dim(dv);
    IF dv(i)=. THEN dv(i)=0; 
    ELSE dv(i)=dv(i);
    END;
DROP i; 

ind_pc_visit     = n_pc_pm      > 0;
ind_ed_visit     = n_ed_pm      > 0;
ind_ffs_bh_visit = n_ffs_bh_pm  > 0;
ind_tel_visit    = n_tel_pm     > 0;
ind_total_cost   = adj_total_pm > 0;
ind_pc_cost      = adj_pc_pm    > 0;
ind_rx_cost      = adj_rx_pm    > 0;
RUN; 

proc sort data = raw.fy1921_3; BY FY; run; 

** GET PERCENTILES FOR ALL & TOP CODE DV's FOR MEMBERS ONLY ; 
* 1618; 
%macro pctl_1921(var,out,pctlpre,t_var,);
PROC UNIVARIATE DATA = raw.FY1921_3;
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

%pctl_1921(var = adj_total_pm,   out = adj_total_pctl,   pctlpre = adj_total_,  t_var = adj_total_95); 
%pctl_1921(var = adj_pc_pm,      out = adj_pc_pctl,      pctlpre = adj_pc_,     t_var = adj_pc_95); 
%pctl_1921(var = adj_rx_pm,      out = adj_rx_pctl,      pctlpre = adj_rx_,     t_var = adj_rx_95); 

data int.pctl1921; merge adj_total_pctl_a adj_pc_pctl_a adj_rx_pctl_a ; run;

PROC PRINT DATA = int.pctl1921; RUN; 
/*Obs   adj_total_95p_19    adj_total_95p_20   adj_total_95p_21 
/*1     4004.66 3           755.49             3691.84 

        adj_pc_95p_19 adj_pc_95p_20 adj_pc_95p_21           adj_rx_95p_19   adj_rx_95p_20   adj_rx_95p_21 
        365.564       353.053       342.660                 1076.74         1148.78         1160.32 */

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
PROC UNIVARIATE NOPRINT DATA = raw.FY1921_3; 
WHERE FY=&FY 
AND   &VAR gt &gt;
VAR   &VAR;
OUTPUT OUT=&out MEAN=&mean; RUN; 
%MEND;

%means_95p(FY=2019, var=adj_total_pm, gt=&adj_total_95p_19, out=mu_total_19, mean=MEAN=Mu_total19);
%means_95p(FY=2020, var=adj_total_pm, gt=&adj_total_95p_20, out=mu_total_20, mean=MEAN=Mu_total20);
%means_95p(FY=2021, var=adj_total_pm, gt=&adj_total_95p_21, out=mu_total_21, mean=MEAN=Mu_total21);

%means_95p(FY=2019, var=adj_pc_pm, gt=&adj_pc_95p_19, out=mu_pc_19, mean=MEAN=Mu_pc19);
%means_95p(FY=2020, var=adj_pc_pm, gt=&adj_pc_95p_20, out=mu_pc_20, mean=MEAN=Mu_pc20);
%means_95p(FY=2021, var=adj_pc_pm, gt=&adj_pc_95p_21, out=mu_pc_21, mean=MEAN=Mu_pc21);

%means_95p(FY=2019, var=adj_rx_pm, gt=&adj_rx_95p_19, out=mu_rx_19, mean=MEAN=Mu_rx19);
%means_95p(FY=2020, var=adj_rx_pm, gt=&adj_rx_95p_20, out=mu_rx_20, mean=MEAN=Mu_rx20);
%means_95p(FY=2021, var=adj_rx_pm, gt=&adj_rx_95p_21, out=mu_rx_21, mean=MEAN=Mu_rx21);

data int.mu_pctl_1921; 
merge mu_total_19       mu_total_20     mu_total_21
      mu_pc_19          mu_pc_20        mu_pc_21
      mu_rx_19          mu_rx_20        mu_rx_21
      adj_total_pctl_a  adj_pc_pctl_a   adj_rx_pctl_a;
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


DATA int.FY1921;
SET  raw.FY1921_3;
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

**** START HERE IT's GREAT!!!; 
* Create elig by year table; 
PROC SORT DATA = int.qrylong1622 (keep=mcaid_id fy) nodupkey out=elig1622; BY _ALL_; RUN; 
PROC SQL;
CREATE TABLE int.elig1622 AS 
SELECT mcaid_id
     , max(case WHEN FY=2016 THEN 1 ELSE 0 end) AS elig_2016
     , max(case WHEN FY=2017 THEN 1 ELSE 0 end) AS elig_2017
     , max(case WHEN FY=2018 THEN 1 ELSE 0 end) AS elig_2018
     , max(case WHEN FY=2019 THEN 1 ELSE 0 end) AS elig_2019
     , max(case WHEN FY=2020 THEN 1 ELSE 0 end) AS elig_2020
     , max(case WHEN FY=2021 THEN 1 ELSE 0 end) AS elig_2021
FROM elig1622
GROUP BY mcaid_id;
QUIT;

PROC SQL; 
CREATE TABLE int.final0 AS 
SELECT a.mcaid_id
/*     join 1618 data*/
     , b.adj_pd_total_16cat, b.adj_pd_total_17cat,  b.adj_pd_total_18cat
     , b.bho_n_hosp_16pm,    b.bho_n_hosp_17pm,     b.bho_n_hosp_18pm
     , b.bho_n_other_16pm,   b.bho_n_other_17pm,    b.bho_n_other_18pm
     , b.bho_n_er_16pm,      b.bho_n_er_17pm,       b.bho_n_er_18pm
/*      join memlist_final with demo*/
     , c.int            , c.int_imp
     , c.age            , c.race            , c.sex     , c.pcmp_loc_id
     , c.budget_group   , c.enr_cnty        , c.fqhc    , c.rae_person_new
FROM int.elig1622               AS A   
LEFT JOIN int.FY1618            AS B    ON a.mcaid_id=B.mcaid_id
LEFT JOIN int.memlist_final     AS C    ON a.mcaid_id=c.mcaid_id;
QUIT; 

PROC SORT DATA = int.final0 NODUPKEY OUT=int.final1; BY _ALL_; RUN; 



     , d.n_pc_pm         ,d.ind_pc_visit
     , d.n_ed_pm         ,d.ind_ed_visit
     , d.n_ffs_bh_pm     ,d.ind_ffs_bh_visit
     , d.n_tel_pm        ,d.ind_tel_visit
     , d.adj_pd_total_tc AS adj_pd_total_pm_tc    , d.ind_total_cost
     , d.adj_pd_rx_tc    AS adj_pd_rx_pm_tc       , d.ind_rx_cost
     , d.adj_pd_pc_tc    AS adj_pd_pc_pm_tc       , d.ind_pc_cost
LEFT JOIN int.memlist_final    AS B   ON a.mcaid_id=b.mcaid_id
LEFT JOIN int.fy1921           AS D   ON a.mcaid_id=d.mcaid_id and b.time=d.time;

DATA missing; 
SET  final2;
nvals = N(of adj_pd_total_16cat--ind_pc_cost);
nmiss = nmiss(of adj_pd_total_16cat--ind_pc_cost);
proc print; 
run; 

DATA int.final3; 
SET  int.final2;
adj_pd_total_16cat = coalesce(adj_pd_total_16cat, -1);
adj_pd_total_17cat = coalesce(adj_pd_total_17cat, -1);
adj_pd_total_18cat = coalesce(adj_pd_total_18cat, -1);
RUN; 

PROC FREQ DATA = int.final3;
tables adj_pd_total_16cat adj_pd_total_17cat adj_pd_total_18cat; 
RUN; 
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

TITLE "int.memlist_final"; 
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