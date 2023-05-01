%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 

%let dat = data.analysis_dataset; 

******************************************************************************************************
*** FIND ISSUES where pcmp wasn't on attr file; 
******************************************************************************************************;

DATA raw.memlist_pcmp_missing;
SET  int.memlist_final ; 
where pcmp_loc_id = . ; 
RUN; 

%sort4merge(ds1=raw.qrylong4, ds2=raw.memlist_pcmp_missing, by=mcaid_id);

DATA raw.memlist_pcmp_find; 
SET  raw.qrylong4 (in=a) raw.memlist_pcmp_missing (in=b);
by   mcaid_id;
IF   a and b;
RUN; 

PROC FREQ DATA = int.memlist_final;
WHERE  pcmp_loc_id = . ; 
TABLES mcaid_id / OUT = raw.memlist_pcmp_missing; 
RUN; 


ods pdf file = "&report./eda_freq_20230424.pdf";

PROC CONTENTS DATA = &dat VARNUM ; RUN ;  

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

PROC FREQ DATA = &dat ; 
TABLES age--time int_imp adj: bh_: ind: fqhc; 
RUN ;  

PROC FREQ DATA = &dat ; 
TABLES (age--time int_imp adj: bh_: ind: fqhc)*int; 
RUN ;   

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

Title "Time Frequency by Member" ; 
PROC FREQ DATA = &dat; 
tables adj: ; 
RUN; 

Title "Time Frequency by Member, Intervention (non-varying)"; 
PROC FREQ DATA = data._max_time ; 
tables time*intervention / plots = freqplot(type=dot scale=percent) nopercent norow; 
RUN; 

PROC FREQ DATA = &dat; 
TABLES (ind_:)*int ; 
TITLE "Indicator DVs by Intervention" ; 
TITLE2 "If DV eq 0 then indicator = 0, > 0 then indicator = 1";
format ind: comma20. ; 
RUN ; 
TITLE ; 
TITLE2; 

PROC UNIVARIATE DATA = &dat ; 
TABLES (util:)*int ; 
RUN ; 

proc univariate data = &dat ; 
VAR cost_rx_tc cost_ffs_tc cost_pc_tc ; 
RUN; 
ods text ="By intervention: univariates"; 
proc univariate data = &dat ; 
by int ; 
VAR cost_rx_tc cost_ffs_tc cost_pc_tc ; 
RUN; 

ods pdf close ; 

************************************************************************************
frequencies for adj_pd_total_yycat
************************************************************************************; 

ods pdf file = "&report./adj_vars.pdf";
Title "Monthly Utilization Costs by formatted Variable adj_*";
TITLE2 "Values where adj_* var=-1 but cost (_YYYY) indicates member was in qry_monthlyutilization but NOT found in qry_longitudinal"; 
PROC SORT DATA = int.adj_pd_total_yycat; by adj_pd_total_16cat; run; 

ods text ="(-1): Not Eligible";
ods text ="( 0): Eligible, PMPM $0"; 
ods text ="( 1): Eligible, PMPM > 0 and <=50 percentile"; 
ods text ="( 2): Eligible, PMPM >50 and <=75 percentile"; 
ods text ="( 3): Eligible, PMPM >75 and <=90 percentile"; 
ods text ="( 4): Eligible, PMPM >90 and <=95 percentile"; 
ods text ="( 5): Eligible, PMPM >95 percentile"; 

PROC MEANS DATA = int.adj_pd_total_yycat MEAN MIN MAX; 
CLASS  adj_pd_total_16cat ;
VAR _2016;
RUN; 

PROC MEANS DATA = int.adj_pd_total_yycat MEAN MIN MAX; 
CLASS  adj_pd_total_17cat ;
VAR _2017;
RUN; 

PROC MEANS DATA = int.adj_pd_total_yycat MEAN MIN MAX; 
CLASS  adj_pd_total_18cat ;
VAR _2018;
RUN; 

Title "Monthly Utilization Costs by formatted Variable adj_*";
TITLE2 "Values where adj_* var=-1 but cost (_YYYY) indicates member was in qry_monthlyutilization but NOT found in qry_longitudinal"; 
PROC FREQ DATA = int.adj_pd_total_yycat; 
TABLES _2016*adj_pd_total_16cat
       _2017*adj_pd_total_17cat
       _2018*adj_pd_total_18cat; 
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
