
# Check if this section was selected run in the input file
if (region.gen.stacks){

  if ( typeof(total.generation)=='character' ) {
    print('INPUT ERROR: total.generation has errors. Cannot run this section.')
  } else if ( typeof(total.avail.cap) == 'character' ) { 
    print('INPUT ERROR: total.avail.cap has errors. Cannot run this section.')
  } else if ( typeof(r.load) == 'character' ) { 
    print('INPUT ERROR: r.load has errors. Cannot run this section.')
  } else{
    # Query annual generation by type.
    z.gen.scen = tryCatch( region_gen_diff(total.generation, total.avail.cap), 
                       error = function(cond) { return('ERROR: region_gen_diff function not returning correct results.') } )
    # If the query doesn't work, print an error. Else continue.
    if ( typeof(z.gen.scen)=='character' ) {
      print('ERROR: region_gen_diff function not returning correct results.')
    } else {

      # Create plot
      plot.data = gen_diff_stack_plot(z.gen.scen[!Region %in% ignore.regions, ], 
                                      r.load[!Region %in% ignore.regions, ],
                                      filters = 'Region')
      print(plot.data[[1]] + theme(aspect.ratio = 2.5/(length(db.loc)-1),axis.text.x = element_text(angle = -30, hjust = 0)) +
      	    facet_wrap(~Region, scales = 'free', ncol=3) +
            scale_y_continuous(breaks=plot.data[[2]], limits=c(min(plot.data[[2]]), max(plot.data[[2]])), expand=c(0,0), label=comma))
    }
  }

} else { print('Section not run according to input file.')}
