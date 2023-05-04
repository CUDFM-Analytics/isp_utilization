%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 
%let dat = data.analysis_dataset; 
%let allcols = data.analysis_dataset_allcols; 

******************************************************************************************************
*** FIND ISSUES where pcmp wasn't on attr file; 
******************************************************************************************************;

* COUNT MISSING VARIABLES, see if any exist;
/* create a format to group missing and nonmissing */
proc format;
 value $missfmt ' '='Missing' other='Not Missing';
 value  missfmt  . ='Missing' other='Not Missing';
run;
 
/*proc freq data=data.analysis_dataset; */
/*format _CHAR_ $missfmt.; /* apply format for the duration of this PROC */*/
/*tables _CHAR_ / missing missprint nocum nopercent;*/
/*format _NUMERIC_ missfmt.;*/
/*tables _NUMERIC_ / missing missprint nocum nopercent;*/
/*run;*/
/**/
/*DATA missing; */
/*SET  data.analysis_dataset;*/
/*nvals = N(of FY--adj_pd_rx_tc);*/
/*nmiss = nmiss(of FY--adj_pd_rx_tc);*/
/*proc print; */
/*run; */

******************************************************************************************************
*** EXPORT PDF FREQUENCIES; 
******************************************************************************************************;

ODS PDF FILE = "&report/eda_memlist_final_20230503.pdf";

PROC CONTENTS DATA = &dat VARNUM; run; 

%macro univar_gt0(var, title);
PROC UNIVARIATE DATA = &dat;
TITLE &TITLE; 
VAR &var; 
WHERE &var gt 0 ;
HISTOGRAM; 
RUN; 
%mend; 

%macro univar(var, title);
PROC UNIVARIATE DATA = &dat;
TITLE &TITLE; 
VAR &var; 
HISTOGRAM; 
RUN; 
%mend; 

TITLE "Unique Member Count, Final Dataset"; 
PROC SQL ; 
SELECT COUNT (DISTINCT mcaid_id ) 
FROM &memlist ; 
QUIT ; 

Title "Unique PCMP count by Intervention Status (Non-Varying)"; 
PROC SQL ; 
SELECT COUNT(DISTINCT pcmp_loc_id) as n_pcmp
     , int as intervention
FROM &memlist
GROUP BY int;
QUIT; 
TITLE ; 

Title "Time Frequency by Member, Intervention (non-varying)"; 
PROC FREQ DATA = data._max_time ; 
tables time*intervention / plots = freqplot(type=dot scale=percent) nopercent norow; 
RUN; 

ods text = "Frequencies for categorical variables by Intervention (non-varying)" ; 

TITLE "Unique Member Count, Final Dataset"; 
PROC SQL ; 
SELECT COUNT (DISTINCT mcaid_id ) 
FROM &dat ; 
QUIT ; 

Title "Unique PCMP count by Intervention Status (Non-Varying)"; 
PROC SQL ; 
SELECT COUNT(DISTINCT pcmp_loc_id) as n_pcmp
     , int as intervention
FROM &dat
GROUP BY int;
QUIT; 
TITLE ; 

TITLE "Max Time by Member" ;
PROC SQL ; 
CREATE TABLE data._max_time AS 
SELECT mcaid_id
     , MAX (time) as time
     , MAX (int) as intervention
FROM &dat
GROUP BY mcaid_id ; 
QUIT; 

Title "Time Frequency by Member" ; 
PROC FREQ DATA = data._max_time ; 
tables time / nopercent norow; 
RUN; 

PROC FREQ DATA = &dat; 
TABLES (ind_:)*int ; 
TITLE "Indicator DVs by Intervention" ; 
TITLE2 "Where 1 indicates all values > 0";
format ind: comma20. ; 
RUN ; 
TITLE ; 
TITLE2; 

%univar_gt0(var=adj_pd_total_tc, title = "WHERE &var gt 0"); 
%univar_gt0(var=adj_pd_pc_tc, title = "WHERE &var gt 0"); 
%univar_gt0(var=adj_pd_rx_tc, title = "WHERE &var gt 0"); 

%univar(var=n_pc_pm, title = "&var (Visits)");
%univar(var=n_ed_pm, title = "&var (Visits)");
%univar(var=n_ffs_bh_pm, title = "&var  (Visits)");
%univar(var=n_tel_pm, title = "&var  (Visits)");


Title "Monthly Utilization Costs by formatted Variable adj_*";
TITLE2 "Values where adj_* var=-1 but cost (_YYYY) indicates member was in qry_monthlyutilization but NOT found in qry_longitudinal"; 

ods text ="(-1): Not Eligible";
ods text ="( 0): Eligible, PMPM $0"; 
ods text ="( 1): Eligible, PMPM > 0 and <=50 percentile"; 
ods text ="( 2): Eligible, PMPM >50 and <=75 percentile"; 
ods text ="( 3): Eligible, PMPM >75 and <=90 percentile"; 
ods text ="( 4): Eligible, PMPM >90 and <=95 percentile"; 
ods text ="( 5): Eligible, PMPM >95 percentile"; 


PROC FREQ DATA = &allcols;
TABLES (adj_pd_total_16cat adj_pd_total_17cat adj_pd_total_18cat)*FY /nopercent; 
RUN; 
ODS pdf close; 

* where eligibility = -1 and cost > 0, why? Is possible? 
check mcaidids "A049816", "A371525", "A653864", "A789247"; 
* Checked qry_longitudinal and qry_monthlyutilization; 
/**/
/*PROC PRINT DATA = ana.qry_longitudinal (obs=1000);*/
/*where mcaid_id in ("A049816", "A371525", "A653864", "A789247")*/
/*AND   month ge "01JAN2016"d*/
/*AND   month le "31DEC2016"d; */
/*RUN; */
/**/
/*PROC PRINT DATA = ana.qry_monthlyutilization (obs=1000);*/
/*where mcaid_id in ("A049816", "A371525", "A653864", "A789247")*/
/*AND   month ge "01JAN2016"d*/
/*AND   month le "31DEC2016"d; */
/*RUN; */
/**/
/*PROC PRINT DATA = ana.qry_monthlyutilization (obs=1000);*/
/*where mcaid_id in ("A001791", "A009133", "A009604", "A010792")*/
/*AND   month ge "01JAN2016"d*/
/*AND   month le "31DEC2016"d; */
/*RUN; */
/**/
/*PROC PRINT DATA = ana.qry_longitudinal (obs=1000);*/
/*where mcaid_id in ("A001791", "A009133", "A009604", "A010792")*/
/*AND   month ge "01JAN2016"d*/
/*AND   month le "31DEC2016"d; */
/*RUN; */
