**********************************************************************************************
 PROGRAM NAME   : ISP Utilization
 PROGRAMMER     : K Wiggins
 DATE CREATED   : 09/13/2022
 PROJECT        : ISP Utilization, question 1
 PURPOSE        : Per ISP_Utilization_Analytic_Plan_20221118.docx #1: 
                     Attributed member trends, monthly 7/2019-6/2022: above in the title it specifies (all for ISP and non-ISP PMCPs)
 INPUT FILE/S   : datasets.isp_masterids.sas7bdat
                : ana.qry_longitudinal
 OUTPUT FILE/S  : 
;
* PROJECT PATHS, MAPPING; 
%LET ROOT = S:/FHPC/DATA/HCPF_Data_files_SECURE/Kim/isp/isp_utilization;
%INCLUDE "&ROOT./code/00_global.sas";

*====== get ISP list  ========================================         

* Regular attribution / no subsetting membership, budgetgroup, etc
* previously was using Copy of full ISP Practice Report 20220828.xlsx - update, make sure this is right... #DO#;
DATA isp ;
SET  datasets.isp_masterids ( KEEP = pcmp_loc_id splitid ) ;
RUN; 

PROC SQL;
SELECT *
     , count ( distinct pcmp_loc_id ) as n_pcmp
FROM isp;
QUIT; * 117; 

* === QUESTION 1: Attributed Member Trends, monthly 7/2019-6/2022 =============================================== ;        
DATA  qry_long_y19_22_0; 
SET   ana.qry_longitudinal ( KEEP = MCAID_ID 
                                    ENR_CNTY 
                                    PCMP_LOC_ID 
                                    PCMP_LOC_TYPE_CD 
                                    MONTH
                            ); 
LENGTH mcaid_id $11; 

  * convert pcmp to numeric > create new var, drop old one, rename new one; 
  pcmp_loc_id2 = input(pcmp_loc_id, 8.);
  DROP pcmp_loc_id;
  RENAME pcmp_loc_id2 = pcmp_loc_id;

WHERE month ge '01Jul2019'd 
AND   month le '30Jun2022'd 
AND   pcmp_loc_ID ne '' ;
RUN; *[42737078, 3];

* Sort both before getting flag; 
PROC SORT DATA = qry_long_y19_22_0 ; BY pcmp_loc_id ; 
PROC SORT DATA = isp               ; BY pcmp_loc_id ; RUN;  

* Create flag for ISP vs non-ISP in medlong2;
PROC SQL;
CREATE TABLE data.qrylong_y19_22 as 
SELECT   *
       , pcmp_loc_id IN ( SELECT pcmp_loc_id from isp ) as flag
FROM     qry_long_y19_22_0 
WHERE    pcmp_loc_id ne .
ORDER BY pcmp_loc_id;
QUIT; 

        * checking pcmp's ; 
        PROC SQL;
        CREATE TABLE isp_pcmp_count AS
        SELECT pcmp_loc_id
             , count ( pcmp_loc_id ) as n_pcmp
        FROM data.qrylong_y19_22
        WHERE flag = 1
        GROUP BY pcmp_loc_id;
        QUIT; 
        
        * pcmp loc id's we'd identified as ISP but not matched in qry_longitudinal - EXPORT / share with Mark; 
        PROC SQL; 
        SELECT * 
        FROM isp 
        WHERE pcmp_loc_id NOT IN ( SELECT pcmp_loc_id FROM isp_pcmp_count ) 
        ORDER BY splitid;
        QUIT; 
        
        PROC SORT DATA  = isp ; by splitid ; RUN; 
        PROC PRINT DATA = isp ; 
        RUN; 
        * check against Copy of ISP_outPCMP_20220606.xlsx to see about what PIP data team said re: finding them; 

* Generate lists with unique pcmps =============================================== ;   
ODS OUTPUT CrossTabFreqs=freqs;
ODS TRACE ON;
PROC FREQ DATA = data.qrylong_y19_22;
     TABLES pcmp_loc_id*flag;
run;
ODS OUTPUT CLOSE;

DATA linelist;
SET  freqs ( KEEP = pcmp_loc_id flag frequency ) ;
IF flag = . THEN DELETE ; 
IF frequency = 0 THEN DELETE;
WHERE pcmp_loc_id ne .;
RUN; * 1056;

DATA data.ll_FY1922_pcmp_isp    ( KEEP = pcmp_loc_id ) 
     data.ll_FY1922_pcmp_nonisp ( KEEP = pcmp_loc_id )        ;
SET  linelist   ( KEEP = pcmp_loc_id flag ) ;
IF   flag = 1 THEN OUTPUT data.ll_FY1922_pcmp_isp;
ELSE OUTPUT data.ll_FY1922_pcmp_nonisp;
RUN; *101, 955; 

        * Create char vars so it'll match those too ; 

* --- Total unique member ids for each pcmp, all flags ----------------------------------------------- ;        
PROC SQL;
CREATE TABLE n_members AS 
SELECT count ( distinct mcaid_id ) as n_members
FROM data.qrylong_y19_22;
QUIT; *1657892; 

PROC SQL;
CREATE TABLE n_members_isp AS 
SELECT count ( distinct mcaid_id ) as n_members
FROM data.qrylong_y19_22
WHERE pcmp_loc_id IN ( SELECT id_pcmp FROM data.isp_key ) ;
QUIT; *286609; 


PROC SQL;
CREATE TABLE n_pcmp AS 
SELECT count ( pcmp_loc_id ) as n_isp_pcmp
FROM   data.qrylong_y19_22
WHERE  pcmp_loc_id IN ( SELECT id_pcmp FROM data.isp_key ) 
GROUP BY pcmp_loc_id;
QUIT; *1056, 2; 

PROC PRINT DATA = n_members;
RUN ;

* ------ 01 table:  by pcmp_loc_id, all flags ---------------------------------------; 
PROC SQL;
CREATE TABLE attr_all_pcmp0 AS
SELECT flag
     , month
     , count ( DISTINCT mcaid_id ) AS n_members
FROM data.qrylong_y19_22 
GROUP BY flag, month;
QUIT; *72, 3;

PROC SORT DATA = attr_all_pcmp0; by month; run; 


PROC TRANSPOSE DATA = attr_all_pcmp0 
                OUT = tbl.attr_all_pcmp (drop=_name_);
BY  flag; 
ID  month; 
VAR n_members;
run; *;

* create plotting data; 
DATA attr_q;
SET  attr_all_pcmp0;
quarter = qtr(month);
year    = year(month);
RUN; 

PROC SORT DATA = attr_q ; BY flag year quarter month ; run; 

DATA plot_attr;
SET attr_q;
BY  flag  ; 
if  first.flag then label = n_members;
if  last.flag then label = n_members;
format label 32.;
run; 

* === QUESTION 2: Relative to March 2020 for 7/2019-6/2022 =============================================== ;  
* Get March count for each pcmp from the attr results table;
DATA attr_mar2020;
SET  attr_all_pcmp0;
WHERE month eq '01MAR2020'd;
RUN; 

PROC SQL; 
CREATE TABLE attr_mar2020a AS 
SELECT a.*
     , b.n_members AS n_mar2020
FROM attr_all_pcmp0  AS a
JOIN attr_mar2020    AS b
ON a.flag = b.flag; 
QUIT; 

proc format ; 
value isp_prac
0 = "non ISP"
1 = "ISP" ; 
run; 

DATA tbl.attr_rel_mar20;
SET  attr_mar2020a;
n_diff_mar2020 = n_members - n_mar2020;
pct_diff_mar2020 = round ( ( n_diff_mar2020 / n_members ), .01); 
pct_diff_mar2020 = pct_diff_mar2020*100;
format flag isp_prac.;
RUN; 


PROC TRANSPOSE DATA = tbl.attr_rel_mar20
                OUT = tbl.attr_rel_mar20_t (drop=_name_);
BY  flag; 
ID  month; 
VAR n_diff_mar2020 pct_diff_mar2020;
run; *;

* ---------------Export --------------------------;

ods excel file = "&report/attr_20230215.xlsx"
    options (   sheet_name = "attr_table" 
                sheet_interval = "none"
                frozen_headers = "yes"
                autofilter = "all");

proc print data = tbl.attr_all_pcmp;
run;

ods excel options ( sheet_interval = "now" sheet_name = "attr_plot") ;

TITLE "Attributed Members per PCMP, ISP / non-ISP: 07/2019-06/2022";
proc sgplot data = plot_attr;
yaxis label = " ";
styleattrs datacontrastcolors =(purple steel); 
series x = month y = n_members / group = flag datalabel = label ;
refline '_01MAR2020'd / 
        axis = x 
        lineattrs = ( thickness = 2 color=grey pattern=dash ) 
        label = ("March 2020")
        labelloc = inside
        label = "March 2020";
run; 
TITLE; 

proc print data = attr_all_pcmp0 NOBS; 
where month = '01JUN2022'd 
OR    month = '01JUL2019'd;
format flag isp_prac.;
run;

ods excel options ( sheet_interval = "now" sheet_name = "relative_change_t") ;

proc print data = tbl.attr_rel_mar20_t; run;  

ods excel options ( sheet_interval = "now" sheet_name = "relative_change_plot") ;

TITLE "Percent Change Over Time: Member Count Relative to March 2020, ISP, non-ISP";
proc sgplot data = tbl.attr_rel_mar20;
yaxis label = " ";
styleattrs datacontrastcolors =(purple steel); 
series x = month y=pct_diff_mar2020 / group = flag;
refline '_01MAR2020'd / 
        axis = x 
        lineattrs = ( thickness = 2 color=grey pattern=dash ) 
        label = ("March 2020")
        labelloc = inside
        label = "March 2020";
run; 
TITLE; 

proc print data = tbl.attr_rel_mar20; 
where month eq '01JUN2022'd;
run;

ods excel close; 
run;
