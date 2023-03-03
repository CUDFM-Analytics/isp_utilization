
fn_plot_q <- function(dat, 
											xlabels,
											labx, laby, 
											title, subtitle, caption){
	
	plot <- ggplot(
		dat,
		aes(row, n, group = flag)
	)+
		# vertical gridlines
		geom_vline(
			xintercept = seq(1,12,by = 1),
			color = "grey91",
			size = .4
		)+
		# dotted line for March 2020: 
		geom_vline(
			aes(xintercept = 4),
			color = "grey40",
			linetype = "dotted",
			size = .5
		)+
		# horizontal gridlines
		geom_segment(
			data = tibble(y = seq(0,1400000, 100000), 
										x1 = 1, x2 = 12),
			aes(x=x1, xend = x2, y = y, yend = y),
			inherit.aes = FALSE,
			color = "grey91",
			size = .4
		)+
		# data points lines
		geom_line(
			aes(color = flag))+
		# add the March text annotation 
		annotate(
			"text", x = 4, y = 1305000,
			label = "March\n2020",
			family = "Lato",
			size = 4,
			color = "grey20",
			hjust = 1.1,
			lineheight = .8
		) + 
		# add values at the end of the graph, without grid lines
		geom_text_repel(
			aes(color = flag,
					label = label_max),
			family = "Lato",
			fontface = "bold",
			size = 4,
			direction = "y",
			xlim = c(12.4, NA),
			hjust = 0,
			segment.size = .7,
			segment.alpha = .5, 
			segment.linetype = "dotted",
			box.padding = .4,
			segment.curvature = -0.1,
			segment.ncp = 3,
			segment.angle = 20,
			lineheight = .8
		) + 
		coord_cartesian(
			clip = "off",
			ylim = c(0,1400000)
		)+
		scale_x_continuous(
			expand = c(0,0),
			limits = c(1,16),
			breaks = xlabels$row,
			labels = xlabels$x_txt
		)+
		scale_y_continuous(
			labels = scales::comma,
			expand = c(0,0),
			breaks = seq(0,1400000, 100000)
		)+
		labs(
			y = labx,
			x = laby,
			title = title, 
			subtitle = subtitle,
			caption = caption
		)+
		scale_color_jama()
	
	return(plot)
}
