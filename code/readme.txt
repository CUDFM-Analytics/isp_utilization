readme for Kim/isp/isp_utilization/code/
Last updated 20230221

|-- @rchive
    Contains .txt versions (usually) of .sas files that I refactored and saved new but didn't want to get rid of yet

|-- 202302_gather_data_util_analysis
    Contains scripts used to gather raw datasets, prep them for the analysis needs, and save to data/ >
    The only ones that really have to be done in order are 1-4; after that they can be done in any order

    |-- 01_isp_key.sas --------------------------------------------------------  
        Description    : merges redcap export and datasets.isp_masterids to get id_split, id_pcmp, and dt_start_prac_isp 
					     used in analysis dataset to create ind_isp_active and ind_isp_ever
        Last Ran On    : 2023-02-14
        Input/s        : isp_redcap.csv, datasets.isp_masterids.sas7bdat 
        Output/s       : data/isp_key.sas7bdat 
        Relationship/s : isp_utilization.sas, 04_create_memlist.sas, create_analytic_dataset.sas
    	
    |-- 02_rae.sas	------------------------------------------------  
        Description    : file from Jake to get rae_id, hcpf county codes etc. 
        Last Ran On    : 2023-02-14
        Input          : county_convert or something? numbers are weird fyi - there's an 80 (Broomfield?) 
        Output         : data/rae 
        Relationship/s : joined in 03_qrylong_y15_22.sas
        References     : NA
    
    |-- 03_qrylong_y15_22.sas -------------------------------------------------  
        Description    : create FY, age_end_FY, join longitudinal and demographics from ana. 
        Last Ran On    : 2023-02-21
        Input 1        : ana.qry_longitudinal
		Input 2		   : ana.qry_demographics
		Input 3        : data/rae
		Input 4		   : data/isp_key  
        Output         : data/qrylong_y15_22 [53384196 : 28] 
        Relationship/s : [List relationships to any other files in directory]
        References     : [Copy from previous code file? used references? Links etc?]
    
    |-- 04_create_memlist.sas	------------------------------------------------  
        Description    : uses data.qrylong_15_22 to create memlist from years 19-22
    				   : Creates time-varying covariate based on date practice started ISP 
    						- if id_split ne . (so we don't get only where month > dt_prac_isp) 
    						- and month >= dt_prac_isp then ind_isp = 1
        Last Ran On    : 2023-02-21
        Input          : data.qrylong_y15_22, data.isp_key
        Output         : data.memlist [1594687 : 7] 
        Relationship/s : Get context values (listed in Analytic plan) from here?  
        References     : cost anal _part1.txt
    	
    |-- 05_get_bho.sas	------------------------------------------------  
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

|-- docs_refs_logs
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

