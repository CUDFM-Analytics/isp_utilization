**********************************************************************************************
 PROGRAM NAME		: ISP Utilization for five specific practices
 PROGRAMMER			: K Wiggins
 DATE CREATED		: 11/02/22
 PROJECT			: ISP
 PURPOSE			: Per Mark: Get data for 2018 to current for five practices
						Email from mark on 11/02/22
						Practices:  164763
									152855
									198098
									51820072
									164606

 OUTPUT FILE(S)		: 
 ABBREV				: bhjt

 MODIFICATION HISTORY:
 Date	   	Author   	Description of Change
 --------  	-------  	-----------------------------------------------------------------------
 09/13/22 	ktw			last ran;

%let simisp = "S:\FHPC\DATA\HCPF_Data_files_SECURE\Kim\datasets";
libname simisp &simisp;

%let pracs = 164763 152855 198098 51820072 164606;

* BHJT  -----------------------------;
  %let bhjt = &hcpf/HCPF_SqlServer/queries;
  libname bhjt   "&bhjt";


* -----------MEDLONG----------------------------;
data medlong00 (keep = clnt_id pcmp_loc_id month); 
set bhjt.medicaidlong_bidm; 
where month ge '01Jul2018'd and month le '01Sep2022'd and pcmp_loc_ID in &pracs;
run;
*[170496617];

data medlong2; set medlong1 (keep=clnt_id pcmp_loc_ID month); 
where month ge '01Jul2018'd and month le '01Sep2022'd and pcmp_loc_ID in &pracs;
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
