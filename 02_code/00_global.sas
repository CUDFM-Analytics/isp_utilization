%let hcpf     = S:/FHPC/DATA/HCPF_Data_files_SECURE;
  %let subset = S:/FHPC/DATA/HCPF_Data_files_SECURE/HCPF_SqlServer/AnalyticSubset;
  %let util   = &hcpf/Kim/isp/isp_utilization;
    %let code = &util/02_code;
    %let out  = &util/04_data;
    %let in   = &util/03_data raw;
    %let reports = &util/05 reports; 
	

%let subset = "S:\FHPC\DATA\HCPF_Data_files_SECURE\HCPF_SqlServer\AnalyticSubset";
libname subset &subset; 

OPTIONS FMTSEARCH = (subset) ;  

  libname out "&out";

* proc freq format; 
  %include "C:/Users/wigginki/OneDrive - The University of Colorado Denver/sas/sas_formats/procFreq_pct.sas";

* Connect to bdm for medlong and meddemog, get varlen;
  %include "&hcpf/kim/BDMConnect.sas";

* varlen; 
 %let varlen = \\data.ucdenver.pvt\dept\SOM\FHPC\DATA\HCPF_Data_files_SECURE\HCPF_SqlServer\queries\DBVarLengths;
 libname varlen "&varlen";
 %include "&varlen\MACRO_charLenMetadata.sas";
 %getlen(library=varlen, data=AllVarLengths);

 * BHJT --------------------------------;
  %let bhjt = &hcpf/HCPF_SqlServer/queries;
  libname bhjt   "&bhjt";

* OPTIONS ---------------------------; 
options nofmterr
        fmtsearch =(bhjt, out, util, work, varlen);

* FORMATS  ---------------------------; 
proc format ;  
invalue age_range
0 - 64 = 1
other  = 0;
run;

/**/
/*value pcmp_orgtyp;*/
/*'Clinic - Practitioner'           = Other*/
/*'Federally Qualified Health Center' = FQHC*/
/*'Rural Health Clinic'             = RHC*/
/*'Non-Physician Practitioner - Group'= Other*/
/*'Physician'                           = Other*/
/*'Indian Health Services - FQHC'       = IHS*/
/*'Hospital - General'              = Other*/
/*'Clinic - Dental'                 = Dental*/
/*'Nurse Practitioner'              = Other;*/

