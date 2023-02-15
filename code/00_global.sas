**********************************************************************************************
 PROGRAMMER       : K Wiggins
 DATE INIT        : 02/2023
 PROJECT          : ISP Util
 PURPOSE          : Project paths, libs, global settings, formats
 INPUT FILE(S)    : 
 OUTPUT FILE(S)   : 
 LAST RAN/STATUS  : 20230209
 SPECS            : ISP_Utilization_Analytic_Plan_20221118.docx, 

***********************************************************************************************;

* PROJECT PATHS, MAPPING; 
  %LET hcpf     = S:/FHPC/DATA/HCPF_Data_files_SECURE;

  * Source Data / Raw; 
  %LET ana = &hcpf/HCPF_SqlServer/AnalyticSubset;
  LIBNAME ana "&ana"; 

  * Source Data / Processed, long-term static datasets > if used, copied into libname &data; 
  %LET datasets = &hcpf/Kim/datasets;
  LIBNAME datasets "&datasets";

  %LET util = &hcpf/Kim/isp/isp_utilization;
  * Data used for isp_utilization analysis / Processed datasets, ;
  %LET data = &util/data;
  LIBNAME data "&data"; 

  * specifically for feb results output for hcpf presentation; 
  %LET tbl = &util/data_tables;
  LIBNAME tbl "&tbl"; 

  * exports / excel files out, reports; 
  %LET report = &util/reports;

  * interim / temporary files like proc contents output for eda mid-processing, etc. 
  proc contents, freqs too: ;
  %LET tmp = &util/tmp;
  LIBNAME tmp "&tmp"; 

* VARLEN; 
  %LET varlen = \\data.ucdenver.pvt\dept\SOM\FHPC\DATA\HCPF_Data_files_SECURE\HCPF_SqlServer\queries\DBVarLengths;
  LIBNAME varlen "&varlen";
  %INCLUDE "&varlen\MACRO_charLenMetadata.sas";
  %getlen(library=varlen, data=AllVarLengths);

* OPTIONS ---------------------------; 
  OPTIONS NOFMTERR
          MPRINT MLOGIC SYMBOLGEN
          FMTSEARCH =(ana, data, tmp, datasets, varlen, work);

proc format;
value agecat  1="0-19" 2="20-64" 3="65+";
value agehcpf 1="0-3" 2="4-6" 3="7-12" 4="13-20" 5="21-64" 6="65+";
value age7cat 1="0-5" 2="6-10" 3="11-15" 4="16-20" 5="21-44" 6="45-64" 7="65+";
value fy      1="7/1/18 - 6/30/19" 2="7/1/19 - 6/30/20" 3="7/1/20 - 6/30/21";
value nserve  1="1" 2="2" 3="3" 4="4" 5="5" 6="6" 7="7+";
/*value fhqc  0="No services" 1="Only FQHC" 2="Only non-FQHC" 3="Both FQHC and non-FQHC";*/
value capvsh  1="Same month" 2="Short term first" 3="Cap first" 4="Short term only" 5="Cap only" 6="Neither";
value matchn  1="Both match" 2="Billing match" 3="Rendering match" 4="Neither match";
run;
