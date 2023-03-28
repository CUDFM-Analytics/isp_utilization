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

    VALUE $pcmp_type_new 
    "Hospital - General" = "Other"
    "Physician" = "Other" 
    "Clinic - Practitioner" = "Other" 
    "Federally Qualified Health Center" = "Federally Qualified Health Center" 
    "Nurse Practitioner" = "Other" 
    "Rural Health Clinic" = "Rural Health Clinic" 
    "Clinic - Dental" = "Other" 
    "Indian Health Services - FQHC" = "Indian Health Services - FQHC" ;

    VALUE adj_pd_total_YRcat_
    0 = 0
    1 - 50  = 1
    51 - 75 = 2
    76 - 95 = 3
    96 - 99 = 4 
    Other = .;

    RUN;


%macro create_qrtr(data=,set=,var=,qrtr=);
data &data;
set  &set; 
if &var in ('01JUL2019'd , '01AUG2019'd , '01SEP2019'd ) then &qrtr = 1;
if &var in ('01OCT2019'd , '01NOV2019'd , '01DEC2019'd ) then &qrtr = 2;
if &var in ('01JAN2020'd , '01FEB2020'd , '01MAR2020'd ) then &qrtr = 3;
if &var in ('01APR2020'd , '01MAY2020'd , '01JUN2020'd ) then &qrtr = 4;
if &var in ('01JUL2020'd , '01AUG2020'd , '01SEP2020'd ) then &qrtr = 5;
if &var in ('01OCT2020'd , '01NOV2020'd , '01DEC2020'd ) then &qrtr = 6;
if &var in ('01JAN2021'd , '01FEB2021'd , '01MAR2021'd ) then &qrtr = 7;
if &var in ('01APR2021'd , '01MAY2021'd , '01JUN2021'd ) then &qrtr = 8;
if &var in ('01JUL2021'd , '01AUG2021'd , '01SEP2021'd ) then &qrtr = 9;
if &var in ('01OCT2021'd , '01NOV2021'd , '01DEC2021'd ) then &qrtr = 10;
if &var in ('01JAN2022'd , '01FEB2022'd , '01MAR2022'd ) then &qrtr = 11;
if &var in ('01APR2022'd , '01MAY2022'd , '01JUN2022'd ) then &qrtr = 12;
run;
%mend create_qrtr;


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
