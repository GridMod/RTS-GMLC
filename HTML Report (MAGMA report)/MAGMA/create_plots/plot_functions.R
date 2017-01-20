pretty_axes <- function(data1, data2=NULL, filters=NULL, col='value'){
  # Function to create well spaced axes for plots. 
  # Takes maximum of both data sets (if two are provided)
  # and nicely spaces axes
  # Inputs:
  #   data1 - data used for plot
  #   data2 - optional second set of data
  #   filters - columns to aggregate over
  
  # Aggregate data
  if(is.null(filters)){
    sum1 = data1[, .(value = sum(get(col))) ]  
    if (!is.null(data2)){
      sum2 = data2[, .(value = sum(get(col))) ]
      sum1 = rbindlist(list(sum1,sum2))
    }
  }else{
    sum1 = data1[, .(value = sum(get(col))), by=filters]  
    if (!is.null(data2)){
      sum2 = data2[, .(value = sum(get(col))), by=filters]
      sum1 = rbindlist(list(sum1,sum2))
    }
  }
  
  # This automatically creates the y-axis scaling
  py = pretty(c(sum1$value,0), n = 5, min.n = 3)
  #seq.py = seq(min(c(sum1$value,0)), py[length(py)], 10*(py[2]-py[1]))
  return(py)
}


gen_stack_plot <- function(gen.data, load.data, filters=NULL, x_col='scenario'){
  # Creates total generation stack plot
  # Assumes data has been processed according to XXXX
  # filters are other things you might want to plot over
  # Returns plot handle for ggplot, can add things like facet to that
  
  # reorder the levels of Type to plot them in order
  gen.data[, Type := factor(Type, levels = c(gen.order))]
  if(any(is.na(gen.data$Type))) print("ERROR:gen.order doesn't contain all of the gen types: FIX YOUR INPUT DATA CSV")
  
  if(is.null(filters)){
    agg.filters = c("scenario","Type")
  }else{
    agg.filters = c(c("scenario","Type"),filters)
  }
  load.filters = agg.filters[agg.filters!='Type']
  
  # Group by type and convert GWh to TWh
  gen.plot = gen.data[, .(TWh = sum(GWh)/1000), by=agg.filters]
  setorder(gen.plot,Type)
  
  tot.load = load.data[, .(TWh = sum(value)/1000), by=load.filters]
  tot.load[, variable:='Load']
  
  seq.py = pretty_axes(gen.plot[, value:=TWh ], tot.load[, value:=TWh ], filters=load.filters)

  # Create plot
  p1 = ggplot() +
    geom_bar(data = gen.plot, aes_string(x = x_col, y = 'TWh', fill='Type'), stat="identity", position="stack" ) +
    geom_errorbar(data = tot.load, aes_string(x = x_col, y='TWh', ymin='TWh', ymax='TWh', color='variable'), 
                  size=0.45, linetype='longdash')+
    scale_color_manual(name='', values=c("grey40"), labels=c("Load"))+
    scale_fill_manual('', values = gen.color, limits=rev(gen.order))+     
    labs(y="Generation (TWh)", x=NULL)+
    guides(color = guide_legend(order=1), fill = guide_legend(order=2))+
    theme(    legend.key =      element_rect(color="grey80", size = 0.8),
              legend.key.size = grid::unit(1.0, "lines"),
              legend.text =     element_text(size=text.plot),
              legend.title =    element_blank(),
              #                         text = element_text(family="Arial"),
              axis.text =       element_text(size=text.plot/1.2),
              # axis.text.x =   element_text(face=2),
              axis.title =      element_text(size=text.plot, face=2),
              axis.title.y =    element_text(vjust=1.2),
              panel.margin =    unit(1.5, "lines"))
  
  # Add something for if load only ??

  return(list(p1,seq.py))
}


gen_diff_stack_plot <- function(gen.data, load.data, filters=NULL){
  # Creates a difference in total generation stack plot
  # Assumes data has been processed according to XXX
  # Filters are other things you might want to plot over
  # Returns the plot handle, so you can add additional things to that if desired

  gen.data[, Type := factor(Type, levels = c(gen.order))]

  # Create list of filters to separate data by
  if(is.null(filters)){
    agg.filters = c("scenario","Type")
  }else{
    agg.filters = c(c("scenario","Type"),filters)
  }
  load.filters = agg.filters[agg.filters!='Type']
  load.diff.filters = load.filters[load.filters!='scenario']

  # Separate out the positive and negative halves for easier plotting
  # also convert to TWh and filter out ignored regions
  dat.pos = gen.data[GWh>=0 & scenario!=ref.scenario, 
                        .(TWh = sum(GWh)/1000), by=agg.filters]
  dat.neg = gen.data[GWh<0 & scenario!=ref.scenario, 
                        .(TWh = sum(GWh)/1000), by=agg.filters]
  setorder(dat.pos,Type)
  setorder(dat.neg,Type)

  # gen.sum is just used to set the maximum height on the plot, see pretty() fcn below
  gen.sum = rbindlist(list(dat.pos[, .(TWh = sum(TWh)), by=load.filters], 
                           dat.neg[, .(TWh = sum(TWh)), by=load.filters]))  
  seq.py = pretty_axes(gen.sum)

  # Calculate difference in load
  load.scen = load.data[, .(value = sum(value)/1000), by=load.filters]
  load.scen[, scenario:=as.character(scenario)]
  diff.load = load.scen[, .(scenario, TWh = value-value[scenario==ref.scenario]), by=load.diff.filters]
  diff.load = diff.load[scenario!=ref.scenario, ]

  # Create plot
  p1 = ggplot() +
          geom_bar(data = dat.pos, aes(x = scenario, y = TWh, fill=Type), stat="identity", position="stack" ) +
          geom_bar(data = dat.neg, aes(x = scenario, y = TWh, fill=Type), stat="identity", position="stack" ) +
          geom_errorbar(data = diff.load, aes(x = scenario, ymin=TWh, ymax=TWh, color='load'), 
                        size=0.45, linetype='longdash')+
          scale_fill_manual(values = gen.color, guide = guide_legend(reverse = TRUE))+
          scale_color_manual(name='', values=c("load"="grey40"), labels=c("Load"))+
          labs(y="Difference in Generation (TWh)", x=NULL)+
          # scale_y_continuous(breaks=seq.py, expand=c(0,0), label=comma)+
          guides(color = guide_legend(order=1), fill = guide_legend(order=2, reverse=TRUE))+
               theme(    legend.key =      element_rect(color="grey80", size = 0.8), 
                         legend.key.size = grid::unit(1.0, "lines"),
                         legend.text =     element_text(size=text.plot), 
                         legend.title =    element_blank(),
                 #                         text = element_text(family="Arial"),
                         axis.text =       element_text(size=text.plot/1.2), 
                         axis.text.x =     element_text(angle=-20, hjust=0),
                         axis.title =      element_text(size=text.plot, face=2), 
                         axis.title.y =    element_text(vjust=1.2), 
                         panel.margin =    unit(1.5, "lines"),
                         aspect.ratio =    2.5/length(unique(dat.pos$scenario)))
  return(list(p1,seq.py))
}


dispatch_plot <- function(gen.data, load.data){
  # Make dispatch plot

  # Get axis limits
  gen.data[, value:=value/1000]
  load.data[, value:=value/1000]
  seq.py.t = pretty_axes(gen.data, load.data, filters = 'time')

  # Plot
  p1 = ggplot(gen.data, aes(time, value, group=Type, fill=Type, order=as.numeric(Type)), color="black")+
          geom_area(color=NA)+
          geom_line(position="stack", size=0.3)+
          labs(y="Generation (GWh)", x=NULL)+
          geom_line(data=load.data, linetype="longdash", aes(color="load"),size=0.8)+
          scale_fill_manual("",values = gen.color, limits=rev(gen.order))+
          scale_color_manual(name='', values=c("load"="grey40"), labels=c("Load"))+
          scale_x_datetime(breaks = date_breaks(width = "1 day"), labels = date_format("%b %d\n%I %p"), expand = c(0, 0))+
          scale_y_continuous(breaks=seq.py.t, limits=c(0, max(seq.py.t)), expand=c(0,0))+
          theme(legend.key = element_rect(color = "grey80", size = 0.4),
                legend.key.size = grid::unit(0.9, "lines"), 
                legend.text = element_text(size=text.plot/1.1),
                strip.text=element_text(size=rel(0.7)),
                axis.text=element_text(size=text.plot/1.2), 
                axis.title=element_text(size=text.plot, face=2), 
                axis.title.x=element_text(vjust=-0.3),
                panel.grid.major = element_line(colour = "grey85"),
                panel.grid.minor = element_line(colour = "grey93"),
                aspect.ratio = 0.5)

  return(p1)
}


interface_plot <- function(flow.data, x_col = 'time'){
  # Make plots of interface flows

  flow.data[, name := factor(name, levels = interfaces)]
  flow.data[, value := value/1000]

  # Create plot of interval zone interface flow
  p1 = ggplot(flow.data, aes_string(x=x_col, y='value', color='name', group='name'))+
         geom_line(size=1.2)+
         geom_hline(yintercept=0, color="black", size=0.3)+
         scale_color_manual("", values = scen.pal)+
         labs(y="Flow (GW)", x = '', title='Interval Flow')+
         theme(legend.key = element_rect(NULL),
               legend.text = element_text(size=text.plot),
               text=element_text(size=text.plot),
               strip.text=element_text(face="bold", size=rel(1)),
               axis.text=element_text(face=2, size=text.plot/1),
               axis.title=element_text(size=text.plot, face=2.3),
               # legend.position=c(0.80, 0.12),
               panel.margin = unit(0.35, "lines"))
  return(p1)
}


price_duration_curve <- function(price.data, filters, color=NULL){
  # Create plots of price duration curves
  price.data[, interval := rank(-value,ties.method="random"), by=filters]
  setnames(price.data,'name','area')

  # Create Plot
  p.1 = ggplot(price.data)+
           geom_line(aes(x=interval, y=value, color=color), size=0.8)+  
           labs(y="Price ($/MWh)", x='Hours of Year')+
           theme( legend.key =       element_rect(color = "grey80", size = 0.4),
                  legend.key.size =  grid::unit(0.9, "lines"), 
                  legend.text =      element_text(size=text.plot/1.1),
                  strip.text =       element_text(size=rel(0.7)),
                  axis.text =        element_text(size=text.plot/1.2), 
                  axis.title =       element_text(size=text.plot, face=2), 
                  axis.title.x =     element_text(vjust=-0.3),
                  panel.grid.major = element_line(colour = "grey85"),
                  panel.grid.minor = element_line(colour = "grey93"),
                  aspect.ratio =     0.65,
                  panel.margin =     unit(1.0, "lines") )

  return(p.1)
}


line_plot <- function(plot.data, filters, x.col, y.col, y.lab, color=NULL){
  # Create line plots over time

  seq.py = pretty_axes(plot.data, filters = filters, col = y.col)
  # Create plot
  p.1 = ggplot(plot.data)+
           geom_line(aes_string(x=x.col, y=y.col, color=color), size = 2)+    
           labs(y=y.lab, x=NULL)+
           scale_y_continuous(breaks=seq.py, limits=c(0, max(seq.py)), expand=c(0,0))+
           theme( legend.key =       element_rect(color = "grey80", size = 0.4),
                  legend.key.size =  grid::unit(0.9, "lines"), 
                  legend.text =      element_text(size=text.plot/1.1),
                  strip.text =       element_text(size=rel(0.7)),
                  axis.text =        element_text(size=text.plot/1.2), 
                  axis.title =       element_text(size=text.plot, face=2), 
                  axis.title.x =     element_text(vjust=-0.3),
                  panel.grid.major = element_line(colour = "grey85"),
                  panel.grid.minor = element_line(colour = "grey93"),
                  aspect.ratio =     0.5,
                  panel.margin =     unit(1.0, "lines") )
  return(p.1)
}

