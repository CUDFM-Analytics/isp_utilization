PROC CONTENTS 
     DATA = qry_bho_monthlyutil_working VARNUM;
RUN;

PROC PRINT 
     DATA = data.rae (OBS = 1000);
RUN; 

PROC FREQ 
     DATA = data.bho_fy15_22;
     TABLES month;* PLOTS = freqplot(type=dotplot scale=percent) out=out_ds;
     TITLE  'Frequency BHO months';
RUN; 
TITLE; 

******************************************************
Initial Contents for all work lib
******************************************************;
PROC SQL; 
     CREATE TABLE columns_work AS 
     SELECT *
     FROM sashelp.vcolumn
     WHERE LIBNAME = upcase("WORK");
QUIT; 

PROC PRINT DATA = columns_work NOOBS;
     VAR memname name type length format informat label;
RUN;

ods excel file = "S:/FHPC/DATA/HCPF_Data_files_SECURE/Kim/isp/isp_utilization/tmp/contents_init_datasets.csv"
    options (frozen_headers = "yes"
             autofilter = "all");
PROC PRINT DATA = columns_work;
RUN; 
ods excel close; 
run;
