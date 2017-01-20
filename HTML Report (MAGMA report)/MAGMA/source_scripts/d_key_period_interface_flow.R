# Check for input errors
if ( typeof(interval.interface.flow) == 'character' ) {
    print('INPUT ERROR: interval.interface.flow not correct. Cannot run this section')
} else {

  if (!exists('interface.flows')) {
    # Call the query function to get interface flows for the interfaces selected in the query function.
    interface.flows = tryCatch( interval_interface_flows(interval.interface.flow), error=function(cond) {return('ERROR: interface_flows query not returning correct results.')})
  }
  
  # Check for errors in the query function. If theres an error don't continue.
  if ( typeof(interface.flows)=='character' ) { 
    key.period.interface.flow = 'ERROR: interface_flows function not returning correct results.'
    plot.flows = 'ERROR: interface_flows function not returning correct results.'
    print('ERROR: interface_flows function not returning correct results.')
  } else {
  
    # From the full set of data, pull out only the data corresponding to the key period specified in the input file. 
    setorder(interface.flows,scenario,name,time)
    timediff = interface.flows[,.(timediff=diff(time)), by=.(name,scenario)][,.(min(timediff))][,V1]
    for ( i in 1:n.periods ) {
      key.period.time = seq(start.end.times$start[i], start.end.times$end[i], by = timediff)
      key.period.flow = interface.flows[interface.flows$time %in% key.period.time, ]
      key.period.flow[, Period := period.names[i]]
      
      if ( i == 1 ) {
        interface.flows.key.periods = key.period.flow
      } else {
        interface.flows.key.periods = rbindlist(list(interface.flows.key.periods, key.period.flow))
      }
    }
    plot.flows = interface.flows.key.periods
  }
}