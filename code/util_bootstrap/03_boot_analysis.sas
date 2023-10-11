**********************************************************************************************
AUTHOR   : Carter Sevick (KW adapted)
PROJECT  : ISP
PURPOSE  : Part 3 of 3>  combine the parallel process results and analyze
VERSION  : 2023-09-25
HISTORY  : copied on 08-24-2023 from Carter/Examples/boot total cost/
CHANGES  : [row 108] added _diff_ 
PRE PROCESSING: COPY STORED PROCS INTO DV/FOLDER... 

NOTE: CHANGE rows 16-xxx, rows 26-xxx!! 
***********************************************************************************************;
* for outputs by DV, reporting // Change 12, 13 then okay; 
%LET pdftitle = Cost_Total;
%LET projRoot = S:\FHPC\DATA\HCPF_DATA_files_SECURE\Kim\isp\isp_utilization;

%LET dv = cost_tot;  
/*%LET dv = cost_pc;*/

* pdf output; 
%LET pdf      = S:\FHPC\DATA\HCPF_DATA_files_SECURE\Kim\isp\isp_utilization\reports\boot_se_&dv..pdf;

**** BOOT ANALYSIS*******; 
* stored bootstrap products -- ;
LIBNAME dataPro "&projRoot\data_boot_processed";

* Make this match row 16 name; 
LIBNAME cost_tot "&projRoot\data_boot_processed\cost_total";
/*LIBNAME cost_pc "&projRoot\data_boot_processed\cost_pc";*/

* for format search; 
libname data   "&projRoot\data";

OPTIONS FMTSEARCH = (dataPro, data, &dv);
%put &dv;

%macro combineAndScore(data=                /*list datasets to combine and score*/,
                       lib = dataPro       /*libname for the data location */,
                       prob= prob_stored_   /*prefix of the store objects for the probability model */,
                       cost= cost_stored_   /*prefix of the store objects for the cost model */,
                       subset=              /* subset of the data to score */,
                       exposure =           /* define exposure */,
                       compare =            /* define comparison */,
                       out =                /* name dataset for bootstrap results */
);

%local N_data; *local exists only during the execution of this specific macro (vs global, which is for duration of session/job);

* count data sets to score ;
%let N_data = %sysfunc(countw(&data, %str( )));

* define exposure groups, score the results and aggregate by boot replicate ;
%do i = 1 %to &N_data;

  data _tmp_&i;
    set &lib..%scan(&data, &i, %str( )) (in = a) &lib..%scan(&data, &i, %str( ));
    %if %scan(&subset, 1) NE %then %do;
      where &subset;
    %end;

    if a then do;
      _score_group_ = 1;
      &exposure;
    end;

    if ^a then do;
      _score_group_ = 2;
      &compare;
    end;
  
  run;

  * the predictions for util and cost will be made for each person twice, once exposed and once unexposed;
  * prob of util ;
  ods select none;
  proc plm restore=&dv..&prob&i;
     score data=_tmp_&i out=p_tmp_&i predicted=pred_prob / ilink;
  run;

  * predicted cost ;
  proc plm restore=&dv..&cost&i;
     score data=p_tmp_&i out=cp_tmp_&i predicted=pred_cost / ilink;
  run;
  ods select all;

  * average cost is calculated ;
  proc sql;
  create table _calcCost_&i as
    select  &i as p_set, /* tracker for the parallel run */ 
            replicate, _score_group_,  mean(pred_prob*pred_cost) as m_cost
    from cp_tmp_&i
    group by p_set, replicate, _score_group_
    order by p_set, replicate, _score_group_;
  quit;

%end;

* combine the results from each parallel process ;
DATA _allPred_;
SET _calcCost_:;
RUN;

* contrast the risk groups ;
DATA &out;
  MERGE _allPred_(keep =  m_cost _score_group_  p_set replicate  
                  where = (_score_group_ = 1))
        _allPred_(keep =  m_cost _score_group_ p_set replicate  
                  rename = (m_cost = m_cost_2)
                  where = (_score_group_ = 2));
  BY p_set replicate ;

  DIFF = m_cost - m_cost_2;

  DROP _score_group_;
RUN;

%mend;
option mprint;

* call the MACRO analysis ;
%combineAndScore(
    data     = _resample_out_1 _resample_out_2 _resample_out_3 _resample_out_4 _resample_out_5 _resample_out_6 _resample_out_7 _resample_out_8 /*list datasets to combine and score*/,
    lib      = dataPro              /*libname for the data location */,
    prob     = prob_stored_         /*prefix of the store objects for the probability model */,
    cost     = cost_stored_         /*prefix of the store objects for the cost model */,
    subset   = %str(int_imp = 1)    /* subset of the data to score */,
    exposure = %str(int_imp = 1;)   /* define exposure */,
    compare  = %str(int_imp = 0;)   /* define comparison */,
    out      = _diff_
);

****** RESULTS PRINT to PDF, SAVE _diff_ ***********************; 

* save the work._diff_ and _allpred_ to libname dv ; 
DATA &dv.._diff_;    SET  _diff_; RUN; 
DATA &dv.._allpred_; SET  _allpred_; RUN; 

ods pdf file="&pdf" STARTPAGE=no; TITLE &pdftitle;

%LET today = %SYSFUNC(today(), YYMMDD10.); %put &today;

TITLE  'Bootstrap Standard Error:' &pdftitle ;
proc means data = &dv.._diff_  n nmiss mean median stddev;
  var diff;
run;

title 'Bootstrap distribution';
proc sgplot data = &dv.._diff_;
  histogram diff;
run;
title;

ODS PDF CLOSE; 
