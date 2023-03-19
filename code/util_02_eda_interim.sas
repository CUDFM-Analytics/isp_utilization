**********************************************************************************************
 PROJECT       : ISP Utilization
 PROGRAMMER    : KTW
 DATE RAN      : 08-18-2022
 PURPOSE       : Document frequencies, eda in util_01 & util 02
 INPUT FILE/S  :                  
 OUTPUT FILE/S : 
 NOTES         : Date / Note

* global paths, settings  ---------------------------;
***********************************************************************************************;

*----------------------------------------------------------------------------------------------
SECTION01 Data Dictionary for tmp
----------------------------------------------------------------------------------------------;

PROC sql ; 
create table int_contents as 
select memname
     , name
     , length
     , label 
     , format
     , informat
from dictionary.columns
where upcase(libname)="INT" and memtype="DATA";
quit; 

* Export to excel for varnames ; 
ods excel file = "&util./docs/contents_INT.csv"
    options (frozen_headers = "yes"
             autofilter = "all"
             flow = "tables" );   *so it doesn't include carriage breaks; 

PROC PRINT DATA = int_contents; RUN; 

ods excel close; run;

ods excel options ( sheet_interval = "now" sheet_name = "sheet") ; 

PROC CONTENTS DATA = tmp.adj                  VARNUM ; RUN ; 
PROC CONTENTS DATA = tmp.bho_fy6              VARNUM ; RUN ; 
PROC CONTENTS DATA = tmp.memlist              VARNUM ; RUN ; 
PROC CONTENTS DATA = tmp.qrylong_16_22        VARNUM ; RUN ; 
PROC CONTENTS DATA = tmp.memlist_tele_monthly VARNUM ; RUN ; 
PROC CONTENTS DATA = tmp.memlist_tele_monthly VARNUM ; RUN ; 

ods excel close; run;

*----------------------------------------------------------------------------------------------
SECTION02 Frequencies
----------------------------------------------------------------------------------------------;
PROC FREQ 
     DATA = tmp.qrylong_16_22;
     TABLES age ;* PLOTS = freqplot(type=dotplot scale=percent) out=out_ds;
     TITLE  'Frequency month';
RUN  ; 
TITLE; 

PROC SQL ; 
SELECT COUNT ( DISTINCT mcaid_id ) 
FROM   data.teleCare_monthly ; 
QUIT ; 
