*# PURPOSE compare to jake
VERSION last ran / checked on 06-06 with new dataset; 

/*%LET upl = S:\FHPC\DATA\HCPF_Data_files_SECURE\UPL-ISP;*/
/*LIBNAME upl "&upl";*/
%LET refs = &data/_refs;
LIBNAME refs "&refs";

/*DATA jake_ibh_adj; */
/*set  upl.ibh_adjpaid_16_17_18; */
/*RUN; */

proc sql ; 
CREATE TABLE jake_compare_ibh AS 
SELECT a.* 
     , b.adj_pd_total_16cat+1 as kw_adj16
     , b.adj_pd_total_17cat+1 as kw_adj17
     , b.adj_pd_total_18cat+1 as kw_adj18
FROM refs.jake_ibh_adj as a
INNER JOIN data.analysis as b
on a.clnt_id = b.mcaid_id;
QUIT; 

DATA jake_compare2 (rename=(adj_pd_total_16cat = jt_adj16
                            adj_pd_total_17cat = jt_adj17
                            adj_pd_total_18cat = jt_adj18
                           )); 
SET  jake_compare_ibh;
IF adj_pd_total_16cat = kw_adj16 then match16 = 1; 
IF adj_pd_total_17cat = kw_adj17 then match17 = 1; 
IF adj_pd_total_18cat = kw_adj18 then match18 = 1; 
IF match16 = 1 AND match17 = 1 and match18 = 1 then allmatch = 1;
RUN; 

PROC SORT DATA = jake_compare2 NODUPKEY OUT=int.jake_compare; BY _ALL_ ; RUN; 

PROC FREQ DATA = int.jake_compare;
TABLES jt_adj16 kw_adj16 jt_adj17 kw_adj17 jt_adj18 kw_adj18; 
RUN; 



