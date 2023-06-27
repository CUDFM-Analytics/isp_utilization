PARENT DIR: isp_utilization/reports

SEE 
  - code/ for logs rendered for each report  
  - Outdated reports are moved to _archive_rm for removal once project is completed (save until then for comparisons, historical refs)  

DIRECTORIES

|== attr_20220800 ==================================================================
    Description    : attr results, August 2022
    Last Ran On    : 2022-08-07
    Files          : 1) ISP_attrib_months_20220807.xlsx
    Relationship/s : None

|== attr_20220900 ===================================================================
    Description    : attr results, Sept 2022
    Last Ran On    : 2022-09-13
    Files          : 1) MonthlyAttr_ISP_v_NonISP_20220913.xlsx
    Relationship/s : None

|== eda_final_ds_reports =============================================
    Description    : Frequency/eda reports from final analysis dataset, data.analysis
    Last Edited On : 2023-06-22
    Source         : mostly from code/util_03a_eda.sas, code/util_03b_eda_export_pdf.sas
    Relationship/s : folders int/ and data// 
	
FILES 

|-- cost_pc_2023-06-22.pdf ---------------------------------------------
    Description    : DV=PC Cost, Hurdle 1 model
    Last Ran On    : 2023-06-22
    SOURCE         : code/util_avp_cost_dvs.sas
    Dependencies   : code/util_00_config
				   : code/macro_hurdle1_cost_dvs.sas
	Log			   : code/cost_pc_2023-06-22.log
	Communication  : Emailed MG 6/22 ready to view  
	
|-- cost_rx_2023-06-22.pdf ---------------------------------------------
    Description    : DV=Rx Cost, Hurdle 1 model
    Last Ran On    : 2023-06-22
    SOURCE         : code/util_avp_cost_dvs.sas
    Dependencies   : code/util_00_config
				   : code/macro_hurdle1_cost_dvs.sas
	Log			   : code/cost_rx_2023-06-22.log
	Communication  : Emailed MG 6/22 ready to view 
	
|-- cost_total_2023-06-22.pdf ---------------------------------------------
    Description    : DV=Total FFS Cost, Hurdle 1 model
    Last Ran On    : 2023-06-22
    SOURCE         : code/util_avp_cost_dvs.sas
    Dependencies   : code/util_00_config
				   : code/macro_hurdle1_cost_dvs.sas
	Log			   : code/cost_total_2023-06-22.log
	Communication  : Emailed MG 6/22 ready to view 
	
|-- visits_..._2023-06-27.pdf ---------------------------------------------
    Description    : DV=Visits
    Last Ran On    : 2023-06-27 (all)
    SOURCE         : code/util_avp_visit_dvs.sas
    Dependencies   : code/util_00_config
				   : code/macro_hurdle1_visit_dvs.sas
	Log			   : code/visits_..._2023-06-22.log
	Communication  : Emailed MG, MD 6/27 ready to view  
	
|-- visits_..._2023-06-22_ANON.pdf ---------------------------------------------
    Description    : DV=Visits report anonymized (removed mcaid_id sections)
    Last Ran On    : 2023-06-27 (all)
    SOURCE         : NA
    Dependencies   : Manually edited from visits..._2023-06-27.pdf files
	Communication  : Emailed MG, MD 6/27 ready to view  
