
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# This file contains functions for comparing PLEXOS solutions that reports an HTML of common figures.
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Generation Difference by type
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

gen_diff_by_type = function(total.generation, total.avail.cap) {
  
  #*************************** Potentially make this an input
  yr.gen = tryCatch( gen_by_type(total.generation, total.avail.cap), error = function(cond) { return('ERROR') } )
  all.combos = data.table(expand.grid(unique(yr.gen$scenario), unique(yr.gen$Type)))
  setkey(all.combos,Var1,Var2)
  setkey(yr.gen,scenario,Type)
  yr.gen = yr.gen[all.combos]
  yr.gen[is.na(GWh), GWh:=0]

  yr.gen[, scenario:=as.character(scenario)]
  gen.diff = yr.gen[, GWh:=GWh-GWh[scenario==ref.scenario], by=.(Type)]

  return(gen.diff)
}

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Region and Zone Generation by type according to generator name
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 # Calculate regional generation differences
region_gen_diff = function(total.generation, total.avail.cap) {
  
  r.z.gen = tryCatch( region_zone_gen(total.generation, total.avail.cap)[, .(GWh=sum(GWh)), by=.(scenario, Region, Type)], 
                      error = function(cond) { return('ERROR') } )

  all.combos = data.table(expand.grid(unique(r.z.gen$scenario), unique(r.z.gen$Region), unique(r.z.gen$Type)))
  setkey(all.combos,Var1,Var2,Var3)
  setkey(r.z.gen,scenario, Region,Type)
  r.z.gen = r.z.gen[all.combos]
  r.z.gen[is.na(GWh), GWh:=0]

  r.z.diff = r.z.gen[, GWh := GWh - GWh[as.character(scenario) == ref.scenario], by=.(Region, Type)]

  return(r.z.diff)
}

 # Calculate zonal generation differences
zone_gen_diff = function(total.generation, total.avail.cap) {
  
  r.z.gen = tryCatch( region_zone_gen(total.generation, total.avail.cap)[, .(GWh=sum(GWh)), by=.(scenario, Zone, Type)], 
                      error = function(cond) { return('ERROR') } )

  all.combos = data.table(expand.grid(unique(r.z.gen$scenario), unique(r.z.gen$Zone), unique(r.z.gen$Type)))
  setkey(all.combos,Var1,Var2,Var3)
  setkey(r.z.gen,scenario,Zone,Type)
  r.z.gen = r.z.gen[all.combos]
  r.z.gen[is.na(GWh), GWh:=0]

  r.z.diff = r.z.gen[, GWh := GWh - GWh[as.character(scenario) == ref.scenario], by=.(Zone, Type)]
  
  return(r.z.diff)
}

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Total Curtailment
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Calculate difference in total curtailment for each scenario

curtailment_diff = function(total.generation, total.avail.cap) {
  
  yr.gen = tryCatch( gen_by_type(total.generation, total.avail.cap), error = function(cond) { return('ERROR') } )

  yr.gen[,scenario:=as.character(scenario)]
  curt.diff = yr.gen[Type=='Curtailment', .(scenario, GWh = GWh - GWh[scenario==ref.scenario])]

  return(curt.diff)
}

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Cost 
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Calculate difference in costs between scenarios

costs_diff = function(total.emissions.cost, total.fuel.cost, total.ss.cost, total.vom.cost) {

  cost.table = tryCatch( costs(total.emissions.cost, total.fuel.cost, total.ss.cost, total.vom.cost), 
                         error = function(cond) { return('ERROR: costs function not returning correct results.') })
  cost.table[, scenario := as.character(scenario)]
  cost.diff = cost.table[, .(scenario, `Cost (MM$)` = `Cost (MM$)` - `Cost (MM$)`[scenario == ref.scenario]), by=.(Type)]
  cost.diff.table = dcast.data.table(cost.diff, Type~scenario, value.var = 'Cost (MM$)')

return(cost.diff.table)
}

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Annual Reserve Shortages
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

annual_reserves_short = function(total.reserve.provision, total.reserve.shortage) {
  
  annual.reserves.scen = tryCatch( annual_reserves(total.reserve.provision, total.reserve.shortage), error = function(cond) { return('ERROR: annual_reserves function not returning correct results.') })
  reserves.shortage.table = dcast.data.table(annual.reserves.scen, Type~scenario, value.var = "Shortage (GWh)")
  
  return(reserves.shortage.table)
}

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Annual Reserve Provision
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Calculates total reserve provision by generator type for each reserve product

annual_reserves_provision = function(total.gen.res) {
  
  setkey(total.gen.res, name)
  yr.gen.res = total.gen.res[property == 'Provision', Type:=gen.type.mapping[name] ]
  yr.gen.res = yr.gen.res[, .(GWh = sum(value)), by=.(scenario,parent,Type)]
  setnames(yr.gen.res,"parent","Reserve")
  
  return(yr.gen.res)
}

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Interface Flows 
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

interface_flows_diff = function() {
  
  int.flows = int.data.interface %>%
    select(name, time, value) %>%
    filter(name %in% interfaces)
  
  year.flows = yr.data.interface.flow %>%
    select(name, time, value) %>%
    filter(name %in% interfaces)
  
  int.flows$Type = 'Interval_Flow'
  year.flows$Type = 'Annual_Flow'
    
  flows = rbind(int.flows, year.flows)
  
  return(flows)
}

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Region and Zone Stats
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

region_diff_stats = function() {
  r.data = yr.data.region
  r.stats = dcast(r.data, name~property, value.var = 'value', fun.aggregate = sum)
  return(r.stats)
}

zone_diff_stats = function() {
  z.data = yr.data.region
  z.stats = z.data %>%
    join(select(region.zone.mapping, name=Region, Zone), by='name', match='first') %>%
    dcast(Zone~property, value.var = 'value', fun.aggregate = sum)
  colnames(z.stats)[colnames(z.stats)=='Zone']='name'
  return(z.stats)
}


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Capacity Factor
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

capacity_factor_diff = function() {
  
  cf = yr.data.generator
  
  mc = cf %>%
    filter(property == 'Installed Capacity') %>%
    rename(MaxCap = value) %>%
    join(gen.type.mapping, by = 'name')
  
  gen = cf %>%
    filter(property == 'Generation') %>%
    rename(Gen = value) %>%
    join(gen.type.mapping, by = 'name')
    
    
  mc$Type = factor(mc$Type, levels = rev(c(gen.order)))
  
  c.factor = mc %>%
    select(name, MaxCap, Type) %>%
    join(gen[,c('name', 'Gen')], by = 'name') %>%
    select(Type, MaxCap, Gen) %>%
    ddply('Type', summarise, MaxCap=sum(MaxCap), Gen=sum(Gen))  

  n.int = length(seq(from = first.day, to = last.day, by = 'day'))*intervals.per.day
  c.factor$`Capacity Factor (%)` = c.factor$Gen/(c.factor$MaxCap/1000*n.int)*100
  
  c.factor = select(c.factor, Type, `Capacity Factor (%)`)
  
  return(c.factor)
  
}
