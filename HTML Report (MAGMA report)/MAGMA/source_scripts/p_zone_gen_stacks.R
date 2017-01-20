if (zone.gen.stacks) {
  if ( typeof(total.generation)=='character' ) {
    print('INPUT ERROR: total.generation has errors. Cannot run this section.')
  } else if ( typeof(total.avail.cap) == 'character' ) { 
    print('INPUT ERROR: total.avail.cap has errors. Cannot run this section.')
  } else{ 
    # Query region and zonal generation
    r.z.gen = tryCatch( region_zone_gen(total.generation, total.avail.cap), 
                        error = function(cond) { return('ERROR') } )  
    # Create plot
    plot.data = gen_stack_plot(r.z.gen[!Zone %in% ignore.zones, ],
                               load.data = z.load[!Zone %in% ignore.zones, ], 
                               filters = 'Zone', x_col='Zone')
    print(plot.data[[1]] + theme(axis.text.x = element_text(angle = -30, hjust = 0)))
  }
} else { print('Section not run according to input file.') }