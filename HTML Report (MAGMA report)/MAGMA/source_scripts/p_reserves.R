# Check if this section was selected to run in the input file
if(reserves.plots) {
  if (typeof(interval.reserve.provision)=='character'){
      print('INPUT ERROR: interval.reserve.provision has errors. Cannot run this section')
    } else{
    # Reserves interval data query
    r = tryCatch( interval_reserves(interval.reserve.provision), error = function(cond) { return('ERROR') })
    
    if ( typeof(r)=='character' ) { 
      print('ERROR: interval_reserves function not returning correct results.')
    } else {
      
      # Average reserve provision at each interval
      int.avg = r[, .(Provision = mean(provision)/1000), by = .(interval)]
      int.avg[, hour := floor((interval-1)*(3600*24/intervals.per.day)/3600)]
      int.avg[, minute := floor(((interval-1)*(3600*24/intervals.per.day)/3600-hour)/60)]
      int.avg[, second := floor((((interval-1)*(3600*24/intervals.per.day)/3600-hour)/60-minute)/60)]
      int.avg[, time := as.POSIXct(paste(hour,minute,second, sep=":"), format="%H:%M:%S",tz='UTC')]
    
      # Creating interval reserves provisions plot
      p.1 = line_plot(int.avg, 'interval','time', 'Provision', 'Reserve Provision (GWh)')
      p.1 = p.1 + scale_x_datetime(breaks = date_breaks(width = "2 hour"), 
                                   labels = date_format("%H:%M"), expand = c(0, 0))
    
      # Calculating the daily hourly average
      dy.avg = r[, .(Provision = mean(provision)/1000), by = .(day)]
      dy.avg[, time := as.POSIXct(as.character(day),format='%j')]
    
      # Creating average daily reserves provisions plot
      p.2 = line_plot(dy.avg, 'day','time', 'Provision', 'Reserve Provision (GWh)')
      if (nrow(dy.avg) > 30) {
        p.2 = p.2 + scale_x_datetime(breaks = date_breaks(width = "1 month"), 
                                     labels = date_format("%b %d"), expand = c(0, 0))
      }
      print(p.1)
      print(p.2)
    }
  }
} else { print('Section not run according to input file.') }
