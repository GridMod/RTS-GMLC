# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# This file has all the actual plexos database queries (from the rplexos R package)
# All queries are dependent on which chunks have been selected to run.
# See the query_functions.R file to see how each property is being queried.
# If a value is not returned properly, a warning is issued for that value
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Annual queries
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ( total.gen.stack | region.gen.stacks | zone.gen.stacks |  
     individual.region.stacks.log | capacity.factor.table | region.zone.gen.table | annual.generation.table ){
  # Total generation 
  total.generation     = tryCatch( total_generation(db), error = function(cond) { return('ERROR') } ) 
  if (typeof(total.generation)=='character') { message('\nMissing total generator generation data from solution .db file.')}
}

if ( total.gen.stack | region.gen.stacks | zone.gen.stacks | 
     individual.region.stacks.log | annual.generation.table | region.zone.gen.table ) {
  # Total available energy
  total.avail.cap      = tryCatch( total_avail_cap(db), error = function(cond) { return('ERROR') } ) 
  if (typeof(total.avail.cap)=='character') { message('\nMissing total generator available capacity data from solution .db file.')}
}

if ( annual.cost.table ) {
  # Total emissions cost
  total.emissions.cost = tryCatch( total_emissions(db), error = function(cond) { return('ERROR') } ) 
  if (typeof(total.emissions.cost)=='character') { message('\nMissing total generator emissions cost data from solution .db file.')}
  # Total fuel cost
  total.fuel.cost      = tryCatch( total_fuel(db), error = function(cond) { return('ERROR') } ) 
  if (typeof(total.fuel.cost)=='character') { message('\nMissing total generator fuel cost data from solution .db file.')}
  # Total start and shutdown cost
  total.ss.cost        = tryCatch( total_ss(db), error = function(cond) { return('ERROR') } ) 
  if (typeof(total.ss.cost)=='character') { message('\nMissing total generator start and shutdown cost data from solution .db file.')}
  # Total VO&M cost
  total.vom.cost       = tryCatch( total_vom(db), error = function(cond) { return('ERROR') } ) 
  if (typeof(total.vom.cost)=='character') { message('\nMissing total generator VO&M cost data from solution .db file.')}
}

if ( reserve.stack ) {
  # Total reserve provision by generator
  total.gen.res        = tryCatch( total_gen_reserve_provision(db), error = function(cond) { return('ERROR') } ) 
  # Get all reserve types
  reserve.names        = tryCatch( unique(total.gen.res$parent), error = function(cond) { return('ERROR') } ) 
  if (typeof(total.gen.res)=='character') { message('\nMissing total generator reserve provision data from solution .db file.')}
}

if ( capacity.factor.table | installed.cap.plot ) {
  # Total installed capacity
  total.installed.cap  = tryCatch( total_installed_cap(db), error = function(cond) { return('ERROR') } ) 
  if (typeof(total.installed.cap)=='character') { message('\nMissing total generator installed capacity data from solution .db file.')}
}

if ( region.zone.flow.table | total.gen.stack | region.gen.stacks | zone.gen.stacks |
     individual.region.stacks.log | region.zone.gen.table | key.period.dispatch.total.log | key.period.dispatch.region.log | 
     key.period.dispatch.zone.log | commit.dispatch.zone | commit.dispatch.region) {
  # Total region load 
  total.region.load    = tryCatch( total_region_load(db), error = function(cond) { return('ERROR') } ) 
  # Aggregate region load and get unique names
  r.load               = tryCatch( region_load(total.region.load), error = function(cond) { return('ERROR') } ) 
  # Assign region names based on PLEXOS regions.
  region.names         = tryCatch( unique(r.load$Region), error = function(cond) { return('ERROR') } ) 
  if (typeof(total.region.load)=='character') { message('\nMissing total region load data from solution .db file.')}
  if( length(unique(rz.unique$Region))!=length(region.names) ) { 
    message('\nWarning: Number of regions in generation to region/zone mapping file different than number of regions from region load query! Check region.names object.') 
  }
}

if ( region.zone.flow.table | total.gen.stack | region.gen.stacks | zone.gen.stacks |
     individual.region.stacks.log | region.zone.gen.table | key.period.dispatch.total.log | key.period.dispatch.region.log | 
     key.period.dispatch.zone.log | commit.dispatch.zone | commit.dispatch.region) {
  # Total zone load
  total.zone.load    = tryCatch( total_zone_load(db), error = function(cond) { return('ERROR') } ) 
  # Aggregate zone load and get unique names
  z.load             = tryCatch( zone_load(total.region.load, total.zone.load), error = function(cond) { return('ERROR') } ) 
  # Assign zone names based on PLEXOS regions or region to zone mapping file. 
  zone.names         = tryCatch( unique(z.load$Zone), error = function(cond) { return('ERROR') } ) 
  if (typeof(total.zone.load)=='character' & !reassign.zones) { 
    message('\nMissing total zone load data from solution .db file.')
  }
  if( length(unique(rz.unique$Zone))!=length(zone.names) ) { 
    message('\nWarning: Number of zones in generation to region/zone mapping file different than number of zones from zone load query! Check zone.names object.') 
  }
}

if ( region.zone.flow.table ) {
  # Total region imports
  total.region.imports = tryCatch( total_region_imports(db), error = function(cond) { return('ERROR') } ) 
  if (typeof(total.region.imports)=='character') { message('\nMissing total region imports data from solution .db file.')}
  
  # Total region exports
  total.region.exports = tryCatch( total_region_exports(db), error = function(cond) { return('ERROR') } ) 
  if (typeof(total.region.exports)=='character') { message('\nMissing total region exports data from solution .db file.')}

  # Total region unserved energy
  total.region.ue      = tryCatch( total_region_ue(db), error = function(cond) { return('ERROR') } ) 

  # Total zone imports.
  total.zone.imports = tryCatch( total_zone_imports(db), error = function(cond) { return('ERROR') } ) 
  if (typeof(total.zone.imports)=='character' & !reassign.zones) { 
    message('\nMissing total zone imports data from solution .db file.')}

  # Total zone exports
  total.zone.exports = tryCatch( total_zone_exports(db), error = function(cond) { return('ERROR') } ) 
  if (typeof(total.zone.exports)=='character' & !reassign.zones) { 
    message('\nMissing total zone exports data from solution .db file.')}

  # Total zone unserved energy.
  total.zone.ue      = tryCatch( total_zone_ue(db), error = function(cond) { return('ERROR') } ) 
  if (typeof(total.region.ue)=='character') { 
    message('\nMissing total region unserved energy data from solution .db file.')}
}

if ( annual.reserves.table ) {
  # Total reserve provision.
  total.reserve.provision = tryCatch( total_reserve_provision(db), error = function(cond) { return('ERROR') } ) 
  if (typeof(total.reserve.provision)=='character') { message('\nMissing total reserve provision data from solution .db file.')}

  total.reserve.shortage  = tryCatch( total_reserve_shortage(db), error = function(cond) { return('ERROR') } ) 
  if (typeof(total.reserve.shortage)=='character') { message('\nMissing total reserve shortage data from solution .db file.')}
}

if ( interface.flow.table ) {
  # Total interface flow for each selected interface
  total.interface.flow = tryCatch( total_interface_flow(db), error = function(cond) { return('ERROR') } ) 
  if (typeof(total.interface.flow)=='character') { message('\nMissing total interface flow data from solution .db file.')}
}

if ( line.flow.table ) {
  # Total line flow for each selected line
  total.line.flow = tryCatch( total_line_flow(db), error = function(cond) { return('ERROR') } ) 
  if (typeof(total.line.flow)=='character') { message('\nMissing total line flow data from solution .db file.')}
}



# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Interval level queries
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ( key.period.dispatch.total.log | key.period.dispatch.region.log | key.period.dispatch.zone.log |
     daily.curtailment  | daily.curtailment.type | interval.curtailment | interval.curtailment.type | 
     commit.dispatch.zone | commit.dispatch.region | revenue.plots ) {
  # Interval level generation for each generator.
  interval.generation   = tryCatch( interval_gen(db), error = function(cond) { return('ERROR') } ) 
  # Interval level available capacity for each generator.
  interval.avail.cap    = tryCatch( interval_avail_cap(db), error = function(cond) { return('ERROR') } ) 
  if (exists('interval.generation')) { 
    if (typeof(interval.generation)=='character') { 
      message('\nMissing interval generator generation data from solution .db file.')
      }
    }
  if (exists('interval.avail.cap')) { 
    if (typeof(interval.avail.cap)=='character') { 
      message('\nMissing interval generator available capacity or units generating data from solution .db file.')
      }
    }
}

if ( key.period.dispatch.total.log | key.period.dispatch.region.log | key.period.dispatch.zone.log |
     commit.dispatch.zone | commit.dispatch.region ){
  # interval level region load.
  interval.region.load  = tryCatch( interval_region_load(db), error = function(cond) { return('ERROR') } )
  # Interval level zone load 
  interval.zone.load    = tryCatch( interval_zone_load(db), error = function(cond) { return('ERROR') } ) 
  if (exists('interval.region.load')) { 
    if (typeof(interval.region.load)=='character') { 
      message('\nMissing interval region load data from solution .db file.')
      }
    }
  if (exists('interval.zone.load')) { 
    if (typeof(interval.zone.load)=='character') { 
      message('\nMissing interval zone load data from solution .db file.')
      }
    }
}

if ( interface.flow.plots | key.period.interface.flow.plots ) {
  # Interval level interface flow for selected interfaces.
  interval.interface.flow = tryCatch( interval_interface_flow(db), error = function(cond) { return('ERROR') } ) 
  if (exists('interval.interface.flow')) { 
    if (typeof(interval.interface.flow)=='character') { 
      message('\nMissing interval interface flow data from solution .db file.')
    }
  }
}

if ( line.flow.plots | key.period.line.flow.plots ) {
  # Interval level line flow for selected lines.
  interval.line.flow = tryCatch( interval_line_flow(db), error = function(cond) { return('ERROR') } ) 
  if (exists('interval.line.flow')) { 
    if (typeof(interval.line.flow)=='character') { 
      message('\nMissing interval line flow data from solution .db file.')
    }
  }
}

if ( annual.reserves.table | reserves.plots ) {
  # Interval level reserve provision
  interval.reserve.provision = tryCatch( interval_reserve_provision(db), error = function(cond) { return('ERROR') } ) 
  if (exists('interval.reserve.provision')) { 
    if (typeof(interval.reserve.provision)=='character') { 
      message('\nMissing interval reserve provision data from solution .db file.')
    }
  }
}

if ( revenue.plots ) {
  # Interval level reserve provision
  interval.gen.reserve.provision = tryCatch( interval_gen_reserve_provision(db), error = function(cond) { return('ERROR') } ) 
  if (exists('interval.reserve.provision')) { 
    if (typeof(interval.gen.reserve.provision)=='character') { 
      message('\nMissing interval reserve provision data from solution .db file.')
    }
  }
}

if ( (price.duration.curve | revenue.plots) & !exists('interval.region.price') ) {
  # Interval level region price. This is only called if one logical is true and it doesn't already exist.
  interval.region.price = tryCatch( interval_region_price(db), error = function(cond) { return('ERROR') } ) 
  if (exists('interval.region.price')) { 
    if (typeof(interval.region.price)=='character') { 
      message('\nMissing interval region price data from solution .db file.')
    }
  }
}

if ( (res.price.duration.curve | revenue.plots) & !exists('interval.reserve.price') ) {
  # Interval level reserve price. This is only called if one logical is true and it doesn't already exist.
  interval.reserve.price = tryCatch( interval_reserve_price(db), error = function(cond) { return('ERROR') } ) 
  if (exists('interval.reserve.price')) { 
    if (typeof(interval.reserve.price)=='character') { 
      message('\nMissing interval reserve price data from solution .db file.')
    }
  }
}

if ( commit.dispatch.zone | commit.dispatch.region ) {
  # Interval level day ahead generator available capacity.
  interval.da.committment = tryCatch( interval_avail_cap(db.day.ahead), error = function(cond) { return('ERROR') } ) 
  if (exists('interval.da.committment')) { 
    if (typeof(interval.da.committment)=='character') { 
      message('\nMissing interval available capacity from day ahead solution .db file.')
    }
  }
}


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Model and database queries
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ( runtime.table ) {
  # Interval level day ahead generator available capacity.
  phase.runtime = tryCatch( phase_runtime(db), error = function(cond) { return('ERROR') } ) 
  if (exists('interval.runtime')) { 
    if (typeof(interval.runtime)=='character') { 
      message('\nMissing interval run times from solution .db file.')
    }
  }
}

