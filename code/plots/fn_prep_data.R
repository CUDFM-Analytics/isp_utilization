
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