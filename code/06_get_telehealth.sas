**********************************************************************************************
 PROJECT       : ISP 
 PROGRAMMER    : KTW / Carter Sevick
 DATE RAN      : 01-26-2023
 PURPOSE       : Get telehealth for ISP Utilization
 INPUT FILE/S  : 
                                  
 OUTPUT FILE/S : 
 NOTES         : 

***********************************************************************************************;
libname out 'C:/Data/isp_util2/04_data';

* database location ;

libname ana 'S:/FHPC/DATA/HCPF_Data_files_SECURE/HCPF_SqlServer/AnalyticSubset'; * reset to : M:\HCPF_SqlServer\AnalyticSubset ;
option fmtsearch=(ana);

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

run;

* indicators of telehealth and tele-eligible care ;
proc sql;
  create table margTele as
    select icn_nbr,
           max(teleCare) as telecare,
           max(teleElig) as teleElig
    from telecare
    group by icn_nbr;
quit;

* telehealth is: primary care, tele eligible and a telehealth service ;
proc sql;

create table teleCare_FINAL as
  select a.*
  from pc as a inner join margTele as b
    on a.icn_nbr = b.icn_nbr 
  where a.primCare = 1 and b.teleCare = 1 and b.teleElig = 1;

quit;

* monthy telehealth encounters and costs, per client ;
proc sql;

create table teleCare_monthly as
  select mcaid_id,
         intnx('month',FRST_SVC_DT, 0, 'beginning') as month,
         count (distinct FRST_SVC_DT) as n_tele,
         sum(pd_amt) as pd_tele
  from teleCare_FINAL
  group by mcaid_id, month;

quit;

DATA  data.teleCare_monthly;
SET   teleCare_monthly;
DATA data.teleCare_FINAL;
SET  teleCare_FINAL;
RUN;

* Get FY7 years ;
DATA  data.teleCare_monthly;
SET   data.teleCare_monthly;
WHERE month ge '01Jul2015'd 
AND   month le '30Jun2022'd; 
RUN; 

