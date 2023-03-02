
theme_set(theme_minimal(base_family = "Lato"))

theme_update(
	
	# Axis title is grey if used: 
	axis.title.y = element_text(color = "grey40"),
	
	# Axes labels are grey
	axis.text.x = element_text(color = "grey40"),
	axis.text.y = element_text(color = "grey40"),
	
	# ticks light grey
	axis.ticks = element_line(color = "grey91", size = .5),
	
	# Remove the grid lines 
	panel.grid = element_blank(),
	
	# Customize margin values (top, right, bottom, left)
	# plot.margin = margin(20, 10, 20, 10),
	
	# white background
	plot.background = element_rect(fill = "white", color = "white"),
	panel.background = element_rect(fill = "white", color = "white"),

	# Remove legend
	legend.position = "none"
)