
theme_set(theme_minimal(base_family = "Lato"))

theme_update(
	axis.title.y = element_text(color = "grey40"),
	# Axes labels are grey, angled for x, and give margin for readability
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
	# Customize title appearence
	plot.title = element_text(
		color = "grey10", 
		size = 28, 
		face = "bold",
		margin = margin(t = 15)
	),
	# Customize subtitle appearence
	plot.subtitle = element_markdown(
		color = "grey30", 
		size = 16,
		lineheight = 1.35,
		margin = margin(t = 15, b = 40)
	),
	# Title and caption are going to be aligned
	plot.title.position = "plot",
	plot.caption.position = "plot",
	plot.caption = element_text(
		color = "grey30", 
		size = 13,
		lineheight = 1.2, 
		hjust = 0,
		margin = margin(t = 40) # Large margin on the top of the caption.
	),
	# Remove legend
	legend.position = "none"
)