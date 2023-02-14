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
 09/13/22   KTW         Ran
 12/04/22	KTW			Changed source data from bhjt.medicaiddemog_bidm to clnt_dim_v

* global paths, SETtings  ---------------------------;
  %INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilizatiON/02_code/00_global.sas"; 
  %INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilizatiON/02_code/00_macros.sas"; 
  *use age range; 
* Includes formats, connect to bdm, setting libnames, options, bhjt, varlen;
***********************************************************************************************;

DATA meddemog1; SET bhjt.medicaiddemog_bidm; run; *2,991,591, 7 (same 11/18);  

* Create age variable with clnt_id and dob - LATER merge back with meddemog1 for gender, county, rethnic_hcpf;
DATA meddemog2 (KEEP=clnt_id dob );
SET  meddemog1;
run; * dropped to 5 variables; 

* Get age FROM meddemog;
DATA meddemog3;
SET  meddemog2;
age_sfy1819 = floor((intck('month', dob, '01Jul2018'd) - (day('01Jul2018'd) < day(dob))) / 12); 
age_sfy1920 = floor((intck('month', dob, '01Jul2019'd) - (day('01Jul2019'd) < day(dob))) / 12); 
age_sfy2021 = floor((intck('month', dob, '01Jul2020'd) - (day('01Jul2020'd) < day(dob))) / 12); 
age_sfy2122 = floor((intck('month', dob, '01Jul2021'd) - (day('01Jul2021'd) < day(dob))) / 12); 
fy1819 = input(age_sfy1819, age_range.);
fy1920 = input(age_sfy1920, age_range.);
fy2021 = input(age_sfy2021, age_range.);
fy2122 = input(age_sfy2122, age_range.); 
run;  

* get each year members individually FROM 00_macros file; 
%keep_age(DATA     = mem1819,
          fy       = fy1819,
          age_sfy  = age_sfy1819);  *2651615 (same AS without macro);

%keep_age(DATA     = mem1920,
          fy       = fy1920,
          age_sfy  = age_sfy1920);  *2670614;

%keep_age(DATA     = mem2021,
          fy       = fy2021,
          age_sfy  = age_sfy2021);  *2685956;

%keep_age(DATA     = mem2122,
          fy       = fy2122,
          age_sfy  = age_sfy2122);  *2696471;

* Get members aged 0-64 in at least ONe of the SFY's ONly, save to out.; 
PROC SQL;
CREATE TABLE mem_list AS 
SELECT coalesce(a.clnt_id, b.clnt_id) AS clnt_id
     , a.age_sfy1819
     , b.age_sfy1920
     , a.fy1819
     , b.fy1920
FROM mem1819 AS a
FULL JOIN mem1920 AS b
ON a.clnt_id = b.clnt_id;
QUIT; *2690472;  

PROC SQL; 
CREATE TABLE mem_list2 AS 
SELECT coalesce(a.clnt_id, b.clnt_id) AS clnt_id
     , a.age_sfy1819
     , a.age_sfy1920
     , b.age_sfy2021
     , a.fy1819
     , a.fy1920
     , b.fy2021
FROM mem_list AS a
FULL JOIN mem2021 AS b
ON a.clnt_id = b.clnt_id;
QUIT; *;  

PROC SQL; 
CREATE TABLE mem_list3 AS 
SELECT coalesce(a.clnt_id, b.clnt_id) AS clnt_id
     , a.age_sfy1819
     , a.age_sfy1920
     , a.age_sfy2021
     , b.age_sfy2122
     , a.fy1819
     , a.fy1920
     , a.fy2021
     , b.fy2122
FROM mem_list2 AS a
FULL JOIN mem2122 AS b
ON a.clnt_id = b.clnt_id;
QUIT; *;  

* Save to library 'out' and change all . to 0's ;
DATA out.mem_list;
SET  mem_list3;
ARRAY fy fy1819 -- fy2122;
DO OVER fy;
    IF fy =. THEN fy = 0;
    END;
run; *2759411;

* Merge in with meddemog1;
PROC SQL; 
CREATE TABLE out.mem_list_demo AS 
SELECT a.*
     , b.*
FROM out.mem_list AS a
LEFT JOIN meddemog1 AS b 
ON a.clnt_id = b.clnt_id; 
QUIT;  *2759411, 15 cols';

PROC PRINT
DATA = out.mem_list_demo (obs = 200); 
run;  

* Get medicaidlong where managedcare = 0 using member list ; 
DATA 	eligible;  
SET  	bhjt.medicaidlong_bidm; 
WHERE	;

PROC CONTENTS
DATA = bhjt.medicaiddemog_bidm; 
RUN;

proc contents DATA = bhjt.medicaid
