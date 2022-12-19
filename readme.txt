TEMPLATE PROCESS from Carter: 

Template_DemogEligClaims.sas file: 

01: Get final subject ID's (rows 12-23)
02: Create raw.longitudinal: merge medicaiddemog_bidm, medicaidlong_bidm, finalSubjects and ageEndMon  (rows 40+)
03: Create raw.demographics (rows48+) from medicaiddemog_bidm inner join finalSubjects 
04: Subset trick for clientids to: 
05: Make 'raw.clm_headers' from 'db.clm_dim_v'
06: Use subset trick to get icns from raw.clm_headers (keep=ICN_NBR) to: 
07: Create 'raw.diagTable' from 'db.CLM_DIAG_FACT_V' (rows)
08:  Create 'raw.clm_lines' from 'db.clm_lne_fact_V' (rows 168-219) with where statements

Template_claimUtilization.sas  

(Assumes eligibility and claims have been extracted)
clmType 1 = 'Pharmacy' 2 = 'Hospitalizations' 3 = 'ER' 4 = 'Primary Care' 100='Other'
Dental is excluded, records within Hospitalizations are rolled up

09: Value primProc : Format: 'codes that assist in defining primary care records (HCPF defn); (rows 27-61)
10: Create table provIdFmt for FQHC prov ID's for primary care from db.prov_loc_dim_v  (prov_typ_cd 32, 45, 61)
11: Query claim line file from raw.clm_lines, created in step 08: flag/keep ER visits, primCare visits only, fields ICN_NBR, ER, PrimCare
12: Create clm_lne_class: file with one row per original ICN_NBR, flagged for ER, PC
13: Create hosp from raw.clm_headers (steps 05,06): Roll up records into hospitalizations
14: Create hospDates from hosp (step 13)
15: Add recnum to 14
16: Create hospPlus from inner join hospDates (step 14) and hosp (step 13) and between a.start, a.stop
17: Create hospFinal from hospPlus (get first)
ROLL UP non-hosp records within hospitalizations --> 
18: Create nonhosp from raw.clm_headers
19: Create inhosp from nonhoso and hospFinal 
20: Create NotInHosp from nonHosp except inHosp 
21: Create hospAgg from hospFinal left join inhosp 
22: Create clm_dim_hospAgg from sets hospAgg, NotInHosp  
23: Remove duplicates from 22
24: format: category names for clmTypes
25: Create outFile from clm_dim_hospAgg left join clm_lne_class on ICN_NBR, exclude dental  

----------------------------------------------------------------------------------------------------------

Folder Contents

August 17
- added 'pcmp_not_found.xlsx' with copied data from tab in ISP_outPMCP_20220606 where there wasn't a pcmp match and it wasn't active; 
	- emailed to support@practiceinnovation email 
	- emailed Sabrina and asked her if she gets those too... 
	