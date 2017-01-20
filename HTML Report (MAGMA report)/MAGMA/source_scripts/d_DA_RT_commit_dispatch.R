# Call query functions to get committed capacity (day ahead) and available capacity in the real time.
committed.cap = tryCatch( cap_committed(interval.da.committment), error = function(cond) { return('ERROR')})
avail.cap.rt = tryCatch( cap_committed(interval.avail.cap), error = function(cond) { return('ERROR')})

# Check to see if interval generation data already exists. If it doesn't call that query function.
if( !exists('int.gen') ) {
  int.gen = tryCatch( interval_generation(interval.region.load, interval.zone.load, interval.generation, interval.avail.cap), error = function(cond) { return('ERROR') } )
}

# If there is a problem with the query return an error, else create the plots.
if ( typeof(committed.cap)=='character' | typeof(int.gen)=='character' | typeof(avail.cap.rt)=='character' ) { 
  print('ERROR: daily_curtailment or cap_committed function not returning correct results.')
} else {
  
  # Remove unneccessary data values and rename the data for plotting. This is interval generation data in the real time.
  da.rt.data = int.gen[!Type%in%c("Curtailment","Load"), ]
  
  # Prep data for merging
  setnames(avail.cap.rt,'committed.cap','value')
  setnames(committed.cap,'committed.cap','value')
  da.rt.data[, data:='RT Generation']
  avail.cap.rt[, data:='RT Committed Capacity']
  committed.cap[, data:='DA Committed Capacity or \nForecasted Generation']
  
  # Add the day ahead capacity and real time capacity to the real time generation.
  da.rt.data = rbindlist(list(da.rt.data,avail.cap.rt,committed.cap),use.names=TRUE) 
  
  # Only pull out data for the time spans that were requested in the input file. 
  timediff = da.rt.data[data=='RT Generation',
                        .(timediff=diff(time)),
                        by=.(scenario,Region,Type,Zone)][,.(min(timediff))][,V1]
  for ( i in 1:n.periods ) {
    key.period.time = seq(start.end.times[i,start], start.end.times[i,end], 
                          by = timediff)
    plot.data = da.rt.data[da.rt.data$time %in% key.period.time, ]
    plot.data[, Period := period.names[i]]
    
    if ( i == 1 ) {
      plot.data.all = plot.data
    } else {
      plot.data.all = rbindlist(list(plot.data.all, plot.data))
    }
  }  
  
}
