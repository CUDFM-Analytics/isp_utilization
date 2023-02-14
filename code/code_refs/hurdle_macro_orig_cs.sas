/*From Carter 8/2*/
/*The following two macros provide a map of how the modeling might go. */
/*The second macro is imbedded in the first. */
/*At the end I have included the call to the macro. */

%macro hurdle(data=postemanc_grp, 
              /* predictor variables for the probability model */
              pmodel = relmonth Emancipated 
						relmonth*Emancipated 
						relzero*Emancipated   
						ageEmanc 
						gender 
                 		rethnic 
                 		pmca_cat  
                		pmca_cat*Emancipated
                		pmca_cat*relmonth
               			pov_month_post
                		emanc_dt
                		fost_count 
						dys_count  
						placement_count    ,
              p_corr = ar(1),
             /* predictors for the cost model (if blank then it uses the same as those in the probability model) */
              cmodel=,
                /* correlation structure for the cost model */
              c_corr=ind,
              /* cost model outcome */
              costVar=,
              /* probability model outcome */
              utilVar =
              );

%if %scan(&cmodel,1,%str( )) = %then %let cmodel = &pmodel;

data costdat;
  set &data;

  pcost = (&utilVar>0);
  %if %scan(&costVar,1) NE %then %do; 
  nzcost = &costVar;
  if &costVar<=0 then nzcost = .;
  %end;
  relmonth2 = relmonth;
  relzero = relmonth=0;

  if emancipated = 0 then do;
   fost_count=0; dys_count=0;  placement_count=0;  episode_count=0; 
  end;

  if emancipated = 0 then RMVL_END_REASON='Matched comp';
run;

title4 'Probability model';
ods output type3 = p_anova GEEEmpPEst = p_parmest;
ods select GEEModInfo ConvergenceStatus GEEFitCriteria
;

proc genmod data = costdat desc namelen=100 order = internal;
  class uniqid relmonth2 RMVL_END_REASON(ref = 'Matched comp') gender rethnic(ref='Non-Hispanic White') 
		pmca_cat pov_month_post emanc_dt fost_count_cat dys_count_cat placement_count_cat episode_count_cat / ref = first;
  model pcost =  &pmodel 
			/ dist = binomial link = logit type3 wald;
  repeated subject = uniqID 
			/ type = &p_corr within = relmonth2;
  output out = p_predout pred = predicted_prob ;
  format emanc_dt year4.;
run;

%if %scan(&costVar,1) NE %then %do; 
title4 'Cost model';
ods output type3 = c_anova GEEEmpPEst = c_parmest;
ods select GEEModInfo ConvergenceStatus GEEFitCriteria
;

proc genmod data = costdat namelen=100 order = internal desc;
  where nzcost>0  ;
  class uniqid relmonth2 RMVL_END_REASON(ref = 'Matched comp')   gender 
         rethnic(ref='Non-Hispanic White') pmca_cat pov_month_post
        fost_count_cat dys_count_cat placement_count_cat episode_count_cat emanc_dt / ref = first;
  model nzcost =  &cmodel
  		/ dist = gamma link = log type3 wald;
  repeated subject = uniqID 
		/ type = &c_corr within = relmonth2;
  output out = c_predout 
  reschi = pearson_resid 
  pred = predicted_cost  
  STDRESCHI = STDRESCHI 
  xbeta=xbeta;
  format emanc_dt year4.;
run;
title4;
%end;

title4 'Parameter Estimates';
data p_parmest;
  set p_parmest;

  ord = _n_;
run;

proc sql;

create table allParm as
  select a.parm, a.level1 , 
         c.probchisq as Prob_joint_test, 
         a.estimate as log_OR,
         a.lowerCL as log_OR_LCL,
         a.upperCL as log_OR_UCL,
         a.probz as prob_PVal
%if %scan(&costVar,1) NE %then %do;
         ,
         B.estimate as log_costRatio,
          d.probchisq as cost_joint_test,  
        b.lowerCL as log_costRatio_LCL,
         b.upperCL as log_costRatio_UCL,
         b.probz as cost_PVal
%end;
  from p_parmest as a 
                      left join (select * from p_anova where df>1)  as c on a.parm = c.source
                    %if %scan(&costVar,1) NE %then %do;
                      left join c_parmest as b on a.parm = b.parm and a.level1 = b.level1
                      left join (select * from c_anova where df>1) as d on a.parm = d.source
                      %end;
  order by a.ord;

quit;

proc report data = allparm missing nowd;
  *where parm NE "Intercept";
  column parm  
        ("Joint tests" Prob_joint_test %if %scan(&costVar,1) NE %then %do;cost_joint_test %end;)
        level1
        ("Probability of a cost" log_OR log_OR_LCL log_OR_UCL prob_PVal) 
       %if %scan(&costVar,1) NE %then %do; ("Cost ratios" log_costRatio log_costRatio_LCL log_costRatio_UCL cost_PVal) %end;
;
  define parm / group order = data; 
  define level1 / group order = data; 
  define Prob_joint_test / group order = data; 
 %if %scan(&costVar,1) NE %then %do; define cost_joint_test / group order = data; %end;

  format log_OR log_OR_LCL log_OR_UCL %if %scan(&costVar,1) NE %then %do;log_costRatio log_costRatio_LCL log_costRatio_UCL %end; 10.3;
run;

title4;

title 'Model checking';
title2 'Probability of cost';
%calibrationPlot(data= p_predout, pred=predicted_prob, obs=pcost, groups=predicted_prob, ngroups=10 );
title;
%calibrationPlot(data= p_predout, pred=predicted_prob, obs=pcost, groups=predicted_prob, ngroups=10, by =emancipated);
%calibrationPlot(data= p_predout, pred=predicted_prob, obs=pcost, groups=relmonth, ngroups=0, by =emancipated);

%calibrationPlot(data= p_predout, pred=predicted_prob, obs=pcost, groups=fost_count_cat, ngroups=0, by =emancipated);
%calibrationPlot(data= p_predout, pred=predicted_prob, obs=pcost, groups=dys_count_cat, ngroups=0, by =emancipated);
%calibrationPlot(data= p_predout, pred=predicted_prob, obs=pcost, groups=placement_count_cat, ngroups=0, by =emancipated);
%calibrationPlot(data= p_predout, pred=predicted_prob, obs=pcost, groups=episode_count_cat, ngroups=0, by =emancipated);

%if %scan(&costVar,1) NE %then %do;
ods graphics / LOESSMAXOBS
= 30000;

title2 'Mean cost';
proc sort data = c_predout;
  by emancipated;
run;
proc sgplot data = c_predout;
  by emancipated;
  loess x = xbeta y = pearson_resid;
  refline 0/ axis=y;
  yaxis max = 25;
run;

%calibrationPlot(data= c_predout, pred=predicted_cost, obs=nzcost, groups=predicted_cost, ngroups=10 );
%calibrationPlot(data= c_predout, pred=predicted_cost, obs=nzcost, groups=predicted_cost, ngroups=10, by =emancipated);
%calibrationPlot(data= c_predout, pred=predicted_cost, obs=nzcost, groups=relmonth, ngroups=0, by =emancipated);
%calibrationPlot(data= c_predout, pred=predicted_cost, obs=nzcost, groups=fost_count_cat, ngroups=0, by =emancipated);
%calibrationPlot(data= c_predout, pred=predicted_cost, obs=nzcost, groups=dys_count_cat, ngroups=0, by =emancipated);
%calibrationPlot(data= c_predout, pred=predicted_cost, obs=nzcost, groups=placement_count_cat, ngroups=0, by =emancipated);
%calibrationPlot(data= c_predout, pred=predicted_cost, obs=nzcost, groups=episode_count_cat, ngroups=0, by =emancipated);
%end;
title2;
title;

%mend;

%macro calibrationPlot(data=, pred=, obs=, groups=, ngroups=10, by =);

%if &ngroups>0 %then %do;
proc rank data = &data out = cp_tmp_pmean groups = &ngroups;
  var  &groups    ;
  ranks predGrp;
run;
%end;

proc means data = %if &ngroups>0 %then %do; cp_tmp_pmean %end; %else %do; &data %end; noprint  nway;
  var &pred &obs;
  class &by   %if &ngroups>0 %then %do; predGrp %end; %else %do; &groups %end; ;
  output out = cp_tmp_meanout mean = / autoname;
run;
/*
proc sgplot data = cp_tmp_meanout;
   %if %scan(&by,1) ne %then %do; by &by ; %end; 
 scatter x = &pred._mean y = &obs._mean;
*series x = predgrp y = pred_mean;
   lineparm x=0 y=0 slope=1;

run;*/

%if &ngroups>0 %then %do;  
Title4 "Observed VS predicted &obs, by quantiles of &groups";

%end;
%else %do;
Title4 "Observed VS predicted &obs, by &groups";
%end;
   %if %scan(&by,1) ne %then %do; 
     proc sgpanel data = cp_tmp_meanout;
       panelby &by ;
   %end; /**/
   %else %do; 
     proc sgplot data = cp_tmp_meanout;
   %end; /**/
scatter x = %if &ngroups>0 %then %do; predGrp %end; %else %do; &groups %end; y = &obs._mean 
  / /*%if %scan(&by,1) ne %then %do; group = &by  %end;*/ MARKERATTRS=(symbol=circlefilled);
series x =%if &ngroups>0 %then %do; predGrp %end; %else %do; &groups %end; y = &pred._mean 
  / /* %if %scan(&by,1) ne %then %do; group = &by  %end;*/ markers MARKERATTRS=(symbol=circle);
label &obs._mean='Observed mean' &pred._mean='Predicted mean';
%if %scan(&by,1) ne %then %do; rowaxis label = 'Mean'; %end; %else %do; yaxis label = 'Mean'; %end;
run;
title4;

proc datasets nolist library = work;
  delete cp_tmp_meanout cp_tmp_pmean;
  run;
quit;

%mend;
/*
%calibrationPlot(data=predout, pred=pred, obs=pcost, groups=relmonth, ngroups=0, by =emancipated);
%calibrationPlot(data=E_p_predout, pred=pred, obs=pcost, groups=relmonth, ngroups=0, by =emancipated);
*/

%hurdle(data=postemanc_grp,
		utilVar = totEnc, 
        costVar=adj_totpaid,
        obsPred = YES);
