# Check if this section was selected to run in the input file
if (interval.curtailment){
  
  # Check inputs
  if ( typeof(interval.generation) == 'character' ) { 
    print('INPUT ERROR: interval.generation has errors. Cannot run this section.')
  } else if ( typeof(interval.avail.cap) == 'character' ) { 
    print('INPUT ERROR: interval.avail.cap has errors. Cannot run this section.')
  } else{
    # Query curtailment data
    interval.curt = tryCatch( total_curtailment(interval.generation, interval.avail.cap), error = function(cond) { return('ERROR')})
    # Check for errors in the querying function.
    if ( typeof(interval.curt)=='character' ) { 
      print('ERROR: daily_curtailment function not returning correct results.')
    } else {

      # Sum up the curtailment each interval to get average interval curtailment. Assign an interval to each row.
      avg.curt = interval.curt[,.(Curtailment_GWh=sum(Curtailment)/1000),by=.(scenario,interval)]
      avg.curt[, hour := floor((interval-1)*(3600*24/intervals.per.day)/3600)]
      avg.curt[, minute := floor((interval-1)*(3600*24/intervals.per.day)/60-hour*60)]
      avg.curt[, second := floor((interval-1)*(3600*24/intervals.per.day)-hour*3600-minute*60)]
      avg.curt[, time := as.POSIXct(paste(hour,minute,second, sep=":"),'UTC', format="%H:%M:%S")]
      
      p1 = line_plot(avg.curt, filters=c('scenario','time'), x.col='time', y.col='Curtailment_GWh',
                     y.lab='Curtailment (GWh)', color='scenario')
      p1 = p1 + scale_color_brewer(palette='Set1') +
           scale_x_datetime(breaks = date_breaks(width = "2 hour"), labels = date_format("%H:%M"), 
                            expand = c(0, 0), timezone='UTC')
      print(p1)
      
      # Calculate diffs
      avg.curt[, scenario:=as.character(scenario)]
      diff.curt = avg.curt[, .(scenario, Curtailment_GWh = Curtailment_GWh - Curtailment_GWh[scenario==ref.scenario]), by=.(time)]
      
      p2 = line_plot(diff.curt, filters=c('scenario','time'), x.col='time', y.col='Curtailment_GWh',
                     y.lab='Difference in Curtailment (GWh)', color='scenario')
      p2 = p2 + scale_color_brewer(palette='Set1') +
           scale_x_datetime(breaks = date_breaks(width = "2 hour"), labels = date_format("%H:%M"), 
                            expand = c(0, 0), timezone='UTC')
      print(p2)
    }
  }  
} else { print('Section not run according to input file.') }
