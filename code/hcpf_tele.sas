**********************************************************************************************
 PROJECT       : ISP 
 PROGRAMMER    : KTW 
 DATE RAN      : 02-21-2023
 PURPOSE       : Get telehealth for ISP Utilization
 INPUT FILE/S  : 
                                  
 OUTPUT FILE/S : 
 NOTES         : 

***********************************************************************************************;
* PROJECT PATHS, MAPPING; 
%LET ROOT = S:/FHPC/DATA/HCPF_Data_files_SECURE/Kim/isp/isp_utilization;
%INCLUDE "&ROOT./code/00_global.sas";

/*libname ana 'S:/FHPC/DATA/HCPF_Data_files_SECURE/HCPF_SqlServer/AnalyticSubset'; * reset to : M:\HCPF_SqlServer\AnalyticSubset ;*/
/*option fmtsearch=(ana);*/

* primary care records ;
data pc;
  set ana.Qry_clm_dim_class;
  where hosp_episode NE 1
    and ER NE 1
    and primCare = 1;
run;* 43044039;


* telehealth records ;
proc format;
 * telehealth eligible visits ;
 invalue teleElig 
 '76801','76802','76805','76811','76812','76813','76814','76815','76816','76817','90791','90792','90832','90833','90834','90836',
'90837','90838','90839','90840','90846','90847','90849','90853','90863','92507','92508','92521','92522','92523','92524','92526',
'92606','92607','92608','92609','92610','92630','92633','96101','96102','96110','96111','96112','96113','96116','96118','96119',
'96121','96125','96130','96131','96132','96133','96136','96137','96138','96139','96146','97110','97112','97129','97130','97140',
'97150','97151','97153','97154','97155','97158','97161','97162','97163','97164','97165','97166','97167','97168','97530','97533',
'97535','97537','97542','97755','97760','97761','97763','97802','97803','97804','98966','98967','98968','99201','99202','99203',
'99204','99205','99211','99212','99213','99214','99215','99382','99383','99384','99392','99393','99394','99401','99402','99403',
'99404','99406','99407','99408','99409','99441','99442','99443','G0108','G0109','G8431','G8510','G9006','H0001','H0002','H0004',
'H0006','H0025','H0031','H0032','H0049','H1005','H2000','H2011','H2015','H2016','S9445','S9485','T1017','V5011'
=1
other=0;
run;

data telecare;
  set ana.Clm_lne_fact_v;

  teleCare = (CLM_TYP_CD in ( 'B','M' ) and POS_CD = '02' ) or 
             (
               CLM_TYP_CD in ( 'C','O' ) and 
               (PROC_MOD_1_CD='GT' or PROC_MOD_2_CD='GT' or PROC_MOD_3_CD='GT' or PROC_MOD_4_CD='GT')
              );

  *eligible for telehealth ;
  teleElig = input(proc_cd, teleElig.);

   * keeping only rows that are ER or primary or urgent or tele care ;
  if teleCare or teleElig;

run; *There were 509386139 observations read from the data set ANA.CLM_LNE_FACT_V.
NOTE: The data set WORK.TELECARE has 70872713 observations and 32 variables.;

proc contents data = telecare; run; 

data  telecare2;
set   telecare  ( keep = bill_prov_loc_id rend_prov_loc_id icn_nbr mcaid_id teleCare teleElig lne_frst_svc_dt) ;
bill_prov_loc_id_num = input(bill_prov_loc_id, best12.);
rend_prov_loc_id_num = input(rend_prov_loc_id, best12.);

where datepart(lne_frst_svc_dt) ge '01JUL2019'd
and   datepart(lne_frst_svc_dt) le '01JUN2022'd;
run; 

proc sql; 
create table telecare3 as 
select bill_prov_loc_id
     , rend_prov_loc_id 
     , icn_nbr 
     , mcaid_id 
     , teleCare 
     , teleElig 
     , lne_frst_svc_dt
from telecare2; 
quit; 

data telecare3;
set  telecare3; 
lne_svc_new = datepart(lne_frst_svc_dt);
format lne_svc_new date9.;
run;  

data telecare4;
set  telecare3; 
where  lne_svc_new ge '01JUL2019'd
and    lne_svc_new le '01JUN2022'd;
bill2 = input(bill_prov_loc_id, best8.);
rend2 = input(rend_prov_loc_id, best8.);
run;  *The data set WORK.TELECARE3 has 23324748 observations and 8 variables
Errors are due to the N/A's in the character columns;

proc contents data = telecare3 varnum; run; 

* Get lists of isp / non-isp id's, add flag;
proc sql; 
create table telecare5 as 
select bill_prov_loc_id
     , rend_prov_loc_id
     , bill2 in ( select pcmp_loc_id from data.ll_fy1922_pcmp_isp ) as flag_bill_isp
     , rend2 in ( select pcmp_loc_id from data.ll_fy1922_pcmp_isp ) as flag_rend_isp
     , bill2 in ( select pcmp_loc_id from data.ll_fy1922_pcmp_nonisp ) as flag_bill_nonisp
     , rend2 in ( select pcmp_loc_id from data.ll_fy1922_pcmp_nonisp ) as flag_rend_nonisp
     , icn_nbr
     , teleCare
     , teleElig
     , lne_svc_new
     , lne_frst_svc_dt
FROM telecare4;
QUIT; 

* prioritize the rend_ columns; 
data telecare6;
set  telecare5;
IF flag_rend_isp = 1 then flag_bill_isp = .;
IF flag_rend_nonisp = 1 then flag_bill_nonisp = . ; 
flag_sum = sum(flag_bill_isp, flag_rend_isp, flag_bill_nonisp, flag_rend_nonisp); 
IF rend_prov_loc_id = "N/A" then rend_prov_loc_id = "";
IF bill_prov_loc_id = "N/A" then bill_prov_loc_id = "";
run; 

* copy the loc_id to a new column based on the match; 
data telecare7; 
set  telecare6; 
IF flag_rend_isp = 1    then pcmp = rend_prov_loc_id;
IF flag_bill_isp = 1    then pcmp = bill_prov_loc_id; 
IF flag_rend_nonisp = 1 then pcmp = rend_prov_loc_id;
IF flag_bill_nonisp = 1 then pcmp = bill_prov_loc_id; 
run; 

proc freq data = telecare7; tables flag_rend_isp ; run; 
proc print data = telecare7 ; where flag_rend_isp = 1 ; run ;  

* Find missing values; 
proc sql; 
select nmiss(bill_prov_loc_id) as missing_bill
    , nmiss(rend_prov_loc_id) as missing_rend
from telecare7; 
quit; 

proc format ; 
value ind_isp_
0 = "non-ISP"
1 = "ISP";
run; 

data telecare8 ( keep = pcmp ind_pcmp bill_prov_loc_id rend_prov_loc_id icn_nbr telecare teleElig lne_svc_new isp non_isp ) ; 
set  telecare7 ; 
ISP      = sum(flag_bill_isp, flag_rend_isp);
non_isp  = sum(flag_bill_nonisp, flag_rend_nonisp);
ind_PCMP = sum(ISP, non_isp); 
run; *23324748;

* indicators of telehealth and tele-eligible care ;
proc sql;
  create table margTele as
    select icn_nbr,
           max(teleCare) as telecare,
           max(teleElig) as teleElig,
           isp,
           ind_PCMP,
           non_isp,
           pcmp
    from telecare8
    group by icn_nbr, pcmp;
quit; *23324748;

* telehealth is: primary care, tele eligible and a telehealth service ;
proc sql;

create table teleCare_FINAL as
  select a.*
        , b.*
  from pc as a inner join margTele as b
    on a.icn_nbr = b.icn_nbr 
  where a.primCare = 1 and b.teleCare = 1 and b.teleElig = 1;

quit; *: Table WORK.TELECARE_FINAL created, with 1190785 rows and 31 columns.; 

proc print data = teleCare_final (obs=1000); run; 

proc format ; 
value ind_isp_
0 = "non-ISP"
1 = "ISP";
run; 

data data.pcmps_tele;
set  teleCare_final; 
format isp ind_isp_.;
run; 


* ==== QUESTION 3: monthy telehealth encounters and costs, per client ===================;

proc sql;
create table tbl.n_pcmp_tele as
  select intnx('month',FRST_SVC_DT, 0, 'B') as month format=date9.,
         count ( distinct pcmp ) as n_pcmp,
         isp format ind_isp_.
  from data.pcmps_tele
  where ind_pcmp = 1
  group by month, isp;
quit; *65, 3 cols; 

proc sort data = tbl.n_pcmp_tele ; by ISP ; run ; 

PROC TRANSPOSE DATA = tbl.n_pcmp_tele
                OUT = tbl.n_pcmp_tele_t (drop=_name_);
BY  ISP; 
ID  month; 
VAR n_pcmp;
run; *;  


* ==== QUESTION 4: percentage of pcmps delivering any telehealth service ==========================;
proc sql; 
create table tbl.n_total_isp as
select count ( distinct pcmp_loc_id ) as n_total
from data.ll_fy1922_pcmp_isp;
quit; *101;

proc sql; 
create table tbl.n_total_nonISP as
select count ( distinct pcmp_loc_id ) as n_total
from data.ll_fy1922_pcmp_nonisp;
quit;  *955;

data tbl.pct_tele ; 
set  tbl.n_pcmp_tele;
IF isp = 1 then n_total = 101;
IF isp = 0 then n_total = 955; 
pct_tele = n_pcmp / n_total;
format pct_tele percent8.1;
run; 

PROC TRANSPOSE DATA = tbl.pct_tele 
                OUT = tbl.pct_tele_t (drop=_name_);
BY  ISP; 
ID  month; 
VAR pct_tele n_pcmp;
run; *;  

* ===============Export ==========================;

ods excel file = "&report/hcpf_q3_q4_telehealth.xlsx"
    options (   sheet_name = "q3_n_pcmp" 
                sheet_interval = "none");

proc print data = tbl.n_pcmp_tele_t;
run;

ods excel options ( sheet_interval = "now" sheet_name = "q3_plot") ;

TITLE "PCMP's providing Telehealth services, ISP & non-ISP: 07/2019-06/2022";
proc sgplot data = tbl.n_pcmp_tele;
yaxis label = " ";
styleattrs datacontrastcolors =(purple steel); 
series x = month y = n_pcmp / group = isp ; *datalabel = label ;
refline '_01MAR2020'd / 
        axis = x 
        lineattrs = ( thickness = 2 color=grey pattern=dash ) 
        label = ("March 2020")
        labelloc = inside
        label = "March 2020";
run; 
TITLE; 

ods excel options ( sheet_interval = "now" sheet_name = "pct_tele") ;

proc print data = tbl.pct_tele_t; run;  

ods excel options ( sheet_interval = "now" sheet_name = "pct_plot") ;

TITLE "Percentage of PCMPs Delivering Any Telehealth Service";
proc sgplot data = tbl.pct_tele;
yaxis label = " ";
styleattrs datacontrastcolors =(purple steel); 
series x = month y=pct_tele / group = isp;
refline '_01MAR2020'd / 
        axis = x 
        lineattrs = ( thickness = 2 color=grey pattern=dash ) 
        label = ("March 2020")
        labelloc = inside
        label = "March 2020";
run; 
TITLE; 

proc print data = tbl.n_total_isp ; 
title "Count ISP PCMPs" ; run; 
proc print data = tbl.n_total_nonISP ; 
title "Count nonISP PCMPS" ; run; 

ods excel close; 
run;
