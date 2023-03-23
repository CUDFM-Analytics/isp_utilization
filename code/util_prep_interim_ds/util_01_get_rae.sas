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
