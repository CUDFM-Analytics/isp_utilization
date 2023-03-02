
# function to create and subset the x_labels
fn_x_labels <- function(df_in){
	
	# make final: 
	final <- c(row = 36,
						 x_txt = "Jun")
	
	out <- df_in %>% 
		filter(q_beg == 1) %>% 
		select(row, x_txt) %>% 
		rbind(final) %>% 
		mutate(row = as.numeric(row))
	
	return(out)
}