%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/config.sas"; 
LIBNAME eda "&data/out_eda_checks"; 
LIBNAME tmp "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/data/out_tmp_nov"; 

%let dat = data.utilization; 

/*%let all = data.analysis_allcols; */

OPTIONS pageno=1 linesize=88 pagesize=60 SOURCE fmtsearch=(data, work);
%LET root  = %qsubstr(%sysget(SAS_EXECFILEPATH), 1, 
             %length(%sysget(SAS_EXECFILEPATH))-%length(%sysget(SAS_EXECFILEname))-6); *remove \Code\;

%LET script  = %qsubstr(%sysget(SAS_EXECFILEPATH), 1, 
               %length(%sysget(SAS_EXECFILEPATH))-4);

%LET today = %SYSFUNC(today(), YYMMDD10.);

%LET pdf   = &script._&today..pdf;

PROC SQL NOPRINT;
SELECT count(*) into :nobs from &dat;
QUIT; 

PROC SQL NOPRINT; 
SELECT COUNT (DISTINCT mcaid_id ) into :nmem
FROM &dat ; 
QUIT ; 

PROC SQL NOPRINT;
SELECT count(distinct mcaid_id) into :int
FROM &dat
WHERE int=1; 
QUIT; 

PROC SQL NOPRINT;
SELECT count(*) into :nobsint
FROM &dat
WHERE int=1; 
QUIT; 

PROC FORMAT;
VALUE adj1719fy
0 = "(0) Not Eligble for HFC during FY"
1 = "(1) PMPM in YR is $0 (Eligible HFC)"
2 = "(2) PMPM YR >0 and <= 50th percentile"
3 = "(3) PMPM YR >50th percentiles, <= 75th percentile"
4 = "(4) PMPM YR >75th percentiles, <= 90th percentile"
5 = "(5) PMPM YR >90th percentiles, <= 95th percentile"
6 = "(6) PMPM YR > 95th percentile";

VALUE bh1719fy
0 = "FY Visits = 0"
1 = "FY Visits > 0";
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

***************************************************************;
ODS PDF FILE = "&pdf" STARTPAGE = no;
Title "ISP Utilization Dataset Summary &today";

proc odstext;
p "Date: &today";
p "Project Root: &root";
p "Script: %sysget(SAS_EXECFILENAME)";
p "Total Observations in Dataset: &nobs";
p "Total unique medicaid IDs in Dataset: &nmem";
p "Total medicaid IDs where int 1: &int"; 
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
p "The final dataset contains n=&nobs total records, with n=&nmem unique member ids and n=&int members had time-invariant intervention status of 1" / style=header;
p "There were n=&nobsint total records with int value 1.";
RUN; 

%LET cat = time int_imp season: ind: bh: race sex budget: age_cat fqhc rae: adj_pd_total_17cat adj_pd_total_18cat adj_pd_total_19cat;
%LET num = cost: visits: ; 

* Print columns for dataset (use abbreviation 'sql_cols'); 
PROC ODSTEXT; 
p "Variable Info" /style=systemtitle;
RUN; 

PROC SQL ;
SELECT name, type, length, format, informat
FROM dictionary.columns
/*FROM sashelp.vcolumn*/
WHERE LIBNAME = 'DATA' AND MEMNAME='UTILIZATION';
quit;

ods pdf startpage=now;
TITLE "Frequencies, Categorical Vars";

PROC SQL;
CREATE TABLE memlist_ids_time AS 
select count(distinct mcaid_id), time 
FROM &dat 
GROUP BY time; QUIT;

PROC FREQ DATA = &dat;
TABLES int &cat;
RUN; 

ods pdf startpage=now;
TITLE "Frequencies, Categorical Vars Grouped by INT status";

PROC FREQ DATA = &dat;
TABLES (&cat)*int;
RUN; 


ods pdf startpage=now;
TITLE "Frequencies, Categorical Vars Grouped by TIME";
PROC FREQ DATA = &dat; 
TABLES time*(int int_imp ind: adj_pd_total_1: fqhc budget_grp_new age_cat rae_person_new race sex); 
RUN; 

PROC SQL; 
SELECT count(distinct pcmp_loc_id) 
     , time
FROM &dat
GROUP BY TIME; 
QUIT; 


ods pdf startpage=now;
TITLE "FYs20-23 Cost DV 95th pctls and means where above 0"; 

PROC TRANSPOSE DATA = tmp.mu_pctl_2023 OUT=tmp.mu_pctl_2023_long 
(rename=(_NAME_  = percentile 
         _LABEL_ = label
         COL1    = original_value));
RUN; 
PROC PRINT DATA = tmp.mu_pctl_2023_long; RUN; 

ods pdf startpage=now;
TITLE "Cost PC: Checking pre and post topcoding, Post Proc Univariate (where gt 0)"; 
/*PROC ODSTEXT; p ""; p "cost_pc before and after topcoding, values GT 0 ";RUN; */
/*PROC PRINT DATA = eda.cost_pc_tc_prepost_gt0 noobs; RUN; */
%univar_gt0(var=cost_pc, title = "Cost PC gt 0"); 

ods pdf startpage=now;
TITLE "Cost Rx, Checking pre and post topcoding, Post Proc Univariate (where gt 0)"; 
/*PROC ODSTEXT; p ""; p "cost_rx before and after topcoding, values GT 0 ";RUN; */
/*PROC PRINT DATA = eda.cost_rx_tc_prepost_gt0 noobs; RUN; */
%univar_gt0(var=cost_rx, title = "Cost Rx gt 0"); 

ods pdf startpage=now;
TITLE "Cost Total, Checking pre and post topcoding, Post Proc Univariate (where gt 0)"; 
/*PROC ODSTEXT; p ""; p "cost_total before and after topoding, values GT 0 ";RUN; */
/*PROC PRINT DATA = eda.cost_total_tc_prepost_gt0 noobs; RUN; */
%univar_gt0(var=cost_total, title = "Cost Total gt 0"); 


ods pdf startpage=now;
%univar_gt0(var=visits_pc, title = "Visits PC where gt 0");


ods pdf startpage=now; 
%univar_gt0(var=visits_ed, title = "Visits ED where gt 0");


ods pdf startpage=now; 
%univar_gt0(var=visits_ffsbh, title = "Visits FFSBH where gt 0");


ods pdf startpage=now; 
%univar_gt0(var=visits_tel, title = "Visits Tel where gt 0");


ods pdf startpage=now; 
TITLE "FY2017-FY2019 Categorical Cost Variables with Original Values"; 

PROC ODSTEXT;
p "FY17-FY19 Categorical Adjusted Monthly Costs (vars adj_pd_total_YYcat)" /style = systemtitle;
p ""; 
p "(0): Not Eligible";
p "(1): Eligible, PMPM $0"; 
p "(2): Eligible, PMPM > 0 and <=50 percentile"; 
p "(3): Eligible, PMPM >50 and <=75 percentile"; 
p "(4): Eligible, PMPM >75 and <=90 percentile"; 
p "(5): Eligible, PMPM >90 and <=95 percentile"; 
p "(6): Eligible, PMPM >95 percentile"; 
p "";
RUN; 

PROC ODSTEXT;
p "Percentiles,  Values for FY17-FY19 vars Prior to Top-Coding" /style = systemtitle;
RUN; 
PROC TRANSPOSE DATA = tmp.pctl1719 OUT=tmp.pctl1719_long (rename=(_NAME_  = percentile
                                                                  _LABEL_ = label
                                                                  COL1    = original_value));
RUN; 
ods proclabel 'adj FY 1719: Percentiles, Mus'; RUN; 
PROC PRINT DATA = tmp.pctl1719; RUN; 

**************************************************************************************
* ADJ means FY1618
**************************************************************************************; 
PROC ODSTEXT;
p "Means for FY17-FY19 values by category, confirming max values and ranges" /style = header;
RUN; 

%macro means_adj(FY);
PROC MEANS DATA = tmp.qrylong_1719 stackodsoutput n mean std min max;
CLASS adj_pd_total_&fy.cat;
VAR   adj_pd_&fy.pm;
RUN; 
%mend; 

%means_adj(FY=17);
%means_adj(FY=18);
%means_adj(FY=19);

PROC PRINTTO; RUN; ODS PDF CLOSE; 


