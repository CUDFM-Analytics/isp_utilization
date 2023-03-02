
fn_prep_data <- function(df, df2){

	df2 <- df %>% 
		select(-Obs) %>% 
		pivot_longer(cols = -flag,
								 names_to = "month",
								 values_to = "n"
		)  %>% 
		mutate(flag = factor(flag,
												 levels = c(0,1),
												 labels = c("Non-ISP","ISP"))) %>% 
		mutate(month = stringr::str_replace_all(month, "_","")) %>% 
		group_by(flag) %>% 
		mutate(row = as.numeric(row_number())) %>% 
		
		# make month into date var, then extract month, year, q for grouping
		mutate(month = lubridate::dmy(month)) %>% 
		mutate(month_abbrev = format(month, format = "%b")) %>% 
		mutate(year  = format(month, format = "%Y")) %>% 
		mutate(qrtr = quarter(month, with_year = FALSE)) %>% 
		
		# add label for max at end of line graph 
		mutate(label0 = if_else(month == max(month), n, NA_real_)) %>% 
		mutate(label0 = scales::comma(label0)) %>% 
		mutate(label_max = if_else(!is.na(label0), 
															 glue::glue("{flag}\n(n={label0})"),
															 NA_character_)) %>% 
		ungroup() %>% 
		select(-label0) %>% 
		
		# create x_label col indicator to subset outside function
		group_by(year, qrtr) %>% 
		mutate(q_beg = ifelse(row == min(row), 1, 0)) %>%
		ungroup() %>% 
		group_by(year) %>% 
		mutate(
			x_txt = case_when(
				row == min(row) ~ format(month, format = "%b\n%Y"),
				TRUE ~ month_abbrev)) %>% 
		ungroup() 
	
	return(df2)
	
}


# for the quarter one ; a little different - 
fn_prep_q <- function(){
	
	q0 <- read_excel(here("reports_hcpf_pres_march2023/hcpf_attr_quarterly.xlsx"), 
									 sheet = "attr_quarter")
	
	q <- q0 %>% 
		select(n = n_unique_mem,
					 flag = ind_isp,
					 q) %>% 
		
		# fix month (quarter) up: 
		mutate(month = fct_inorder(q)) %>% 
		mutate(month = stringr::str_replace_all(month, "_"," ")) %>% 
		mutate(qn    = stringr::str_sub(month, start = -2)) %>% 
		
		# flag factorize, group
		mutate(flag = factor(flag,
												 levels = c("non-ISP","ISP"),
												 labels = c("Non-ISP","ISP"))) %>% 

		group_by(flag) %>% 
		mutate(row = as.numeric(row_number())) %>% 
		
		# make month into date var, then extract month, year, q for grouping
		mutate(year = stringr::str_extract(month, "\\d{4}")) %>% 
		
		# add label for max at end of line graph 
		mutate(label0 = if_else(row == max(row), n, NA_real_)) %>% 
		mutate(label0 = scales::comma(label0)) %>% 
		mutate(label_max = if_else(!is.na(label0), 
															 glue::glue("{flag}\n(n={label0})"),
															 NA_character_)) %>% 
		ungroup() %>% 
		select(-label0) %>% 
		
		# create x_label col indicator to subset outside function
		group_by(year) %>% 
		mutate(
			x_txt = case_when(
				row == min(row) ~ glue::glue("{qn}\n{year}"),
				TRUE ~ qn)) %>% 
		ungroup() 
	
	return(q)
	
}
