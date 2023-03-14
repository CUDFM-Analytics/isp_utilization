**********************************************************************************************
 PROGRAMMER       : K Wiggins
 DATE INIT        : 02/2023
 PROJECT          : ISP Util
 PURPOSE          : Project paths, libs, global settings, formats
 INPUT FILE(S)    : 
 OUTPUT FILE(S)   : 
 LAST RAN/STATUS  : 20230224
 SPECS            : ISP_Utilization_Analytic_Plan_20221118.docx, others... 

***********************************************************************************************;

* PROJECT PATHS, MAPPING; 
  %LET hcpf     = S:/FHPC/DATA/HCPF_Data_files_SECURE;

  * Source Data / Raw - keep in case you need formats; 
  %LET ana = &hcpf/HCPF_SqlServer/AnalyticSubset;
  LIBNAME ana "&ana"; 

  %LET util = &hcpf/Kim/isp/isp_utilization;
  * Data used for isp_utilization analysis;
  %LET data = &util/data;
  LIBNAME data "&data"; 

  %LET raw = &data/raw;
  LIBNAME raw "&raw";

  * Datasets used to create the final analysis dataset; 
  %LET int = &data/interim;
  LIBNAME int "&int"; 

/*  %LET feb = &util/data/hcpf_pres;*/
/*  LIBNAME feb "&feb";*/

  * exports / excel files out, reports; 
  %LET results = &util/results;

* VARLEN; 
  %LET varlen = \\data.ucdenver.pvt\dept\SOM\FHPC\DATA\HCPF_Data_files_SECURE\HCPF_SqlServer\queries\DBVarLengths;
  LIBNAME varlen "&varlen";
  %INCLUDE "&varlen\MACRO_charLenMetadata.sas";
  %getlen(library=varlen, data=AllVarLengths);

* OPTIONS ---------------------------; 
  OPTIONS NOFMTERR
          MPRINT MLOGIC SYMBOLGEN
          FMTSEARCH =(ana, datasets, data, tmp, varlen, work);

%INCLUDE "C:/Users/wigginki/OneDrive - The University of Colorado Denver/Documents/src_sas/sas_macros/data_specs.sas";

PROC FORMAT;

VALUE age_cat_
0 - 5 = 1
6 -10 = 2
11-15 = 3
16-20 = 4 
21-44 = 5
45-64 = 6 ;

VALUE budget_grp_new_
5    = "MAGI TO 68% FPL"
3    = "MAGI 69 - 133% FPL"
6-10 = "Disabled"            
11   = "Foster Care"
12   = "MAGI Eligible Children"
Other = "Other"; 
      
VALUE pcmp_type_rc
32 = "FQHC"    
45 = "RHC"
51 = "SHS"
61 = "IHS"
62 = "IHS"
Other = "Other"; 

VALUE adj_pd_total_YRcat_
0 = "Not eligible for Health First Colorado during year"
1 = "PMPM in YR is $0 (eligible but cost was 0)"
2 = "PMPM YR >0 and <=50th percentile"
3 = "PMPM YR >50th percentile and <=75th percentile"
4 = "PMPM YR >75th percentile and <=90th percentile" 
5 = "PMPM YR >90th percentile and <=95th percentile" 
6 = "PMPM YR >95th percentile"
Other = "Other";

RUN;


proc format;
 picture pctfmt low-high='000.00%';
run; 
ods path work.templat(update) sashelp.tmplmst(read);
proc template;
 edit Base.Freq.OneWayList;
 edit Percent;
 header="; Relative Frequency ;";
 format= pctfmt.;
 justify= on;
 end;
 edit CumPercent;
 header = ";Cumulative; Relative Frequency;";
 format= pctfmt.;
 justify= on;
 end;
 end;
run; 
