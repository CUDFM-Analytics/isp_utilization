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
* claim headers 1819 - I took out some to speed it up... add in if needed;
proc sql;
create table out.clm_header_all as
  select ICN_NBR  length = &ICN_NBR , 
         mcaid_id length = &mcaid_id, 
		 ATTD_PROV_LOC_ID length = &ATTD_PROV_LOC_ID,
/*		 ATTD_PROV_LOC_NM length = &ATTD_PROV_LOC_NM,*/
		 REND_PROV_LOC_ID   length = &REND_PROV_LOC_ID,
/*		 REND_PROV_LOC_NM   length = &REND_PROV_LOC_NM,*/
		 REND_PROV_TYP_CD   length = &REND_PROV_TYP_CD,
		 REND_PROV_TYP_DESC length = &REND_PROV_TYP_DESC,
		 BILL_PROV_LOC_ID   length = &BILL_PROV_LOC_ID,
/*		 BILL_PROV_LOC_NM   length = &BILL_PROV_LOC_NM,*/
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

* Get claims for 2015-2019 SFY for 1819 members - should be only one, since 1920y = 0 (1819=no) members won't have data before 1819; 
data out.clm_header_1518;
set  out.clm_header_1819;
if '01Jul2015'd <= FRST_SVC_DT <= '30Jun2018'd;
run;   *68,458,900;

data out.clm_header_1819;
set  out.clm_header_all;
if '01Jul2018'd <= FRST_SVC_DT <= '30Jun2019'd;
run;   *22,406,479;  

proc print data = out.clm_header_1819 (obs=100);
run;  

* Create ICN_NBR; 
PROC SQL; 
CREATE TABLE out.icn_nbr_1819 AS 
SELECT 		 DISTINCT ICN_NBR
FROM 		 out.clm_header_1819;
QUIT; 


* diagnoses ;
PROC SQL; 
CREATE 
	TABLE OUT.diagTable_1519 AS
SELECT 		 
	DISTINCT
         a.ICN_NBR length = &ICN_NBR,
         a.DIAG_PRSNT_ON_ADMSN_CD  length = &DIAG_PRSNT_ON_ADMSN_CD,
         a.DIAG_CD length = &DIAG_CD,
         a.DIAG_DESC length = &DIAG_DESC,
         a.CD_SET_CD length = &CD_SET_CD,
         a.CD_SET_VER_NBR length = &CD_SET_VER_NBR,
         a.DIAG_SEQ_CD length = &DIAG_SEQ_CD,
         a.DIAG_SEQ_DESC length = &DIAG_SEQ_DESC
  from db.CLM_DIAG_FACT_V as a  
  where a.CURR_REC_IND = 'Y'
    and a.SRC_REC_DEL_IND = 'N'
    and 
;
quit;

* claim lines ;
 
data out.clm_lines_1519;

  length mcaid_id $ &mcaid_id
         ICN_NBR $ &ICN_NBR
         RVN_CD $ &RVN_CD
         CLM_TYP_CD $ &CLM_TYP_CD 
         pos_cd $ &pos_cd
         DIAG_1_CD $ &DIAG_1_CD
         DIAG_2_CD $ &DIAG_2_CD
         DIAG_3_CD $ &DIAG_3_CD
         DIAG_4_CD $ &DIAG_4_CD
         proc_cd   $ &proc_cd
         PROC_MOD_1_CD $ &PROC_MOD_1_CD 
         PROC_MOD_2_CD  $ &PROC_MOD_2_CD
         PROC_MOD_3_CD  $ &PROC_MOD_3_CD
         PROC_MOD_4_CD $ &PROC_MOD_4_CD
         ATTD_PROV_LOC_ID $ &ATTD_PROV_LOC_ID
         BILL_PROV_MCAID_ID $ &BILL_PROV_MCAID_ID
         BILL_PROV_NPI_ID   $ &BILL_PROV_NPI_ID

         BILL_PROV_LOC_ID   $ &BILL_PROV_LOC_ID
         REND_PROV_LOC_ID   $ &REND_PROV_LOC_ID
         REND_PROV_MCAID_ID $ &REND_PROV_MCAID_ID
         REND_PROV_NPI_ID   $ &REND_PROV_NPI_ID

         BILL_PROV_TYP_CD   $ &BILL_PROV_TYP_CD 
         REND_PROV_TYP_CD   $ &REND_PROV_TYP_CD 

         FAC_PROV_LOC_ID    $ &FAC_PROV_LOC_ID
         SUPV_PROV_LOC_ID    $ &SUPV_PROV_LOC_ID
;

  set db.clm_lne_fact_v ( keep = mcaid_id ICN_NBR lne_nbr LNE_FRST_SVC_DT LNE_LST_SVC_DT RVN_CD CLM_TYP_CD proc_cd 
								 BILL_PROV_MCAID_ID  BILL_PROV_NPI_ID  BILL_PROV_LOC_ID REND_PROV_LOC_ID REND_PROV_MCAID_ID 
								 REND_PROV_NPI_ID  ATTD_PROV_LOC_ID BILL_PROV_TYP_CD REND_PROV_TYP_CD FAC_PROV_LOC_ID 
								 SUPV_PROV_LOC_ID CURR_REC_IND SRC_REC_DEL_IND pos_cd CLM_STS_CD lne_sts_cd enc_ind 
								 most_rcnt_clm_ind PROC_MOD_1_CD PROC_MOD_2_CD PROC_MOD_3_CD PROC_MOD_4_CD DIAG_1_CD 
								 DIAG_2_CD DIAG_3_CD DIAG_4_CD BILL_UNT_QTY
						 );
  where CURR_REC_IND = 'Y'
    and SRC_REC_DEL_IND = 'N'
    and CLM_STS_CD = 'P'
    and lne_sts_cd = 'P'
    and most_rcnt_clm_ind = 'Y'
    and enc_ind = 'N'
	and put(ICN_NBR, $MyIcns. ) = "KEEP"
;
             /* variables to ensure the claim is valid and paid: conditioned on in the where statement */
  drop   CURR_REC_IND 
         SRC_REC_DEL_IND 
         CLM_STS_CD 
         lne_sts_cd 
         enc_ind 
         most_rcnt_clm_ind
;

run;
