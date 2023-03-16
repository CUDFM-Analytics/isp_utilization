**********************************************************************************************
AUTHOR   : KTW
PROJECT  : ISP Utilization Analysis
PURPOSE  : configs 
VERSION  : 2023-03-16 [date last updated]
FILE/S   : 1) ISP-CTLP_Model_specifications.docx
NOTES    : See ../../_rchive_utilization for LOGS and all archived docs, ds, code, etc 
GIT      : github organization DFM, `isp_utilization`

LOG
2023-03-16 Moved all archived/outdated files to Kim/_rchive_utilization due to new spec file from MG
***********************************************************************************************;

* SOM DIR -------------------------------------------------------------------------------------; 
    %LET hcpf     = S:/FHPC/DATA/HCPF_Data_files_SECURE;

* PROJECT ROOT DIR ----------------------------------------------------------------------------; 
      %LET util = &hcpf/Kim/isp/isp_utilization;

    * DATA
      |--data           [libname 'data': stores final analytic dataset and other data folders]                                                     
         |--_raw`       [libname 'raw' : raw, read-only files to be prepped then stored in /interim]
         |--interim     [libname 'int' : intermediate ds used to make final analytic ds or eda]
         |--results     [libname 'out' : results tables, get exported to ../results
      ;

      %LET data = &util/data;   LIBNAME data "&data"; 
      %LET raw = &data/raw;     LIBNAME raw "&raw";
      %LET int = &data/interim; LIBNAME int "&int"; 
      %LET out = &util/out;     LIBNAME out "&out";

    * export folder for excel files output; 
      %LET report = &util/reports; 

* EXT DATA SOURCES ---------------------------------------------------------------------------; 

    * Medicaid dats: keep attached for formats (until/if final fmts copied); 
      %LET ana = &hcpf/HCPF_SqlServer/AnalyticSubset;
      LIBNAME ana "&ana"; 

    * VARLEN (not sure if still needed... can ask Carter); 
      %LET varlen = \\data.ucdenver.pvt\dept\SOM\FHPC\DATA\HCPF_Data_files_SECURE\HCPF_SqlServer\queries\DBVarLengths;
      LIBNAME varlen "&varlen";
      %INCLUDE "&varlen\MACRO_charLenMetadata.sas";
      %getlen(library=varlen, data=AllVarLengths);

* PROJECT-WIDE GLOBAL OPTIONS ----------------------------------------------------------; 

    OPTIONS NOFMTERR
              MPRINT MLOGIC SYMBOLGEN
              FMTSEARCH =(ana, datasets, data, util, varlen, work);

/** INCLUDE FILES  -----------------------------------------------------------------------; */
/*%INCLUDE "C:/Users/wigginki/OneDrive - The University of Colorado Denver/Documents/src_sas/sas_macros/data_specs.sas";*/


* FORMATS ----------------------------------------------------------; 
* Specified in ISP-CTLP_Model_specifications.docx from MG 03/13/2023;

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

    VALUE $adj_pd_total_YRcat_
    0 = "Not eligible for Health First Colorado during year"
    1 = "PMPM in YR is $0 (eligible but cost was 0)"
    2 = "PMPM YR >0 and <=50th percentile"
    3 = "PMPM YR >50th percentile and <=75th percentile"
    4 = "PMPM YR >75th percentile and <=90th percentile" 
    5 = "PMPM YR >90th percentile and <=95th percentile" 
    6 = "PMPM YR >95th percentile"
    Other = "Other";

    RUN;

* THIS SUCKS because it shows 0.87% as 87% but SAS stopped rounding my proc freqs so I don't know what to do; 
* Remove it if you can ever figure that out... ; 
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
