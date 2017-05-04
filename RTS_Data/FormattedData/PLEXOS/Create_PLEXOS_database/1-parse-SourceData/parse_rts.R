pacman::p_load(data.table)
SourceData = normalizePath(file.path('../../../SourceData/'))
output.dir = normalizePath(file.path('./1-parse-SourceData/outputs/'))

src.bus = fread(file.path(SourceData,'bus.csv'))
src.branch = fread(file.path(SourceData,'branch.csv'))
src.dc_branch = fread(file.path(SourceData,'dc_branch.csv'))
src.gen = fread(file.path(SourceData,'gen.newHRs.csv'),colClasses = 'numeric')
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
fuel.price = fuel.price[!is.na(Fuel)]
all.tabs = c(all.tabs,"fuel.price")

gen.fuel = src.gen[,.(Generator = `GEN UID`, Fuel)]
all.tabs = c(all.tabs,"gen.fuel")

# Gen Base Cost Data
gen.cost.data.base = src.gen[,.(`GEN UID`,`PMin MW`,HR_avg_0)]
gen.cost.data.base[,`Heat Rate Base`:=0.75*`PMin MW`*HR_avg_0]
setnames(gen.cost.data.base,c('GEN UID'),c('Generator'))
gen.cost.data.base = gen.cost.data.base[,.(Generator,`Heat Rate Base`)]
all.tabs = c(all.tabs,"gen.cost.data.base")

# Gen Cost Data
setnames(src.gen,'HR_avg_0','HR_incr_0')
hr.traunches = tstrsplit(names(src.gen)[grep('Output_pct',names(src.gen))],'_')[[3]]
gen.cost.data = src.gen[,.SD,.SDcols = c('GEN UID','PMax MW',paste0('HR_incr_',hr.traunches),
                                         paste0('Output_pct_',hr.traunches)) ]
gen.cost.data[,HR_incr_0:=0.25*HR_incr_0]
gen.cost.data = melt(gen.cost.data,id.vars = c('GEN UID','PMax MW'))
gen.cost.data[,Band:= gsub('.*_([0-9]+).*','\\1',variable)]

# make sure bands start at 1
if(min(as.numeric(gen.cost.data[,Band]))==0){
  gen.cost.data[,Band:=as.numeric(Band)+1]
}

gen.cost.data[,variable:= gsub('(.*)_[0-9]+.*','\\1',variable)]
gen.cost.data = dcast.data.table(gen.cost.data, `GEN UID`+`PMax MW`+Band~variable)
names(gen.cost.data) = c('Generator','Max Capacity', 'Band','Heat Rate Incr','Load Point')
gen.cost.data[,`Load Point`:=`Load Point`*`Max Capacity`]
gen.cost.data[,`Max Capacity`:=NULL]
gen.cost.data[grepl('HYDRO',Generator),c('Heat Rate Incr','Load Point'):=0]
all.tabs = c(all.tabs,"gen.cost.data")

# outage rates
gen.outages = src.gen[,.(Generator = `GEN UID`,`Forced Outage Rate` = 100*FOR, `Mean Time to Repair` = `MTTR Hr` )]
gen.outages = gen.outages[!(`Forced Outage Rate` == 0 & `Mean Time to Repair` == 0),]
all.tabs = c(all.tabs,"gen.outages")

# generator parameters
generator.data = src.gen[,.(Generator = `GEN UID`,
                            Category = Category,
                            Nodes_Node = `Bus ID`,
                            Fuels_Fuel = Fuel,
                            `Max Capacity` = `PMax MW`,
                            Units = 1,
                            `Shutdown Cost` = `Start Heat Cold MBTU` * `Fuel Price $/MMBTU` ,
                            `Start Cost` = (`Start Heat Cold MBTU` * `Fuel Price $/MMBTU`) + `Non Fuel Start Cost $` ,
                            `Max Ramp Up` = ifelse(`Ramp Rate MW/Min` == 0, NA,`Ramp Rate MW/Min`),
                            `Max Ramp Down` = ifelse(`Ramp Rate MW/Min` == 0, NA,`Ramp Rate MW/Min`),
                            `Pump Load` = ifelse(`Pump Load MW` == 0, NA, `Pump Load MW`),
                            `Pump Efficiency` = ifelse(`Storage Roundtrip Efficiency` == 0, NA, `Storage Roundtrip Efficiency`),
                            `Min Down Time` = `Min Down Time Hr`,
                            `Min Up Time` = `Min Up Time Hr`,
                            `Min Stable Level` = `PMin MW`
                            )]
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
eligible.gens = src.reserves[,.(`Reserve Product`,`Elegible Gen Categories`)]

eligible.gens[,`Elegible Gen Categories` := gsub("\\(",'',`Elegible Gen Categories`)]
eligible.gens[,`Elegible Gen Categories` := gsub("\\)",'',`Elegible Gen Categories`)]
eligible.gens = cbind(eligible.gens, setDT(tstrsplit(eligible.gens$`Elegible Gen Categories`,",")))[,`Elegible Gen Categories`:=NULL]
eligible.gens = melt(eligible.gens,id.vars = 'Reserve Product',value.name = 'Elegible Gen Categories')[,variable:=NULL]

direction = data.frame(row.names = c('Up','Down'),value = c(1,2))
reserve.data = src.reserves[,.(Reserve = `Reserve Product`,
                               `Is Enabled` = -1,
                               Type = direction[gsub('.*_(.*)','\\1',`Reserve Product`),'value'], 
                               Scenario = paste0('Add ',`Reserve Product`),
                               Timeframe = `Timeframe (sec)`,
                               VoRS = 4000,
                               `Mutually Exclusive` = 1)]

reserve.generators = merge(eligible.gens[,.(Reserve = `Reserve Product`,`Category` = `Elegible Gen Categories`)],
                           src.gen[,.(Generator = `GEN UID`,`Category`)],by = "Category",
                           allow.cartesian = T)[,`Category`:= NULL]

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
gen.da.vg.fixed = src.timeseries_pointers[( grepl('hydro',Object,ignore.case = T) | grepl('rtpv',Object,ignore.case = T) ) & Simulation == 'DAY_AHEAD' & Parameter == 'PMax MW',.(Generator = Object, `Fixed Load` = paste0('../',`Data File`))]
gen.rt.vg.fixed = src.timeseries_pointers[( grepl('hydro',Object,ignore.case = T) | grepl('rtpv',Object,ignore.case = T) ) & Simulation == 'REAL_TIME' & Parameter == 'PMax MW',.(Generator = Object, `Fixed Load` = paste0('../',`Data File`))]

gen.da.vg = src.timeseries_pointers[( grepl('wind',Object,ignore.case = T) | grepl('_pv',Object,ignore.case = T) | grepl('csp',Object,ignore.case = T) ) & Simulation == 'DAY_AHEAD' & Parameter == 'PMax MW',.(Generator = Object, Rating = paste0('../',`Data File`))]
gen.rt.vg = src.timeseries_pointers[( grepl('wind',Object,ignore.case = T) | grepl('_pv',Object,ignore.case = T) | grepl('csp',Object,ignore.case = T) ) & Simulation == 'REAL_TIME' & Parameter == 'PMax MW',.(Generator = Object, Rating = paste0('../',`Data File`))]

storage.csp = src.timeseries_pointers[grepl('csp',Object,ignore.case = T) & Simulation == 'DAY_AHEAD' & Parameter == 'Natural_Inflow',.(Storage = Object, `Natural Inflow` = paste0('../',`Data File`))]

all.tabs = c(all.tabs,"gen.da.vg.fixed","gen.rt.vg.fixed","gen.da.vg","gen.rt.vg","storage.csp")

# CSP Storage
storage.props = src.storage[,.(Storage = `Storage`,`Max Volume`= `Max Volume GWh`,`Initial Volume` = `Initial Volume GWh`,`Decomposition Method` = 0, `End Effects Method` = 1, `Spill Penalty` = 0, `Max Spill` = 1e+30)]
storage.props.rt = src.storage[,.(Storage = `Storage`,`Enforce Bounds`= 0)]

all.tabs = c(all.tabs, "storage.props","storage.props.rt")

for (tab in all.tabs) {
  
  write.csv(get(tab), file.path(output.dir, paste0(tab, ".csv")),
            quote = FALSE, row.names = FALSE)
  
}

rm(tab, all.tabs)

