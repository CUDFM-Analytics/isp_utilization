**********************************************************************************************
 PROGRAM NAME		: 01c_claim_headers
 PROGRAMMER			: K Wiggins
 DATE OF CREATION	: Nov 2022
 PROJECT			: ISP Utilization
 PURPOSE			: create / get claim headers  
 INPUT FILE(S)		: 
 OUTPUT FILE(S)		:
 REFERENCE FILE/S   : sas/sas_refs/from carter medicaid templates/TEMPLATE_DemogEligClaims.sas

***********************************************************************************************;
%include "S:/FHPC/DATA/HCPF_Data_files_SECURE/Kim/isp/isp_utilization/02_code/00_global.sas";  

proc print data = out.clm_1819;
var drug_dspn_dt;
run;
* claim headers 1819;
proc sql;
create table out.clm_header_1819 as
  select ICN_NBR  length = &ICN_NBR , 
         mcaid_id length = &mcaid_id, 
		 ATTD_PROV_LOC_ID length = &ATTD_PROV_LOC_ID,
		 ATTD_PROV_LOC_NM length = &ATTD_PROV_LOC_NM,
		 REND_PROV_LOC_ID   length = &REND_PROV_LOC_ID,
		 REND_PROV_LOC_NM   length = &REND_PROV_LOC_NM,
		 REND_PROV_TYP_CD   length = &REND_PROV_TYP_CD,
		 REND_PROV_TYP_DESC length = &REND_PROV_TYP_DESC,
		 BILL_PROV_LOC_ID   length = &BILL_PROV_LOC_ID,
		 BILL_PROV_LOC_NM   length = &BILL_PROV_LOC_NM,
		 BILL_PROV_TYP_CD   length = &BILL_PROV_TYP_CD,
         BILL_PROV_TYP_DESC length = &BILL_PROV_TYP_DESC,
         datepart(FRST_SVC_DT)  as FRST_SVC_DT format=yymmddd10.,
         datepart(LST_SVC_DT)   as LST_SVC_DT format=yymmddd10.,
		 datepart(DRUG_DSPN_DT) as DRUG_DSPN_DT format=yymmddd10.,
         clm_ctg_cd     length = &clm_ctg_cd,
         CLM_TYP_CD     length = &CLM_TYP_CD, 
         CTG_OF_SVC_CD  length = &CTG_OF_SVC_CD, 
         CLNT_CNTY_CD   length = &CLNT_CNTY_CD,
         CLNT_CNTY_DESC length = &CLNT_CNTY_DESC,
         pd_amt,
         tpl_pd_amt 
  from  db.CLM_DIM_V 
  where CURR_REC_IND = 'Y'
    and SRC_REC_DEL_IND = 'N'
    and CLM_STS_CD = 'P'
    and most_rcnt_clm_ind = 'Y'
    and enc_ind = 'N'
	and mcaid_id in (SELECT clnt_id
				  FROM out.clntid_1819)
  order by mcaid_id;
quit;

* Get claims for 2015-2019 SFY for 1819 members; 
data out.clm_header_1518_grp1819;
set  out.clm_header_1819;
if '01Jul2015'd <= FRST_SVC_DT <= '30Jun2018'd;
run;   *68458900;

data out.clm_header_1819_SFY;
set  out.clm_header_1819;
if '01Jul2018'd <= FRST_SVC_DT <= '30Jun2019'd;
run;   *22406479;
