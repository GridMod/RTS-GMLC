# Check if this section was selected run in the input file
if (total.gen.stack){
  if ( typeof(total.generation)=='character' ) {
    print('INPUT ERROR: total.generation has errors. Cannot run this section.')
  } else if ( typeof(total.avail.cap) == 'character' ) { 
    print('INPUT ERROR: total.avail.cap has errors. Cannot run this section.')
  } else{
    # Query annual generation by type.
    yr.gen = tryCatch( gen_by_type(total.generation, total.avail.cap), 
                       error = function(cond) { return('ERROR: gen_by_type function not returning correct results.') } )
    # Create plot
    plot.data = gen_stack_plot(yr.gen, load.data = r.load)
    print(plot.data[[1]] + theme(aspect.ratio = 2.5) +
          scale_y_continuous(breaks=plot.data[[2]], limits=c(min(plot.data[[2]]), max(plot.data[[2]])), expand=c(0,0), label=comma))
  }
} else { print('Section not run according to input file.')}
