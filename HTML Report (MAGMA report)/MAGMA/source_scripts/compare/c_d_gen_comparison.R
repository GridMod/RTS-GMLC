# Check to see if interval generation data already exists. If it doesn't call that query function.
if( !exists('int.gen') ) {
  int.gen = tryCatch( interval_generation(interval.region.load, interval.zone.load, interval.generation, interval.avail.cap), error = function(cond) { return('ERROR') } )
}

# If there is a problem with the query return an error, else create the plots.
if ( typeof(int.gen)=='character' ) { 
  print('ERROR: interval_generation function not returning correct results.')
} else {
  
  # Remove unneccessary data values and rename the data for plotting. This is interval generation data in the real time.
  gen.compare.data = int.gen[Type%in%da.rt.types, ]
  
  # Only pull out data for the time spans that were requested in the input file. 
  timediff = gen.compare.data[,.(timediff=diff(time)),by=.(scenario,Region,Type,Zone)][,.(min(timediff))][,V1]
  for ( i in 1:n.periods ) {
    key.period.time = seq(start.end.times[i,start], start.end.times[i,end], 
                          by = timediff)
    plot.data = gen.compare.data[gen.compare.data$time %in% key.period.time, ]
    plot.data[, Period := period.names[i]]
    
    if ( i == 1 ) {
      compare.plot.data = plot.data
    } else {
      compare.plot.data = rbindlist(list(compare.plot.data, plot.data))
    }
  }  
  
}
