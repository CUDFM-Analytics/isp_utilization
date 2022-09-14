**********************************************************************************************
 PROGRAM NAME		: ISP Utilization
 PROGRAMMER			: K Wiggins
 DATE CREATED		: 09/13/2022
 PROJECT			: ISP
 PURPOSE			: Get data for 2018 to current months with ISP vs non-ISP
 INPUT FILE(S)		: 
 OUTPUT FILE(S)		: 
 ABBREV				: 

 MODIFICATION HISTORY:
 Date	   	Author   	Description of Change
 --------  	-------  	-----------------------------------------------------------------------
 08/18/22	KTW			Copied this from 00_ISP_Counts in NPI_Matching - Documents
 09/13/22 	ktw			last ran;

* ISP NPI file, updated to recode two NPI's on 09/2022;
%let isp_npi = "S:/FHPC/DATA/HCPF_Data_files_SECURE/UPL-ISP/Copy of FULL ISP Practice Report 20220828.xlsx";

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

* ISP NPI file, updated to recode two NPI's on 09/2022;
%let isp_npi = "S:/FHPC/DATA/HCPF_Data_files_SECURE/UPL-ISP/Copy of FULL ISP Practice Report 20220828.xlsx";


* UPDATE ALL BELOW TO USE NEW FILE _ don't use sas7bdats until updated - ;

** QUESTION 1**;
data simisp.isp_medlong; 
merge isp_IDS_unique_PCMP(in=a) medlong2 (in=b); 
by PCMP_LOC_ID; 
if a; 
run; *6155304  ;

*If running again, remove libname to make sure to not overwrite it until you are confirmed;
proc sql; 
create table simisp.AA_Question1_notmissing as
select FY
    , pcmp_loc_ID
    , clinicname
    , count(distinct clnt_ID) as n_client_IDs
    from simisp.isp_medlong
    where FY ne .
    group by FY, clinicname, pcmp_loc_id;
quit; *369 on June 10;

proc sql; 
create table simisp.AA_Question1_Unmatched as
select FY
    , pcmp_loc_ID
    , clinicname
    , count(distinct clnt_ID) as n_client_IDs
    from simisp.isp_medlong
    where FY = .
    group by FY, clinicname, pcmp_loc_id;
quit; 


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
    from simisp.isp_medlong;
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
from simisp.isp_medlong
group by FY, pcmp_loc_ID;
quit;  *386;

*REPORT Q2B;
proc freq data = q2_simisp.isp_medlong;
title 'q2_simisp.isp_medlongA';
tables FY; run;

proc sql;
create table ispcount1 as
select pcmp_loc_ID
    , clinicname
    , month
    , count(distinct clnt_id) as n_client_id
from simisp.isp_medlong group by pcmp_loc_ID, clinicname, month;
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

***Section Months ---;

proc sql;
create table tot_id_isp as
select
  count(distinct clnt_id) as n_client_id
from simisp.isp_medlong ;
quit;

*** QUESTION 3: Months 6 or more within an FY; 

*sort by vars you want sorted; 
proc sort data = simisp.isp_medlong ;
by pcmp_loc_ID FY clnt_ID ;
run;

data Months6; 
set simisp.isp_medlong;
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
VALUE SixMos_   0 = "No"
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
/*      proc datasets library=work nolist;*/
/*      delete Months6b;*/
/*      quit;*/

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
run; *;

*Unique counts client PER YEAR ID all 4 years combined (so not unique client ID for all 4 years - a person might exist 4 times); 
proc freq data = Months6b;
title 'All FY: pcmp_loc_id, client ID 6 months in same practice for FY';
tables pcmp_loc_id /nopercent nocol; 
run; *;
*Unique counts client ID each year; 
proc freq data = Months6b;
title 'All FY: pcmp_loc_id, client ID 6 months in same practice for FY';
tables pcmp_loc_id*FY /nopercent nocol; 
run; *;
proc sql; 
    create table unique_client_4total as 
    select count (distinct Clnt_id)
          , pcmp_loc_id
from Months6b
group by pcmp_loc_id;
quit; 

proc print data = unique_client_4total;
run;

proc report data = Months6b nowd split='~'
    style(summary)=header;
    title "FY: Member ID in Practice >= 6 months~___";
    column pcmp_loc_id FY FY,SixMonths_F,(n pctFY) Delta4Y ;
    define pcmp_loc_id      /  group style(column)=Header;
    define FY               / group across format = FY.;
    define SixMonths_F      / across;
    define n                / 'n' f=comma6.;
    define pctFY            / '%'  COMPUTED format=percent9.1;
    define Delta4Y          / 'FY4-FY1' computed style(column)=Header;
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
Question 04: All 4 years
;
*sum FY;

proc sql; 
 create table All4Years as
 select pcmp_loc_ID
        , clnt_ID
        , count(FY) as CountYears
        , FY
 from Months6b
 group by clnt_id, pcmp_loc_ID;
quit; 

proc print data = All4Years(obs=100);
run;

proc sort data = All4Years nodupkey; by _all_; run; *none; 

data All4Yearsa;
set All4Years;
if CountYears =4 then All4Yrs = 1;
else if CountYears<4 then All4Yrs = 0;
format All4Yrs SixMos_.;
run;

proc print data = All4Yearsa(obs=100);
run;
*find UNIQUE CLIENT IDs so they're not duplicated in each FY: ;

proc sort data = all4Yearsa nodupkey out=unique_client_pcmp_4yrs(drop=FY); by pcmp_loc_id clnt_id; run;

proc print data = unique_client_pcmp_4yrs(obs=100);
run;

*unique client ID's across all 4 years; 
proc freq data = unique_client_pcmp_4yrs;
tables pcmp_loc_id*All4Yrs /nopercent nocol; 
run;



*--------------------------------------------------------------------------------
2nd Export: Question 4 and some new counts export / print 
;
ods excel file = "&path./ISPQ4_20220610.xlsx" 
    options (flow="tables" sheet_name = "_4yrs" sheet_interval="proc");

proc report data = unique_client_pcmp_4yrs nowd split='~'
    style(summary)=header;
    title "Client ID present at least one month in each of the 4 years";
    column pcmp_loc_id n All4Yrs,(n pct_PCMP);
    define pcmp_loc_id      /  group style(column)=Header;
    define All4Yrs          / group across format = SixMos_.;
    define n                / 'n' format=comma6.;
    define pct_PCMP         / computed format=percent9.1 '%';
    compute pct_PCMP;
        _c4_=_c3_/_c2_;
        _c6_=_c5_/_c2_;
    endcomp;
rbreak after / summarize;
run;

ods excel close;

*** get columns;

proc sql;
create table columns as
select name as variable
            ,type as datatype
             ,memname as table_name
from dictionary.columns
where libname = 'SIMISP';
quit;

proc print data=columns noobs;
var table_name variable datatype;
run; 


*--------------------------------------------------------------------------------
1st Export...
DO NOT RUN / RENAME if you want to re-run - I edited the output and don't want to overwrite it. 

I removed the name below just in case - this was exported as
"&path./ISP_outPCMP_20220606.xlsx" ;

ods excel file = 
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
    define pcmp_loc_id      /  group style(column)=Header;
    define FY               / group across format = FY.;
    define SixMonths_F      / across;
    define n                / 'n' f=comma6.;
    define pctFY            / '%'  COMPUTED format=percent9.1;
    define Delta4Y          / 'FY4-FY1' computed style(column)=Header;
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



*PCMPPRIOR
3rd export: pcmp ids Jake had before that are not included now: ;

proc sql; 
    create table PriorListPCMP as 
    select * 
    from medlong2
    where pcmp_loc_id in (102424, 
                                103232, 
                                107242, 
                                123272, 
                                124324, 
                                124853, 
                                128878, 
                                129296, 
                                129418, 
                                133194, 
                                135107, 
                                135278, 
                                135460, 
                                148316, 
                                148610, 
                                153296, 
                                153964, 
                                154815, 
                                155420, 
                                164149, 
                                165405, 
                                167736, 
                                168359, 
                                173855);
    
quit; 

proc sql; 
    create table PriorListPCMP_medlong1 as 
    select * 
    from medlong1
    where pcmp_loc_id in ('102424', 
                                '103232', 
                                '107242', 
                                '123272', 
                                '124324', 
                                '124853', 
                                '128878', 
                                '129296', 
                                '129418', 
                                '133194', 
                                '135107', 
                                '135278', 
                                '135460', 
                                '148316', 
                                '148610', 
                                '153296', 
                                '153964', 
                                '154815', 
                                '155420', 
                                '164149', 
                                '165405', 
                                '167736', 
                                '168359', 
                                '173855');
    
quit; 

proc contents data = priorlistpcmp_medlong1;
run;

data prior_medlong2; set priorlistpcmp_medlong1 (keep=clnt_id pcmp_loc_ID month ); 
where /*managedCare=0 and*/ month ge '01Jul2018'd and month le '01May2022'd and pcmp_loc_ID ne ' ';
if month ge '01Jul2018'd and month le '30Jun2019'd then FY=1;
else if month ge '01Jul2019'd and month le '30Jun2020'd then FY=2;
else if month ge '01Jul2020'd and month le '30Jun2021'd then FY=3;
else if month ge '01Jul2021'd and month le '30Jun2022'd then FY=4;
run; *937869;


*change pcmp to numeric so these'll merge;
data prior_medlong2;
set prior_medlong2;
pcmp_loc_id2 = input(pcmp_loc_id, 12.);
drop pcmp_loc_id;
rename pcmp_loc_id2 = pcmp_loc_id; 
run; *937869;

proc sort data=prior_medlong2; by pcmp_loc_id; run;  

proc sql; create table PriorIDs_Q1 as
select FY
    , pcmp_loc_ID
    , count(distinct clnt_ID) as n_client_IDs
    from prior_medlong2
    where FY ne .
    group by FY, pcmp_loc_id;
quit; *369 on June 10;

*REPORT Q2B_PRIOR;

proc sql;
create table PriorIDs_Q2 as
select pcmp_loc_ID
    , month
    , count(distinct clnt_id) as n_client_id
from prior_medlong2 group by pcmp_loc_ID, month;
quit;  *3992, 3 (got 20 more than the other day... );

proc transpose data=PriorIDs_Q2 ;
by pcmp_loc_ID; id month; var n_client_id;
run; *116, 47;

proc sort data = PriorIDs_Q2; by pcmp_loc_ID; run;

proc transpose data=PriorIDs_Q2;
title '';
by pcmp_loc_ID ; id month; var n_client_id;
run; 

proc print data = data5; title ''; run;

data simisp.priorIDS;
set data5; 
run;

*Export ;
ods excel file = "&path./PriorPCMP_Counts_Months.xlsx" 
    options (flow="tables" sheet_name = "PriorIDS" sheet_interval="proc");

proc print data = data5; title ''; run;

ods excel close;


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
/*  , PROV_LOC_ID length = &PROV_LOC_ID*/
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
/*  , a.pcmp_loc_id*/
/*  , b.splitID*/
/*  , b.practiceNPI*/
/*  , b.pcmp_loc_id*/
/*  from simisp.isp_provdata_FromBDM as a*/
/*  left join simisp.isp_masterIDS as b*/
/*  on a.prov_NPI_ID=b.practiceNPI;*/
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
