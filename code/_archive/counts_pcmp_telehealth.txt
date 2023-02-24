**********************************************************************************************
 PROGRAMMER       : K Wiggins
 DATE INIT        : 02/2023
 PROJECT          : ISP Util
 PURPOSE          : merges all day
 INPUT FILE(S)    : 
 OUTPUT FILE(S)   : 
 LAST RAN/STATUS  : 20230209
 SPECS            : ISP_Utilization_Analytic_Plan_20221118.docx, 
***********************************************************************************************;

* do telehealth first so you can get pcmp counts easily (without the other columns); 
PROC SQL; 
CREATE TABLE merge0 AS 
SELECT a.*
     , b.*
FROM data.memlist AS A
LEFT JOIN data.memlist_tele_monthly AS B
ON a.mcaid_id = b.mcaid_id;
QUIT; 

* get n_telehealth pcmps ; 
PROC SQL; 
CREATE TABLE feb.tbl_pcmp_tele AS 
SELECT ind_isp
     , month 
     , count (distinct pcmp_loc_id) as n_pcmp
FROM merge0 
WHERE n_tele ne . OR pd_tele ne .
GROUP BY month, ind_isp;
QUIT; 

DATA tbl_pcmp_tele2
SET  feb.tbl_pcmp_tele;
IF month = '01Jun2022'd then label = n_pcmp;
RUN; 
        * did it a second way so I could see - there are for sure a lot; 
        DATA checking;
        SET  merge0 ( KEEP = pcmp_loc_id month ind_isp ) ;
        RUN; 

        PROC SORT DATA = checking NODUPKEY ; BY _ALL_ ; RUN; 

        PROC SQL;
        CREATE TABLE checking0 AS 
        SELECT count ( distinct pcmp_loc_id ) as n_pcmp
             , month
             , ind_isp
        FROM checking
        GROUP BY month, ind_isp;
        QUIT; 

PROC SORT DATA = feb.tbl_pcmp_tele ; BY ind_isp month ; RUN; 

PROC TRANSPOSE DATA = feb.tbl_pcmp_tele 
                OUT = feb.tbl_pcmp_tele_t (drop=_name_);
BY  ind_isp; 
ID  month; 
VAR n_pcmp;
run; *;
* ---------------Export --------------------------;
ods excel file = "&feb/hcpf_n_pcmps_tele_20230214.xlsx"
    options (   sheet_name     = "n_pcmps_tele" 
                sheet_interval = "none"
                frozen_headers = "yes"
                autofilter     = "all");

proc print data = feb.tbl_pcmp_tele_t;
run;

ods excel options ( sheet_interval = "now" sheet_name = "plot") ;

TITLE "Frequency of PCMPs that provided any telehealth";
proc sgplot data = feb.tbl_pcmp_tele noautolegend;
yaxis label = " ";
styleattrs datacontrastcolors =(purple steel); 
series x = month y=n_pcmp / group = ind_isp ;
refline '_01MAR2020'd / 
        axis = x 
        lineattrs = ( thickness = 2 color=grey pattern=dash ) 
        label = ("March 2020")
        labelloc = inside
        label = "March 2020";
run; 
TITLE; 

ods excel close; 
run;
