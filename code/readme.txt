readme for Kim/isp/isp_utilization/code/
Last updated 20230221

|-- @rchive
    Contains .txt versions (usually) of .sas files that I refactored and saved new but didn't want to get rid of yet

|-- refs_logs
    Contains scripts I've stalked, been sent for use, etc. 
    
	|== logs_results_viewer : contains log files from sas, results viewer from sas html etc  
        |-- .log
    	|-- .mht
    	|-- .txt (if I was too embarrased to save whole log and just copied relevant bits needed)
    
	|-- cost anal _fin1.sas      : copied from Jake/ - just making sure I'm not missing steps, etc
    |-- cost anal _part1.txt     : also copied from Jake/
    |-- cost anal _part2.sas     : from Jake / check against analysis file for utilization  
	|-- hurdle_APV.sas           : from Carter 2/14 update to the hurdle / logistic model for utilization 
    |-- hurdle_macro_orig_cs.sas : original hurdle macro sent to me from Carter; shared with Miriam & Carlos
    |-- PMPM cost by FY and number STBH.xlsx : was an output file from one of JT's analyses for me to mimic my results output (per MG)

|-- attr_202209.sas	------------------------------------------------  
    Description    : Monthly BHO utilization for ER visits and Other pd_cost
				     - Subset FY 01Jul2015-30JUN2022
				     - creates var FY7, bh_n_er, bh_n_other
    Last Ran On    : 2023-02-21
    Input  1       : ana.qry_bho_monthlyutil_working [6405694 : 7] 
    Output 1       : data.bho_fy15_22                [4767794 : 5] 
	Variables	   : mcaid_id, month, bh_n_er, bh_n_other, fy7  
    Relationship/s : [List relationships to any other files in directory]
    References     : [Copy from previous code file? used references? Links etc?]
	
|-- 06_get_monthly_utilization.sas	------------------------------------------------  
    Description    : From ana.qry_monthly_utilization,
						adds format to clmClass {clmClass_recode} to get Pharmacy / Hosp / ER / Primary Care / Other
						adds format fy7 to get FYs from 01JulXXXX through 01JUNXXXX+1 (read through all proc freq and counted it's good) 
						sum count, pd_amt to get tot_n_month and tot_pd_month by clmClass_r
    Last Ran On    : 2023-02-21
    Input          : ana.qry_monthly_utilization [] 
    Output         : data.util_month_y15_22 [61939211 : 6] 
	Variables	   : mcaid_id, month, clmClass_r, tot_n_month, tot_pd_month, fy7  
    Relationship/s : [List relationships to any other files in directory]
    References     : [Copy from previous code file? used references? Links etc?]  
	
|-- 07_get_telehealth.sas	------------------------------------------------  
    Description    : Creates tmp ds `pc` from ana.qry_clm_dim_class where hosp_episode NE 1 and ER NE 1 and primCare = 1 [43044039 : xx]
				   : Creates tmp ds `telecare` from ana.clm_lne_fact_v with lots of pos_cd / proc_mod_X_cd and format 
					 > margTele grouped by icn_nbr
					 > teleCare_FINAL joins pc
					 > NB No records before 01DEC2016 in this dataset
    Last Ran On    : 2023-02-21
    Input          : ana.qry_monthly_utilization [] 
    Output 1       : data.util_month_y15_22 [61939211 : 6] 
	Output 2       : data.tele_memlist [  ]
	Variables	   : mcaid_id, month, clmClass_r, tot_n_month, tot_pd_month, fy7  
    Relationship/s : [List relationships to any other files in directory]
        References     : [Copy from previous code file? used references? Links etc?]


