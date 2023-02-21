FOLDER: reports

|== @rchive ========================================================================
    Description    : old documents to reference or just don't want to delete

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
	
|== hcpf_pres_20230300	=============================================================  
    Description    : Output / Results for Qs 1-6: ISP_Utilization_Analytic_Plan_20221118.docx 
	
	|-- hcpf_q1_q2_attr.xlsx ------------------------------------------------  
	    Description    : Attributed members to ISP, non-ISP and Attr n/pcts relative to March 2020 for ISP, non-ISP 
	    Details   	   : tab1: attr for 07/19-06/22 // tab2: tab1 plot // tab3: attr relative to March 2020 // tab4: plot for tab3
	    Code File      : 2023_hcpf_attr_q1_q2.sas
	    Data Source/s  : HCPF/Kim/datasets/isp_masterids.sas7bdat; analytic_subset/qry_longitudinal
	    Last Ran       : 2023-02-15
	    Requires       : 00_global.sas

	|-- hcpf_q3_q4_telehealth.xlsx
	    Description    : Frequency telehealth providing clinics
		Details   	   : 
	    Code File      : 202302_hcpf_tele_q3_q4.sas
	    Data Source/s  : 
	    Last Ran       : 2023-02-21
	    Details        : 
		Requires       : 00_global.sas [libnames, formats, macros]

	