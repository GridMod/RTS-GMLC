# Check if this section was selected to run in the input file
if(price.duration.curve) {

  # If there is a problem with the query return an error, else create the plots.
  if ( typeof(interval.region.price)=='character' ) { 
      print('ERROR: interval.region.price not correct. Cannot run this section')
    } else {

      # Create plot
      p1 = price_duration_curve(interval.region.price[!Region %in% ignore.regions & property == 'Price', ],
                                filters = c('property','Region'), color='Region')
      p1 = p1 + theme(aspect.ratio = 0.65)
      # Create plot with slightly different y-axis limit.
      p2 = p1 + coord_cartesian(ylim=c(0,200))
           
      print(p1)
      print(p2)
  }

} else { print('Section not run according to input file.') }
