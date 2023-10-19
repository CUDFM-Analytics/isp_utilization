**********************************************************************************************
AUTHOR   : KTW
PROJECT  : ISP Utilization Analysis
PURPOSE  : configs 
VERSION  : 2023-06-06
FILE/S   : 1) ISP-CTLP_Model_specifications.docx
NOTES    : See ../../_rchive_utilization for LOGS and all archived docs, ds, code, etc 
GIT      : github organization DFM, `isp_utilization

LOG
2023-03-16 Moved all archived/outdated files to Kim/_rchive_utilization due to new spec file from MG
2023-05-30 Updated macro for quarter to incude qrtr 13, Jul-Sept 2022;
***********************************************************************************************;

* SOM DIR -------------------------------------------------------------------------------------; 
    %LET hcpf     = S:/FHPC/DATA/HCPF_Data_files_SECURE;

* PROJECT ROOT DIR ----------------------------------------------------------------------------; 
      %LET util = &hcpf/Kim/isp/isp_utilization;

    * DATA dir tree:
      |--data           [libname 'data': stores final analytic dataset and other data folders]                                                     
         |--_raw`       [libname 'raw' : raw, read-only files to be prepped then stored in /interim]
         |--_refs       files from others: Carter's bootstrap examples, etc. 
         |--interim     [libname 'int' : intermediate ds used to make final analytic ds or eda]
         |--out_attr    
         |--out_hurdle  
      ;

      %LET data = &util/data;   
        LIBNAME data "&data"; 
      %LET raw = &data/_raw;     
/*      LIBNAME raw "&raw";      */
      %LET int = &data/interim; 
        LIBNAME int "&int"; 
      %LET out = &data/out_hurdle; 
        LIBNAME out "&out"; 
      %LET store = &out/hurdle_stored_prods; *store product output from hurdle models; 
        LIBNAME store "&store";
/*    %LET eda = &data/results_util_eda_tests;*/
/*      LIBNAME eda "&eda";*/
/*%LET out_boot = &util/data_boot_processed;*/
/*LIBNAME boot "&out_boot";*/
    * export folder for excel files output; 
      %LET report = &util/reports; 

      %LET raw = &data/_raw;
        LIBNAME raw "&raw";

      %LET ana = &hcpf/HCPF_SqlServer/AnalyticSubset;
      LIBNAME ana "&ana"; 

* PROJECT-WIDE GLOBAL OPTIONS ----------------------------------------------------------; 
OPTIONS 
NOFMTERR MPRINT MLOGIC FMTSEARCH =(ana, datasets, data, util, work);

%macro nodupkey(ds, out);
PROC SORT DATA = &ds NODUPKEY OUT=&out; BY _ALL_ ; RUN; 
%mend;

%macro concat_id_time(ds=);
DATA &ds;
SET  &ds;
id_time_helper = CATX('_', mcaid_id, time); 
RUN; 
%mend; 

 %macro check_ids_n16(ds=);
            proc sql; 
            create table n_ids_&ds AS 
            select mcaid_id
                 , count(mcaid_id) as n_ids
            FROM &ds
            GROUP BY mcaid_ID
            having n_ids>16;
            quit; 
 %mend;

%macro sort4merge(ds1=,ds2=,by=);
PROC SORT DATA = &ds1; by &by;
PROC SORT DATA = &ds2; by &by; 
RUN; 
%mend;

%macro colstring(into=, memname=,nchar=,string=);
PROC SQL; 
SELECT name INTO :&into separated by ' ' FROM dictionary.columns 
WHERE memname=&memname AND substr(name, 1, &nchar)=&string;
QUIT; 
%mend; 

%macro create_qrtr(data=,set=,var=,qrtr=);
data &data;
set  &set; 
if &var in ('01JUL2019'd , '01AUG2019'd , '01SEP2019'd ) then &qrtr = 1;
if &var in ('01OCT2019'd , '01NOV2019'd , '01DEC2019'd ) then &qrtr = 2;
if &var in ('01JAN2020'd , '01FEB2020'd , '01MAR2020'd ) then &qrtr = 3;
if &var in ('01APR2020'd , '01MAY2020'd , '01JUN2020'd ) then &qrtr = 4;
if &var in ('01JUL2020'd , '01AUG2020'd , '01SEP2020'd ) then &qrtr = 5;
if &var in ('01OCT2020'd , '01NOV2020'd , '01DEC2020'd ) then &qrtr = 6;
if &var in ('01JAN2021'd , '01FEB2021'd , '01MAR2021'd ) then &qrtr = 7;
if &var in ('01APR2021'd , '01MAY2021'd , '01JUN2021'd ) then &qrtr = 8;
if &var in ('01JUL2021'd , '01AUG2021'd , '01SEP2021'd ) then &qrtr = 9;
if &var in ('01OCT2021'd , '01NOV2021'd , '01DEC2021'd ) then &qrtr = 10;
if &var in ('01JAN2022'd , '01FEB2022'd , '01MAR2022'd ) then &qrtr = 11;
if &var in ('01APR2022'd , '01MAY2022'd , '01JUN2022'd ) then &qrtr = 12;
if &var in ('01JUL2022'd , '01AUG2022'd , '01SEP2022'd ) then &qrtr = 13;
if &var in ('01OCT2022'd , '01NOV2022'd , '01DEC2022'd ) then &qrtr = 14;
if &var in ('01JAN2023'd , '01FEB2023'd , '01MAR2023'd ) then &qrtr = 15;
if &var in ('01APR2023'd , '01MAY2023'd , '01JUN2023'd ) then &qrtr = 16;
run;
%mend create_qrtr;

ods path(prepend) work.templat(update);

proc format;
 picture pctfmt (round) other="009.99%";
run;

proc template; 
 edit Base.Freq.OneWayList;
 edit h1;
 text VARLABEL;
 end; 
 edit frequency; 
 header="Count"; 
 format=comma12.;
 end; 
 edit cumfrequency;
 header="Cumulative Count";
 format=comma12.; 
 end;
 edit percent;
 header="Pct";
 format=pctfmt.;
 end; 
 edit cumpercent;
 format=pctfmt.; 
 end; 
 end;
run; 
