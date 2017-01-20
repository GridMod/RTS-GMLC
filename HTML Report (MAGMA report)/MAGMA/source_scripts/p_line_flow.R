# Check if this section was selected to run in the input file
if (line.flow.plots) {
  if (length(lines)>0) {
    if ( typeof(interval.line.flow) == 'character' ) {
      print('INPUT ERROR: interval.line.flow not correct. Cannot run this section')
    } else { 
      # Call the query function to get line flows for the lines selected in the query function.
      line.flows = tryCatch( interval_line_flows(interval.line.flow), 
                                  error=function(cond) {return('ERROR: line_flows query not returning correct results.')})
        
      # Check for errors in the query function. If theres an error don't continue.
      if ( typeof(line.flows)=='character' ) { 
        print('ERROR: line_flows function not returning correct results.')
      } else {
        # Get interval plots
        p1 = interface_plot(line.flows, x_col = 'time',interfaces = lines, color = 'name')
        print(p1 + labs(title='Interval Flow'))
        # Aggregate interval flow data into daily flow data
        line.flows[, day := as.POSIXlt(time)[[8]] ]
        daily.flows = line.flows[, .(value=sum(value)), by=.(day,name)]
        daily.flows[,time:=as.POSIXct(as.character(day+1),format="%j")]
        p2 = interface_plot(daily.flows, x_col = 'time',interfaces = lines, color = 'name')
        if (nrow(daily.flows) > 30*length(lines)){
          p2 = p2 + scale_x_datetime(breaks=date_breaks(width="1 month"), 
                     labels = date_format("%b"), expand = c(0, 0))
        }
        print(p2 + labs(title='Daily Flow'))
      }
    }
  } else { print('No lines specified. No line data will be shown.')}
} else { print('Section not run according to input file.') }
