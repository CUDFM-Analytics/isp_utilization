%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 
%let dat = data.analysis_dataset; 
%let allcols = data.analysis_dataset_allcols; 

* MACRO VARS created: &nobs (records in &dat), &nmem (unique member n) ; 
******************************************************************************************************
*** FIND ISSUES where pcmp wasn't on attr file; 
******************************************************************************************************;

******************************************************************************************************
*** EXPORT PDF FREQUENCIES; 
******************************************************************************************************;

ODS PDF FILE = "&report/eda_analysis_dataset_20230504.pdf"
STARTPAGE = no;


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

* Get total observations: ; 
PROC SQL NOPRINT;
SELECT count(*) into :nobs from &dat;
QUIT; 

PROC ODSTEXT;
p "Final Dataset Inclusion Rules"
  /style = systemtitle;
p "Eligibility determination based on ID presence in qry_longitudinal where records for FYs 19-21 indicated:" 
  /style = header;
p "     1) Age 0-64"; 
p "     2) rae_id not NA";
p "     3) pcmp_loc_id not NA";
p "     4) Sex = M, F (excluded "U")";
p "     5) ManagedCare = 0";
p "     6) budget_group NOT 16:27, -1";
p "Final dataset grouped by quarter.";
p "Variables enr_cnty, rae_id, budget_group, and pcmp_loc_id logic: Where unique value per quarter n >1 , the max value was used.";
p "In cases of ties, the most recent value was used.";
p ' ';

p "The final dataset contains n=&nobs unique mcaid_id*time (quarter) records, with n=&nmem unique member ids." / style=header;
p ' ' ;
p "Dataset Contents / Info:" /style=systemtitle;

* Get columns for dataset (use abbreviation 'columns'); 
PROC SQL; 
TITLE "Contents: Final Dataset (data.analysis_dataset)"; 
SELECT memtype as libname
     , memname as dataset
     , name    as variable
     , type
     , length
     , label
     , format
     , informat
FROM sashelp.vcolumn
WHERE LIBNAME = 'DATA' 
AND   MEMNAME = 'ANALYSIS_DATASET';
quit;

* UNIQUE MEMBER COUNT; 
proc odstext;
p "Unique Member Count:" / style=systemtitle;

PROC SQL NOPRINT; 
SELECT COUNT (DISTINCT mcaid_id ) into :nmem
FROM &dat ; 
QUIT ; 

* Average time records by member; 
proc odstext;
p "Average 'time' values" / style=systemtitle;
ODS GRAPHICS ON;
PROC FREQ 
     DATA = &dat NOPRINT;
     TABLES time / OUT = freq_time PLOTS = freqplot;
RUN; 
TITLE; 
ODS GRAPHICS OFF;

* UNIQUE PCMP COUNT; 
proc odstext;
p "Counts of Unique PCMP_LOC_IDs by Intervention Status (Time Invariant Var: 'int')" / style=systemtitle;
PROC SQL ; 
SELECT COUNT(DISTINCT pcmp_loc_id) as n_pcmp
     , int as intervention
FROM &dat
GROUP BY int;
QUIT; 
TITLE ; 

* FREQUENCIES, ungrouped (entire dataset); 
proc odstext;
p "TIME frequency" / style=systemtitle;
ODS GRAPHICS ON;
PROC FREQ 
     DATA = &dat;
     TABLES time / PLOTS = freqplot;
RUN; 
TITLE; 
ODS GRAPHICS OFF;

* FREQUENCIES, ungrouped (entire dataset); 
proc odstext;
p "Frequencies, Categorical Vars: Ungrouped" / style=systemtitle;
PROC FREQ DATA = &dat; 
TABLES int: age race sex budget_group enr_cnty rae_person_new fqhc bho: adj_pd_total: ind:   ; 
format comma20. ; 
RUN ; 

* PROC UNIVAR for continuous vars, ungrouped (entire dataset); 
proc odstext;
p "PROC UNIVAR, Continuous Vars: Ungrouped" / style=systemtitle;
* Cost vars;
%univar_gt0(var=adj_pd_total_tc, title = "WHERE &var gt 0"); 
%univar_gt0(var=adj_pd_pc_tc,    title = "WHERE &var gt 0"); 
%univar_gt0(var=adj_pd_rx_tc,    title = "WHERE &var gt 0"); 
* Visit vars; 
%univar(var=n_pc_pm,     title = "&var (Visits)");
%univar(var=n_ed_pm,     title = "&var (Visits)");
%univar(var=n_ffs_bh_pm, title = "&var (Visits)");
%univar(var=n_tel_pm,    title = "&var (Visits)");

* FREQUENCIES, ungrouped (entire dataset); 
proc odstext;
p "Frequencies, Categorical Vars by ISP Participation (Time-Invariant Indicator Var: 'int')" / style=systemtitle;
PROC FREQ DATA = &dat; 
TABLES (int_imp age race sex time budget_group enr_cnty rae_person_new fqhc bho: adj_pd_total: ind:)*int   ; 
format comma20. ; 
RUN ; 

PROC ODSTEXT;
p "FY16-18 Adjusted, Categorized Monthly Utilization (Cost) Frequencies (variables adj_pd_total_YYcat)"
  /style = systemtitle;
p "Eligibility determination based on ID presence in qry_longitudinal where:";
p "     1) Age between 0-64 in FY at EOFY"; 
p "     2) rae_id was not not missing for FY's 19-21";
p "     3) pcmp_loc_id not missing";
p "     4) Sex = M, F";
p "     5) ManagedCare = 0";
p "     6) budget_group NOT 16:27, -1";

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
