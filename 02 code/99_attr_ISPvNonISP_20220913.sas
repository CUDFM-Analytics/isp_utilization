**********************************************************************************************
 PROGRAM NAME		: ISP Utilization
 PROGRAMMER			: K Wiggins
 DATE CREATED		: 09/13/2022
 PROJECT			: ISP
 PURPOSE			: Per Mark: Get data for 2018 to current months with only two rows: ISP vs non-ISP
						(like attribution by month files)
 INPUT FILE(S)		: simisp.masterids dataset for ISP flag
					: bhjt.medicaidlong_bidm
 OUTPUT FILE(S)		: 
 ABBREV				: 

 MODIFICATION HISTORY:
 Date	   	Author   	Description of Change
 --------  	-------  	-----------------------------------------------------------------------
 09/13/22 	ktw			last ran;

* copy of full ISP Practice Report 20220828.xlsx;
%let full_isp_prac_report = "S:/FHPC/DATA/HCPF_Data_files_SECURE/UPL-ISP/Copy of FULL ISP Practice Report 20220828.xlsx";
proc import datafile = &full_isp_prac_report
	out = isp0 (keep= split_id prac_npi practice_name)
dbms = xlsx replace;
run;  

proc sort data = isp0; by prac_npi; 
proc sort data = simisp.isp_masterids; by practicenpi; run;

* Get pcmp_loc_ids from simisp.isp_masterids;
data isp1;
merge isp0 (in=a rename=(prac_npi=practicenpi)) simisp.isp_masterids (in=b) ;
by practicenpi;
if a; 
run; *119; 

data simisp.isp_sept2022;
set  isp1; 
run;

proc sort data = isp1 nodupkey out = simisp.un_isp_pcmp_sept2022;
by pcmp_loc_id; 
run; *3 duplicates were removed, leaving 116 observations;


* -----------MEDLONG----------------------------;
data medlong1; set bhjt.medicaidlong_bidm; run;
*[170496617];

data medlong2; set medlong1 (keep=clnt_id pcmp_loc_ID month); 
where month ge '01Jul2018'd and month le '01Sep2022'd and pcmp_loc_ID ne ' ';
run; 
*09/13/22: 57036022, 3
took out managedcare = 0 - should I?;

*change pcmp to numeric so these'll merge;
data medlong2;
set medlong2;
pcmp_loc_id2 = input(pcmp_loc_id, 12.);
drop pcmp_loc_id;
rename pcmp_loc_id2 = pcmp_loc_id; 
run; *57036022;

proc sort data=medlong2; by pcmp_loc_id; run;

* Create flag for ISP vs non-ISP in medlong2;
proc sql; 
create table medlong3 as 
select *
	, pcmp_loc_id in (SELECT pcmp_loc_id from simisp.un_isp_pcmp_sept2022) as flag
from medlong2;
quit; *09/13 57036022;

proc freq data = medlong3;
tables flag;
run;
* 09/13/22;
/*flag Count 		Pct 		Cumulative Count CumulativePercent */
/*0 50,050,116 		87.8% 		50,050,116 			87.8% */
/*1 6,985,906 		12.2% 		57,036,022 			100.0% */


/*data simisp.isp_medlong; */
/*merge isp_IDS_unique_PCMP(in=a) medlong2 (in=b); */
/*by PCMP_LOC_ID; */
/*if a; */
/*run; *6155304  ;*/

* Get unique number of client ID's per pcmp_loc_id;

proc sql; 
create table un_clnt_ids_isp_sept2022 as 
select pcmp_loc_id
	, count(distinct clnt_id) as n_client_id
from medlong3 group by pcmp_loc_id;
run;

proc print data = un_clnt_ids_isp_sept2022;
run;

* 01 table:  by pcmp_loc_id; 
proc sql;
create table ispcount1 as
select pcmp_loc_ID
	, flag
	, month
 	, count(distinct clnt_id) as n_client_id
from medlong3 group by flag, pcmp_loc_ID, month;
quit; *09/13: 42687, 4;

proc transpose data = ispcount1 
				out = ispcount1a (drop=_name_);
by flag pcmp_loc_ID; 
id month; 
var n_client_id;
run;

*02 table: by flag only;
proc sql;
create table ispcount2 as
select flag
	, month
 	, count(distinct clnt_id) as n_client_id
from medlong3 group by flag, month;
quit; *98, 3 (it's months contributing to rows, not id's - don't panic);

proc transpose data=ispcount2 
				out=out.attr_by_isp_nonisp_sept (drop=_name_);
by flag ; id month; var n_client_id;
run;


* ISP pcmp_loc_id's included;
proc sql;
create table tot_pcmp_isp as
select
  count(distinct pcmp_loc_id) as n_pcmp
from medlong3
where flag = 1;
quit; run;
proc print data=tot_pcmp_isp; run; *100;

proc sql;
create table tot_id_isp as
select
  count(distinct clnt_id) as n_client_id
from medlong3
where flag = 1;
quit; run;
proc print data=tot_id_isp; run; *368278;

* ---------------Export --------------------------;
ods excel file = "&reports/MonthlyAttr_ISP_v_NonISP.xlsx"
	options (   sheet_name = "ISP_nonISP" 
				sheet_interval = "none"
				frozen_headers = "yes"
				autofilter = "all");

proc print data = out.attr_by_isp_nonisp_sept;
run;

ods excel options ( sheet_interval = "now" sheet_name = "ISPflag_byPCMP") ;

proc print data = ispcount1a; run;  

ods excel options ( sheet_interval = "now" sheet_name = "counts"	) ;

proc odstext; p "Total client_ids where ISP = yes, June 2018 to Aug 2022";

proc print data=tot_id_isp; run;

proc odstext; p "Total PCMP_LOC_IDs matched where ISP = yes, June 2018 to Aug 2022";

proc print data=tot_pcmp_isp; run;   

ods excel close; 
run;
