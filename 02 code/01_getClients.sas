**********************************************************************************************
 PROGRAM NAME		: ISP Utilization
 PROGRAMMER			: K Wiggins
 DATE OF CREATION	: 08 18 2022
 PROJECT			: ISP
 PURPOSE			: Get client ID's for members 0-64 in SFY's 18/19 through 21/22
 INPUT FILE(S)		: 
 OUTPUT FILE(S)		: 
 ABBREV				: 

 MODIFICATION HISTORY:
 Date	   	Author   	Description of Change
 --------  	-------  	-----------------------------------------------------------------------
 08/18/22	KTW			Copied this from 00_ISP_Counts in NPI_Matching - Documents;

* global paths, settings  ---------------------------;
  %let hcpf = S:/FHPC/DATA/HCPF_Data_files_SECURE;
  %let proj = &hcpf/Kim;
  %let util = &proj/isp/isp_utilization/04 data;
  libname util "&util";
/*  %include format file when complete; */

* proc freq format; 
  %include "C:/Users/wigginki/OneDrive - The University of Colorado Denver/Documents/projects/00_sas_formats/procFreq_pct.sas";

* Connect to bdm for medlong and meddemog;
  %include "&proj/BDMConnect.sas";

* VARLEN  -----------------------------;
  %include "&varlen\MACRO_charLenMetadata.sas";
  %getlen(library=varlen, data=AllVarLengths);

* BHJT --------------------------------;
  %let bhjt = &hcpf/HCPF_SqlServer/queries;
  libname bhjt   "&bhjt";

* OPTIONS ---------------------------; 
options nofmterr
        fmtsearch =(bhjt, util, work, varlen);
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


* MEDLONG ----------------------------------------------------; 

data medlong1; set bhjt.medicaidlong_bidm; run;

proc freq data = medlong1;
tables managedCare;
run;  

* MEDLONG: Subset & create SFY variables, select variables, filter managedCare = 0; 
data medlong2 (keep=clnt_id 
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
set  medlong1 ; 

where /*managedCare = 0 and */
	  month ge '01Jul2018'd and month le '30Jun2022'd and pcmp_loc_ID ne ' ';

if 		month ge '01Jul2018'd and month le '30Jun2019'd then SFY=1819;
else if month ge '01Jul2019'd and month le '30Jun2020'd then SFY=1920;
else if month ge '01Jul2020'd and month le '30Jun2021'd then SFY=2021;
else if month ge '01Jul2021'd and month le '30Jun2022'd then SFY=2122;
run; 
*51524899, 3;

*change pcmp to numeric ;
data medlong2;
set medlong2;
pcmp_loc_id2 = input(pcmp_loc_id, 12.);
drop pcmp_loc_id;
rename pcmp_loc_id2 = pcmp_loc_id; 
run; *51524899;  




