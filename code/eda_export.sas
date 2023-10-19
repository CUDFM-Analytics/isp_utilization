
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/config.sas"; 

%let dat = data.utilization; 
/*%let all = data.analysis_allcols; */

OPTIONS pageno=1 linesize=88 pagesize=60 SOURCE fmtsearch=(data, work);
%LET root  = %qsubstr(%sysget(SAS_EXECFILEPATH), 1, 
             %length(%sysget(SAS_EXECFILEPATH))-%length(%sysget(SAS_EXECFILEname))-6); *remove \Code\;

%LET script  = %qsubstr(%sysget(SAS_EXECFILEPATH), 1, 
               %length(%sysget(SAS_EXECFILEPATH))-4);

%LET today = %SYSFUNC(today(), YYMMDD10.);

%LET log   = &script._&today..log;
%LET pdf   = &script._&today..pdf;

PROC PRINTTO LOG = "&log" NEW; RUN;
ODS PDF FILE     = "&pdf"
                    STARTPAGE = no;

Title %sysget(SAS_EXECFILENAME);

PROC SQL NOPRINT;
SELECT count(*) into :nobs from &dat;
QUIT; 

PROC SQL NOPRINT; 
SELECT COUNT (DISTINCT mcaid_id ) into :nmem
FROM &dat ; 
QUIT ; 

PROC SQL NOPRINT;
SELECT count(distinct mcaid_id) into :int
FROM &dat; 
QUIT; 

proc odstext;
p "Date: &today";
p "Project Root: &root";
p "Script: %sysget(SAS_EXECFILENAME)";
p "Total Observations in Dataset: &nobs";
p "Total unique medicaid IDs in Dataset: &nmem";
p "Total medicaid ID's where int 1: &int"; 
p ""; 
RUN; 

* Print specs ; 
PROC ODSTEXT;
/*p "Update/s to data.utilization (final ds)" /style=systemtitle;*/
/*p "-- 09-11: changed to data.utilization, renamed data.utilization to data.analysis_prev to adjust length of variables (also renamed some)."; */
/*p "-- 06/24: Created rescaled integer visit DVs mult by 6 ";*/
/*p "-- 06/19: Changed formats to hard coded values for budget vars, age";*/
/*p "-- 06/08: Changed age determination date from EOFY to Quarter Month=2";*/
/*p "-- 06/05: Collapsed bh FY16-18 variables by FY (ie bh_2016 = 1 if bh_oth2016, bh_er16, or bh_hosp16 = 1)";*/
/*p "-- 06/02: Re-generated dataset and updated to include FY22 Q1";*/
/*p "-- 05/15: Effect Coding time with season variables"; */
/*p "-- 05/10: Included fyqrtr variable in final analysis dataset"; */
/*p " ";*/
/**/
/*p "Final Dataset Inclusion Rules"  /style = systemtitle;*/
/*p "Eligibility determination based on ID presence in qry_longitudinal where records for FYs 19-22 indicated:" */
/*  /style = header;*/
/*p "-----1) Age 0-64 (as of quarter month2)"; */
/*p "-----2) rae_id not NA";*/
/*p "-----3) pcmp_loc_id not NA";*/
/*p "-----4) Sex = M, F only (excluded U)";*/
/*p "-----5) ManagedCare = 0";*/
/*p "-----6) budget_group NOT 16:27";*/
/*p "Final dataset records aggregated by quarters.";*/
/*p "-- Where unique value per quarter n >1 for variables rae_id, budget_group, and pcmp_loc_id:";*/
/*p "----- a) Max value used where possible";*/
/*p "----- b) In cases of ties, used value in quarter months that was most recent";*/
/*p " ";*/
p "The final dataset contains n=&nobs unique mcaid_id*time (quarter) records, with n=&nmem unique member ids, where &int members had time-invariant status 1" / style=header;
p " ";
RUN; 

PROC FORMAT;
VALUE adj1618fy
0 = "(0) Not Eligble for HFC during FY"
1 = "(1) PMPM in YR is $0 (Eligible HFC)"
2 = "(2) PMPM YR >0 and <= 50th percentile"
3 = "(3) PMPM YR >50th percentiles, <= 75th percentile"
4 = "(4) PMPM YR >75th percentiles, <= 90th percentile"
5 = "(5) PMPM YR >90th percentiles, <= 95th percentile"
6 = "(6) PMPM YR > 95th percentile";

VALUE bh1618fy
0 = "FY Visits = 0"
0.001 - high = "FY Visits >0";
RUN; 
*******************************************************************************
* Print columns for dataset (use abbreviation 'columns'); 
ods proclabel 'Analytic Dataset Columns'; RUN;
PROC ODSTEXT; 
p "Dataset Contents" /style=systemtitle;
RUN; 
PROC CONTENTS DATA = &dat VARNUM; RUN; 

ods proclabel 'Frequencies, Cat Vars: Ungrouped'; RUN; 
proc odstext; p "Frequencies, Categorical Vars: Ungrouped"; RUN; 

PROC FREQ DATA = &dat;
TABLES time int int_imp season: ind: bh: race sex budget_grp_num age_cat fqhc rae: adj_pd_total_16cat adj_pd_total_17cat adj_pd_total_18cat;
RUN; 

ods proclabel 'Frequencies, Cat Vars: GROUPED by INT (time invariant)'; RUN; 
proc odstext;
p "Frequencies, Categorical Vars: GROUPED by INT (time invariant)"; RUN; 

PROC FREQ DATA = &dat;
TABLES time int int_imp season: ind: bh: race sex budget_grp_num age_cat fqhc rae: 
            adj_pd_total_16cat adj_pd_total_17cat adj_pd_total_18cat;
BY INT; 
RUN; 

%macro univar_gt0(var, title);
PROC UNIVARIATE DATA = &dat;
TITLE &TITLE; 
VAR &var; 
WHERE &var gt 0 ;
HISTOGRAM; 
RUN; 
TITLE; 
%mend; 

%macro univar(var, title);
PROC UNIVARIATE DATA = &dat;
TITLE &TITLE; 
VAR &var; 
HISTOGRAM; 
RUN; 
TITLE; 
%mend; 

/*proc odstext;*/
/*p "New BH Variables (bh_2016, bh_2017, bh_2018)" / style=systemtitle; */
/*p "Includes all records (not grouped by mcaid_id)"; RUN;  */
/**/
/*PROC SQL; */
/*CREATE TABLE sums_bh_1618 AS */
/*SELECT sum(bh_2016) as n_bh_16*/
/*     , sum(bh_2017) as n_bh_17*/
/*     , sum(bh_2018) as n_bh_18*/
/*FROM &dat; */
/*Quit; */

/*PROC PRINT DATA = sums_bh_1618; RUN; */

/**/
/*********************************************************************************/
/** Time frequency : find missing time, pct time; */
/*ods proclabel 'Time Frequency Description';*/
/*proc odstext;*/
/*p "Time freq by member" / style=systemtitle;*/
/*p "(Divided time frequency by total unique member ids (n=&nmem) to get percent, then subtracted percent from 1 to get missing val)"; */
/*p "";*/
/*RUN; */
/**/
/*ods proclabel 'Time Frequency Table';*/
/*PROC PRINT DATA = int.eda_time_freq;*/
/*format pct: percent10.2;*/
/*VAR  time n_time pct_time_mem pct_time_missing; */
/*RUN; */

**************************************************************************************
* PROC UNIVAR for continuous vars, ungrouped (entire dataset); 
ods proclabel 'Top Coded Vals, text'; RUN; 
PROC ODSTEXT;
p "Percentiles and values for top-coded DVs (cost: pc, rx, total)"
  /style = systemtitle;
p "Means taken where value gt 95th percentile"; RUN; 

PROC TRANSPOSE DATA = int.mu_pctl_1922 OUT=int.mu_pctl_1922_long (rename=(_NAME_  = percentile
                                                                          _LABEL_ = label
                                                                          COL1    = original_value));
RUN; 
ods proclabel 'Top Coded Vals'; RUN; 
PROC PRINT DATA = int.mu_pctl_1922_long; RUN; 

ods proclabel 'Univar for DVs, text'; RUN; 

proc odstext;
p "PROC UNIVAR for DV's: WHERE VALUES >0 ONLY" / style=systemtitle;
p "For all values, including 0's, see the ind_: variables";  RUN; 

* Cost vars;
%univar_gt0(var=cost_total, title = "Cost Total, WHERE &var gt 0"); 
%univar_gt0(var=cost_pc,    title = "Cost PC where &var gt 0"); 
%univar_gt0(var=cost_rx,    title = "Cost Rx WHERE &var gt 0"); 

* Visit vars; 
%univar_gt0(var=n_visits_pc,     title = "&var (Visits) where gt 0");
%univar_gt0(var=n_visits_ed,     title = "&var (Visits) where gt 0");
%univar_gt0(var=n_visits_ffsbh,  title = "&var (Visits) where gt 0");
%univar_gt0(var=n_visits_tel,    title = "&var (Visits) where gt 0");

ods proclabel 'Univar for DVs, text'; RUN; 

proc odstext;
p "PROC UNIVAR for DV's: WHERE VALUES >0 ONLY" / style=systemtitle;
p "For all values, including 0's, see the ind_: variables";  RUN; 

* Cost vars;
%univar(var=cost_total, title = "Cost Total, all values (incl 0s)"); 
%univar(var=cost_pc,    title = "Cost PC, all values incl 0s"); 
%univar(var=cost_rx,    title = "Cost Rx, all values incl 0s"); 

* Visit vars; 
%univar(var=n_visits_pc,     title = ", all values incl 0s");
%univar(var=n_visits_ed,     title = ", all values incl 0s");
%univar(var=n_visits_ffsbh,  title = ", all values incl 0s");
%univar(var=n_visits_tel,    title = ", all values incl 0s");


**************************************************************************************
* adj vars 16-18
**************************************************************************************; 
ods proclabel 'adj FY 1618: categories'; RUN; 

PROC ODSTEXT;
p "FY16-18 Adjusted, Categorized Monthly Utilization (Cost) Frequencies (variables adj_pd_total_YYcat)"
  /style = systemtitle;

p "(0): Not Eligible";
p "(1): Eligible, PMPM $0"; 
p "(2): Eligible, PMPM > 0 and <=50 percentile"; 
p "(3): Eligible, PMPM >50 and <=75 percentile"; 
p "(4): Eligible, PMPM >75 and <=90 percentile"; 
p "(5): Eligible, PMPM >90 and <=95 percentile"; 
p "(6): Eligible, PMPM >95 percentile"; 
p "";
RUN; 

ods proclabel 'adj FY 1618: Percentiles, Mus (text)'; RUN; 
PROC ODSTEXT;
p "Percentiles,  Values for FY16-18 vars" /style = header;
p "NB: Frequencies below generated from UNIQUE member records only - not from the final analysis dataset, where record frequency is multiplied by the quarters"/style = header;
p "Frequencies from final dataset are in section 2, and match Jakes proportions almost exactly."/style = header;
RUN; 
PROC TRANSPOSE DATA = int.pctl1618 OUT=int.pctl1618_long (rename=(_NAME_  = percentile
                                                                  _LABEL_ = label
                                                                  COL1    = original_value));
RUN; 
ods proclabel 'adj FY 1618: Percentiles, Mus'; RUN; 
PROC PRINT DATA = int.pctl1618; RUN; 


**************************************************************************************
* ADJ means FY1618
**************************************************************************************; 
PROC FREQ DATA = &dat;
FORMAT adj_pd_total_16cat adj_pd_total_17cat adj_pd_total_18cat adj1618fy. bho: bh1618fy.;
TABLES adj_pd_total_16cat adj_pd_total_17cat adj_pd_total_18cat bh:;
RUN; 

%macro means_adj(FY);
PROC MEANS DATA = &dat stackodsoutput n mean std min max;
CLASS adj_pd_total_&fy.cat;
VAR   adj_pd_&fy.pm;
ods output summary= mus&FY (drop=_control_ Variable) ;
RUN; 

PROC PRINT DATA = mus&fy (drop=_control_ Variable NObs); RUN; 
%mend; 

ods proclabel 'adj FY 1618 MEANS'; RUN; 

%means_adj(FY=16);
%means_adj(FY=17);
%means_adj(FY=18);


PROC PRINTTO; RUN; ODS PDF CLOSE; 


