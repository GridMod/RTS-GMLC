# Check if this section was selected to run in the input file
if (interval.curtailment.type){

  # Check inputs
  if ( typeof(interval.generation) == 'character' | typeof(interval.avail.cap) == 'character' ) { 
    print('INPUT ERROR: interval.generation or interval.avail.cap has errors. Cannot run this section.')
  } else if (length(re.types)==0) { 
    print('INPUT ERROR: No variable generation types specified for curtailment. Cannot run this section.')
  } else{
    # If the data doesn't exist, run the query function. 
    if ( !exists('interval.curt') ) {
      # Query curtailment data
      interval.curt = tryCatch( total_curtailment(interval.generation, interval.avail.cap), error = function(cond) { return('ERROR')})
    }

    # Check for errors in the querying function.
    if ( typeof(interval.curt)=='character' ) { 
      print('ERROR: daily_curtailment function not returning correct results.')
    } else {
      # Sum up the curtailment each interval to get average interval curtailment. Assign an interval to each row.
      avg.curt = interval.curt[,.(Curtailment=mean(Curtailment)/1000),by=.(interval,Type)]
      avg.curt[, hour := floor((interval-1)*(3600*24/intervals.per.day)/3600)]
      avg.curt[, minute := floor((interval-1)*(3600*24/intervals.per.day)/60-hour*60)]
      avg.curt[, second := floor((interval-1)*(3600*24/intervals.per.day)-hour*3600-minute*60)]
      avg.curt[, time := as.POSIXct(paste(hour,minute,second, sep=":"), format="%H:%M:%S",tz='UTC')]
      # Create plots
      p1 = line_plot(avg.curt, filters='interval', x.col='time', y.col='Curtailment', 
                     y.lab='Curtailment (GWh)', color='Type')
      p1 = p1 + scale_x_datetime(breaks = date_breaks(width = "2 hour"), 
                                 labels = date_format("%H:%M"), expand = c(0, 0)) +
           scale_color_manual("",values=gen.color)
      print(p1)
    }
  }
} else { print('Section not run according to input file.') }
