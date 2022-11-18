**********************************************************************************************
 PROGRAM NAME       : ISP Utilization
 PROGRAMMER         : K Wiggins
 DATE CREATED       : 08 18 2022
 PROJECT            : ISP
 PURPOSE            : Get claims for members FY 2015-16 through 2017-18
 INPUT FILE(S)      : bhjt.medicaidlong_bidm, out.mem_list
 OUTPUT FILE(S)     : out.mem_claims_1518

 MODIFICATION HISTORY:
 Date       Author      Description of Change
 --------   -------     -----------------------------------------------------------------------
 08/18/22   KTW         Copied this from 00_ISP_Counts in NPI_Matching - Documents
 11/18/22   ktw         last ran;

***********************************************************************************************;
*Init: June 03 2022;
%include "S:/FHPC/DATA/HCPF_Data_files_SECURE/Kim/isp/isp_utilization/02_code/00_global.sas"; 


* MEDLONG ----------------------------------------------------; 
* GET CLAIMS FOR MEMBERS in out.mem_list for FY's 2015-16 through 2017-18;
proc sql; 
create table mem_claims as 
select *
from bhjt.medicaidlong_bidm
where (clnt_id IN 
		(SELECT clnt_id
			FROM out.mem_list)) AND
	month ge '01Jul2015'd  AND
	month le '30Jun2018'd  AND
	pcmp_loc_id ne ' '     AND
	budget_group not in (16,17,18,19,20,21,22,23,24,25,26,27,-1,);
quit; * 25146142;  

* Create SFY column, keep columns, make pcmp numeric; 
data out.mem_claims_1518
	(
	keep=clnt_id 
	    pcmp_loc_ID 
	    month 
	    enr_cnty
	    eligGrp
	    aid_cd
	    budget_group
	    pcmp_loc_type_cd
	    rae_assign
	    SFY
	    managedCare
	); 
set  mem_claims;

if      month ge '01Jul2015'd and month le '30Jun2016'd THEN SFY=1516;
else if month ge '01Jul2016'd and month le '30Jun2017'd THEN SFY=1617;
else if month ge '01Jul2017'd and month le '30Jun2018'd THEN SFY=1718;

pcmp_loc_id2 = input(pcmp_loc_id, 12.);
drop pcmp_loc_id;
rename pcmp_loc_id2 = pcmp_loc_id; 

run; * 25146142;


proc sort data=out.mem_claims_1518; by pcmp_loc_id; run;

