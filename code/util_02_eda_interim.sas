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


proc sql;
create table contents as
select libname
     , memname
     , nobs
     , nvar
     , delobs
     , nlobs
from dictionary.tables
where libname = upcase("TMP");
quit;

proc sql;
create table columns as
select *
from sashelp.vcolumn 
where libname = upcase("tmp");
quit;

proc print data=columns noobs;
var memname nvar nobs name type length format informat label;
run;  

* Export to excel for varnames ; 
ods excel file = "&tmp./contents_TMP.csv"
    options (frozen_headers = "yes"
             autofilter = "all"
             flow = "tables" );   *so it doesn't include carriage breaks; 

PROC PRINT DATA = columns; RUN; 

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
