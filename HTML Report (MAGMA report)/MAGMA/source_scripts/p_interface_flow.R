# Check if this section was selected to run in the input file
if (interface.flow.plots) {
  if (length(interfaces)>0) {
    if ( typeof(interval.interface.flow) == 'character' ) {
      print('INPUT ERROR: interval.interface.flow not correct. Cannot run this section')
    } else { 
      # Call the query function to get interface flows for the interfaces selected in the query function.
      interface.flows = tryCatch( interval_interface_flows(interval.interface.flow), 
                                  error=function(cond) {return('ERROR: interface_flows query not returning correct results.')})
        
      # Check for errors in the query function. If theres an error don't continue.
      if ( typeof(interface.flows)=='character' ) { 
        print('ERROR: interface_flows function not returning correct results.')
      } else {
        # Get interval plots
        p1 = interface_plot(interface.flows, x_col = 'time')
        print(p1 + labs(title='Interval Flow'))
        # Aggregate interval flow data into daily flow data
        interface.flows[, day := as.POSIXlt(time)[[8]] ]
        daily.flows = interface.flows[, .(value=sum(value)), by=.(day,name)]
        daily.flows[,time:=as.POSIXct(as.character(day+1),format="%j")]
        p2 = interface_plot(daily.flows, x_col = 'time')
        if (nrow(daily.flows) > 30*length(interfaces)){
          p2 = p2 + scale_x_datetime(breaks=date_breaks(width="1 month"), 
                     labels = date_format("%b"), expand = c(0, 0))
        }
        print(p2 + labs(title='Daily Flow'))
      }
    }
  } else { print('No interfaces specified. No interface data will be shown.')}
} else { print('Section not run according to input file.') }
