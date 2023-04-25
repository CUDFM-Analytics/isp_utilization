*# PURPOSE compare to jake;

%LET upl = S:\FHPC\DATA\HCPF_Data_files_SECURE\UPL-ISP;
LIBNAME upl "&upl";

DATA int.jake_ibh_adj; 
set  upl.ibh_adjpaid_16_17_18; 
RUN; 

PROC SORT DATA = data.analysis_dataset NODUPKEY OUT=unique_adj_isp; by mcaid_id adj: ; run; 

proc sql ; 
CREATE TABLE jake_compare_ibh AS 
SELECT a.* 
     , b.adj_pd_total_16cat+1 as kw_adj16
     , b.adj_pd_total_17cat+1 as kw_adj17
     , b.adj_pd_total_18cat+1 as kw_adj18
FROM int.jake_ibh_adj as a
LEFT JOIN unique_adj_isp as b
on a.clnt_id = b.mcaid_id;
QUIT; 

DATA jake_compare2; 
SET  jake_compare_ibh;
IF adj_pd_total_16cat = kw_adj16 then match16 = 1; 
IF adj_pd_total_17cat = kw_adj17 then match17 = 1; 
IF adj_pd_total_18cat = kw_adj18 then match18 = 1; 
RUN; 

PROC SORT DATA = jake_compare2 NODUPKEY OUT=int.jake_compare; BY _ALL_ ; RUN; 

PROC PRINT DATA =int.jake_compare (obs=1000); 
WHERE match16 = . | match17 = . | match18=.; 
RUN; 

PROC FREQ DATA = int.jake_compare; tables match16 ; run; 


PROC PRINT DATA = ana.qry_longitudinal ;
WHERE mcaid_id = "A003219" 
AND   month ge "01JUN2016"d 
AND   month lt "01JUL2017"d; 
RUN; 
