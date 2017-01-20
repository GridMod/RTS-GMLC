# Check if this section was selected run in the input file
if (region.gen.stacks) {
  if ( typeof(total.generation)=='character' ) {
    print('INPUT ERROR: total.generation has errors. Cannot run this section.')
  } else if ( typeof(total.avail.cap) == 'character' ) { 
    print('INPUT ERROR: total.avail.cap has errors. Cannot run this section.')
  } else{

    if( !exists('r.z.gen') ) {
      # Query region and zonal generation
      r.z.gen = tryCatch( region_zone_gen(total.generation, total.avail.cap), error = function(cond) { return('ERROR') } )
    }

    # Check if zonal.gen query worked and create plot of regional gen, else return an error.
    if ( typeof(r.z.gen)=='character' ) {
      print('ERROR: region_zone_gen function not returning correct results.')
    } else if ( typeof(r.load) == 'character' ) {
      print('ERROR: region_load function not returning correct results.')
    } else {
      if (length(unique(r.z.gen$Region))>length(unique(r.z.gen$Zone))) {
        region.load = r.load[!Region %in% ignore.regions, ] # Remove load data from regions being ignored
        
        setkey(region.load,Region)
        setkey(rz.unique,Region)
        region.load = rz.unique[region.load][!Zone %in% ignore.zones, ] # ignored regions removed above
        region.load = region.load[complete.cases(region.load),]
        plot.load = region.load

        x.col = 'Region'
        facet = facet_wrap(~Zone, scales = 'free', ncol=3)
      } else{
        zone.load = z.load[!Zone %in% ignore.zones, ] # Remove load data from regions being ignored

        setkey(zone.load,Zone)
        setkey(rz.unique,Zone)
        zone.load = rz.unique[zone.load][!Region %in% ignore.regions, ] # ignored zones removed above
        zone.load = zone.load[complete.cases(zone.load),]
        plot.load = zone.load

        x.col = 'Zone'
        facet = facet_wrap(~Region, scales = 'free', ncol=3)
      }
      
      # Create and plot data
      p1 <- gen_stack_plot(r.z.gen[(!Zone %in% ignore.zones & !Region %in% ignore.regions),],
                           load.data = plot.load[(!Zone %in% ignore.zones & !Region %in% ignore.regions),],
                           filters = c('Region','Zone'), x_col = x.col)
      print(p1[[1]] + facet + theme(axis.text.x = element_text(angle = -30, hjust = 0)))
    }
  }
} else { print('Section not run according to input file.') }
