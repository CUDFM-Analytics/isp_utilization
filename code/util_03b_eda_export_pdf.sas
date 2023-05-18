%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 
%let dat = data.analysis; 
%let all = data.analysis_allcols; 

PROC SQL NOPRINT;
SELECT count(*) into :nobs from &dat;
QUIT; 

PROC SQL; 
SELECT COUNT (DISTINCT mcaid_id ) into :nmem
FROM &dat ; 
QUIT ; 


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


PROC FORMAT;
VALUE adj1618fy
-1 = "(-1) Not Eligble for HFC during FY"
0 = "(0) PMPM in YR is $0 (Eligible HFC)"
1 = "(1) PMPM YR >0 and <= 50th percentile"
2 = "(2) PMPM YR >50th percentiles, <= 75th percentile"
3 = "(3) PMPM YR >75th percentiles, <= 90th percentile"
4 = "(4) PMPM YR >90th percentiles, <= 95th percentile"
5 = "(5) PMPM YR > 95th percentile";

VALUE bh1618fy
0 = "FY Visits = 0"
0.001 - high = "FY Visits >0";

RUN; 

ODS PDF FILE = "&report/eda_analysis_dataset_2023-05-18.pdf"
STARTPAGE = no;

ods proclabel 'Data Specs';
* Print specs ; 
PROC ODSTEXT;
p "Update/s to data.analysis (final ds)";
p "-- 5/15: Effect Coding time with season variables"; 
p "-- 5/10: Included fyqrtr variable in final analysis dataset"; 
p " ";

p "Final Dataset Inclusion Rules"
  /style = systemtitle;
p "Eligibility determination based on ID presence in qry_longitudinal where records for FYs 19-21 indicated:" 
  /style = header;
p "-----1) Age 0-64"; 
p "-----2) rae_id not NA";
p "-----3) pcmp_loc_id not NA";
p "-----4) Sex = M, F only (excluded U)";
p "-----5) ManagedCare = 0";
p "-----6) budget_group NOT 16:27, -1";
p "Final dataset records aggregated by quarters.";
p "-- Where unique value per quarter n >1 for variables rae_id, budget_group, and pcmp_loc_id:";
p "----- a) Max value used where possible";
p "----- b) In cases of ties, used value in quarter months that was most recent";
p " ";
p "The final dataset contains n=&nobs unique mcaid_id*time (quarter) records, with n=&nmem unique member ids." / style=header;
p " ";
RUN; 


*******************************************************************************
* Print columns for dataset (use abbreviation 'columns');
ods proclabel 'Analysis_Dataset Columns'; RUN;
PROC ODSTEXT; 
p "Dataset Contents" /style=systemtitle;
RUN; 
PROC PRINT DATA = data.analysis_meta ; RUN; 

**************************************************************************************
* CATEGORICAL FREQUENCIES, ungrouped (entire dataset)
**************************************************************************************; 
ods proclabel 'Frequencies, Cat Vars: Ungrouped'; RUN; 
proc odstext;
p "Frequencies, Categorical Vars: Ungrouped" / style=systemtitle; RUN; 

PROC FREQ DATA = int.eda_n_ids; TABLES n_id; RUN; 

* Categorical vars; 
PROC FREQ 
DATA   = &dat; 
TABLES int: age race sex budget_group rae_person_new fqhc bh: ind:  
       adj_pd_total_16cat adj_pd_total_17cat adj_pd_total_18cat fy: season:; 
RUN ; 

*******************************************************************************
* Time frequency : find missing time, pct time; 
ods proclabel 'Time Frequency Description';
proc odstext;
p "Time freq by member" / style=systemtitle;
p "(Divided time frequency by total unique member ids (n=&nmem) to get percent, then subtracted percent from 1 to get missing val)"; 
p "";
RUN; 

ods proclabel 'Time Frequency Table';
PROC PRINT DATA = int.eda_time_freq;
format pct: percent10.2;
VAR  time n_time pct_time_mem pct_time_missing; 
RUN; 

**************************************************************************************
* UNIQUE PCMP COUNT; 
ods proclabel 'PCMP Loc ID Description'; RUN; 
proc odstext;
p "Counts of Unique PCMP_LOC_IDs by Intervention Status (Time Invariant Var: 'int')" 
   / style=systemtitle;RUN; 
ods proclabel 'PCMP Loc ID table'; RUN; 
PROC SQL ; 
SELECT COUNT(DISTINCT pcmp_loc_id) as n_pcmp
     , int as intervention
FROM &dat
GROUP BY int;
QUIT; 
TITLE ; 

**************************************************************************************
* PROC UNIVAR for continuous vars, ungrouped (entire dataset); 
ods proclabel 'Top Coded Vals, text'; RUN; 
PROC ODSTEXT;
p "Percentiles and values for top-coded DVs (cost: pc, rx, total)"
  /style = systemtitle;
p "Means taken where value gt 95th percentile"; RUN; 

/*PROC TRANSPOSE DATA = int.mu_pctl_1921 OUT=int.mu_pctl_1921_long (rename=(_NAME_  = percentile*/
/*                                                                          _LABEL_ = label*/
/*                                                                          COL1    = original_value));*/
/*RUN; */
ods proclabel 'Top Coded Vals'; RUN; 
PROC PRINT DATA = int.mu_pctl_1921_long; RUN; 

ods proclabel 'Univar for DVs, text'; RUN; 

proc odstext;
p "PROC UNIVAR for DV's: WHERE VALUES >0 ONLY" / style=systemtitle;
p "For all values, including 0's, see the ind_: variables";  RUN; 

* Cost vars;
%univar_gt0(var=adj_pd_total_tc, title = "WHERE &var gt 0"); 
%univar_gt0(var=adj_pd_pc_tc,    title = "WHERE &var gt 0"); 
%univar_gt0(var=adj_pd_rx_tc,    title = "WHERE &var gt 0"); 

* Visit vars; 
%univar_gt0(var=n_pc_pm,     title = "&var (Visits)");
%univar_gt0(var=n_ed_pm,     title = "&var (Visits)");
%univar_gt0(var=n_ffs_bh_pm, title = "&var (Visits)");
%univar_gt0(var=n_tel_pm,    title = "&var (Visits)");

**************************************************************************************
* CATEGORICAL FREQUENCIES, Grouped by INTERVENTION (0,1), time invariant 
**************************************************************************************; 
ods proclabel 'Frequencies, Cat Vars: Int Status (excluded: adj fy1618)'; RUN; 
proc odstext;
p "Frequencies, Categorical Vars by ISP Participation (Time-Invariant Indicator ('int'))" / style=systemtitle;
p "adj fy 1618 vars have their own section"; 
RUN; 
ods proclabel 'Frequencies, Cat Vars: Int Status'; RUN; 
PROC FREQ DATA = &all; 
TABLES (int_imp age race sex time budget_group rae_person_new fqhc fy: bh: ind:)*int; 
RUN ; 

**************************************************************************************
* adj vars 16-18
**************************************************************************************; 
ods proclabel 'adj FY 1618: categories'; RUN; 

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
RUN; 
ods proclabel 'adj FY 1618: Percentiles, Mus (text)'; RUN; 
PROC ODSTEXT;
p "Percentiles,  Values for FY16-18 vars" /style = header;
p "NB: Frequencies below generated from UNIQUE member records only - not from the final analysis dataset, where record frequency is multiplied by the quarters"/style = header;
p "Frequencies from final dataset are in section 2, and match Jakes proportions almost exactly."/style = header;
RUN; 
/*PROC TRANSPOSE DATA = int.pctl1618 OUT=int.pctl1618_long (rename=(_NAME_  = percentile*/
/*                                                                  _LABEL_ = label*/
/*                                                                  COL1    = original_value));*/
/*RUN; */
ods proclabel 'adj FY 1618: Percentiles, Mus (table)'; RUN; 
PROC PRINT DATA = int.pctl1618_long; RUN; 

**************************************************************************************
* ADJ means FY1618
**************************************************************************************; 
PROC FREQ DATA = int.eda_FY1618;
FORMAT adj_pd_total_16cat adj_pd_total_17cat adj_pd_total_18cat adj1618fy. bho: bh1618fy.;
TABLES adj_pd_total_16cat adj_pd_total_17cat adj_pd_total_18cat bho:;
RUN; 

%macro means_adj(FY);
PROC MEANS DATA = int.fy1618 stackodsoutput n mean std min max;
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

ODS pdf close; 



