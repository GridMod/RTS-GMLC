# Check for input errors
if ( typeof(interval.line.flow) == 'character' ) {
    print('INPUT ERROR: interval.line.flow not correct. Cannot run this section')
} else {

  if (!exists('line.flows')) {
    # Call the query function to get line flows for the lines selected in the query function.
    line.flows = tryCatch( interval_line_flows(interval.line.flow), error=function(cond) {return('ERROR: line_flows query not returning correct results.')})
  }
  
  # Check for errors in the query function. If theres an error don't continue.
  if ( typeof(line.flows)=='character' ) { 
    key.period.line.flow = 'ERROR: line_flows function not returning correct results.'
    plot.flows = 'ERROR: line_flows function not returning correct results.'
    print('ERROR: line_flows function not returning correct results.')
  } else {
  
    # From the full set of data, pull out only the data corresponding to the key period specified in the input file. 
    timediff = line.flows[,.(timediff=diff(time)), by=.(name,scenario)][,.(min(timediff))][,V1]
    for ( i in 1:n.periods ) {
      key.period.time = seq(start.end.times$start[i], start.end.times$end[i], by = timediff)
      key.period.flow = line.flows[line.flows$time %in% key.period.time, ]
      key.period.flow[, Period := period.names[i]]
      
      if ( i == 1 ) {
        line.flows.key.periods = key.period.flow
      } else {
        line.flows.key.periods = rbindlist(list(line.flows.key.periods, key.period.flow))
      }
    }
    plot.flows = line.flows.key.periods
  }
}