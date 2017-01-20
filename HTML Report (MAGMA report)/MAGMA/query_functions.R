
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# This file contains functions for the general PLEXOS solution analysis that reports an HTML of common figures.
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Generation by type
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# This function returns total generation by type and curtailment. Curtailment is calculated according to the renewable types specified in the input file. 

gen_by_type = function(total.generation, total.avail.cap) {
  
  setkey(total.generation,'name')
  setkey(total.avail.cap,'name')
  
  # Filter out generation and available capacity data and add generation type by matching generator name. 
  yr.gen = total.generation[property == 'Generation',][, Type:=gen.type.mapping[name] ][,.(scenario,Type,property,value)]
  
  avail = total.avail.cap[property == 'Available Energy',][, Type:=gen.type.mapping[name] ][,.(scenario,Type,property,value)]
  avail = avail[Type %in% re.types,.(value=sum(value)),by=.(scenario,Type,property)]
  avail[,property:=NULL]
  
  # Pull out generation data for types used in curtailment calculation.
  re.gen = yr.gen[Type %in% re.types, .(value=sum(value)),by=.(scenario,Type,property)]
  re.gen[,property:=NULL]

  # Sum up generation by type
  yr.gen = yr.gen[,.(GWh=sum(value)),by=.(scenario,Type)]
    
  if(typeof(avail)=='double' & typeof(re.gen)=='double') {
    # Calculate curtailment
    curt = avail - re.gen
    curt.tot = sum(curt)
    
    # Combine everything before returning the resulting data.
    yr.gen = rbind(yr.gen, data.table(scenario = unique(yr.gen[,scenario]), Type = 'Curtailment', GWh = curt.tot))
    
  } else if (length(avail[,1])>0 & length(re.gen[,1])>0) {
    # Calculate curtailment
    setkey(avail, Type, scenario)
    setkey(re.gen, Type, scenario)
    curt = avail[re.gen][,curt:=value-i.value]
    curt.tot = curt[,.(Type='Curtailment',GWh=sum(curt)), by=.(scenario)]
    
    # Combine everything before returning the resulting data.
    yr.gen = rbindlist(list(yr.gen, curt.tot))
  }

  return(yr.gen)
}

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Capacity by type
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# This function returns total generation by type and curtailment. Curtailment is calculated according to the renewable types specified in the input file. 

cap_by_type = function(total.installed.capacity) {
  
  setkey(total.installed.capacity,'name')

  # Add generation type by matching generator name. 
  yr.cap = total.installed.capacity[, Type:=gen.type.mapping[name] ][,.(scenario,Type,property,value)]
  
  # Sum up generation by type
  yr.cap = yr.cap[,.(GW=sum(value)),by=.(scenario,Type)]
  
  return(yr.cap)
}

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Curtailment by type
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# This function returns total curtailment by type of generator. Curtailment is calculated according to the renewable types specified in the input file. 

curt_by_type = function(total.generation, total.avail.cap) {
  
  setkey(total.generation,'name')
  setkey(total.avail.cap,'name')
  
  # Filter out generation and available capacity data for RE types
  # and add generation type by matching generator name. 
  yr.gen = total.generation[property == 'Generation',][, Type:=gen.type.mapping[name] ][,.(scenario,Type,property,value)]
  re.gen = yr.gen[Type %in% re.types, .(value=sum(value)),by=.(scenario,Type,property)]
  re.gen[,property:=NULL]
  setnames(re.gen,'value','Generation')
  
  avail = total.avail.cap[property == 'Available Energy',][, Type:=gen.type.mapping[name] ][,.(scenario,Type,property,value)]
  avail = avail[Type %in% re.types,.(value=sum(value)),by=.(scenario,Type,property)]
  avail[,property:=NULL]
  setnames(avail,'value','Available Energy')
  
  # Calculate curtailment
  setkey(avail, Type, scenario)
  setkey(re.gen, Type, scenario)
  curt = avail[re.gen][,Curtailment:=`Available Energy`-Generation]

  return(curt)
}

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Region and Zone Generation by type according to generator name
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# This function returns total generation separated by type but also by region and zone.  

region_zone_gen = function(total.generation, total.avail.cap) {
  
  setkey(total.generation,'name')
  setkey(total.avail.cap,'name')
  gen.type.zone.region = region.zone.mapping[, Type:=gen.type.mapping[name]]
  
  # Filter out generation and available capacity data and add generation type by matching generator name.
  # Also add region and zone by matching generator name in the region and zone mapping file. 
  gen.data = gen.type.zone.region[total.generation[property=='Generation', .(scenario,name,category,value)]]
  if(nrow(gen.data[is.na(Type) | is.na(Region) | is.na(Zone)])>0){
    warning("You are missing Types, Regions, or Zones for some of your generators. Please Fix your Input File")
    print(gen.data[is.na(Type) | is.na(Region) | is.na(Zone)])
  }
  gen.data = gen.data[, .(value=sum(value)), by=.(scenario,Type, Region, Zone)]
  
  avail.data = gen.type.zone.region[total.avail.cap[property == 'Available Energy', 
                               .(scenario,name,category,value)]]
  avail.data = avail.data[Type %in% re.types, .(Avail = sum(value)), by=.(scenario,Type, Region, Zone)]
    

  # Curtailment calculation based on renewable types specified in input file
  setkey(avail.data,scenario,Type,Region,Zone)
  curt = gen.data[Type %in% re.types, ]
  setkey(curt,scenario,Type,Region,Zone)
  curt = curt[avail.data]
  curt[,Type := 'Curtailment']
  curt[,value := Avail - value]
  curt[,Avail := NULL ]
   
  # Combine generation and curtailment and return.
  gen.data = rbindlist(list(gen.data, curt))
  setnames(gen.data,'value','GWh')
  
  return(gen.data)
}

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Region and Zone Capacity by type according to generator name
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# This function returns total generation separated by type but also by region and zone.  

region_zone_cap = function(total.installed.capacity) {
  
  setkey(total.installed.capacity,'name')
  gen.type.zone.region = region.zone.mapping[, Type:=gen.type.mapping[name]]
  
  # Add generation type by matching generator name.
  # Also add region and zone by matching generator name in the region and zone mapping file. 
  cap.data = gen.type.zone.region[total.installed.capacity[, .(scenario,name,category,value)]]
  cap.data = cap.data[, .(value=sum(value)), by=.(scenario,Type, Region, Zone)]
  
  return(gen.data)
}

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Key Period Generation by Type 
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# This function returns interval level generation and curtailment used for the key period time series dispatch stacks. 

interval_generation = function(interval.region.load, interval.zone.load, interval.generation, interval.avail.cap) {

  gen.type.zone.region = region.zone.mapping[, Type:=gen.type.mapping[name]]
  setkey(interval.generation,name)
  setkey(interval.avail.cap,name)
  
  # Either sum up load for each region or each zone, depending on which there are more of. 
  if (length(region.names)>=length(zone.names)){
    load = interval.region.load[,.(value=sum(value)),by=.(scenario,time,name,property)]
    setnames(load,"name","Region")
    spatialcol = "Region"    
  } else {
    load = interval.zone.load[,.(value=sum(value)),by=.(scenario,time,name,property)]
    setnames(load,"name","Zone")
    spatialcol = "Zone"
  }
  setkeyv(rz.unique,spatialcol)
  setkeyv(load,spatialcol)
  load = load[rz.unique]
  setkeyv(load,c('time',spatialcol))
  setnames(load,'property','Type')
  
  # Pull out interval generation data, and add generation type and region and zone according to generator name. Then add load data.
  int.gen = gen.type.zone.region[interval.generation[,.(scenario, name, time, value, category)]]
  int.gen = int.gen[,.(value=sum(value,na.rm=TRUE)),by=.(scenario,time,Region,Zone,Type)] 
  setkeyv(int.gen,c('time',spatialcol))
  int.gen = rbindlist(list(int.gen,load),use.names=TRUE)
  
  #make sure that the right zones and regions are there...
  dropcol=names(rz.unique)[names(rz.unique) != spatialcol]
  setkeyv(int.gen,spatialcol)
  int.gen = merge(int.gen[,!dropcol,with=FALSE],rz.unique,all.y=TRUE)
  
  # Pull out interval generation capacity and add generation type, region, and zone based on matching generator names.
  int.avail = gen.type.zone.region[interval.avail.cap[,.(scenario, name, time, value, category)]]
  int.avail = int.avail[,.(value=sum(value,na.rm=TRUE)),by=.(scenario,time,Region,Zone,Type)]
 
  if (all(re.types!='none_specified')){
    #  Pull out renewable data for curtilment calculations. 
    re.gen = int.gen[Type %in% re.types, ]
    setkey(re.gen,scenario,time,Region,Zone,Type)
  
    int.avail = int.avail[Type %in% re.types, ]
    setkey(int.avail,scenario,time,Region,Zone,Type)
    
    # Calculate curtailment and add it to generation and load data from above.
    curtailed = merge(int.avail, re.gen, all=TRUE)
    curtailed[is.na(curtailed)] = 0
    curtailed=curtailed[,.(Type='Curtailment',value=sum(value.x-value.y)),by=.(scenario,time,Region,Zone)]
    
    int.gen = rbindlist(list(int.gen, curtailed), use.names=TRUE)
  
  } 
 
  return(int.gen)
}

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Total Curtailment
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Calculates interval level total curtailment

total_curtailment = function(interval.generation, interval.avail.cap) {
  
  setkey(interval.generation,name)
  setkey(interval.avail.cap,name)
  
  # Separate generation and available capacity data by type for each interval.
  c.gen = interval.generation[, Type:=gen.type.mapping[name] ][Type %in% re.types,.(value=sum(value)),by=.(scenario, time, Type)]
  c.avail = interval.avail.cap[, Type:=gen.type.mapping[name] ][Type %in% re.types,.(value=sum(value)),by=.(scenario, time, Type)]

  if (typeof(c.avail)=='double' & typeof(c.gen)=='double') {
    curt.tot = c.avail - c.gen
    curt.tot = data.table(curt.tot)
    curt.tot[,year := 1900+as.POSIXlt(time)[[6]]]
    curt.tot[,day := as.POSIXlt(time)[[8]]+1]
    curt.tot[,interval := 1:intervals.per.day,by=.(day)]
  } else {
    # Summing up total curtailment for each interval
    setkey(c.avail,scenario,time,Type)
    setkey(c.gen,scenario,time,Type)
    curt = c.avail[c.gen][,curt := value-i.value]
    curt.tot = curt[,.(Curtailment=sum(curt)),by=.(scenario,time,Type)]
    curt.tot[,year := 1900+as.POSIXlt(time)[[6]]]
    curt.tot[,day := as.POSIXlt(time)[[8]]]
    curt.tot[,interval := 1:intervals.per.day,by=.(scenario,day,Type)]
  }

  return(curt.tot)
}

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Cost 
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Returns a table of total run costs

costs = function(total.emissions.cost, total.fuel.cost, total.ss.cost, total.vom.cost) {
  
  # add NAs for errored cost data
  if( !(is.character(total.emissions.cost) & is.character(total.fuel.cost) & 
        is.character(total.ss.cost) & is.character(total.vom.cost))){
    if(is.character(total.emissions.cost)){
      total.emissions.cost = data.table(scenario = db$scenario,property = 'Emissions Cost', value=NA)
    }
    if(is.character(total.fuel.cost)){
      total.fuel.cost = data.table(scenario = db$scenario,property = 'Fuel Cost', value=NA)
    }
    if(is.character(total.ss.cost)){
      total.ss.cost = data.table(scenario = db$scenario,property = 'Start & Shutdown Cost', value=NA)
    }
    if(is.character(total.vom.cost)){
      total.vom.cost = data.table(scenario = db$scenario,property = 'VO&M Cost', value=NA)
    }
  }
  
  cost.data = rbindlist(list(total.emissions.cost, total.fuel.cost, total.ss.cost, total.vom.cost),fill=TRUE)
  cost.table = cost.data[,.(Cost = sum(value/1000)), by=.(scenario,property)]
  cost.table[, property:=gsub("Cost","",property)]
  tot.cost = cost.table[,.(property = "Total", Cost = sum(Cost)), by=.(scenario)]
  cost.table = rbindlist(list(cost.table,tot.cost))
  cost.table[,property:=factor(property,levels=unique(property))]

  setnames(cost.table, "property","Type")
  setnames(cost.table, "Cost", "Cost (MM$)")

  if (length(unique(cost.table$scenario))==1){
    cost.table[, scenario := NULL]
  }

return(cost.table)
}

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Annual Reserve Provisions
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Calculates total reserve provision and shortage for each reserve type. 

annual_reserves = function(total.reserve.provision, total.reserve.shortage) {
    
  provision = total.reserve.provision[, .(Type = name,`Provisions (GWh)` = sum(value)),by = .(scenario, name)]
  provision[,name:=NULL]
  shortage = total.reserve.shortage[, .(Type = name, `Shortage (GWh)` = sum(value)),by = .(scenario, name)]
  shortage[,name:=NULL]
  
  setkey(provision,scenario,Type)
  setkey(shortage,scenario,Type)
  r.data = provision[shortage]
  
  return(r.data)
}

# Calculates total reserve provision by generator type for each reserve product
annual_reserves_provision = function(total.gen.res) {
  
  setkey(total.gen.res, name)
  yr.gen.res = total.gen.res[property == 'Provision', Type:=gen.type.mapping[name] ]
  yr.gen.res = yr.gen.res[, .(GWh = sum(value)), by=.(scenario,parent,Type)]
  setnames(yr.gen.res,"parent","Reserve")
  
  return(yr.gen.res)
}

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Interval Reserve Provisions 
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Calculates the interval level reserve provision

interval_reserves = function(interval.reserve.provision) {
  provision = interval.reserve.provision[, .(provision = sum(value)), by = .(time,scenario)]
  # Summing reserves types, and adding indexing for interval number and day.
  provision[,day := as.POSIXlt(time)[[8]]]
  provision[,interval := 1:intervals.per.day,by=.(day,scenario)]
  return(provision)
}

# Calculates interval reserve provision by generator type for each reserve product
interval_reserves_provision = function(interval.gen.res) {
  
  setkey(interval.gen.res, name)
  int.gen.res = interval.gen.res[property == 'Provision', Type:=gen.type.mapping[name] ]
  int.gen.res = int.gen.res[, .(GWh = sum(value)), by=.(scenario,name,parent,Type)]
  setnames(int.gen.res,"parent","Reserve")
  
  return(int.gen.res)
}

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Interface Flows 
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Total run and interval level interface flow data, for specific interfaces that are specified in the input file. 

annual_interface_flows = function(total.interface.flow) {
  year.flows = total.interface.flow[name %in% interfaces,.(scenario,name,time,value)]  
  return(year.flows[,.(GWh=sum(value)), by=.(name,scenario)])
}

interval_interface_flows = function(interval.interface.flow) {
  int.flows = interval.interface.flow[name %in% interfaces,.(scenario,name,time,value)]   
  return(int.flows)
}

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# line Flows 
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Total run and interval level line flow data, for specific lines that are specified in the input file. 

annual_line_flows = function(total.line.flow) {
  year.flows = total.line.flow[name %in% lines,.(scenario,name,time,value)]  
  return(year.flows[,.(GWh=sum(value)), by=.(name,scenario)])
}

interval_line_flows = function(interval.line.flow) {
  int.flows = interval.line.flow[name %in% lines,.(scenario,name,time,value)]   
  return(int.flows)
}

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Region and Zone Stats
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# This function sums up region and zone stats for the entire run. 
# zones are defined either in PLEXOS, or using the region and zone mapping file. 

region_stats = function(total.region.load, total.region.imports, total.region.exports, total.region.ue) {
  r.data = rbindlist(list(total.region.load, total.region.imports, total.region.exports, total.region.ue))
  r.data = r.data[, .(value=sum(value)), by=.(name,property,scenario)]
  r.stats = dcast.data.table(r.data, name+scenario~property, value.var = 'value')
  return(r.stats)
}

zone_stats = function(total.region.load, total.region.imports, total.region.exports, total.region.ue, total.zone.load, total.zone.imports, total.zone.exports, total.zone.ue) {
  if (reassign.zones==TRUE | any(as.character(total.zone.load)=='ERROR')){
    z.data = rbindlist(list(total.region.load, total.region.imports, total.region.exports, total.region.ue))
    setnames(z.data,'name','Region')
    setkey(z.data,Region)
    setkey(rz.unique,Region)
    z.stats = z.data[rz.unique][, .(value = sum(value)), by = .(Zone,property,scenario)] %>%
      dcast.data.table(Zone+scenario~property, value.var = 'value') 
    setnames(z.stats,'Zone','name')
  } else {
    z.data = rbindlist(list(total.zone.load, total.zone.imports, total.zone.exports, total.zone.ue))
    z.data = z.data[,.(value=sum(value)),by=.(name,property,scenario)]
    z.stats = dcast.data.table(z.data, name+scenario~property, value.var = 'value')
  }
  return(z.stats)
}

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Region and Zone Load
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Returns region level and zone level load data for the entire run. 

region_load = function(total.region.load) {
  r.load = total.region.load[,.(value=sum(value)), by=.(scenario,name)]
  setnames(r.load,'name','Region')
  return(r.load)
}

zone_load = function(total.region.load, total.zone.load) {
  if (reassign.zones==TRUE | any(as.character(total.zone.load)=='ERROR')){
    setkey(total.region.load,name)
    setkey(rz.unique,Region)
    z.load = rz.unique[total.region.load][, .(value=sum(value)), by=.(scenario, Zone)]
  } else {
    z.load = total.zone.load[,.(value=sum(value)), by=.(scenario, name)]
    setnames(z.load,"name","Zone")
  }
  return(z.load)
}

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Capacity Factor
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Calculates the capacity factor of all the generation types for the full run. 

capacity_factor = function(total.generation, total.installed.cap) {
  
  setkey(total.installed.cap,name,scenario)
  setkey(total.generation,name,scenario)
  
  # Pull out installed capacity and generation and match them to generation type by generator name. 
  mc = total.installed.cap[, Type:=gen.type.mapping[name] ]
  try(setnames(mc,'value', 'MaxCap (GWh)'),silent=T)
  
  gen = total.generation[, Type:=gen.type.mapping[name] ]
  try(setnames(gen,'value', 'Gen (GWh)'),silent=T)
  
  mc[, Type := factor(Type, levels = rev(c(gen.order)))]
  
  # Calculates generation type total capacity and generation for the full run
  c.factor = mc[,.(scenario,name,`MaxCap (GWh)`,Type)][gen[,.(scenario,name,`Gen (GWh)`)]]
  c.factor = c.factor[,.(`MaxCap (GWh)`=sum(`MaxCap (GWh)`),`Gen (GWh)`=sum(`Gen (GWh)`)),by=.(Type,scenario)]
  
  # Calculate capacity factor for each generation type
  n.hours = length(seq(from = first.day, to = last.day, by = 'hour'))
  c.factor = c.factor[,.(`Capacity Factor (%)` = `Gen (GWh)`/(`MaxCap (GWh)`/1000*n.hours)*100),by=.(Type,scenario, `MaxCap (GWh)`, `Gen (GWh)`)]
  
  # make sure names of total.generation and total.installed.cap aren't changed
  try(setnames(total.generation, 'Gen (GWh)', 'value'), silent=TRUE)
  try(setnames(total.installed.cap, 'MaxCap (GWh)', 'value'), silent=TRUE)
  
  return(c.factor)
}

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Revenue
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# This function calculates the revenue from a particular revenue stream (reserves or generation)

revenue_calculator = function(interval.generation, interval.region.price,
                              interval.gen.reserve.provision,interval.reserve.price){
  
  gen.type.zone.region = region.zone.mapping[, Type:=gen.type.mapping[name]]
  setkey(gen.type.zone.region,name)
  setkey(interval.generation,name)
  setkey(interval.gen.reserve.provision,name)
  # Add region and zone by matching generator name in the region and zone mapping file. 
  gen.data = gen.type.zone.region[interval.generation[property=='Generation', .(scenario,name,time,value)]]
  res.data = gen.type.zone.region[interval.gen.reserve.provision[property=='Provision', 
                                                                 .(scenario,name,parent,time,value)]]
  #Merge prices onto generation and reserve data
  setkey(gen.data,Region,time,scenario)
  setkey(interval.region.price,Region,time,scenario)
  gen.data = interval.region.price[gen.data]
  
  setkey(res.data,parent,time,scenario)
  setkey(interval.reserve.price,name,time,scenario)
  res.data = interval.reserve.price[res.data]
  
  gen.data[, Revenue_Type:='Generation']
  gen.data[, revenue:=value*i.value]
  res.data[, Revenue_Type:='Reserves']
  res.data[, revenue:=value*i.value]
  
  revenue = rbindlist(list(gen.data[, .(revenue=sum(revenue)), by=.(scenario,Region,Zone,Type,Revenue_Type)],
                           res.data[, .(revenue=sum(revenue)), by=.(scenario,Region,Zone,Type,Revenue_Type)]))
  return(revenue)
}

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Committed capacity 
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# This function just pulls out available capacity at the interval level for use int he DA-RT committment and dispatch plots

cap_committed = function(interval.da.committment) {
  
  if (length(region.names)>=length(zone.names)){
    spatialcol = "Region"
  } else {
    spatialcol = "Zone"    
  }

  gen.type.zone.region = region.zone.mapping[, Type:=gen.type.mapping[name]]
  setkey(interval.da.committment,name)
  
  # Query available capacity at the interval level, add generation type and region and zone by matching mapping file with generator names.
  commit.data = gen.type.zone.region[interval.da.committment[,.(scenario,time,name,category,value)]]
  commit.data = commit.data[,.(committed.cap=sum(value)),by=.(scenario,time,Region,Zone,Type)]
  
  return(commit.data)
} 

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Query General Data
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# These functions are called from the setup data queries file. They use the rplexos package to query the solution database.

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Generator total run data
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Full run generation data
total_generation = function(database) {
  if ("Generation" %in% properties[is_summary==1 & collection=="Generator",property]){
    total.gen = data.table(query_year(database, 'Generator', 'Generation', columns = c('category', 'name')))
  } else if ("Generation" %in% properties[is_summary==0 & collection=="Generator",property]){
    total.gen = data.table(query_interval(database, 'Generator', 'Generation', columns = c('category', 'name')))
    total.gen = total.gen[, .(value=sum(value)/(intervals.per.day/24)/1000), by=.(scenario, property, name, category)]
  }
  return(total.gen[, .(value=sum(value)), by=.(scenario, property, name, category)])
}

# Full run available capacity
total_avail_cap = function(database) {
  if ("Available Energy" %in% properties[is_summary==1 & collection=="Generator",property]){
    total.avail.cap = data.table(query_year(database, 'Generator', 'Available Energy', columns = c('category', 'name')))
  } else if ("Available Capacity" %in% properties[is_summary==0 & collection=="Generator",property]){
    total.avail.cap = data.table(query_interval(database, 'Generator', 'Available Capacity', columns = c('category', 'name')))
    total.avail.cap = total.avail.cap[, .(value=sum(value)/(intervals.per.day/24)/1000), by=.(scenario, property, name, category)]
  }
  return(total.avail.cap[, .(value=sum(value)), by=.(scenario, property, name, category)])
}

# Full run emissions cost
total_emissions = function(database) {
  if ("Emissions Cost" %in% properties[is_summary==1 & collection=="Generator",property]){
    total.emissions.cost = data.table(query_year(database, 'Generator', 'Emissions Cost', columns = c('category', 'name')))
  } else if ("Emissions Cost" %in% properties[is_summary==0 & collection=="Generator", property]){
    total.emissions.cost = data.table(query_interval(database, 'Generator', 'Emissions Cost', columns = c('category', 'name')))
    total.emissions.cost = total.emissions.cost[, .(value=sum(value)/1000), by=.(scenario, property, name, category)]
  }
  return(total.emissions.cost[, .(value=sum(value)), by=.(scenario, property, name, category)])
}

# Full run fuel cost
total_fuel = function(database) {
  if ("Fuel Cost" %in% properties[is_summary==1 & collection=="Generator",property]){
    total.fuel.cost = data.table(query_year(database, 'Generator', 'Fuel Cost', columns = c('category', 'name')))
  } else if ("Fuel Cost" %in% properties[is_summary==0 & collection=="Generator", property]){
    total.fuel.cost = data.table(query_interval(database, 'Generator', 'Fuel Cost', columns = c('category', 'name')))
    total.fuel.cost = total.fuel.cost[, .(value=sum(value)/1000), by=.(scenario, property, name, category)]
  }
  return(total.fuel.cost[, .(value=sum(value)), by=.(scenario, property, name, category)])
}

# Full run S&S cost
total_ss = function(database) {
  if ("Start & Shutdown Cost" %in% properties[is_summary==1 & collection=="Generator",property]){
    total.ss.cost = data.table(query_year(database, 'Generator', 'Start & Shutdown Cost', columns = c('category', 'name')))
  } else if ("Start & Shutdown Cost" %in% properties[is_summary==0 & collection=="Generator", property]){
    total.ss.cost = data.table(query_interval(database, 'Generator', 'Start & Shutdown Cost', columns = c('category', 'name')))
    total.ss.cost = total.ss.cost[, .(value=sum(value)/1000), by=.(scenario, property, name, category)]
  }
  return(total.ss.cost[, .(value=sum(value)), by=.(scenario, property, name, category)])
}

# Full run VO&M cost
total_vom = function(database) {
  if ("VO&M Cost" %in% properties[is_summary==1 & collection=="Generator",property]){
    total.vom.cost = data.table(query_year(database, 'Generator', 'VO&M Cost', columns = c('category', 'name')))
  } else if ("VO&M Cost" %in% properties[is_summary==0 & collection=="Generator", property]){
    total.vom.cost = data.table(query_interval(database, 'Generator', 'VO&M Cost', columns = c('category', 'name')))
    total.vom.cost = total.vom.cost[, .(value=sum(value)/1000), by=.(scenario, property, name, category)]
  }
  return(total.vom.cost[, .(value=sum(value)), by=.(scenario, property, name, category)])
}

# Full run installed capacity
total_installed_cap = function(database) {
  if ("Installed Capacity" %in% properties[is_summary==1 & collection=="Generator",property]){
    total.installed.cap = data.table(query_year(database, 'Generator', 'Installed Capacity', columns = c('category', 'name')))
  } else if ("Installed Capacity" %in% properties[is_summary==0 & collection=="Generator", property]){
    total.installed.cap = data.table(query_interval(database, 'Generator', 'Installed Capacity', columns = c('category', 'name')))
    total.installed.cap = total.installed.cap[, .(value=max(value)), by=.(scenario, property, name, category)]
  }
  return(total.installed.cap[, .(value=sum(value)), by=.(scenario, property, name, category)])
}

# Full run reserve provision
total_gen_reserve_provision = function(database) {
  if ("Provision" %in% properties[is_summary==1 & collection=="Reserve.Generators",property]){
    total.res.provision = data.table(query_year(database, 'Reserve.Generators', 'Provision', columns = c('category', 'name')))
  } else if ("Provision" %in% properties[is_summary==0 & collection=="Reserve.Generators", property]){
    total.res.provision = data.table(query_interval(database, 'Reserve.Generators', 'Provision', columns = c('category', 'name')))
    total.res.provision = total.res.provision[, .(value=sum(value)/(intervals.per.day/24)/1000), by=.(scenario, property, name, parent, category)]
  }
  return(total.res.provision[, .(value=sum(value)), by=.(scenario, property, name, parent, category)])
}

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Region total run data
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Full run region load
total_region_load = function(database) {
  if ("Load" %in% properties[is_summary==1 & collection=="Region", property]){
    total.region.load = data.table(query_year(database, 'Region', 'Load'))
  } else if ("Load" %in% properties[is_summary==0 & collection=="Region", property]){
    total.region.load = data.table(query_interval(database, 'Region','Load', columns = c('category','name')))
    total.region.load = total.region.load[, .(value = sum(value)/(intervals.per.day/24)/1000), by=.(scenario, property, name)]
  }
  return(total.region.load[, .(value=sum(value)), by=.(scenario, property, name)])
}

# Full run region imports
total_region_imports = function(database) {
  if ("Imports" %in% properties[is_summary==1 & collection=="Region", property]){
    total.region.imports = data.table(query_year(database, 'Region', 'Imports'))
  } else if ("Imports" %in% properties[is_summary==0 & collection=="Region", property]){
    total.region.imports = data.table(query_interval(database, 'Region','Imports', columns = c('category','name')))
    total.region.imports = total.region.imports[, .(value = sum(value)/(intervals.per.day/24)/1000), by=.(scenario, property, name)]
  }
  return(total.region.imports[, .(value=sum(value)), by=.(scenario, property, name)])
}

# Full run region exports
total_region_exports = function(database) {
  if ("Exports" %in% properties[is_summary==1 & collection=="Region", property]){
    total.region.exports = data.table(query_year(database, 'Region', 'Exports'))
  } else if ("Exports" %in% properties[is_summary==0 & collection=="Region", property]){
    total.region.exports = data.table(query_interval(database, 'Region','Exports', columns = c('category','name')))
    total.region.exports = total.region.exports[, .(value = sum(value)/(intervals.per.day/24)/1000), by=.(scenario, property, name)]
  }
  return(total.region.exports[, .(value=sum(value)), by=.(scenario, property, name)])
}

# Full run region unserved energy
total_region_ue = function(database) {
  if ("Unserved Energy" %in% properties[is_summary==1 & collection=="Region", property]){
    total.region.ue = data.table(query_year(database, 'Region', 'Unserved Energy'))
  } else if ("Unserved Energy" %in% properties[is_summary==0 & collection=="Region", property]){
    total.region.ue = data.table(query_interval(database, 'Region','Unserved Energy', columns = c('category','name')))
    total.region.ue = total.region.ue[, .(value = sum(value)/(intervals.per.day/24)/1000), by=.(scenario, property, name)]
  }
  return(total.region.ue[, .(value=sum(value)), by=.(scenario, property, name)])
}

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Zone total run data
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Full run zone load
total_zone_load = function(database) {
  if ("Load" %in% properties[is_summary==1 & collection=="Zone", property]){
    total.zone.load = data.table(query_year(database, 'Zone', 'Load'))
  } else if ("Load" %in% properties[is_summary==0 & collection=="Zone", property]){
    total.zone.load = data.table(query_interval(database, 'Zone','Load', columns = c('category','name')))
    total.zone.load = total.zone.load[, .(value = sum(value)/(intervals.per.day/24)/1000), by=.(scenario, property, name)]
  }
  return(total.zone.load[, .(value=sum(value)), by=.(scenario, property, name)])
}

# Full run zone imports
total_zone_imports = function(database) {
  if ("Imports" %in% properties[is_summary==1 & collection=="Zone", property]){
    total.zone.imports = data.table(query_year(database, 'Zone', 'Imports'))
  } else if ("Imports" %in% properties[is_summary==0 & collection=="Zone", property]){
    total.zone.imports = data.table(query_interval(database, 'Zone','Imports', columns = c('category','name')))
    total.zone.imports = total.zone.imports[, .(value = sum(value)/(intervals.per.day/24)/1000), by=.(scenario, property, name)]
  }
  return(total.zone.imports[, .(value=sum(value)), by=.(scenario, property, name)])
}

# Full run zone exports
total_zone_exports = function(database) {
  if ("Exports" %in% properties[is_summary==1 & collection=="Zone", property]){
    total.zone.exports = data.table(query_year(database, 'Zone', 'Exports'))
  } else if ("Exports" %in% properties[is_summary==0 & collection=="Zone", property]){
    total.zone.exports = data.table(query_interval(database, 'Zone','Exports', columns = c('category','name')))
    total.zone.exports = total.zone.exports[, .(value = sum(value)/(intervals.per.day/24)/1000), by=.(scenario, property, name)]
  }
  return(total.zone.exports[, .(value=sum(value)), by=.(scenario, property, name)])
}

# Full run zone unserved energy
total_zone_ue = function(database) {
  if ("Unserved Energy" %in% properties[is_summary==1 & collection=="Zone", property]){
    total.zone.ue = data.table(query_year(database, 'Zone', 'Unserved Energy'))
  } else if ("Unserved Energy" %in% properties[is_summary==0 & collection=="Zone", property]){
    total.zone.ue = data.table(query_interval(database, 'Zone','Unserved Energy', columns = c('category','name')))
    total.zone.ue = total.zone.ue[, .(value = sum(value)/(intervals.per.day/24)/1000), by=.(scenario, property, name)]
  }
  return(total.zone.ue[, .(value=sum(value)), by=.(scenario, property, name)])
}

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Reserves total run data
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Full run reserves provision
total_reserve_provision = function(database) {
  if ("Provision" %in% properties[is_summary==1 & collection=="Reserve", property]){
    total.reserve.provision = data.table(query_year(database, 'Reserve', 'Provision'))
  } else if ("Provision" %in% properties[is_summary==0 & collection=="Reserve", property]){
    total.reserve.provision = data.table(query_interval(database, 'Reserve','Provision', columns = c('category','name')))
    total.reserve.provision = total.reserve.provision[, .(value = sum(value)/(intervals.per.day/24)/1000), by=.(scenario, property, name)]
  }
  return(total.reserve.provision[, .(value=sum(value)), by=.(scenario, property, name)])
}

# Full run reserves shortage
total_reserve_shortage = function(database) {
  if ("Shortage" %in% properties[is_summary==1 & collection=="Reserve", property]){
    total.reserve.shortage = data.table(query_year(database, 'Reserve', 'Shortage'))
  } else if ("Shortage" %in% properties[is_summary==0 & collection=="Reserve", property]){
    total.reserve.shortage = data.table(query_interval(database, 'Reserve','Shortage', columns = c('category','name')))
    total.reserve.shortage = total.reserve.shortage[, .(value = sum(value)/(intervals.per.day/24)/1000), by=.(scenario, property, name)]
  }
  return(total.reserve.shortage[, .(value=sum(value)), by=.(scenario, property, name)])
}

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Selected interface total run data
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Full run interface flows
total_interface_flow = function(database) {
  if ("Flow" %in% properties[is_summary==1 & collection=="Interface", property]){
    total.interface = data.table(query_year(database, 'Interface', 'Flow'))
  } else if ("Flow" %in% properties[is_summary==0 & collection=="Interface", property]){
    total.interface = data.table(query_interval(database, 'Interface','Flow', columns = c('category','name')))
    total.interface = total.interface[, .(value = sum(value)/(intervals.per.day/24)/1000), by=.(scenario, property, name, time)]
  }
  return(total.interface[, .(value=sum(value)), by=.(scenario, property, name, time)])
}

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Selected line total run data
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Full run line flows
total_line_flow = function(database) {
  if ("Flow" %in% properties[is_summary==1 & collection=="Line", property]){
    total.line = data.table(query_year(database, 'Line', 'Flow'))
  } else if ("Flow" %in% properties[is_summary==0 & collection=="Line", property]){
    total.line = data.table(query_interval(database, 'Line','Flow', columns = c('category','name')))
    total.line = total.line[, .(value = sum(value)/(intervals.per.day/24)/1000), by=.(scenario, property, name, time)]
  }
  return(total.line[, .(value=sum(value)), by=.(scenario, property, name, time)])
}


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Interval queries
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Interval level generator generation
interval_gen = function(database) {
  interval.gen = data.table(query_interval(database, 'Generator', 'Generation', columns = c('category', 'name'))) 
  return(interval.gen[,.(scenario, property, name, value, time, category) ])
}

# Interval level generator capacity
interval_avail_cap = function(database) {
  interval.avail.cap = data.table(query_interval(database, 'Generator', c('Available Capacity','Units Generating'), columns = c('category', 'name'))) 
  interval.avail.cap = dcast.data.table(interval.avail.cap, scenario+name+time+category~property, value.var = "value")
  interval.avail.cap[, value:=`Available Capacity`*(`Units Generating`>0)]
  interval.avail.cap[, property:='Available Capacity']
  return(interval.avail.cap[,.(scenario, property, name, value, time, category) ])
}

# Interval level region load 
interval_region_load = function(database) {
  interval.region.load = data.table(query_interval(database, 'Region', 'Load'))
  return(interval.region.load[, .(scenario, property, name, time, value)])
}

# Interval level region load and price
interval_region_price = function(database) {
  interval.region.price = data.table(query_interval(database, 'Region', 'Price'))
  return(interval.region.price[, .(scenario, property, Region=name, time, value)])
}

# Interval level reserve price
interval_reserve_price = function(database) {
  interval.reserve.price = data.table(query_interval(database, 'Reserve', 'Price'))
  return(interval.reserve.price[, .(scenario, property, name, time, value)])
}

# Interval level zone load
interval_zone_load = function(database) {
  interval.zone.load = data.table(query_interval(database, 'Zone', 'Load'))
  return(interval.zone.load[, .(scenario, property, name, time, value)])
}

# Interval level interface flows
interval_interface_flow = function(database) {
  interval.interface.flow = data.table(query_interval(database, 'Interface', 'Flow'))
  return(interval.interface.flow[, .(scenario, property, name, time, value)])
}

# Interval level line flows
interval_line_flow = function(database) {
  interval.line.flow = data.table(query_interval(database, 'Line', 'Flow'))
  return(interval.line.flow[, .(scenario, property, name, time, value)])
}

# Interval level reserve provisions
interval_reserve_provision = function(database) {
  interval.reserve.provision = data.table(query_interval(database, 'Reserve', 'Provision'))
  return(interval.reserve.provision[, .(scenario, property, name, time, value)])
}

# Interval level reserve provisions by generator type
interval_gen_reserve_provision = function(database) {
  interval.gen.reserve.provision = data.table(query_interval(database, 'Reserve.Generators', 'Provision'))
  return(interval.gen.reserve.provision[, .(scenario, property, name, parent, time, value)])
}

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Runtime queries
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Runtime data
phase_runtime = function(database){
  phase.runtime = data.table(query_log(database))
  return(phase.runtime[,.(scenario,phase,time)] )
}

# Runtime step data
interval_runtime = function(database){
  interval.runtime = data.table(query_log_steps(database))
  return(interval.runtime[,.(scenario,phase,step,time)] )
}

# Timestep data
model_timesteps = function(database){
  timesteps = data.table(query_time(database))
  timesteps = timesteps[phase=="ST", ]
  return(timesteps[, .(scenario, phase, start, end, count, timestep)])
}