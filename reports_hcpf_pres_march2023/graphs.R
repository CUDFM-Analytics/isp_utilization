# PURPOSE  Graphs for HCPF presentation slide deck 

# ---- load libraries & params --------------------------------------------
{
	library(here)
	library(tidyverse)
}

attr <- "reports_hcpf_pres_march2023/hcpf_attr_quarterly.xlsx"

attr <- readxl::read_excel(attr,
													 sheet = 'attr_table')
