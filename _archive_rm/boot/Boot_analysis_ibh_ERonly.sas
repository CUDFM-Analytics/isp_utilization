*****************************************************************************************
DATE CREATED: 3/ 29/ 2023

PROGRAMMER  : Carter Sevick

PURPOSE     : combine the parallel process results and analyze

NOTES       :

UPDATES     :

*****************************************************************************************;

*formats!!;
libname moncost 'X:\HCPF_SqlServer\AnalyticSubset'; 
options fmtsearch=(moncost); 

proc format;
 value yesno 0='No' 1='Yes'; 
 value age7cat 1="0-5" 2="6-10" 3="11-15" 4="16-20" 5="21-44" 6="45-64" 7="65+";
 value budgrN 3="MAGI 69 - 133% FPL" 5="MAGI TO 68% FPL" 6="Disabled" 11="Foster Care" 12="MAGI Eligible Children" 14="Other";
 value rae 3="3" 5="5" 6="6" 99="(1,2,4,7)"; 
 value pdpre 0="No health 1st" 1="0" 2="0-50th pcntl" 3="50th to 75th pcntl" 4="75th to 90th pcntl" 5="90th to 95th pcntl" 6="> 95th pcntl";
 value racej 1="Hispanic/Latino" 2="White/Caucasian" 3="Black/African American" 4="Asian" 5="Other People of Color" 6="Other/Unknown Race";

 value bhonb 0='0' 1='>0';
 value bhont 0='0' 1='(0-1]' 2='>1';
run;





%let projRoot = X:\Jake\other\IBH\cost and utilization;

* location for bootstrap products ;

libname dataPro "&projRoot\dataProcessed";


%macro combineAndScorebin(data= /*list datasets to combine and score*/,
                       lib = dataPro /*libname for the data location */,
                       prob= prob_stored_/*prifix of the store objects for the probability model */,
                       
                       subset= /* subset of the data to score */,
                       exposure = /* define exposure */,
                       compare = /* define comparison */,
                       out = /* name dataset for bootstrap results */
);

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
  ods select all;

  * average cost is calculated ;
  proc sql;
  create table _calcCost_&i as
    select  &i as p_set, /* tracker for the parallel run */ 
            replicate, _score_group_,  mean(pred_prob) as m_prob
    from p_tmp_&i
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
  merge _allPred_(keep =  m_prob _score_group_  p_set replicate  
                  where = (_score_group_ = 1))
        _allPred_( keep =  m_prob _score_group_ p_set replicate  
                   rename = (m_prob = m_prob_2)
                   where = (_score_group_ = 2));
  by p_set replicate ;

  diff = m_prob - m_prob_2;

  drop _score_group_;
run;

%mend;
option mprint;

* call the MACRO analysis ;
%combineAndScorebin(
    data= _resample_out_1 _resample_out_2 _resample_out_3 _resample_out_4 _resample_out_5 _resample_out_6 _resample_out_7 _resample_out_8/*list datasets to combine and score*/,
    lib = dataPro /*libname for the data location */,
    prob= prob_stored_/*prifix of the store objects for the probability model */,
    
    subset= %str(psych_visit_offer = 1)  /* subset of the data to score */,
    exposure = %str(psych_visit_offer = 1;)/* define exposure (sets variable for everyone to the value) */,
    compare = %str(psych_visit_offer = 0;)/* define comparison (sets variable for everyone to the value */,
    out = _diff_
);
 


title  'bootstrap standard error' ;
proc means data = _diff_  n mean median stddev maxdec=3;
  var diff m_prob m_prob_2;
run;

title 'Bootstrap distribution';
proc sgplot data = _diff_;
  histogram diff;
run;
title;

proc sgplot data = _diff_;
  histogram m_prob;
run;
