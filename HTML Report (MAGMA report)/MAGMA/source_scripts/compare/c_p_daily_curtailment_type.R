# Check if this section was selected to run in the input file
if (daily.curtailment) {
  
  # Check inputs
  if ( typeof(interval.generation) == 'character' ) { 
    print('INPUT ERROR: interval.generation has errors. Cannot run this section.')
  } else if ( typeof(interval.avail.cap) == 'character' ) { 
    print('INPUT ERROR: interval.avail.cap has errors. Cannot run this section.')
  } else{
    # Query curtailment data
    interval.curt = tryCatch( total_curtailment(interval.generation, interval.avail.cap), error = function(cond) { return('ERROR')})
    # If there is a problem with the query return an error.
    if ( typeof(interval.curt)=='character' ) { 
      print('ERROR: daily_curtailment function not returning correct results.')
    } else {
      
      # Calculate average curtailment for each day 
      daily.curt = interval.curt[,.(Curtailment = mean(Curtailment)),by=.(scenario,day,year,Type)] 
      daily.curt[, timeformat := sprintf("%d %d", day+1, year)]
      daily.curt[, time := as.POSIXct(timeformat,format='%j %Y', tz='UTC')] # Add time column
      
      p1 = line_plot(daily.curt, filters=c('scenario','time','Type'), x.col='time', 
                     y.col='Curtailment', y.lab='Curtailment (MWh)', color='scenario', linesize=1.2)
      if (nrow(daily.curt)>30) {
        p1 = p1 + scale_x_datetime(breaks = date_breaks(width = "1 month"), 
                                   labels = date_format("%b"), expand = c(0, 0)) 
      }
      print(p1 + facet_wrap(~Type,ncol=1,scales='free') + scale_color_brewer(palette='Set1'))
      
      # Calculate diffs
      daily.curt[, scenario:=as.character(scenario)]
      diff.daily.curt = daily.curt[, .(scenario, Curtailment = Curtailment - Curtailment[scenario==ref.scenario]), 
                                   by=.(time,Type)]
      
      p2 = line_plot(diff.daily.curt, filters=c('scenario','time','Type'), x.col='time',
                     y.col='Curtailment', y.lab='Difference in Curtailment (MWh)', color='scenario', linesize=1.2)
      if (nrow(daily.curt)>30) {
        p2 = p2 + scale_x_datetime(breaks = date_breaks(width = "1 month"), 
                                   labels = date_format("%b"), expand = c(0, 0))
      }
      print(p2 + facet_wrap(~Type,ncol=1,scales='free') + scale_color_brewer(palette='Set1'))
    }
  }
} else { print('Section not run according to input file.') }
