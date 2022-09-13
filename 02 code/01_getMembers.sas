**********************************************************************************************
 PROGRAM NAME		: ISP Utilization
 PROGRAMMER			: K Wiggins
 DATE OF CREATION	: 08 18 2022
 PROJECT			: ISP
 PURPOSE			: Get client ID's for members 0-64 in SFY's 18/19 through 21/22
 INPUT FILE(S)		: 
 OUTPUT FILE(S)		: 
 ABBREV				: bhjt, hcpf (include bdmconnect file has varlen)

 MODIFICATION HISTORY:
 Date	   	Author   	Description of Change
 --------  	-------  	-----------------------------------------------------------------------
 08/18/22	KTW			Copied this from 00_ISP_Counts in NPI_Matching - Documents
 09/13/22	KTW			Ran;

* global paths, settings  ---------------------------;
  %include "S:/FHPC/DATA/HCPF_Data_files_SECURE/Kim/isp/isp_utilization/02_code/00_paths_formats.sas"; *use age range; 
* Includes formats, connect to bdm, setting libnames, options, bhjt, varlen;


***********************************************************************************************;
*Init: Sept 2022;

data meddemog1; set bhjt.medicaiddemog_bidm; run; *2991591, 7; 

* Get variables from meddemog1 needed;
data meddemog2 (keep=clnt_id dob gender county rethnic_hcpf);
set  meddemog1;
run; * dropped to 5 variables; 

* Get age from meddemog;
data meddemog3;
set  meddemog2;
age_sfy1819 = floor((intck('month', dob, '30Jun2018'd) - (day('30Jun2018'd) < day(dob))) / 12); 
age_sfy1920 = floor((intck('month', dob, '30Jun2019'd) - (day('30Jun2019'd) < day(dob))) / 12); 
age_sfy2021 = floor((intck('month', dob, '30Jun2020'd) - (day('30Jun2020'd) < day(dob))) / 12); 
age_sfy2122 = floor((intck('month', dob, '30Jun2021'd) - (day('30Jun2021'd) < day(dob))) / 12); 
keep_sfy1819 = input(age_sfy1819, age_range.);
keep_sfy1920 = input(age_sfy1920, age_range.);
keep_sfy2021 = input(age_sfy2021, age_range.);
keep_sfy2122 = input(age_sfy2122, age_range.); 
run;  

* Checking 1819 ; 
proc freq data = meddemog3;
tables age_sfy1819*keep_sfy1819; 
run; *perfect; 

* Get members aged 0-64 in at least one of the SFY's only, save to out.; 
data out.meddemog;
set  meddemog3;
where keep_sfy1819 = 1 OR keep_sfy1920 = 1 OR keep_sfy2021 = 1 OR keep_sfy2122 = 1; 
run;  

proc contents data = out.meddemog; 
run;


* MEDLONG ----------------------------------------------------; 

data medlong1 (keep=clnt_id 
					pcmp_loc_ID 
					month 
					enr_cnty
					eligGrp
					aid_cd
					budget_group
					pcmp_loc_type_cd
					rae_assign
					SFY
					managedCare); 
set  bhjt.medicaidlong_bidm; 
where /*managedCare = 0 and*/
	  month ge '01Jul2018'd and month le '30Jun2022'd and 
	  pcmp_loc_ID ne ' ' and 
	  BUDGET_GROUP not in (16,17,18,19,20,21,22,23,24,25,26,27,-1,);

if 		month ge '01Jul2018'd and month le '30Jun2019'd then SFY=1819;
else if month ge '01Jul2019'd and month le '30Jun2020'd then SFY=1920;
else if month ge '01Jul2020'd and month le '30Jun2021'd then SFY=2021;
else if month ge '01Jul2021'd and month le '30Jun2022'd then SFY=2122;
run;  *09/07/2022 55641948, 11;  

*change pcmp to numeric ;
data out.medlong;
set  medlong1;
pcmp_loc_id2 = input(pcmp_loc_id, 12.);
drop pcmp_loc_id;
rename pcmp_loc_id2 = pcmp_loc_id; 
run; *55641948;     

* combine members from meddemog to medlong1; 
data meddemog_1819;
set  out.meddemog;
where keep_sfy1819 = 1; 
run;

proc sql; 
create table out.sfy_medlong_1819 as 
select t1.*
	   t2.client_id
from out.medlong as t1
left join out.meddemog as t2
where t1.sfy = 1819 and t2.keep_sfy1819 = 1


data medlong_managedcare1;
set  medlong2; 
where managedcare = 1;
run;






