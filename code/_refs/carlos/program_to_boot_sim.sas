*****************************************************************************************
DATE CREATED: 3/29/2023

PROGRAMMER  : Carter Sevick

PURPOSE     : define the bootstrap process to parallelize 

NOTES       :

UPDATES     : changed the projRoot directory,
			  changed the subject argument in %resample() to member_composite_ID for SIM

*****************************************************************************************;
* PART 1 of 3 in Carter's parallel processing framework.
	- set project root directory
	- set bootstrap output directory
	- set path to input data directory
	- set macro variable to dataset name
	- set probability model
	- set cost model;


*options noquotelenmax;
*Load the global vars file;
*%INCLUDE "V:/Research/DFM analytic group/sim_utilization/02_code/00_global_vars.sas";

* Project root directory;
%let projRoot = V:/Research/DFM analytic group/sim_utilization/05_models/01_allowed_amt;

* Set location for bootstrap output ;
libname out "&projRoot/DataProcessed";

* Set location of input data to boot ;
*libname in "&projRoot/DataRaw"; *Would require to copy over the data set;
libname in "V:/Research/DFM analytic group/sim_utilization/04_data";

* Set input data to bootstrap;
%let data = in.apcd_sim;

* Load macro programs ;
%include "V:/Research/DFM analytic group/sim_utilization/02_code/MACRO_resample_V4.sas";

* get process parameters ;
** process number ;
%let    i = %scan(&SYSPARM,1,%str( ));

** seed number ;
%let    seed = %scan(&SYSPARM,2,%str( ));

** N bootstrap samples ;
%let    N = %scan(&SYSPARM,3,%str( ));


* Create a format to identify the CMHC values -------------------------------------------------;
* Needed to overcome formatting warnings with sim data;
proc format;
	value cmhc
	1='CRC'	
	2='JCMH'	
	3='MHP'	
	4='SHG'
	0='nonCMHC';
run;

*
Draw bootstrap samples 

two new variables are added:
1) bootUnit = the new subject identifier
2) replicate = identifies specific bootstrap samples

!!!!! the old ID variable is still included, BUT YOU CAN NOT US IT IN THIS DATA FOR STATISTICS!!!!!!!!!!!
;
ods select none;
* MACRO resample V4;
%resample(data=&data
	, out=_resample_out_
	, subject=member_composite_id
	, reps=&N 
	, strata=ever_sim0
	, seed=&seed
	, bootUnit=bootUnit
	, repName=replicate
	, samprate= (.25 .25)
	, lightSort = YES
);
	
	
* save a copy of the booted data ;
data out._resample_out_&i;
  set _resample_out_;
run;



* run models and output store objects ;
* probability model ;
ods select none;
options nonotes;
proc genmod data  = _resample_out_ desc;
	by replicate;
	class bootUnit member_composite_id ever_sim0 status_bin assigned_LOB timepoint gender_cd_num cnty_fips(ref = '31');
  	model pvar_allowed_amt_adj_top = ever_sim0 status_bin assigned_LOB timepoint age gender_cd_num cnty_fips risk_cat/ dist = binomial link = logit;
  	repeated subject = bootUnit;
  	store out.prob_stored_&i;
run;
ods select all;
options notes;


* cost model ;
ods select none;
options nonotes;
proc genmod data = _resample_out_  ;
   by replicate;
   where allowed_amt_adj_top > 0;
   class bootUnit member_composite_id ever_sim0 status_bin assigned_LOB timepoint gender_cd_num cnty_fips(ref = '31');
   model allowed_amt_adj_top = ever_sim0 status_bin assigned_LOB timepoint age gender_cd_num cnty_fips risk_cat/ dist=gamma link = log;
   repeated subject = bootUnit;
   store out.cost_stored_&i;
run;
ods select all;
options notes;

* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%;

