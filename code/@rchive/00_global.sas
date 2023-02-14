* PROJECT PATHS, MAPPING; 
  %LET hcpf     = S:/FHPC/DATA/HCPF_Data_files_SECURE;

    %LET subset = S:/FHPC/DATA/HCPF_Data_files_SECURE/HCPF_SqlServer/AnalyticSubset;
	LIBNAME subset "&subset"; 

    %LET util   = &hcpf/Kim/isp/isp_utilization;
      %LET code = &util/02_code;

      %LET out  = &util/04_data;
	  LIBNAME out 	 "&out";

	  %LET in   = &util/03_data raw;
      %LET reports = &util/05 reports; 

* BDM Connection > for medlong and meddemog, get varlen;
  %INCLUDE "&hcpf/kim/BDMConnect.sas";

* VARLEN; 
  %LET varlen = \\data.ucdenver.pvt\dept\SOM\FHPC\DATA\HCPF_Data_files_SECURE\HCPF_SqlServer\queries\DBVarLengths;
  LIBNAME varlen "&varlen";
  %INCLUDE "&varlen\MACRO_charLenMetadata.sas";
  %getlen(library=varlen, data=AllVarLengths);

* BHJT --------------------------------;
  %LET bhjt = &hcpf/HCPF_SqlServer/queries;
  LIBNAME bhjt   "&bhjt";

* OPTIONS ---------------------------; 
  OPTIONS NOFMTERR
          FMTSEARCH =(bhjt, out, util, work, varlen, subset);
* PROC FREQ format; 
  %INCLUDE "C:/Users/wigginki/OneDrive - The University of Colorado Denver/sas/sas_formats/procFreq_pct.sas";


* FORMATS  ---------------------------; 
  PROC FORMAT;  
  INVALUE age_range
  	0 - 64 = 1
  	other  = 0; 
  VALUE agecat 1="0-19" 2="20-64" 3="65+";
  VALUE agehcpf 1="0-3" 2="4-6" 3="7-12" 4="13-20" 5="21-64" 6="65+";
  VALUE age7cat 1="0-5" 2="6-10" 3="11-15" 4="16-20" 5="21-44" 6="45-64" 7="65+";
  VALUE fy 1="7/1/18 - 6/30/19" 2="7/1/19 - 6/30/20" 3="7/1/20 - 6/30/21";
  VALUE nserve 1="1" 2="2" 3="3" 4="4" 5="5" 6="6" 7="7+";
  VALUE fhqc 0="No services" 1="Only FQHC" 2="Only non-FQHC" 3="Both FQHC and non-FQHC";
  VALUE capvsh 1="Same month" 2="Short term first" 3="Cap first" 4="Short term only" 5="Cap only" 6="Neither";
  VALUE matchn 1="Both match" 2="Billing match" 3="Rendering match" 4="Neither match";
  RUN;

* Sources: 
  code_refs / cost analysis from Jake ; 


/**/
/*value pcmp_orgtyp;*/
/*'Clinic - Practitioner'             = Other*/
/*'Federally Qualified Health Center' = FQHC*/
/*'Rural Health Clinic'               = RHC*/
/*'Non-Physician Practitioner - Group'= Other*/
/*'Physician'                         = Other*/
/*'Indian Health Services - FQHC'     = IHS*/
/*'Hospital - General'                = Other*/
/*'Clinic - Dental'                   = Dental*/
/*'Nurse Practitioner'                = Other;*/

