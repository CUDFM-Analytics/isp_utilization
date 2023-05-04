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

*******************************************************************************
* Get columns for dataset (use abbreviation 'columns')
*******************************************************************************; 
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

*******************************************************************************
* Unique Member Count, store macro value &nmem
*******************************************************************************; 
proc odstext;
p "Unique Member Count:" / style=systemtitle;

PROC SQL NOPRINT; 
SELECT COUNT (DISTINCT mcaid_id ) into :nmem
FROM &dat ; 
QUIT ; 

*******************************************************************************
* Time frequency : find missing time, pct time
*******************************************************************************; 
proc odstext;
ODS GRAPHICS ON;
PROC FREQ 
     DATA = &dat NOPRINT;
     TABLES time / OUT = freq_time;
RUN; 
TITLE; 
ODS GRAPHICS OFF;

DATA freq_time2;
SET  freq_time (drop=percent rename=(count=n_time)); 
n_mem = &nmem;
pct_time_mem = n_time/n_mem;
pct_time_missing = 1-pct_time_mem; 
RUN; 

proc odstext;
p "Time values by member" / style=systemtitle;
p "Divided time frequency by total unique member ids (n=&nmem) to get percent, 
   then subtracted percent from 1 to get missing val"; 

PROC PRINT DATA = freq_time2;
format pct: percent10.2;
VAR  time n_time pct_time_mem pct_time_missing; 
RUN; 

**************************************************************************************
* UNIQUE PCMP COUNT
**************************************************************************************; 
proc odstext;
p "Counts of Unique PCMP_LOC_IDs by Intervention Status (Time Invariant Var: 'int')" 
   / style=systemtitle;
PROC SQL ; 
SELECT COUNT(DISTINCT pcmp_loc_id) as n_pcmp
     , int as intervention
FROM &dat
GROUP BY int;
QUIT; 
TITLE ; 

*******************************************************************************
* FREQUENCIES, ungrouped (entire dataset)
*******************************************************************************; 
proc odstext;
p "TIME frequency" / style=systemtitle;
ODS GRAPHICS ON;
PROC FREQ 
     DATA = &dat;
     TABLES time / PLOTS = freqplot;
RUN; 
TITLE; 
ODS GRAPHICS OFF;

**************************************************************************************
* FREQUENCIES, ungrouped (entire dataset)
**************************************************************************************; 
proc odstext;
p "Frequencies, Categorical Vars: Ungrouped" / style=systemtitle;
PROC FREQ DATA = &dat; 
TABLES int: age race sex budget_group enr_cnty rae_person_new fqhc bho: adj_pd_total: ind:   ; 
format comma20. ; 
RUN ; 

**************************************************************************************
* PROC UNIVAR for continuous vars, ungrouped (entire dataset)
**************************************************************************************; 
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

**************************************************************************************
* FREQUENCIES, Grouped by INTERVENTION (0,1), time invariant 
**************************************************************************************; 
proc odstext;
p "Frequencies, Categorical Vars by ISP Participation (Time-Invariant Indicator Var: 'int')" / style=systemtitle;
PROC FREQ DATA = &dat; 
TABLES (int_imp age race sex time budget_group enr_cnty rae_person_new fqhc bho: adj_pd_total: ind:)*int   ; 
format comma20. ; 
RUN ; 

**************************************************************************************
* adj vars 16-18
**************************************************************************************; 
PROC ODSTEXT;
p "FY16-18 Adjusted, Categorized Monthly Utilization (Cost) Frequencies (variables adj_pd_total_YYcat)"
  /style = systemtitle;

p "(-1): Not Eligible";
p "( 0): Eligible, PMPM $0"; 
p "( 1): Eligible, PMPM > 0 and <=50 percentile"; 
p "( 2): Eligible, PMPM >50 and <=75 percentile"; 
p "( 3): Eligible, PMPM >75 and <=90 percentile"; 
p "( 4): Eligible, PMPM >90 and <=95 percentile"; 
p "( 5): Eligible, PMPM >95 percentile"; 
p "";
p "Frequency: Ungrouped" / style=header;
PROC FREQ DATA = &allcols;
TABLES (adj_pd_total_16cat adj_pd_total_17cat adj_pd_total_18cat)*FY /nopercent; 
RUN; 

PROC ODSTEXT;
p "Frequency: Grouped by FY (since that's how top-coding was done)"
  /style = header;
PROC FREQ DATA = &allcols;
TABLES (adj_pd_total_16cat adj_pd_total_17cat adj_pd_total_18cat)*FY /nopercent; 
RUN; 

PROC ODSTEXT;
p "Percentiles and values for FY16-18 vars"
  /style = header;
PROC TRANSPOSE DATA = int.pctl1618 OUT=int.pctl1618_long (rename=(_NAME_  = percentile
                                                                  _LABEL_ = label
                                                                  COL1    = original_value));
RUN; 


PROC MEANS DATA = int.fy1618 stackodsoutput n mean std min max;
CLASS adj_pd_total_16cat;
VAR adj_pd_16pm;
ods output summary= mus_adj_16cat (drop=_control_ Variable) ;
RUN; 

PROC PRINT DATA = mus_adj_16cat (drop=_control_ Variable); RUN; 

proc sgplot data=mergedGroup;
  label value='STD';
  format value 5.2;
  vbox cholesterol / category=deathcause group=sex nooutliers
             nofill grouporder=ascending name='a';
  scatter x=deathcause y=cholesterol / group=sex groupdisplay=cluster
                grouporder=ascending jitter markerattrs=(symbol=circlefilled size=5)
               transparency=0.95 clusterwidth=0.7;
  xaxistable value / x=cat class=grp classdisplay=cluster colorgroup=grp location=inside classorder=ascending;
  xaxis display=(nolabel);
  keylegend 'a' / linelength=24;
run;

PROC FREQ DATA = &allcols;
TABLES (adj_pd_total_16cat adj_pd_total_17cat adj_pd_total_18cat)*FY /nopercent; 
RUN; 


ODS pdf close; 



