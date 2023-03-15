**********************************************************************************************
PROJECT    : ISP Utilization Analysis
PROGRAMMER : KTW
UPDATED ON : 03-07-2023 (new config file from MG) 
PURPOSE    : Gather, Process datasets needed to create Final Analysis Datasets  
CHANGES    : tmp is interim files
           : new specs file from Mark / can reduce many files

*---- global paths, settings  ----------------------------------------------------------------;
%INCLUDE "S:/FHPC/DATA/HCPF_DATA_files_SECURE/Kim/isp/isp_utilization/code/util_00_config.sas"; 
***********************************************************************************************;

* ---- SECTION01 ------------------------------------------------------------------------------
Create isp id dataset
 - Need date practice started ISP for the time varying cov
 - Covariate ISP participate pcmp at any time

Inputs      redcap.csv, datasets/isp_master_ids.sas7bdat
Outputs     data/isp_key;

%LET redcap = S:/FHPC/DATA/HCPF_Data_files_SECURE/Kim/isp/isp_utilization/data/isp_redcap.csv;
* select columns and convert id_split to numeric (others??); 
proc import datafile = "&redcap"
    out  = redcap0
    dbms = csv
    replace;
run;

PROC IMPORT 
     DATAFILE = &redcap
     OUT      = redcap0 
     DBMS     = csv
     REPLACE;
RUN; 

PROC FREQ 
     DATA = redcap0;
     TABLES dt_prac_start_isp;* PLOTS = freqplot(type=dotplot scale=percent) out=out_ds;
     TITLE  'Frequency: Date practices started ISP';
RUN; * all started on 01's ; 

DATA   int.redcap; 
SET    redcap0 ( KEEP = id_npi_redcap 
                        id_npi_pcmp
                        id_pcmp
                        id_split 
                        name_practice 
                        dt_prac_start_isp 
                        wave 
                        pr_county
                        fct_county_class   /* county classification of frontier, urban, rural. */
               ); 
* make pcmp numeric ;
num_id_pcmp = input(id_pcmp, 8.);

* reformat date variable to match on qry_longitudinal;
dt_prac_isp = put(dt_prac_start_isp, date9.);
label dt_prac_isp = "Formatted Date Start ISP";
RUN;  * 122, 10 on 02/14;

DATA isp_key0 ( KEEP = id_pcmp splitid ) ;
SET  datasets.isp_masterids;
id_npi  = input(practiceNPI, best12.);
id_pcmp = input(pcmp_loc_id, best12.);
RUN; 

PROC SORT DATA = isp_key0    ; BY id_split id_pcmp ; 
PROC SORT DATA = int.redcap ; BY id_split id_pcmp ; RUN; 

DATA redcap;
SET  int.redcap ( KEEP = id_split name_practice dt_prac_isp pr_county fct_county_class ) ;  
RUN; 

PROC SQL;
CREATE TABLE int.isp_key AS 
SELECT coalesce ( a.id_split , b.splitID ) as id_split
     , a.name_practice
     , a.pr_county
     , a.fct_county_class
     , a.dt_prac_isp
     , b.id_pcmp
FROM redcap as A
FULL JOIN isp_key0 as B
ON  a.id_split = b.splitID;
QUIT; * 153 ; 

PROC SORT DATA = int.isp_key NODUPKEY; BY _ALL_ ; RUN; 
* 30 duplicates, 123 remain; 

ods trace on; 
PROC FREQ 
     DATA = int.isp_key NLEVELS ;
     TABLES _all_ ;* PLOTS = freqplot(type=dotplot scale=percent) out=out_ds;
     TITLE  'Frequency isp_key';
RUN; 
TITLE; 
ods trace off;

data int.isp_key; 
set  int.isp_key; 
pcmp_loc_id = put(id_pcmp, best.-L); 
run ;

* ==== SECTION02 RAE ==============================================================================
Get RAE_ID and county info
Inputs      Kim/county_co_data.csv
Outputs     data/isp_key
Notes       Got from Jake and did all in R, just got the _c var here 
;

DATA int.rae; 
SET  int.rae; 
HCPF_County_Code_C = put(HCPF_County_Code,z2.); 
RUN; 
