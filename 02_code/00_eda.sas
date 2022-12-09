**********************************************************************************************
 PROGRAM NAME       : 00_eda
 PROGRAMMER         : K Wiggins
 DATE OF CREATION   : 12 06 2022
 PROJECT            : ISP utilization
 PURPOSE            : eda file general > keep open 
 INPUT FILE(S)      : 
 OUTPUT FILE(S)     : out.subset_dictionary
 ABBREV             : 

 MODIFICATION HISTORY:
 Date       Author      Description of Change
 --------   -------     -----------------------------------------------------------------------
 08/18/22   KTW         Copied this FROM 00_ISP_Counts in NPI_Matching - Documents
 12/04/22	KTW			Changed source data from bhjt.medicaiddemog_bidm to clnt_dim_v (spoke w Carter)

* global paths, settings  ---------------------------;
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilizatiON/02_code/00_global.sas"; 
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilizatiON/02_code/00_macros.sas"; 
  *use age range; 
* Includes formats, connect to bdm, setting libnames, options, bhjt, varlen;
***********************************************************************************************;
* Subset Analytics library;
PROC SQL; 
CREATE 
TABLE  out.subset_dictionary AS
SELECT name AS variable
	   , memname AS table_name
FROM   dictionary.columns
WHERE  libname = "SUBSET";
QUIT; 
