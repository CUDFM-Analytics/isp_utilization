**********************************************************************************************
 PROGRAM NAME       : ISP Utilization
 PROGRAMMER         : K Wiggins
 DATE OF CREATION   : 08 18 2022
 PROJECT            : ISP
 PURPOSE            : Get client ID's for members 0-64 in SFY's 18/19 through 21/22
 INPUT FILE(S)      : bhjt.medicaiddemog_bidm
                      macro: %keep_age
                      
 OUTPUT FILE(S)     : out.mem_list
                      out.mem_list_demo
 ABBREV             : bhjt, hcpf (include bdmconnect file has varlen)

 MODIFICATION HISTORY:
 Date       Author      Description of Change
 --------   -------     -----------------------------------------------------------------------
 08/18/22   KTW         Copied this FROM 00_ISP_Counts in NPI_Matching - Documents
 12/04/22   KTW         Changed source data from bhjt.medicaiddemog_bidm to clnt_dim_v (spoke w Carter)

* global paths, settings  ---------------------------;
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilizatiON/02_code/00_global.sas"; 
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilizatiON/02_code/00_macros.sas"; 
  *use age range; 
* Includes formats, connect to bdm, setting libnames, options, bhjt, varlen;
***********************************************************************************************;
OPTIONS fmtsearch=(bhjt);
DATA medlong1; 
SET  bhjt.medicaidlong_bidm;
RUN; 

*instead of meddemog_
filter to get ages between 0-64 in those years (roughly);
DATA clnt_dim_v;
SET  subset.clnt_dim_v; 
dob  = datepart(brth_dt);
FORMAT dob yymmdd10.;
IF     datepart(brth_dt) ge "01JUL1954"d
       AND datepart(brth_dt) le "01JUL2022"D
       THEN OUTPUT; 
RUN; 
/*NOTE: There were 3074445 observations read from the data set SUBSET.CLNT_DIM_V.*/
/*NOTE: The data set WORK.CLNT_DIM_V has 2815913 observations and 7 variables.*/

PROC CONTENTS
DATA = clnt_dim_v;
RUN;

DATA   medlong_y15_y22;
LENGTH clnt_id $11; 
SET    medlong1 (drop=aid_cd_1-aid_cd_5 title19: FED_POV_LVL_PC);
WHERE  month ge '01JUL2015'd
  AND  month le '30JUN2022'd
  AND  BUDGET_GROUP not in (16,17,18,19,20,21,22,23,24,25,26,27,-1,)
  AND  managedCare = 0;
RUN;
/*NOTE: The data set WORK.MEDLONG_Y15_Y22 has 99507799 observations and 17 variables*/

PROC SQL; 
CREATE TABLE medlong_y15_y22_2 as
SELECT       a.*,
             b.dob,
             b.gndr_cd,
             b.race_cd,
             b.rsdnc_cnty_cd,
             b.ethnc_cd
FROM         medlong_y15_y22 AS a 
LEFT JOIN    clnt_dim_v AS b 
ON           a.clnt_id=b.mcaid_id ;
QUIT; 
/*NOTE: Table WORK.MEDLONG_Y15_Y22_2 created, with 99507799 rows and 22 columns.*/


DATA medlong_y15_y22_3; 
SET  medlong_y15_y22_2;
 IF      month ge '01Jul2015'd and month le '30Jun2016'd THEN last_day_fy='30Jun2016'd;
 ELSE IF month ge '01Jul2016'd and month le '30Jun2017'd THEN last_day_fy='30Jun2017'd;
 ELSE IF month ge '01Jul2017'd and month le '30Jun2018'd THEN last_day_fy='30Jun2018'd;
 ELSE IF month ge '01Jul2018'd and month le '30Jun2019'd THEN last_day_fy='30Jun2019'd;
 ELSE IF month ge '01Jul2019'd and month le '30Jun2020'd THEN last_day_fy='30Jun2020'd;
 ELSE IF month ge '01Jul2020'd and month le '30Jun2021'd THEN last_day_fy='30Jun2021'd;
 ELSE IF month ge '01Jul2021'd and month le '30Jun2022'd THEN last_day_fy='30Jun2022'd;

 age_end_fy = floor( (intck('month', dob, last_day_fy) - (day(last_day_fy) < min(day(dob), day(intnx ('month', last_day_fy, 1) -1)))) /12 );

 IF age_end_fy lt 0 OR age_end_fy gt 64 THEN DELETE;
 FORMAT last_day_fy date9.;
RUN; 
/*NOTE: There were 99507799 observations read from the data set WORK.MEDLONG_Y15_Y22_2.*/
/*NOTE: The data set WORK.MEDLONG_Y15_Y22_3 has 95112495 observations and 24 variables.*/

PROC DATASETS nolist lib=work;
DELETE medlong_y15_y22_2;
QUIT; 
RUN; 

PROC SORT 
DATA = medlong_y15_y22_3 
       (keep=clnt_id month pcmp_loc_ID rae_assign age_end_fy last_day_fy) 
       NODUPKEY
       OUT = finalSubjects; 
WHERE  pcmp_loc_id ne ' ' 
  AND  rae_assign=1
  AND  month ge '01JUL2018'd 
  AND  month le '30JUN2022'd; 
BY     clnt_id; 
RUN; 
/*NOTE: There were 53397827 observations read from the data set WORK.MEDLONG_Y15_Y22_3.*/
/*      WHERE (pcmp_loc_id not = ' ') and (rae_assign=1) and (month>='01JUL2018'D and*/
/*      month<='30JUN2022'D);*/
/*NOTE: 51607779 observations with duplicate key values were deleted.*/
/*NOTE: The data set WORK.FINALSUBJECTS has 1790048 observations and 6 variables.*/

DATA out.medlong_y15_y22;
SET  medlong_y15_y22_3;
RUN; 

DATA out.finalsubjects;
SET  finalsubjects;
RUN; 
/*NOTE: There were 1790058 observations read from the data set WORK.FINALSUBJECTS.*/
/*NOTE: The data set OUT.FINALSUBJECTS has 1790058 observations and 5 variables.*/

PROC FREQ 
DATA = out.finalsubjects;
TABLES age_end_fy*last_day_fy;
RUN; 

PROC PRINT 
DATA = medlong_y15_y22 (obs=100);
RUN;

PROC PRINT 
DATA = out.finalSubjects (obs=100);
RUN;

PROC CONTENTS
DATA = medlong_y15_y22;
RUN;

