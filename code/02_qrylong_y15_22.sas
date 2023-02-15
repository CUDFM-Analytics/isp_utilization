**********************************************************************************************
 PROGRAMMER       : K Wiggins
 DATE INIT        : 
 PROJECT          : ISP Util
 PURPOSE          : merge qry_longitudinal and qry_demographics
 INPUT FILE(S)    : qry_longitudinal, qry_demographics, rae
 OUTPUT FILE(S)   : data.qrylong_y15_22
 LAST RAN/STATUS  : 20230214
 SEE              : ISP_Utilization_Analytic_Plan_20221118.docx, data_specs.xlsx     
***********************************************************************************************;

DATA qry_longitudinal;            SET ana.qry_longitudinal;            RUN; *02/09/23 [1,177,273,652 : 25];
DATA qry_demographics;            SET ana.qry_demographics;            RUN; *02/09/23 [  3008709     :  7];

******************************************************
Initial Datasteps before merging
******************************************************;
proc format ; 
value pcmp_type_rc
32 = "FQHC"
45 = "RHC" 
51 = "SHS"
61 = "IHS"
62 = "IHS"
Other = "Other"; 
run; 
* ;

DATA   qrylong_y15_22   ( DROP = managedCare ); 
LENGTH mcaid_id $11; 
SET    qry_longitudinal ( DROP = aid_cd_1-aid_cd_5 title19: FED_POV_LVL_PC ) ; 

* Recode pcmp loc type with format above; 
num_pcmp_type = input(pcmp_loc_type_cd, 7.);
pcmp_type     = put(num_pcmp_type, pcmp_type_rc.);        

WHERE  month ge '01Jul2015'd 
AND    month le '30Jun2022'd 
AND    BUDGET_GROUP not in (16,17,18,19,20,21,22,23,24,25,26,27,-1,)
AND    managedCare = 0
AND    pcmp_loc_id ne '';
RUN;  * 81494187, 18;

PROC FREQ 
     DATA = qrylong_y15_22;
     TABLES pcmp_type / ;* PLOTS = freqplot(type=dotplot scale=percent) out=out_ds;
     TITLE  'Frequency pcmp_type all records';
RUN; 
TITLE; 

PROC FREQ 
     DATA = qry_longitudinal;
     TABLES pcmp_loc_type_cd ;
RUN; 

* ; 
PROC SQL; 
CREATE TABLE qrylong_y15_22a AS
SELECT a.*, 
       b.dob, 
       b.gender, 
       b.race,
       b.ethnic
FROM   qrylong_y15_22 AS a 
LEFT JOIN qry_demographics AS b 
ON     a.mcaid_id=b.mcaid_id ;
QUIT; 
* 81494187, 22;

DATA qrylong_y15_22b; 
SET  qrylong_y15_22a;

  * create age variable;
  IF      month ge '01Jul2015'd AND month le '30Jun2016'd THEN last_day_fy='30Jun2016'd;
  ELSE IF month ge '01Jul2016'd AND month le '30Jun2017'd THEN last_day_fy='30Jun2017'd;
  ELSE IF month ge '01Jul2017'd AND month le '30Jun2018'd THEN last_day_fy='30Jun2018'd;
  ELSE IF month ge '01Jul2018'd AND month le '30Jun2019'd THEN last_day_fy='30Jun2019'd;
  ELSE IF month ge '01Jul2019'd AND month le '30Jun2020'd THEN last_day_fy='30Jun2020'd;
  ELSE IF month ge '01Jul2020'd AND month le '30Jun2021'd THEN last_day_fy='30Jun2021'd;
  ELSE IF month ge '01Jul2021'd AND month le '30Jun2022'd THEN last_day_fy='30Jun2022'd;
  * create FY variable; 
  IF      last_day_fy = '30Jun2016'd then FY = 'FY_1516';
  ELSE IF last_day_fy = '30Jun2017'd then FY = 'FY_1617';
  ELSE IF last_day_fy = '30Jun2018'd then FY = 'FY_1718';
  ELSE IF last_day_fy = '30Jun2019'd then FY = 'FY_1819';
  ELSE IF last_day_fy = '30Jun2020'd then FY = 'FY_1920';
  ELSE IF last_day_fy = '30Jun2021'd then FY = 'FY_2021';
  ELSE IF last_day_fy = '30Jun2022'd then FY = 'FY_2122';

  age_end_fy = floor( (intck('month', dob, last_day_fy) - (day(last_day_fy) < min(day(dob), day(intnx ('month', last_day_fy, 1) -1)))) /12 );
  * remove if age not in range;
  IF age_end_fy lt 0 or age_end_fy gt 64 THEN delete;
  FORMAT last_day_fy date9.;
  
RUN; * 20230214 FEB.QRYLONG_Y15_22 has 78680146 observations and 25 variables.
;

proc datasets nolist lib=work; delete qrylong_y15_22; quit; run; 

PROC CONTENTS 
     DATA = data.qrylong_y15_22 VARNUM;
RUN;  

PROC SQL; 
CREATE TABLE data.qrylong_y15_22 AS 
SELECT a.*
     , b.county_rating_area_id
     , b.rae_id
     , b.hcpf_county_code_c
FROM qrylong_y15_22b AS A
LEFT JOIN data.rae AS b
ON a.enr_cnty = b.hcpf_county_code_c; 
QUIT; 


