LOG / DATA ACTIVITY  

 
3/16   

- created readme.qmd in root dir started
- moved archive files out to own dir so cleans up the old stuff a bit  

- CODE working notes: file `util_01c_gather_ana.sas`    
  for var create `adj_pd_total_YRcat`, need medicaid eligibility for 16 17 18
  - problem : data/qrylong_1621 didn't have 16, 17 : I think bc rae_assign==1, rae's started 2018? 
	- row 130 : get eligibility for 16, 17, 18 
	- delete int.qrylong_1621 (there was work.qrylong_1621b, wasn't saved before broken into 1618, 1921)?
	  - named it zz_delete... for now, remove if you don't use again soon   
	- work.abr_1618 [4,477,705]
	- make FY 2 digits 
	
  picking up from 3/15's notes : 
  - int.util_1618d 
	- mcaid_id, FY, month, dt_qrtr (date of quarter starting), adj_pd_total   (checked to make sure there were still 0 vars, and there are). 
  - util_1618e 
    - 331
	
3/15 
 - ended at int.util_1618d row 317 ish = start there   > saved progress but not finished. Need mem list for elig in 16 17 18
 


-----------------------------------------------------------------------------------------

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



