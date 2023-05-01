**********************************************************************************************
AUTHOR   : KTW
PROJECT  : ISP Utilization Analysis
PURPOSE  : Gather, Process datasets from analytic subset dir
VERSION  : 2023-03-16 [date last updated]
DEPENDS  : ana subset folder, config file [dependencies]
    Need 16-18 for adj_pd_total_YRcat (16,17,18) and 19-21 for outcome vars
    Inputs      ana.qry_monthly_utilization     [111,221,842 : 7] 2023-02-09
    Outputs     data.util_month_fy6             [ 66,367,624 : 7] 2023-03-08;

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

%LET dat = int.final3; 
%put &dat; 
PROC GEE DATA  = &dat DESC;
     CLASS  mcaid_id    
            adj_pd_total_16cat 
            adj_pd_total_17cat  
            adj_pd_total_18cat
            ind_pc_cost ;
     model ind_pc_cost = adj_pd_total_16cat 
                         adj_pd_total_17cat 
                         adj_pd_total_18cat
                         time  / dist = binomial link = logit ; 
  repeated subject = mcaid_id / type = exch ; *ind;
/*  store p_model;*/
run;

PROC FREQ DATA = int.JAKE_compare;
tables adj:;
RUN; 
