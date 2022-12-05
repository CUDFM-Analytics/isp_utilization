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
 12/04/22	KTW			Changed source data from bhjt.medicaiddemog_bidm to clnt_dim_v (spoke w Carter)

* global paths, settings  ---------------------------;
  %INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilizatiON/02_code/00_global.sas"; 
  %INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilizatiON/02_code/00_macros.sas"; 
  *use age range; 
* Includes formats, connect to bdm, setting libnames, options, bhjt, varlen;
***********************************************************************************************;
PROC CONTENTS
DATA = subset.clnt_dim_v;
RUN; 

*Get dob's to include ;
DATA clnt_dim_v (DROP = brth_dt); 
SET  subset.clnt_dim_v; 
dob = datepart(brth_dt);
FORMAT dob yymmdd10.;
IF	 datepart(brth_dt) ge "01JUL1954"D 
	 AND  datepart(brth_dt) le "01JUL2022"D
	 THEN OUTPUT; 
RUN; *2,815,913 ;

* Create age; 
DATA out.clnt_dim_v;
SET  clnt_dim_v; 
age_sfy1819 = floor((intck('month', dob, '01Jul2018'd) - (day('01Jul2018'd) < day(dob))) / 12); 
age_sfy1920 = floor((intck('month', dob, '01Jul2019'd) - (day('01Jul2019'd) < day(dob))) / 12); 
age_sfy2021 = floor((intck('month', dob, '01Jul2020'd) - (day('01Jul2020'd) < day(dob))) / 12); 
age_sfy2122 = floor((intck('month', dob, '01Jul2021'd) - (day('01Jul2021'd) < day(dob))) / 12); 
fy1819 = input(age_sfy1819, age_range.);
fy1920 = input(age_sfy1920, age_range.);
fy2021 = input(age_sfy2021, age_range.);
fy2122 = input(age_sfy2122, age_range.); 
run;  

PROC PRINT
DATA = out.clnt_dim_v (obs = 200); 
run;    

* Get medicaidlong where managedcare = 0 using member list ; 
PROC CONTENTS
DATA = bhjt.medicaidlong_bidm; 
RUN;

PROC SQL;
CREATE TABLE medlong1 AS
SELECT * 
FROM   bhjt.medicaidlong_bidm
WHERE  clnt_id IN (SELECT mcaid_id
			       FROM   clnt_dim_v2)
  AND  budget_group not in (16,17,18,19,20,21,22,23,24,25,26,27,-1,)
  AND  managedCare = 0
  AND  month between '01JUL2015'd and '30JUN2022'd;
QUIT; 
*Table WORK.MEDLONG1 created, with 137226720 rows and 25 columns;

PROC CONTENTS
DATA = medlong1;
RUN;

PROC PRINT 
DATA = medlong1 (obs=100);
RUN; 
