PROC CONTENTS 
     DATA =  int.util_1921
VARNUM;
RUN;


PROC FREQ 
     DATA = int.adj;   
/*     TABLES month * fy;* PLOTS = freqplot(type=dotplot scale=percent) out=out_ds;*/
RUN; 


PROC FREQ 
     DATA = qrylong_1621;
     TABLES month ;
     WHERE month le '01JUL2018'd ; 
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

PROC sql ; 
create table adj_check_ids as 
select mcaid_id
     , count(mcaid_id) as n_id
FROM util1621_adj
group by mcaid_id ; 
QUIT ; 


PROC FREQ 
     DATA = adj_check_ids ;
     TABLES n_id;* PLOTS = freqplot(type=dotplot scale=percent) out=out_ds;
     TITLE  'Frequency...';
RUN; 
TITLE; 


proc contents data = int_contents varnum ; run ; 
proc print data=columns noobs;
var memname name type length format informat label;
run; 
