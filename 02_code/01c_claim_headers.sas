**********************************************************************************************
 PROGRAM NAME		: ISP utilization  
 PROGRAMMER			: K Wiggins
 DATE OF CREATION	: 08 08 2022
 PROJECT			: 
 PURPOSE			:
 INPUT FILE(S)		: 
 OUTPUT FILE(S)		:


***********************************************************************************************;
%include "S:/FHPC/DATA/HCPF_Data_files_SECURE/Kim/isp/isp_utilization/02_code/00_global.sas"; 
libname db odbc complete="driver=SQL Server; database=BIDM; server=SOMD-S-SQLDB.ucdenver.pvt" access=readonly schema="ro";/**/
%let varlen = \\data.ucdenver.pvt\dept\SOM\FHPC\DATA\HCPF_Data_files_SECURE\HCPF_SqlServer\queries\DBVarLengths;
libname varlen "&varlen";
%include "&varlen\MACRO_charLenMetadata.sas";
%getlen(library=varlen, data=AllVarLengths);
/*%macro claim_headers(set=,table=,);*/
* subsetting format trick for subjects;
data MysubjFmt;
   set out.mem_attr_1819 (keep = clnt_id);

   retain hlo " ";
   fmtname = "$MySubj" ;
   type    = "c" ;
   start   = clnt_id;
   label   = 'KEEP';
   output ;
   if eof then do ;
      start = " " ;
      label = " " ;
      hlo   = "o" ;
      output ;
   end ;
run;

proc format cntlin = MysubjFmt;
run;


* claim headers ;
proc sql;
*table was = raw.clm_headers;
create table out.claim_headers_1819 as
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
		 BILL_PROV_TYP_CD length = &BILL_PROV_TYP_CD,

         BILL_PROV_TYP_DESC length = &BILL_PROV_TYP_DESC,

         datepart(FRST_SVC_DT) as FRST_SVC_DT,
         datepart(LST_SVC_DT) as LST_SVC_DT,
		 datepart(DRUG_DSPN_DT) as DRUG_DSPN_DT,

         clm_ctg_cd    length = &clm_ctg_cd,
         CLM_TYP_CD    length = &CLM_TYP_CD, 
         CTG_OF_SVC_CD length = &CTG_OF_SVC_CD, 
         CLNT_CNTY_CD length = &CLNT_CNTY_CD,
         CLNT_CNTY_DESC length = &CLNT_CNTY_DESC,
         pd_amt,
         tpl_pd_amt 
  from  db.CLM_DIM_V  
  where CURR_REC_IND = 'Y'
    and SRC_REC_DEL_IND = 'N'
    and CLM_STS_CD = 'P'
    and most_rcnt_clm_ind = 'Y'
    and enc_ind = 'N'
	and put(mcaid_id, $MySubj. ) = "KEEP"
    /*and CLM_TYP_CD not in ('A','B','C')*/
  order by mcaid_id;

quit;
/*%mend; */
