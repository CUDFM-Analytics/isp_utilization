ods excel file = "&report./contents_20230328.csv"
    options (frozen_headers = "yes"
             flow = "tables"
            sheet_interval = "none");   *so it doesn't include carriage breaks; 

proc contents data = data.analysis_dataset ; 
RUN ; 


* Univar  ; 
ods excel file = "&report./isp_cost_univar_20230328.csv"
    options (frozen_headers = "yes"
             flow = "tables"
            sheet_interval = "none");   *so it doesn't include carriage breaks; 

ods excel options ( sheet_interval = "now" sheet_name = "univar cost") ; 

proc univariate data = data.analysis_dataset ; 
VAR = cost: ; 
RUN; 

ods excel file = "&report./isp_cost_univar_20230328.csv"
    options (frozen_headers = "yes"
             flow = "tables");   *so it doesn't include carriage breaks; 

proc univariate data = data.analysis_dataset ; 
VAR = util: ; 
RUN; 

ods excel options ( sheet_interval = "now" sheet_name = "bh_cat_freqs") ; 

PROC SORT DATA = int.bh_1618_long ; BY FY ; RUN ; 

PROC FREQ DATA = int.bh_1618_long order = freq; 
tables bh_util*bh*fy; 
RUN ; 

ods excel options ( sheet_interval = "now" sheet_name = "time_checks") ; 
 
PROC FREQ DATA = data.ANALYIS_DATASET ; 
TABLES time*int_imp int*int_imp; 
RUN ;

ods excel options ( sheet_interval = "now" sheet_name = "dv_rx") ; 

PROC UNIVARIATE DATA = data.ANALYIS_DATASET ; 
VAR cost_rx_tc  ; 
RUN ; 

ods excel options ( sheet_interval = "now" sheet_name = "dv_ffs") ; 

PROC UNIVARIATE DATA = data.ANALYIS_DATASET ; 
VAR cost_ffs_tc ; 
RUN ; 

ods excel options ( sheet_interval = "now" sheet_name = "dv_pc") ; 

PROC UNIVARIATE DATA = data.ANALYIS_DATASET ; 
VAR cost_pc ; 
RUN ; 

ods excel close ; 

