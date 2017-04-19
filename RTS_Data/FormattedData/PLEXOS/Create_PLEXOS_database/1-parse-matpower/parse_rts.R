pacman::p_load(data.table)
SourceData = normalizePath(file.path('../../../SourceData/'))
output.dir = normalizePath(file.path('./1-parse-matpower/outputs/'))

src.bus = fread(file.path(SourceData,'bus.csv'))
src.branch = fread(file.path(SourceData,'branch.csv'))
src.dc_branch = fread(file.path(SourceData,'dc_branch.csv'))
src.gen = fread(file.path(SourceData,'gen.csv'),colClasses = 'numeric')
src.simulation_objects = fread(file.path(SourceData,'simulation_objects.csv'))
src.timeseries_pointers = fread(file.path(SourceData,'timeseries_pointers.csv'))
src.reserves = fread(file.path(SourceData,'reserves.csv'))
src.storage = fread(file.path(SourceData,'storage.csv'))

all.tabs <- c()

#  TODO: For now, these are hardcoded
"da_rt"     
"da_rt_filepointer_template"

"import_horizons"
"import_models"                   
"import_report"

"STSched_MTSched_Perf_Transm_Prod"


# Fuel Prices
fuel.price = unique(src.gen[,.(Fuel, Price = `Fuel Price $/MMBTU`)])
all.tabs = c(all.tabs,"fuel.price")

gen.fuel = src.gen[,.(Generator = `GEN UID`, Fuel)]
all.tabs = c(all.tabs,"gen.fuel")

# Gen Cost Data
hr.traunches = tstrsplit(names(src.gen)[grep('Output_pct',names(src.gen))],'_')[[3]]
gen.cost.data = src.gen[,.SD,.SDcols = c('GEN UID',paste0('Net_Heat_Rate_',hr.traunches),paste0('Output_pct_',hr.traunches)) ]
gen.cost.data = melt(gen.cost.data,id.vars = 'GEN UID')
gen.cost.data[,Band:= gsub('.*_([0-9]+).*','\\1',variable)]
gen.cost.data[,variable:= gsub('(.*)_[0-9]+.*','\\1',variable)]
gen.cost.data = dcast.data.table(gen.cost.data, `GEN UID`+Band~variable)
names(gen.cost.data) = c('Generator','Band','Heat Rate','Load Point')
all.tabs = c(all.tabs,"gen.cost.data")

# Min Gen
gen.mingen = src.gen[,.(Generator = `GEN UID`, `Min Stable Level` = `PMin MW`)]
all.tabs = c(all.tabs,"gen.mingen")

# Min up down times
gen.minupdown = src.gen[,.(Generator = `GEN UID`, `Min Down Time` = `Min Down Time Hr`,`Min Up Time` = `Min Up Time Hr`)]
gen.minupdown = gen.minupdown[!(`Min Down Time` == 0 & `Min Up Time` == 0),]
all.tabs = c(all.tabs,"gen.minupdown")

# outage rates
gen.outages = src.gen[,.(Generator = `GEN UID`,`Forced Outage Rate` = FOR, `Mean Time to Repair` = `MTTR Hr` )]
gen.outages = gen.outages[!(`Forced Outage Rate` == 0 & `Mean Time to Repair` == 0),]
all.tabs = c(all.tabs,"gen.outages")

# ramp rates
gen.ramps = src.gen[,.(Generator = `GEN UID`,`Max Ramp Up` = `Ramp Rate MW/Min`, `Max Ramp Down` = `Ramp Rate MW/Min` )]
gen.ramps = gen.ramps[!(`Max Ramp Up` == 0 & `Max Ramp Down` == 0),]
all.tabs = c(all.tabs,"gen.ramps")

# UC costs
gen.startshut = src.gen[,.(Generator = `GEN UID`,`Start Cost` = `Start Heat Cold MBTU` * `Fuel Price $/MMBTU` , `Shutdown Cost` = `Start Heat Cold MBTU` * `Fuel Price $/MMBTU` )]
gen.startshut = gen.startshut[!(`Start Cost` == 0 &  `Shutdown Cost` == 0),]
all.tabs = c(all.tabs,"gen.startshut")

#  Gen Data
generator.data = src.gen[,.(Generator = `GEN UID`, `Max Capacity` = `PMax MW`, Node = `Bus ID`, Units = 1)]
all.tabs = c(all.tabs,"generator.data")

# tx AC line data
line.data = src.branch[,.(Line = ID, `Node From` = `From Bus`, `Node To` = `To Bus`, Resistance = R, Reactance = X,
              `Max Flow` = `Cont Rating`, rateA = `LTE Rating`, rateB = `STE Rating`, rateC = `STE Rating`, Units = 1, `Min Flow` = `Cont Rating` * -1)]

# tx DC line data
dc.max.flow = as.numeric(src.dc_branch[Variable == 'Power demand (MW):',Value])
dc.nodes = unique(src.dc_branch[grepl('Converter bus',Filter),Filter])
dc.node.from = as.numeric(strsplit(dc.nodes[1],'=')[[1]][2])
dc.node.to = as.numeric(strsplit(dc.nodes[2],'=')[[1]][2])

dc.line.data = data.table(Line = paste0(dc.node.from,'_',dc.node.to,'_1'),
                          `Node From`=dc.node.from,`Node To`=dc.node.to,
                          Resistance = 0,Reactance = NA,
                          `Max Flow`=dc.max.flow,
                          rateA=dc.max.flow, rateB=dc.max.flow, rateC=dc.max.flow,
                          Units=1,
                          `Min Flow`=-1*dc.max.flow)

rm(dc.max.flow,dc.nodes,dc.node.from,dc.node.to)

line.data = rbind(line.data,dc.line.data,fill=TRUE)

all.tabs = c(all.tabs,"line.data")

# node data
node.data = src.bus[,.(Node = `Bus ID`, Voltage = BaseKV, Region = Area, Zone = `Sub Area`)]
all.tabs = c(all.tabs,"node.data")

# node load participation factors 
node.lpf = src.bus[,.(Node = `Bus ID`, Load = `MW Load`, Status = 1)]
all.tabs = c(all.tabs,"node.lpf")

# reference node(s)
region.refnode.data = src.bus[`Bus Type`=='Ref',.(Region = Area, `Region.Reference Node` = `Bus ID`)]
all.tabs = c(all.tabs,"region.refnode.data")

# Reserve DAta
eligible.gens = src.reserves[,.(`Reserve Product`,`Elegible Gen Types`)]

eligible.gens[,`Elegible Gen Types` := gsub("\\(",'',`Elegible Gen Types`)]
eligible.gens[,`Elegible Gen Types` := gsub("\\)",'',`Elegible Gen Types`)]
eligible.gens = cbind(eligible.gens, setDT(tstrsplit(eligible.gens$`Elegible Gen Types`,",")))[,`Elegible Gen Types`:=NULL]
eligible.gens = melt(eligible.gens,id.vars = 'Reserve Product',value.name = 'Elegible Gen Types')[,variable:=NULL]

direction = data.frame(row.names = c('Up','Down'),value = c(1,2))
reserve.data = src.reserves[,.(Reserve = `Reserve Product`,
                               `Is Enabled` = 1,
                               Type = direction[gsub('.*_(.*)','\\1',`Reserve Product`),'value'], 
                               Scenario = paste0('Add ',`Reserve Product`),
                               Timeframe = `Timeframe (sec)`,
                               VoRS = 4000,
                               `Mutually Exclusive` = 1)]

reserve.generators = merge(eligible.gens[,.(Reserve = `Reserve Product`,`Unit Type` = `Elegible Gen Types`)],
                           src.gen[,.(Generator = `GEN UID`,`Unit Type`)],by = "Unit Type",
                           allow.cartesian = T)[,`Unit Type`:= NULL]

reserve.provisions = src.timeseries_pointers[Simulation=='DAY_AHEAD' & Object %in% unique(src.reserves$`Reserve Product`),
                        .(Reserve = Object,`Min Provision` = paste0('../',`Data File`))]

reserve.provisions.rt = src.timeseries_pointers[Simulation=='REAL_TIME' & Object %in% unique(src.reserves$`Reserve Product`),
                                                .(Reserve = Object,`Min Provision` = paste0('../',`Data File`))]
all.tabs <- c(all.tabs, "reserve.data","reserve.generators","reserve.provisions","reserve.provisions.rt")

# load
region.load.da = data.table(unique(src.bus[,.(Region = Area)]), src.timeseries_pointers[Object == 'Load' & Simulation == 'DAY_AHEAD',.(Load = paste0('../',`Data File`))])
region.load.rt = data.table(unique(src.bus[,.(Region = Area)]), src.timeseries_pointers[Object == 'Load' & Simulation == 'REAL_TIME',.(Load = paste0('../',`Data File`))])
all.tabs = c(all.tabs,"region.load.da","region.load.rt" )

# VG
gen.vg.da.fixed = src.timeseries_pointers[( grepl('hydro',Object,ignore.case = T) | grepl('rtpv',Object,ignore.case = T) ) & Simulation == 'DAY_AHEAD' & Parameter == 'PMax MW',.(Generator = Object, `Fixed Load` = paste0('../',`Data File`))]
gen.vg.rt.fixed = src.timeseries_pointers[( grepl('hydro',Object,ignore.case = T) | grepl('rtpv',Object,ignore.case = T) ) & Simulation == 'REAL_TIME' & Parameter == 'PMax MW',.(Generator = Object, `Fixed Load` = paste0('../',`Data File`))]

gen.da.vg = src.timeseries_pointers[( grepl('wind',Object,ignore.case = T) | grepl('_pv',Object,ignore.case = T) | grepl('csp',Object,ignore.case = T) ) & Simulation == 'DAY_AHEAD' & Parameter == 'PMax MW',.(Generator = Object, Rating = paste0('../',`Data File`))]
gen.rt.vg = src.timeseries_pointers[( grepl('wind',Object,ignore.case = T) | grepl('_pv',Object,ignore.case = T) | grepl('csp',Object,ignore.case = T) ) & Simulation == 'REAL_TIME' & Parameter == 'PMax MW',.(Generator = Object, Rating = paste0('../',`Data File`))]

storage.csp = src.timeseries_pointers[grepl('csp',Object,ignore.case = T) & Simulation == 'DAY_AHEAD' & Parameter == 'Natural_Inflow',.(Storage = Object, `Natural Inflow` = paste0('../',`Data File`))]

all.tabs = c(all.tabs,"gen.vg.da.fixed","gen.vg.rt.fixed","gen.da.vg","gen.rt.vg","storage.csp")

# CSP Storage
storage.props = src.storage[,.(Storage = paste(Storage,'Storage',`GEN UID`,sep='_'),`Max Volume`= `Max Volume GWh`,`Decomposition Method` = 0, `End Effects Method` = 1, `Spill Penalty` = 0, `Max Spill` = 1e+30)]
storage.props.rt = src.storage[,.(Storage = paste(Storage,'Storage',`GEN UID`,sep='_'),`Enforce Bounds`= 0)]

all.tabs = c(all.tabs, "storage.props","storage.props.rt")

for (tab in all.tabs) {
  
  write.csv(get(tab), file.path(output.dir, paste0(tab, ".csv")),
            quote = FALSE, row.names = FALSE)
  
}

rm(tab, all.tabs)

