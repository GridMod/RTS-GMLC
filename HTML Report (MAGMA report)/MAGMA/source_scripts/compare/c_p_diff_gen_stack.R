# Check if this section was selected run in the input file
if (total.gen.stack){

  if ( typeof(total.generation)=='character' ) {
    print('INPUT ERROR: total.generation has errors. Cannot run this section.')
  } else if ( typeof(total.avail.cap) == 'character' ) { 
    print('INPUT ERROR: total.avail.cap has errors. Cannot run this section.')
  } else{
    # Query annual generation by type.
    yr.gen.scen = tryCatch( gen_by_type(total.generation, total.avail.cap), 
                       error = function(cond) { return('ERROR: gen_by_type function not returning correct results.') } )
    # If the query doesn't work, print an error. Else continue.
    if ( typeof(yr.gen.scen)=='character' ) {
      print('ERROR: gen_by_type function not returning correct results.')
    } else {
      # Calc diffs
      yr.gen.scen[,GWh:=GWh-GWh[scenario==ref.scenario],by='Type']
      
      # Create plot
      plot.data = gen_diff_stack_plot(yr.gen.scen, load.data = r.load)
      print(plot.data[[1]] + theme(aspect.ratio = 2.5/(length(db.loc)-1),
                                   axis.text.x = element_text(angle = -30, hjust = 0)) +
            scale_y_continuous(breaks=plot.data[[2]], 
                               limits=c(min(plot.data[[2]]), max(plot.data[[2]])), 
                               expand=c(0,0), label=comma))
    }
  }

} else { print('Section not run according to input file.')}
