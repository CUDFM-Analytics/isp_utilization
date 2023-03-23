PROC CONTENTS DATA = int.adj_pd_total_YYcat_final VARNUM;
PROC CONTENTS DATA = int.bh_1618                  VARNUM;
PROC CONTENTS DATA = data.a3                     VARNUM;
RUN;
PROC CONTENTS 
     DATA = int.memlist_final
VARNUM;
RUN;

PROC MEANS DATA = int.qrylong_1621  ; 
VAR pd_tot_q_adj ;
BY FY ; 
RUN ; 

PROC UNIVARIATE DATA = data.a7 ; 
VAR cost_rx_tc cost_ffs_tc ; 
RUN ;

PROC PRINT DATA = data.a1 ; 
            where mcaid_id in ("P861019", "L155867"); 
            run ; 

  proc print data = int.qrylong_1621 ; 
            where mcaid_id in ("P861019", "L155867"); 
            run ;

              proc print data = int.qrylong_1921_time ; 
            where mcaid_id in ("G010516", "G002318"); 
            run ;

            proc sort data = int.qrylong_1621 ; by mcaid_id month ; RUN ; 
                          proc print data = int.qrylong_1621_time ; 
            where mcaid_id in ("G010516"); 
            run ;

             proc print data = int.memlist ; 
            where mcaid_id in ("G010516"); 
            run ;

             proc print data = data.a3 (obs=100); 
            run ;

              proc print data = ana.qry_longitudinal (obs = 1000); 
            where mcaid_id in ("A001791", "A003524","A000405","A002526","A003219")
            AND month ge '01JUL2016'd and month le '30Jun2017'd; 
            run ; 

PROC FREQ DATA = data.a7 ; 
TABLES FY*cost_ffs_tc ; 
RUN ; 

PROC FREQ 
     DATA = int.memlist_final;
TABLES FY time age sex race rae_person_new budget_grp_new  ;  
/*     TABLES month * fy;* PLOTS = freqplot(type=dotplot scale=percent) out=out_ds;*/
RUN; 

Data month_time ; 
SET  int.qrylong_1921 (KEEP = month time ) ; 
RUN ;

PROC SORT DATA = month_time NODUPKEY; BY _ALL_ ; RUN ; 

PROC FREQ 
     DATA = int.qrylong_1921;
     TABLES month*time ;
RUN; 

PROC PRINT 
     DATA = data.a5 (OBS = 100);
    VAR mu: n_: pd_: ;
RUN; 

PROC PRINT 
     DATA =data.a8 (obs=100);
     WHERE mcaid_id = "G010516" ;
/*     VAR mcaid_id  time;*/
RUN; 

PROC PRINT 
     DATA = ana.qry_longitudinal (obs=100);
     WHERE mcaid_id = "G010516" ;
/*     VAR mcaid_id month time;*/
RUN; 

PROC FREQ 
     DATA = a1;
     TABLES time*int_imp;* PLOTS = freqplot(type=dotplot scale=percent) out=out_ds;
     TITLE  'pcmp 103320';
     WHERE pcmp_loc_id = 103320;
RUN; 
TITLE; 

* EXAMPLE of int_imp = 0 and intervention = 1 ; 
proc print data = data.a6 (obs = 1000) ; 
var mcaid_id pcmp:  time int:  ; 
where mcaid_id = "A005156";   *was dt_prac_isp ne . ; 
run ; * Looks good!! 

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
