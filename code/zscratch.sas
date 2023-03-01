PROC CONTENTS 
     DATA =  VARNUM;
RUN;

PROC CONTENTS 
     DATA = analysis6 VARNUM;
RUN;

proc print data = analysis (obs = 500) ; run ; 

PROC CONTENTS 
     DATA = data.qrylong_y15_22 VARNUM;
RUN;

PROC FREQ 
     DATA = qry_monthly_utilization;
     TABLES clmClass;* PLOTS = freqplot(type=dotplot scale=percent) out=out_ds;
     TITLE  'qry_monthly_utilization clmClass';
RUN; 
TITLE; 

PROC FREQ 
     DATA = qry_longitudinal;
     TABLES pcmp_loc_type_cd ;
RUN; 

PROC PRINT 
     DATA = util0 (OBS = 1000);
     where mcaid_id = "A000405";
RUN; 

PROC FREQ 
     DATA = data.rae;
     TABLES _all_;* PLOTS = freqplot(type=dotplot scale=percent) out=out_ds;
     TITLE  'rae codes';
RUN; 
TITLE; 

******************************************************
Initial Contents for all work lib
******************************************************;
PROC SQL; 
     CREATE TABLE columns_data AS 
     SELECT *
     FROM sashelp.vcolumn
     WHERE LIBNAME = upcase("DATA");
QUIT; 

PROC PRINT DATA = columns_DATA NOOBS;
     VAR memname name type length format informat label;
RUN;

ods excel file = "S:/FHPC/DATA/HCPF_Data_files_SECURE/Kim/isp/isp_utilization/tmp/contents_DATA.csv"
    options (frozen_headers = "yes"
             autofilter = "all"
             flow = "tables" );   *so it doesn't include carriage breaks; 
PROC PRINT DATA = columns_DATA;
RUN; 
ods excel close; 
run;
