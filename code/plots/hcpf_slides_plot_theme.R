
theme_set(theme_minimal(base_family = "Lato"))

theme_update(
	
	# Axis title is grey if used: 
	axis.title.y = element_text(color = "grey40",
															size = 10,
															margin = margin(10,0,10,0, "pt")),
	
	axis.title.x = element_text(color = "grey40",
															size =10,
															margin = margin(5,0,0,0,"pt")),
	
	# Axes labels are grey
	axis.text.x = element_text(color = "grey40",
														 size = 10),
	axis.text.y = element_text(color = "grey40",
														 size = 10),
	
	# ticks light grey
	axis.ticks = element_line(color = "grey91", size = .5),
	
	# Remove the grid lines 
	panel.grid = element_blank(),
	
	# Customize margin values (top, right, bottom, left)
	plot.margin = margin(10, 15, 10, 15),
	
	# white background
	plot.background  = element_rect(fill = "white", color = "white"),
	panel.background = element_rect(fill = "white", color = "white"),
	
	# Customize title appearance
	plot.title = element_text(
		color = "grey10", 
		size = rel(1.5), 
		face = "bold",
		margin = margin(t = 15)
	),
	
	# Customize subtitle appearance
	plot.subtitle = element_text(
		color = "grey30", 
		size = rel(1),
		lineheight = 1.35,
		margin = margin(t = 5, b = 15)
	),
	
	# Title and caption are going to be aligned
	plot.title.position = "plot",
	plot.caption.position = "plot",
	plot.caption = element_text(
		color = "grey50", 
		size = rel(.7),
		lineheight = .8, 
		hjust = 0,
		margin = margin(t = 20) # Large margin on the top of the caption.
	),

	# Remove legend
	legend.position = "none"
)
