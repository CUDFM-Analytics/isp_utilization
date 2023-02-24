PROC CONTENTS 
     DATA = merge0 VARNUM;
RUN;

PROC CONTENTS 
     DATA = analysis_data0 VARNUM;
RUN;

PROC CONTENTS 
     DATA = data.util_month_y15_22 VARNUM;
RUN;

PROC FREQ 
     DATA = analysis_data0;
     TABLES fy;* PLOTS = freqplot(type=dotplot scale=percent) out=out_ds;
     TITLE  'Frequency fy';
RUN; 
TITLE; 

PROC FREQ 
     DATA = qry_longitudinal;
     TABLES pcmp_loc_type_cd ;
RUN; 

PROC PRINT 
     DATA = analysis0a (OBS = 1000);
     where flag = 1;
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
