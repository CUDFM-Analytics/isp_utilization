
* output final data to folder;
libname out "X:\Jake\short_term_bh\cost data";
%let outFile = clm_count_pay_amt_J1;



* connection to the BIDM data repo ;
libname db odbc complete="driver=SQL Server; database=BIDM; server=SOMD-S-SQLDB.ucdenver.pvt" access=readonly schema="ro";/**/

*** variable lengths ***;
  * this will create a macro variable for each variable in the SQL server database containing the maximum required length to contain the data
    in the case that a variable exists in more than one table, the max length will be used ;
%let varlen = \\data.ucdenver.pvt\dept\SOM\FHPC\DATA\HCPF_Data_files_SECURE\HCPF_SqlServer\queries\DBVarLengths;
libname varlen "&varlen";
%include "&varlen\MACRO_charLenMetadata.sas";
%getlen(library=varlen, data=AllVarLengths);



* subsetting format trick for subjects;
data MysubjFmt;
   set finalSubjects (keep = clnt_id) end = eof;

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

create table clm_headers as
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

 



* subsetting using an index ;
%macro idx_decider();

length errormessage $ 200;
drop errormessage;

select(_iorc_);
  when(%sysrc(_sok)) do;
    output;
  end;
  when(%sysrc(_dsenom)) do;
    _error_ = 0;
  end;
  otherwise do;
    errormessage = iorcmsg();
    put "ERROR: unknown: " errormessage;
  end;
end;

%mend;

* index setup for ICNs ;
proc sort data = clm_headers(keep = ICN_NBR) out = IcnIndex(index = (ICN_NBR)) nodupkey; by ICN_NBR; run;



* claim lines ;
 
data clm_lines;

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

  set db.clm_lne_fact_v 
     (  keep = mcaid_id ICN_NBR  lne_nbr LNE_FRST_SVC_DT LNE_LST_SVC_DT RVN_CD CLM_TYP_CD proc_cd BILL_PROV_MCAID_ID  BILL_PROV_NPI_ID  BILL_PROV_LOC_ID REND_PROV_LOC_ID REND_PROV_MCAID_ID REND_PROV_NPI_ID  ATTD_PROV_LOC_ID BILL_PROV_TYP_CD REND_PROV_TYP_CD FAC_PROV_LOC_ID SUPV_PROV_LOC_ID CURR_REC_IND SRC_REC_DEL_IND pos_cd CLM_STS_CD lne_sts_cd enc_ind most_rcnt_clm_ind
                              PROC_MOD_1_CD PROC_MOD_2_CD PROC_MOD_3_CD PROC_MOD_4_CD DIAG_1_CD DIAG_2_CD DIAG_3_CD DIAG_4_CD BILL_UNT_QTY

   where=(CURR_REC_IND = 'Y'
    and SRC_REC_DEL_IND = 'N'
    and CLM_STS_CD = 'P'
    and lne_sts_cd = 'P'
    and most_rcnt_clm_ind = 'Y'
    and enc_ind = 'N'))
;

  set IcnIndex(keep = icn_nbr) key = icn_nbr / unique;

  %idx_decider();

/* variables to ensure the claim is valid and paid: conditioned on in the where statement */
  drop   CURR_REC_IND 
         SRC_REC_DEL_IND 
         CLM_STS_CD 
         lne_sts_cd 
         enc_ind 
         most_rcnt_clm_ind
;

run;






**claim utilization (primary care, total...);


proc format;

** codes that assist in defining primary care records (HCPF defn)**;
value $ primProc
'36415','36416','59400','59425','59426','59510','59610','59618','77052','77055',
 '77057','77080','82951','82952','87086','90378','90384','90385','90386','90460',
 '90461','90471','90472','90473','90474','90632','90633','90636','90645','90647',
 '90648','90649','90650','90654','90655','90656','90657','90658','90660','90661',
 '90669','90670','90672','90680','90681','90686','90688','90696','90698','90700',
 '90702','90703','90704','90705','90707','90708','90710','90713','90714',
 '90715','90716','90718','90721','90723','90732','90733','90734','90736','90740',
 '90743','90744','90746','90747','92551','92552','92553','92558','92585','92586',
 '92587','92588','96110','99173','99174','D0120','D0140','D0145','D0150','D0190',
 'D1110','D1120','D1206','D1208','G0101','G0102','G0124','G0143','G0144','G0145',
 'G0147','G0148','G0202','G0432','P3000','P3001','Q0091','Q0111','S0195','S3620',
 'T1023','69210','90651','90706','96127','98967','98968','98969','99441','99442',
 '99443','99444','99446','99447','99448','99449','99487','99489','99495','99496',
 '99490','G0181','80055','80061','81007','82270','82274','82465','82728','82947','82948','82950',
 '83020','83036','84030','84153','84478','85013','85014','85018','85660','86580',
 '86592','86593','86631','86632','86689','86701','86702','86703','86782','86803',
 '86804','86901','87081','87088','87110','87164','87166','87205','87270','87285',
 '87320','87340','87341','87350','87380','87390','87391','87490','87491','87520',
 '87521','87522','87590','87591','87592','87801','87810','87850','90847','90853',
 '90887','96372','97802','97803','97804','99050','99201','99202','99203','99204',
 '99205','99211','99212','99213','99214','99215','99304','99305','99306','99307',
 '99308','99309','99310','99315','99316','99318','99324','99325','99326','99327',
 '99328','99334','99335','99336','99337','99341','99342','99343','99344','99345',
 '99347','99348','99349','99350','99355','99363','99364','99367','99368','99381',
 '99382','99383','99384','99385','99386','99387','99391','99392','99393','99394',
 '99395','99396','99397','99401','99402','99403','99404','99406','99407','99408',
 '99409','99411','99412','99420','99429','G0442','G0443','G0444','G0445','G0446',
 'G0447','G9006','G9012','H0001','H0002','H0004','H0025','H0031','H0034','H0039',
 'H0049','H1010','H1011','T1017','96150','96151','96152','96153','96154','96155',
 '99398','99497','H0023','S0257','98966','99374','99375','99377','99378','99379',
 '99380','G0182' = 'YES'
 other = 'NO';

 run;

 ** FQHC prov ID's for primary care ;
proc sql;
create table provIdFmt as
  select distinct 
         '$ProvPrimID' as fmtname,
         PROV_LOC_ID as start,
         'YES' as label
  from db.prov_loc_dim_v 
  where PROV_TYP_CD in ('32','45','61') 
    and CURR_REC_IND = 'Y'  
    and SRC_REC_DEL_IND = 'N';
quit;
proc format cntlin = provIdFmt;
run;


* querying claim line file;
data clm_lne;

  set clm_lines;
  * where ; * may need to modify ;
 
  * flag ER visits ;
  ER = ((CLM_TYP_CD IN ('C','O') AND RVN_CD IN ('0450','0451','0452','0456','0459','0981')) OR 
       (CLM_TYP_CD IN ('B','M') AND     '99281'  <= proc_cd <= '99285') OR 
       (CLM_TYP_CD IN ('B','M') AND POS_CD = '23' AND (  '10021'  <= proc_cd <= '69979' OR PROC_CD = '69990'))
 );

  ** primary care definition, based on SQL code received in email from alexandra.hoffman on march 18, 2020 ; 
  primCare = CLM_TYP_CD in ('B','C','M','O') AND
               (
                put(ATTD_PROV_LOC_ID, $ProvPrimID.) = 'YES' OR
                BILL_PROV_TYP_CD in ('16','32','45','51','61') OR /* added ,'32','45','61' on 6/3/21 to pick up FQHC care */
                REND_PROV_TYP_CD in ('16','26','05','25','39','41','32','45','51')
               ) AND
               (
               ('69210'  <= proc_cd <=  '69250') or
               put(PROC_CD, $primProc.) = 'YES'
               );

   * keeping only rows that are ER or primary ;
  if ER or   PrimCare  ;
  * keeping only the following fields ;
  keep ICN_NBR ER   PrimCare ;

run;

* create a file with one row per original icn number, flagged for ER and primary care;
proc sql;
create table clm_lne_class   as
  select ICN_NBR, max(ER) as ER, max(PrimCare) as PrimCare 
  from clm_lne
  group by ICN_NBR;
quit;


*** Roll up records into hospitalizations ;
proc sql;

create table hosp as
  select *
  from clm_headers
  where CLM_TYP_CD in ('I') 
    and CTG_OF_SVC_CD in ('05')
  order by mcaid_id, FRST_SVC_DT, LST_SVC_DT;
quit;

data hospDates ;
  set hosp ;
  by mcaid_id FRST_SVC_DT LST_SVC_DT;

  retain start stop;

  if first.mcaid_id =1 then do;
    start = FRST_SVC_DT;
    stop = LST_SVC_DT;
  end;
  if first.mcaid_id and last.mcaid_id then output;

  if first.mcaid_id =0 then do;

    if start <= FRST_SVC_DT <= stop then stop = max(stop, LST_SVC_DT);
    else do;
      output;
      start = FRST_SVC_DT;
      stop = LST_SVC_DT;
    end;

    if last.mcaid_id = 1 then output;
  end;

  keep mcaid_id start stop;
run;

data hospDates;
  set hospDates;
  recnum = _n_;
run;

* roll up hospitalizations ;
proc sql;

create table hospPLus as
  select a.mcaid_id, 
         a.recnum, 
         a.start as FRST_SVC_DT,
         a.stop as LST_SVC_DT,
         b.clm_ctg_cd,
         b.CLM_TYP_CD  , 
         b.CTG_OF_SVC_CD ,
         b.ICN_NBR,
         sum(b.pd_amt) as pd_amt,
         sum(b.tpl_pd_amt) as tpl_pd_amt

  from hospDates as a inner join hosp as b on a.mcaid_id = b.mcaid_id and b.FRST_SVC_DT between a.start and a.stop
  group by a.mcaid_id, a.recnum
  order by a.mcaid_id, a.recnum
  ;

quit;

data hospFinal;
  set hospPlus;
  by mcaid_id recnum;
  if first.recnum;
  drop recnum;
run;

*** roll up non-hospital records within hospitalizations ;
proc sql;

create table nonhosp as
  select *
  from clm_headers
  where ^(CLM_TYP_CD in ('I') 
    and CTG_OF_SVC_CD in ('05'));

create table inhosp as
  select distinct a.*, b.ICN_NBR as hosp_ICN_NBR
  from nonhosp as a inner join hospFinal as b
    on a.mcaid_id = b.mcaid_id and a.FRST_SVC_DT between b.FRST_SVC_DT and b.lst_SVC_DT ;

create table NotInHosp as
  select *
  from nonHosp
  except 
  Select *
  from inHosp (drop = hosp_ICN_NBR);

create table hospAgg as
  select distinct 
         a.ICN_NBR   , 
         a.mcaid_id  , 
         a.FRST_SVC_DT,
         a.LST_SVC_DT,
         a.clm_ctg_cd ,
         a.CLM_TYP_CD  , 
         a.CTG_OF_SVC_CD ,
        /* a.pd_amt as a_pd,
         sum(b.pd_amt) as b_pd,*/
         sum(a.pd_amt, sum(b.pd_amt)) as pd_amt,
         sum(a.tpl_pd_amt, sum(b.tpl_pd_amt)) as tpl_pd_amt

  from hospFinal as a left join inhosp as b on a.ICN_NBR = b.hosp_ICN_NBR
  group by a.ICN_NBR;

quit;

data clm_dim_hospAgg;
  set hospAgg NotInHosp;
run;

proc sort data = clm_dim_hospAgg out = _null_ nodupkey;
  by ICN_NBR;
run;

 
 
* record category names ;
/*option fmtsearch = (out); */
proc format /*lib = out*/;
value clmType  1 = 'Pharmacy' 2='Hospitalizations' 3 = 'ER' 4 = 'Primary care'  100='Other';
run;

proc sql;
create table  out.&outFile as
  select mcaid_id, 
         month, 
         clmType, 
         count(distinct a.FRST_SVC_DT) as N_clm_days,
         sum(pd_amt) as pd_amt,
         sum(tpl_pd_amt) as tpl_pd_amt
  from (
    select a.mcaid_id,
         intnx('month',a.FRST_SVC_DT, 0, 'beginning') as month,
         a.FRST_SVC_DT,

         /* record category logic */
         case when a.clm_ctg_cd = 'PHARMACY' then 1
              when a.CLM_TYP_CD in ('I') 
               and a.CTG_OF_SVC_CD in ('05') then 2
              when b.ER = 1                  then 3
              when b.PrimCare = 1            then 4
                                             else 100
         end as clmType format = clmType.,
         pd_amt,
         tpl_pd_amt
         
  from clm_dim_hospAgg as a left join clm_lne_class as b on a.ICN_NBR = b.ICN_NBR
  where a.clm_ctg_cd ^= 'DENTAL'
 
) 
group by mcaid_id, month, clmType
order by mcaid_id, month, clmType
;
quit;






