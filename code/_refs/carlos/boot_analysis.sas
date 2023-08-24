*****************************************************************************************
DATE CREATED: 3/ 29/ 2023

PROGRAMMER  : Carter Sevick

PURPOSE     : combine the parallel process results and analyze

NOTES       :

UPDATES     : How to set subset, exposure, and compare arguments for %combineAndScore()?

*****************************************************************************************;
* PART 3 of 3 in Carter's parallel processing framework.
    - set project root directory
    - set bootstrap output directory from PART 1
    - set the arguments for the combineAndScore macro
      - set the "data= " argument needs as many data sets as specified in nboot from 
        PART 2 run_parallel
      - set the "subset=" argument, e.g. the exposed group
      - set the "exposure=" argument, the value of the exposure condition
      - set the "compare=" argument, what value to change the exposed group to
      - n.b. exposure and compare arguments used to conduct the counterfactual analysis;

* Create a format to identify the CMHC values ---------------------------------------------;
* Needed to overcome formatting warnings with sim data;
proc format;
  value cmhc
  1='CRC' 
  2='JCMH'  
  3='MHP' 
  4='SHG'
  0='nonCMHC';
run;

%macro combineAndScore(data= /*list datasets to combine and score*/,
                       lib = dataPro /*libname for the data location */,
                       prob= prob_stored_/*prefix of the store objects for the probability model */,
                       cost= cost_stored_/*prefix of the store objects for the cost model */,
                       subset= /* subset of the data to score */,
                       exposure = /* define exposure */,
                       compare = /* define comparison */,
                       out = /* name dataset for bootstrap results */
);


* Kick off the analysis part -------------------------------------------------------------;
*%let projRoot = M:\Carter\Examples\boot total cost;
%let projRoot = V:/Research/DFM analytic group/sim_utilization/05_models/01_allowed_amt;

* location for bootstrap products ;
libname dataPro "&projRoot/DataProcessed";

* Macro arguments;
%local N_data;

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
  proc plm restore=&lib..&prob&i;
     score data=_tmp_&i out=p_tmp_&i predicted=pred_prob / ilink;
  run;

  * predicted cost ;
  proc plm restore=&lib..&cost&i;
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
data _allPred_;
  set _calcCost_:;
run;

* contrast the risk groups ;
data &out;
  merge _allPred_(keep =  m_cost _score_group_  p_set replicate  
                  where = (_score_group_ = 1))
        _allPred_( keep =  m_cost _score_group_ p_set replicate  
                   rename = (m_cost = m_cost_2)
                   where = (_score_group_ = 2));
  by p_set replicate ;

  diff = m_cost - m_cost_2;

  drop _score_group_;
run;

%mend;
option mprint;

* call the MACRO analysis original - Commented out;


* call the MACRO analysis on sim;
%combineAndScore(
    data= _resample_out_1 _resample_out_2 _resample_out_3 _resample_out_4 _resample_out_5 _resample_out_6 _resample_out_7 _resample_out_8 /*list datasets to combine and score*/,
    lib = dataPro /*libname for the data location */,
    prob= prob_stored_/*prifix of the store objects for the probability model */,
    cost= cost_stored_/*prifix of the store objects for the cost model */,
    subset= %str(status_bin = 1)/* subset of the data to score */,
    exposure = %str(status_bin = 1;)/* define exposure */,
    compare = %str(status_bin = 0;)/* define comparison */,
    out = _diff_
);
 
title  'bootstrap standard error' ;
proc means data = _diff_  n nmiss mean median stddev;
  var diff;
run;

title 'Bootstrap distribution';
proc sgplot data = _diff_;
  histogram diff;
run;
title;

