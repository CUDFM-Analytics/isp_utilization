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
  RUN;

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

