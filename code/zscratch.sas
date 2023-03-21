PROC CONTENTS 
     DATA = data.a5
VARNUM;
RUN;

  proc print data = int.qrylong_1921 ; 
            where mcaid_id in ("P861019", "L155867"); 
            run ; 

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
     DATA = a1 (OBS = 1000);
     where intervention = 1 and dt_prac_isp = .;
RUN; 

PROC PRINT 
     DATA = a1 ;
     where pcmp_loc_id = 103320;
RUN; 

PROC FREQ 
     DATA = a1;
     TABLES time*int_imp;* PLOTS = freqplot(type=dotplot scale=percent) out=out_ds;
     TITLE  'pcmp 103320';
     WHERE pcmp_loc_id = 103320;
RUN; 
TITLE; 

******************************************************
Initial Contents for all work lib
******************************************************;
PROC SQL; 
     CREATE TABLE contents_int AS 
     SELECT *
     FROM sashelp.vcolumn
     WHERE LIBNAME = upcase("INT");
QUIT; 

PROC PRINT DATA = columns_DATA NOOBS;
     VAR memname name type length format informat label;
RUN;

ods excel file = "S:/FHPC/DATA/HCPF_Data_files_SECURE/Kim/isp/isp_utilization/tmp/contents_DATA.csv"
    options (frozen_headers = "yes"
             autofilter = "all"
             flow = "tables" );   *so it doesn't include carriage breaks; 
PROC PRINT DATA = a2 (obs = 10 ) ; where pcmp_loc_id = 107087 and dt_prac_isp ne . ; RUN ; 
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


proc sql ; 
select count ( distinct pcmp_loc_id ) from a2
where intervention = 1; 
quit ; 
proc print data = a2 (obs = 10 ) ; where dt_prac_isp ne . ; RUn ; 

PROC FREQ DATA = a2 ; tables pcmp_loc_id ; where intervention ne . ; RUN ; 
