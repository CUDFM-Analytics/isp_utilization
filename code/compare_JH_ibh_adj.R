

ibh <- haven::read_sas(
	data_file = "S:/FHPC/DATA/HCPF_Data_files_SECURE/UPL-ISP/ibh_adjpaid_16_17_18.sas7bdat")
ibh <- ibh |> 
	unique()

ibh |> 
	filter(adj_pd_total_16cat == 0)
