readme for Kim/isp/isp_utilization/code/
Last updated 20230221

|-- @rchive
    Contains .txt versions usually of .sas files that I refactored and saved new but didn't want to get rid of yet


|-- get_and_prep
    Contains scripts used to gather raw datasets, prep them for the analysis needs, and save to data/ >
    The only ones that really have to be done in order are 1-4; after that they can be done in any order

    |-- 01_isp_key.sas --------------------------------------------------------  
        Description    : merges redcap export and datasets.isp_masterids to get id_split, id_pcmp, and dt_start_prac_isp 
        Last Ran On    : 2023-02-14
        Input          : dataset/filename [obs : var] 
        Detail         : [subset details, labels, etc.]
        Output         : dataset [obs : var] (if >1, copy all from Input -- Output/s)
        Relationship/s : [List relationships to any other files in directory]
        References     : [Copy from previous code file? used references? Links etc?]
    
    |-- 02_qrylong_y15_22.sas -------------------------------------------------  
        Description    : copy ana.qry_longitudinal, create FY, age_end_FY
        Last Ran On    : [YYYY-MM-DD]
        Input          : dataset/filename [obs : var] 
        Detail         : [subset details, labels, etc.]
        Output         : dataset [obs : var] (if >1, copy all from Input -- Output/s)
        Relationship/s : [List relationships to any other files in directory]
        References     : [Copy from previous code file? used references? Links etc?]
    
    |-- 03_create_memlist.sas	------------------------------------------------  
        Description    : uses 02_qrylong_y15_22 to create memlist from years 19-22
        Last Ran On    : [YYYY-MM-DD]
        Input          : dataset/filename [obs : var] 
        Detail         : [subset details, labels, etc.]
        Output         : dataset [obs : var] (if >1, copy all from Input -- Output/s)
        Relationship/s : [List relationships to any other files in directory]
        References     : [Copy from previous code file? used references? Links etc?]
    	
    |-- 04_get_rae.sas	------------------------------------------------  
        Description    : uses 02_qrylong_y15_22 to create memlist from years 19-22
        Last Ran On    : [YYYY-MM-DD]
        Input          : dataset/filename [obs : var] 
        Detail         : [subset details, labels, etc.]
        Output         : dataset [obs : var] (if >1, copy all from Input -- Output/s)
        Relationship/s : [List relationships to any other files in directory]
        References     : [Copy from previous code file? used references? Links etc?]
    


|-- docs_refs_logs
    Contains scripts I've stalked, been sent for use, etc. 
    
	|== logs_results_viewer : contains log files from sas, results viewer from sas html etc  
        |-- .log
    	|-- .mht
    	|-- .txt (if I was too embarrased to save whole log and just copied relevant bits needed)
    
	|-- cost anal _fin1.sas : copied from Jake/ - just making sure I'm not missing steps, etc
    |-- cost anal _part1.txt : also copied from Jake/
    |-- cost anal _part2.sas : from Jake / check against analysis file for utilization  
    |-- hurdle_macro_orig_cs.sas : original hurdle macro sent to me from Carter; shared with Miriam & Carlos
    |-- PMPM cost by FY and number STBH.xlsx : was an output file from one of JT's analyses for me to mimic my results output (per MG)

