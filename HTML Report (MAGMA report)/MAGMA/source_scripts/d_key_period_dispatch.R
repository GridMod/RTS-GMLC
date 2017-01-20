# Check to make sure relevant data exists
if ( typeof(interval.region.load)=='character' ) {
    print('INPUT ERROR: interval.region.load has errors. Cannot run this section.')
#  } else if ( typeof(interval.zone.load) == 'character' ) { 
#    print('INPUT ERROR: interval.zone.load has errors. Cannot run this section.')
  } else if ( typeof(interval.generation) == 'character' ) { 
    print('INPUT ERROR: interval.generation has errors. Cannot run this section.')
  } else if ( typeof(interval.avail.cap) == 'character' ) { 
    print('INPUT ERROR: interval.avail.cap has errors. Cannot run this section.')
  } else{
    # Query interval generation by type from interval data
    int.gen = tryCatch( interval_generation(interval.region.load, interval.zone.load, interval.generation, interval.avail.cap), error = function(cond) { return('ERROR') } )

    # If the query doesn't work, return an error. 
    if ( typeof(int.gen)=='character' ) { 
      key.period.gen = 'ERROR: interval_generation function not returning correct results.'
      print('ERROR: interval_generation function not returning correct results.')
    } else {
      
      # From the full year of data, pull out only the data corresponding to the key periods specified in the input file. 
      timediff = int.gen[,.(timediff=diff(time)),by=.(scenario,Region,Type,Zone)][,.(min(timediff))][,V1]
      for ( i in 1:n.periods ) {
        key.period.time = seq(start.end.times[i,start], start.end.times[i,end], 
                              by = timediff)
        key.period.gen = int.gen[int.gen$time %in% key.period.time]
        key.period.gen[, Period := period.names[i]]
        
        if ( i == 1 ) {
          int.gen.key.periods = key.period.gen
        } else {
          int.gen.key.periods = rbindlist(list(int.gen.key.periods, key.period.gen))
        }
      }

      # Rearrange data for plotting
      key.period.gen = int.gen.key.periods 
      
      # Rearrange factor levels for plotting.
      key.period.gen[, Type := factor(Type, levels = c(gen.order, 'Load'))]
      
      # Pull out just generation data
      gen.type = key.period.gen[Type != 'Load', ]
      gen.type[value<0, value:=0]
      gen.type[, Period := ordered(Period, levels = period.names)]
      
      # Pull out just load data
      gen.load = key.period.gen[Type == 'Load', ]

      # ###############################################################################
      # Region Data
      # ###############################################################################  
        
      gen.type.region = gen.type[,.(value=sum(value,na.rm=TRUE)),by=.(time,scenario,Region,Type,Period)]
      gen.load.region = gen.load[,.(value=sum(value,na.rm=TRUE)),by=.(time,scenario,Region,Type,Period)] 
      setorder(gen.type.region, Type)
      setorder(gen.load.region, Type)
      
      # ###############################################################################
      # Zone Data
      # ###############################################################################   
      
      gen.type.zone = gen.type[,.(value=sum(value,na.rm=TRUE)),by=.(time,scenario,Zone,Type,Period)]
      gen.load.zone = gen.load[,.(value=sum(value,na.rm=TRUE)),by=.(time,scenario,Zone,Type,Period)]  
      setorder(gen.type.zone, Type)
      setorder(gen.load.zone, Type)
      
      # ###############################################################################
      # Total database Data
      # ###############################################################################   
      
      gen.type.total = gen.type[,.(value=sum(value,na.rm=TRUE)),by=.(time,scenario,Type,Period)]
      gen.load.total = gen.load[,.(value=sum(value,na.rm=TRUE)),by=.(time,scenario,Type,Period)]
      setorder(gen.type.total, Type)
      setorder(gen.load.total, Type)

    }
}