# Check if this section was selected to run in the input file
if (revenue.plots) {
  
  # Check inputs
  if ( typeof(interval.generation) == 'character' ) { 
    print('INPUT ERROR: interval.generation has errors. Cannot run this section.')
  } else if ( typeof(interval.region.price) == 'character' ) { 
    print('INPUT ERROR: interval.region.price has errors. Cannot run this section.')
  } else if ( typeof(interval.reserve.price) == 'character' ) { 
    print('INPUT ERROR: interval.reserve.price has errors. Cannot run this section.')
  } else if ( typeof(interval.gen.reserve.provision) == 'character' ) { 
    print('INPUT ERROR: interval.gen.reserve.provision has errors. Cannot run this section.')
  } else{
    # Query curtailment data
    r.z.revenue = tryCatch( revenue_calculator(interval.generation, interval.region.price,
                                               interval.gen.reserve.provision,interval.reserve.price), 
                            error = function(cond) { return('ERROR')})
    
    # If there is a problem with the query return an error.
    if ( typeof(r.z.revenue)=='character' ) { 
      print('ERROR: revenue_calculator function not returning correct results.')
    } else {
      total.revenue = r.z.revenue[, .(revenue=sum(revenue)), by=.(scenario,Type,Revenue_Type)]
      
      p = ggplot(total.revenue)+
        geom_bar(aes(scenario,revenue/10^6,fill=Revenue_Type), stat='identity')+
        ylab("Total Revenue, Million $") + xlab("Scenario")+
        theme(axis.text.x = element_text(angle = -30, hjust = 0))+
        scale_fill_manual(values=c('dodgerblue2','firebrick1'),name='Revenue Type')+
        facet_wrap(~Type,ncol=3,scales='free')
      print(p)
    }
  }
} else { print('Section not run according to input file.') }