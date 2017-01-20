# Check if this section was selected to run in the input file
if(reserve.stack) {
  if (typeof(total.gen.res)=='character'){
      print('INPUT ERROR: total.gen.res has errors. Cannot run this section')
    } else{
    # Query annual reserves provision by type.
    yr.res.scen = tryCatch( annual_reserves_provision(total.gen.res), error = function(cond) { return('ERROR') })
    
    if ( typeof(yr.res.scen)=='character' ) { 
      print('ERROR: annual_reserves_provision function not returning correct results.')
    } else {
      # Create plot
      plot.data = gen_stack_plot(yr.res.scen, filters = 'Reserve')
      print(plot.data[[1]] + facet_wrap(~Reserve,ncol=3,scales='free'))
    }
  }
} else { print('Section not run according to input file.') }
