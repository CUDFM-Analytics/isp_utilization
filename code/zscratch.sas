PROC FREQ DATA = raw.pcmp_type2;
tables pcmp_loc_type_cd fqhc; 
run; 

PROC PRINT DATA = int.qrylong1622 (obs=25);
WHERE mcaid_id IN ("A001791");
RUN; 

data short_a8;
set  data.a8 (obs=2000); 
RUN; 
PROC SORT DATA int.isp_un_pcmp_dtstart ; by time_start_isp; run; 

proc freq data = isp_un_pcmp_dtstart; tables month; run; 

PROC CONTENTS DATA =  raw.util_all_memlist VARNUM; RUN; 
PROC CONTENTS DATA = int.memlist_attr_qrtr_1921;
PROC CONTENTS DATA = int.pcmp_types; 
RUN;

PROC FREQ DATA = raw.memlist0; tables sex; run; 

TITLE "qrylong0"; proc print data = raw.qrylong0; where mcaid_id in ("G732953"); RUN; 
TITLE "qrylong1"; proc print data = raw.qrylong1; where mcaid_id in ("G732953"); RUN; 
TITLE "qrylong2"; proc print data = raw.qrylong2; where mcaid_id in ("G732953"); RUN; 
TITLE "qrylong4"; proc print data = raw.qrylong4; where mcaid_id in ("G732953"); RUN; 

TITLE "memlist0"; proc print data = raw.memlist0; where mcaid_id in ("G732953"); RUN; 
TITLE "memlist1"; proc print data = raw.memlist1; where mcaid_id in ("G732953"); RUN; 
TITLE "memlist2"; proc print data = raw.memlist2; where mcaid_id in ("G732953"); RUN; 
TITLE "memlist_attr"; proc print data = int.memlist_attr_qrtr_1921; where mcaid_id in ("G732953"); RUN; 

proc contents data = raw.fy1921_3 varnum; run; 
proc print data = int.FY1618 (obs=25); 
VAR mcaid_id adj:; 
RUN; 


proc print data = int.memlist_attr_qrtr_1921; where mcaid_id in ("G732953"); RUN; 
proc print data = raw.qrylong2; where mcaid_id in ("G732953"); RUN; 

ods listing close;
ods output summary=s;
proc means data=int.A5 stackods min mean nmiss n median max;
var mu:;
run;
ods output close;
ods listing;
proc print;
run;


ods pdf file = "S:\FHPC\DATA\HCPF_Data_files_SECURE\Kim\isp\isp_utilization\code\interim_reports\isp_start_dates.pdf" startpage=no;
TITLE; 
proc print data = int.isp_un_pcmp_dtstart ; 
TITLE2 "March 2020 start dates only"; 
VAR dt_prac_isp pcmp_loc_id dt_qrtr time;
where dt_prac_isp = '01MAR2020'd; 
RUN ; 

proc freq data = int.isp_un_pcmp_dtstart;
TITLE2 "Frequency start date by quarter (linearized)" ;
tables dt_prac_isp*time; 
RUN; 

ods pdf close; 


ods pdf file = "S:\FHPC\DATA\HCPF_Data_files_SECURE\Kim\isp\isp_utilization\code\interim_reports\isp_start_dates.pdf" startpage=no;
TITLE; 
proc print data = int.isp_un_pcmp_dtstart ; 
TITLE2 "March 2020 start dates only"; 
VAR dt_prac_isp pcmp_loc_id dt_qrtr time;
where dt_prac_isp = '01MAR2020'd; 
RUN ; 

proc freq data = int.isp_un_pcmp_dtstart;
TITLE2 "Frequency start date by quarter (linearized)" ;
tables dt_prac_isp*time; 
RUN; 

ods pdf close; 


proc sql; 
create table want as 
select mcaid_id
     , count(distinct int) as n_int
FROM short_a8
group by mcaid_id
having n_int > 1
order by mcaid_id; 
quit; 

proc sort data = want ; by mcaid_id ; run; 

PROC CONTENTS DATA = int.adj_pd_total_YYcat_final VARNUM;
PROC CONTENTS DATA = int.bh_1618                  VARNUM;
PROC CONTENTS DATA = data.a3                     VARNUM;
RUN;
PROC CONTENTS 
     DATA = int.memlist_final
VARNUM;
RUN;

PROC PRINT DATA = elig_and_util (obs=100); 
RUN; 

PROC MEANS DATA = int.qrylong_1621  ; 
VAR pd_tot_q_adj ;
BY FY ; 
RUN ; 

PROC UNIVARIATE DATA = data.a7 ; 
VAR cost_rx_tc cost_ffs_tc ; 
RUN ;

proc print data = &dat (obs=100); 
VAR mcaid_id adj: ; 
            where adj_pd_total_16cat = -1 ;  
            RUN ; 
PROC PRINT DATA = int.elig1618_memlist2 ; 
            where mcaid_id in ("D460887"); 
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
