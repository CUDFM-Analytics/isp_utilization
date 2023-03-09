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

  * Datasets used to create the final analysis dataset; 
  %LET tmp = &data/interim;
  LIBNAME tmp "&tmp"; 

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
0 - 5 = "0-5" 
6 -10 = "6-10" 
11-15 = "11-15" 
16-20 = "16-20" 
21-44 = "21-44" 
45-64 = "45-64" ;
      
VALUE pcmp_type_rc
      32 = "FQHC"    45 = "RHC"     51 = "SHS"      61 = "IHS"      62 = "IHS"      Other = "Other"; 

RUN;

