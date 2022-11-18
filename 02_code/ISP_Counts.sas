
*Init: June 03 2022;

%let path = C:/Users/wigginki/The University of Colorado Denver/NPI_Matching - Documents;
%let sim_source = S:/FHPC/DATA/HCPF_Data_files_SECURE;
libname simisp "&sim_source./Kim/IDs";
%include “H:/kwMacros/procFreq_Percent_oneway.sas”;

OPTIONS FMTSEARCH=(simisp);
OPTIONS nofmterr;

%let varlen = \\data.ucdenver.pvt\dept\SOM\FHPC\DATA\HCPF_Data_files_SECURE\HCPF_SqlServer\queries\DBVarLengths;
libname varlen "&varlen";
%include "&varlen\MACRO_charLenMetadata.sas";
%getlen(library=varlen, data=AllVarLengths);

**Medicaid long;
%let bhjt = \\data.ucdenver.pvt\dept\SOM\FHPC\DATA\HCPF_Data_files_SECURE\HCPF_SqlServer\queries;
libname bhjt "&bhjt";
/*libname bhjt 'X:\HCPF_SqlServer\queries';*/
options fmtsearch=(bhjt);

data medlong1; set bhjt.medicaidlong_bidm; run;
*[170496617];

data medlong2; set medlong1 (keep=clnt_id pcmp_loc_ID month); 
where /*managedCare=0 and*/ month ge '01Jul2018'd and month le '01May2022'd and pcmp_loc_ID ne ' ';
if month ge '01Jul2018'd and month le '30Jun2019'd then FY=1;
else if month ge '01Jul2019'd and month le '30Jun2020'd then FY=2;
else if month ge '01Jul2020'd and month le '30Jun2021'd then FY=3;
else if month ge '01Jul2021'd and month le '30Jun2022'd then FY=4;
run; 
*51524899, 3;

*change pcmp to numeric so these'll merge;
data medlong2;
set medlong2;
pcmp_loc_id2 = input(pcmp_loc_id, 12.);
drop pcmp_loc_id;
rename pcmp_loc_id2 = pcmp_loc_id; 
run; *51524899;

proc sort data=medlong2; by pcmp_loc_id; 

proc sort data=simisp.isp_MasterIDS_names  
nodupkey out = isp_IDS_unique_PCMP; 
by pcmp_loc_id; 
run; *116; 
*The only 2 splitIDS that share a pcmp_loc_ID are 3388  and 3465 (162015, 107169)
3353 would if it had the same as 2004;

** QUESTION 1**;
data isp_medlong; 
merge isp_IDS_unique_PCMP(in=a) medlong2 (in=b); 
by PCMP_LOC_ID; 
if a; 
run; *6155304  ;

proc sql; 
create table simisp.AA_Question1_notmissing as
select FY
	, pcmp_loc_ID
	, clinicname
	, count(distinct clnt_ID) as n_client_IDs
	from ISP_Medlong
	where FY ne .
	group by FY, clinicname, pcmp_loc_id;
quit; 

proc sql; 
create table simisp.AA_Question1_Unmatched as
select FY
	, pcmp_loc_ID
	, clinicname
	, count(distinct clnt_ID) as n_client_IDs
	from ISP_Medlong
	where FY = .
	group by FY, clinicname, pcmp_loc_id;
quit; 


*** PCMP NOT FOUND***;

proc sql;
create table distinctIDS_ISP as
	select count(distinct splitID) as distinct_splitIDs
	 , count(splitID) as total_split
	 , count(distinct practiceNPI) as distinct_npis
	 , count(PracticeNPI) as total_NPI
	 , count(distinct pcmp_loc_id) as distinct_pcmp
	 , count(pcmp_loc_id) as total_PCMP
	 , count(distinct clnt_id) as distinct_clientID
	 , count(clnt_id) as total_clientIDS
	 , count(distinct month) as distinct_month
	 , count(month) as n_months
	from isp_medlong;
quit;

proc sql; 
create table countsNPI_PCMP_perSplit
select splitID
	, practiceNPI
	, count(practiceNPI) as NPIperSplit
	, pcmp_loc_id
	, count(PCMP_LOC_ID) as pmcppersplit
	from simisp.isp_masterIDS_names
	group by splitID;
quit;


**QUESTION 2**;
proc sql;
create table Q2_ispmedlong as  /*was  jt's medlong_pr2 I think*/
select FY, pcmp_loc_ID,
count (distinct clnt_id) as n_client_id
from ISP_MEDLONG
group by FY, pcmp_loc_ID;
quit;  *386;

*REPORT Q2B;
proc freq data = q2_isp_medlong;
title 'q2_isp_medlongA';
tables FY; run;

proc sql;
create table ispcount1 as
select pcmp_loc_ID
	, clinicname
	, month
	, count(distinct clnt_id) as n_client_id
from ISP_MEDLONG group by pcmp_loc_ID, clinicname, month;
quit;  *3992, 3 (got 20 more than the other day... );

proc transpose data=ispcount1 out=simisp.AA_ispcount2 (drop= _name_);
by pcmp_loc_ID clinicname; id month; var n_client_id;
run; *116, 47;

proc sort data = ispCount1; by pcmp_loc_ID clinicname; run;

proc transpose data=ispcount1 out=simisp.AA_ispcount2 ;
by pcmp_loc_ID clinicname; id month; var n_client_id;
run; 

data simisp.AA_ispCount2 (drop= _name_);
set simisp.AA_ispCount2;
run;

proc sql;
create table tot_id_isp as
select
  count(distinct clnt_id) as n_client_id
from ISP_MEDLONG ;
quit;

*** QUESTION 3: Months 6 or more within an FY; 

*sort by vars you want sorted; 
proc sort data = ISP_MEDLONG ;
by pcmp_loc_ID FY clnt_ID ;
run;

data Months6; 
set ISP_Medlong;
where FY ne . ;
run; *6155287;

*last.var keeps the last one - retain keeps the running count; 
data Months6a;
set Months6;
by pcmp_loc_id FY clnt_id;

retain N;

if first.clnt_id then N=1;
else N = N+1;

if last.clnt_id then output;

keep pcmp_loc_id FY clnt_ID N;
run; *770516;

proc print data = Months6a (obs=100); run;

proc sort data = Months6a nodupkey; by _all_; run; *NATT; 

*Create dataset CLNT6, but only to check - use the clnt so you can get n and pct total ; 
data clnt6;
set Months6a;
where N >= 6;
run; *555446;

proc format;
VALUE SixMos_	0 = "No"
				1 = "Yes"
				Other ='';
PICTURE pct (ROUND) low-high='009%';
RUN;

data Months6b;
set Months6a;
if N >=6 then SixMonths = 1;
else if N <= 5 then SixMonths = 0;
SixMonths_f = put(SixMonths, SixMos_.);
run;

*Use to delete if re-running: ;
/*		proc datasets library=work nolist;*/
/*		delete Months6b;*/
/*		quit;*/

proc print data = Months6b (obs=50); run;

proc format; 
value FY
	1 = "FY 1"
	2 = "FY 2"
	3 = "FY 3"
	4 = "FY 4";
run;

proc freq data = Months6b;
title 'All FY: pcmp_loc_id, client ID 6 months in same practice for FY';
tables FY*pcmp_loc_id*SixMonths_f /nopercent nocol; 
run; *1=matches 555446;


proc report data = Months6b nowd split='~'
	style(summary)=header;
	title "FY: Member ID in Practice >= 6 months~___";
	column pcmp_loc_id FY FY,SixMonths_F,(n pctFY) Delta4Y ;
	define pcmp_loc_id 		/  group style(column)=Header;
	define FY 				/ group across format = FY.;
	define SixMonths_F 		/ across;
	define n				/ 'n' f=comma6.;
	define pctFY			/ '%'  COMPUTED format=percent9.1;
	define Delta4Y			/ 'FY4-FY1' computed style(column)=Header;
	compute pctFY;
		_c7_=_c6_/_c2_;
		_c9_=_c8_/_c2_;
		_c11_=_c10_/_c3_;
		_c13_=_c12_/_c3_;
		_c15_=_c14_/_c4_;
		_c17_=_c16_/_c4_;
		_c19_=_c18_/_c5_;
		_c21_=_c20_/_c5_;
	endcomp;
	compute Delta4Y;
		_c22_=_c5_-_c2_;
	endcomp;
rbreak after / summarize;
run;



ods graphics on ; 

proc freq data = Months6b;
tables Months6_FY_PRAC*FY /plots=mosaicplot(square); 
title 'Proportion of Members attributed to the same practice for 6 or more months each FY';
run;

ods graphics off; 

*--------------------------------------------------------------------------------
Export...;

ods excel file = "&path./ISP_outPCMP_20220606.xlsx" 
options (flow="tables" sheet_name = "AllIDs_Names" sheet_interval="proc");

proc print data = simisp.isp_masterIDS_names noobs; run; 

ods excel options(sheet_interval= "now" sheet_name = "UnmatchedBDM");

proc print data = simisp.AA_Question1_unmatched noobs; run; 

ods excel options(sheet_interval= "now" sheet_name = "Attrib_Months");

proc print data = ispcount2 noobs; run;

ods excel options(sheet_interval= "now" sheet_name = "Months_FYs");

proc report data = Months6b nowd split='~'
	style(summary)=header;
	title "FY: Member ID in Practice >= 6 months~___";
	column pcmp_loc_id FY FY,SixMonths_F,(n pctFY) Delta4Y ;
	define pcmp_loc_id 		/  group style(column)=Header;
	define FY 				/ group across format = FY.;
	define SixMonths_F 		/ across;
	define n				/ 'n' f=comma6.;
	define pctFY			/ '%'  COMPUTED format=percent9.1;
	define Delta4Y			/ 'FY4-FY1' computed style(column)=Header;
	compute pctFY;
		_c7_=_c6_/_c2_;
		_c9_=_c8_/_c2_;
		_c11_=_c10_/_c3_;
		_c13_=_c12_/_c3_;
		_c15_=_c14_/_c4_;
		_c17_=_c16_/_c4_;
		_c19_=_c18_/_c5_;
		_c21_=_c20_/_c5_;
	endcomp;
	compute Delta4Y;
		_c22_=_c5_-_c2_;
	endcomp;
rbreak after / summarize;
run;

ods excel options(sheet_interval= "now" sheet_name = "Group_Counts");

proc print data = distinctIDS_ISP; run; 


ods excel close;
run;












/**get NPI from HCPF; */
/**/
/*libname db odbc complete="driver=SQL Server; database=BIDM; server=SOMD-S-SQLDB.ucdenver.pvt" access=readonly schema="ro";/**/*/
/**/
/**/
/**get NPIs from prov-dim to see if matches and try to match on 2;*/
/**/
/**/
/**/
/*proc contents data = db.prov_loc_dim_v;*/
/*run;*/
/**/
/**/
/*proc sql; */
/*create table provData as*/
/*  select distinct PROV_NPI_ID length = &PROV_NPI_ID*/
/*	, PROV_LOC_ID length = &PROV_LOC_ID*/
/*  from db.PROV_LOC_DIM_V*/
/*where prov_NPI_ID ne ' ';*/
/*quit; *137680;*/
/**/
/*data provdata2;*/
/*set provdata;*/
/*new = input(prov_NPI_ID, 13.);*/
/*drop prov_NPI_ID;*/
/*rename new=prov_NPI_ID;*/
/*run;*/
/**/
/*data provdata3;*/
/*set provdata2;*/
/*new = input(prov_loc_ID, 13.);*/
/*drop prov_loc_ID;*/
/*rename new=pcmp_loc_ID;*/
/*run; *137680k;*/
/**/
/*/**/*/
/*/*data provData4;*/*/
/*/*merge provdata3 (in=a) simisp.isp_masterIDS (in=b);*/*/
/*/*by prov_loc_id;*/*/
/*/**/*/
/*/*if a and b then output; */*/
/*/*run;*/*/
/**/
/*proc sql; */
/*create table provData4 as */
/*select **/
/*from provData3*/
/*where pcmp_loc_id in (select pcmp_loc_id from simisp.isp_masterIDS);*/
/* *137;*/
/**/
/*proc sql;*/
/*create table provdata4a as*/
/*select **/
/*FROM provdata4*/
/*WHERE prov_npi_id in (select practiceNPI from simisp.isp_MasterIDS);*/
/*quit; *118;*/
/**/
/*data simisp.ISP_provdata_FromBDM;*/
/*set provdata4a;*/
/*run;*/
/**/
/*libname db clear; */
/**/
/*proc sort data = simisp.isp_provdata_FromBDM nodupkey; by _all_; run;*/
/**/
/*proc sql; */
/*create table provData2 as*/
/*  select a.*/
/*  from provdata*/
/*where prov_NPI_ID in (select prov_NPI_id from simisp.isp_masterIDS);*/
/*quit;  *;*/
/**/
/**/
/*proc sql; */
/*create table simisp.compareProv as */
/*select a.prov_NPI_ID*/
/*	, a.pcmp_loc_id*/
/*	, b.splitID*/
/*	, b.practiceNPI*/
/*	, b.pcmp_loc_id*/
/*	from simisp.isp_provdata_FromBDM as a*/
/*	left join simisp.isp_masterIDS as b*/
/*	on a.prov_NPI_ID=b.practiceNPI;*/
/*quit; *185, 4; */
/**/
/*proc sort data = simisp.compareProv nodupkey; by _all_; run; *158;*/
/**/
/*libname db clear; */
/**/
/**** MeRGE;*/
/**/
/**/
/**/
