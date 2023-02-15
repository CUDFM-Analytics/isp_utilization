**********************************************************************************************
 PROGRAM NAME       : ISP Utilization
 PROGRAMMER         : K Wiggins
 DATE CREATED       : 09/13/2022
 PROJECT            : ISP Utilization, question 1
 PURPOSE            : Per ISP_Utilization_Analytic_Plan_20221118.docx #1: 
                        Attributed member trends, monthly 7/2019-6/2022: above in the title it specifies (all for ISP and non-ISP PMCPs)
 INPUT FILE(S)      : datasets.isp_masterids.sas7bdat
                    : ana.qry_longitudinal
 OUTPUT FILE(S)     : 
 ABBREV             : 

 MODIFICATION HISTORY:
 Date       Author      Description of Change
 --------   -------     -----------------------------------------------------------------------
 02/10/23   ktw         Copied from 99_...20220922 and changed a lot;

 *SEARCH TERM: #DO#;

* PROJECT PATHS, MAPPING; 
* These are datasets saved from previous matching with Mark and/or permanent datasets that are sourced in;
  %LET    datasets = S:/FHPC/DATA/HCPF_Data_files_SECURE/Kim/datasets;
  LIBNAME datasets "&datasets"; * for isp_masterids;

* contains #'s 1,2,3 (isp attr, change from 03/2020, telehealth pcmp count) datasets for hcpf presentation specifically
  contains rae, telecare_monthly, qry_long_y19_22.sas7bdat; 
  %LET    data     = S:/FHPC/DATA/HCPF_Data_files_SECURE/Kim/isp/isp_utilization/data;
  LIBNAME data  "&data"; 

* RESULTS, Feb2023, HCPF Presentation
  contains #'s 1,2,3 (isp attr, change from 03/2020, telehealth pcmp count) from analytic plan for hcpf presentation specifically; 
  %LET    feb     = S:/FHPC/DATA/HCPF_Data_files_SECURE/Kim/isp/isp_utilization/results/20230200_hcpf_presentation;
  LIBNAME feb  "&feb";

* analytic subset; 
  %LET    hcpf = S:/FHPC/DATA/HCPF_Data_files_SECURE;
  %LET    ana  = S:/FHPC/DATA/HCPF_Data_files_SECURE/HCPF_SqlServer/AnalyticSubset;
  LIBNAME ana "&ana"; 

* VARLEN; 
  %LET varlen = \\data.ucdenver.pvt\dept\SOM\FHPC\DATA\HCPF_Data_files_SECURE\HCPF_SqlServer\queries\DBVarLengths;
  LIBNAME varlen "&varlen";
  %INCLUDE "&varlen\MACRO_charLenMetadata.sas";
  %getlen(library=varlen, data=AllVarLengths);

* DATASETS ---------------------------; 
  %LET isp = datasets.isp_masterids   ; 
  %LET rae = data.rae                 ;
  %LET tele = data.telecare_monthly   ;
 
* OPTIONS ---------------------------; 
  OPTIONS NOFMTERR
          MPRINT MLOGIC SYMBOLGEN
          FMTSEARCH =(ana, data, interim, varlen, work);

* previously was using Copy of full ISP Practice Report 20220828.xlsx - update, make sure this is right... #DO#;
PROC SORT DATA = &isp ; BY splitID; RUN; 

*====== 02 unique pcmp id list ========================================         
keep only pmcp id so you don't mismatch the ones with >1 splitID or npi / transpose later  ;
PROC SORT DATA = datasets.isp_masterids 
     NODUPKEY 
     OUT       = unique_pcmps_isp;
     BY        pcmp_loc_id;
RUN; * removed 2 > from 119 to 117;

DATA data.un_isp_pcmps;
SET  unique_pcmps_isp ( KEEP = pcmp_loc_id ) ;
RUN;  *117 02/14;


* === 03 HCPF qry_longitudinal records in timeframe =============================================== ;        
DATA  qry_long_y19_22_0; 
SET   ana.qry_longitudinal ( KEEP = mcaid_id pcmp_loc_id month ) ;

  * convert pcmp to numeric > create new var, drop old one, rename new one; 
  pcmp_loc_id2 = input(pcmp_loc_id, 8.);
  DROP pcmp_loc_id;
  RENAME pcmp_loc_id2 = pcmp_loc_id;

WHERE month ge '01Jul2019'd 
AND   month le '30Jun2022'd 
AND   pcmp_loc_ID ne ' ';
RUN; *[42737078, 3];

PROC CONTENTS DATA = qry_long_y19_22_0;
RUN; 

* Sort both before getting flag; 
PROC SORT DATA = qry_long_y19_22_0  ; BY pcmp_loc_id ; 
PROC SORT DATA = unique_pcmps_isp ; BY pcmp_loc_id ; RUN;  

* Create flag for ISP vs non-ISP in medlong2;
PROC SQL;
CREATE TABLE data.qry_long_y19_22 as 
SELECT *
     , pcmp_loc_id IN ( SELECT pcmp_loc_id FROM unique_pcmps_isp ) AS isp_flag
FROM qry_long_y19_22_0;
QUIT; 

* get list of all pcmps and indicator ISP flag, then add NPI and split ID to them to check ; 
PROC SORT 
     DATA = data.qry_long_y19_22;
     BY     pcmp_loc_id isp_flag;
RUN; 


/*02/10/2023 - different counts than in sept bc different time frame, but pct approx the same so seems good */
/*0 37405605 87.52 37405605 87.52 */
/*1 5331473 12.48 42737078 100.00 */

* 09/13/22;
/*flag Count        Pct         Cumulative Count CumulativePercent */
/*0 50,050,116      87.8%       50,050,116          87.8% */
/*1 6,985,906       12.2%       57,036,022          100.0% */


* --- Total unique member ids for each pcmp, all flags ----------------------------------------------- ;        
PROC SQL;
CREATE TABLE un_member_ids AS 
SELECT pcmp_loc_id
     , count ( distinct mcaid_id ) as n_member_id
FROM data.qry_long_y19_22
GROUP BY pcmp_loc_id; 
QUIT; *1056, 2; 

PROC PRINT DATA = un_member_ids;
RUN ;

* ------ 01 table:  by pcmp_loc_id, all flags ---------------------------------------; 
proc sql;
create table attr_all_pcmp0 as
select isp_flag
    , month
    , count(distinct mcaid_id) as n_client_id
from data.qry_long_y19_22 group by isp_flag, month;
quit; *31863, 4;

PROC TRANSPOSE DATA = attr_all_pcmp0 
                OUT = feb.attr_all_pcmp (drop=_name_);
BY  ISP_flag; 
ID  month; 
VAR n_client_id;
run; *;

* ------ 02 table:  Get change relative to March 2020 ---------------------------------------; 
PROC CONTENTS 
     DATA = feb.attr_all_pcmp VARNUM;
RUN;

* Get March count for each pcmp from the attr results table;
PROC SQL;
CREATE TABLE attr_MAR2020_0 AS
SELECT isp_flag
     , month 
     , count(DISTINCT mcaid_id) as n_client_id
FROM data.qry_long_y19_22 
GROUP BY isp_flag, month;
quit; *31863, 4;

* Get march only and cbind then calculate each difference: ;
DATA attr_MAR2020_only;
SET  attr_MAR2020_0;
WHERE month eq '01MAR2020'd;
RUN; 

PROC SQL; 
CREATE TABLE attr_mar2020_2 AS 
SELECT a.*
     , b.n_client_id AS n_mar2020
FROM attr_MAR2020_0 AS a
JOIN attr_MAR2020_only AS b
ON a.isp_flag = b.isp_flag; 
QUIT; 

proc format ; 
value isp_prac
0 = "non ISP"
1 = "ISP" ; 
run; 

DATA feb.attr_rel_march2020;
SET  attr_mar2020_2;
n_diff_mar2020 = n_client_id - n_mar2020;
pct_diff_mar2020 = round ( ( n_diff_mar2020 / n_client_id ), .01); 
pct_diff_mar2020 = pct_diff_mar2020*100;
format isp_flag isp_prac.;
RUN; 

proc print data = feb.attr_rel_march2020;
run;

PROC TRANSPOSE DATA = feb.attr_rel_march2020
                OUT = feb.attr_rel_march2020_t (drop=_name_);
BY  ISP_flag; 
ID  month; 
VAR n_diff_mar2020 pct_diff_mar2020;
run; *;







* ---------------Export --------------------------;
ods excel file = "&feb/hcpf_qs_1_2_20230214.xlsx"
    options (   sheet_name = "All_pcmp_attr" 
                sheet_interval = "none"
                frozen_headers = "yes"
                autofilter = "all");

proc print data = feb.attr_all_pcmp;
run;

ods excel options ( sheet_interval = "now" sheet_name = "relative_change_t") ;

proc print data = feb.attr_rel_march2020_t; run;  

ods excel options ( sheet_interval = "now" sheet_name = "relative_change_plot") ;

TITLE "Percent Change Over Time: Member Count Relative to March 2020, ISP, non-ISP";
proc sgplot data = feb.attr_rel_march2020;
yaxis label = " ";
styleattrs datacontrastcolors =(purple steel); 
series x = month y=pct_diff_mar2020 / group = isp_flag;
refline '_01MAR2020'd / 
        axis = x 
        lineattrs = ( thickness = 2 color=grey pattern=dash ) 
        label = ("March 2020")
        labelloc = inside
        label = "March 2020";
run; 
TITLE; 

proc print data = feb.attr_rel_march2020; 
where month eq '01JUN2022'd;
run;

ods excel close; 
run;
