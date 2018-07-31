pacman::p_load(data.table)
SourceData = normalizePath(file.path('../../../SourceData/'))
output.dir = normalizePath(file.path('1-parse-SourceData/outputs/'))
extra_input.dir = normalizePath(file.path('1-parse-SourceData/extra_inputs'))
unlink(file.path(output.dir,'*.csv'))
file.copy(list.files(extra_input.dir,pattern = '*.csv',full.names = T),output.dir)

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
fuel.data = unique(src.gen[,.(Fuel, Price = `Fuel Price $/MMBTU`)])
fuel.data = fuel.data[!is.na(Fuel)]
all.tabs = c(all.tabs,"fuel.data")

gen.fuel = src.gen[,.(Generator = `GEN UID`, Fuel)]
#all.tabs = c(all.tabs,"gen.fuel")

hr.split = 0.75 # allocation heat requirement below min stable level to Heat Rate Base

# Gen Base Heat Data
gen.cost.data.base = src.gen[,.(`GEN UID`,`PMin MW`,HR_avg_0)]
gen.cost.data.base[,`Heat Rate Base`:=hr.split*`PMin MW`*HR_avg_0*0.001] # to get mmBTU
setnames(gen.cost.data.base,c('GEN UID'),c('Generator'))
gen.cost.data.base = gen.cost.data.base[,.(Generator,`Heat Rate Base`)]
gen.cost.data.base = gen.cost.data.base[`Heat Rate Base` != 0]
gen.cost.data.base = gen.cost.data.base[!(Generator == "212_CSP_1")] # exclude CSP
all.tabs = c(all.tabs,"gen.cost.data.base")

# Gen Heat Data
setnames(src.gen,'HR_avg_0','HR_incr_0')
hr.traunches = tstrsplit(names(src.gen)[grep('Output_pct',names(src.gen))],'_')[[3]]
gen.cost.data = src.gen[,.SD,.SDcols = c('GEN UID','PMax MW',paste0('HR_incr_',hr.traunches),
                                         paste0('Output_pct_',hr.traunches)) ]
gen.cost.data[,HR_incr_0:=ifelse(`GEN UID` == "212_CSP_1",HR_incr_0,(1-hr.split)*HR_incr_0)]
gen.cost.data = melt(gen.cost.data,id.vars = c('GEN UID','PMax MW'))
gen.cost.data[,Band:= gsub('.*_([0-9]+).*','\\1',variable)]
gen.cost.data = gen.cost.data[!is.na(value)] # remove higher-band NAs

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
gen.cost.data[,`Load Point`:=round(`Load Point`,1)]
gen.cost.data = gen.cost.data[`Load Point`!=0]

gen.efficiency.data = gen.cost.data[grepl('CSP',Generator)]
setnames(gen.efficiency.data,'Heat Rate Incr','Efficiency Incr')
gen.cost.data = gen.cost.data[!(Generator == "212_CSP_1")]

all.tabs = c(all.tabs,"gen.cost.data","gen.efficiency.data")

# outage rates
gen.outages = src.gen[,.(Generator = `GEN UID`,`Forced Outage Rate` = 0, `Mean Time to Repair` = `MTTR Hr` )]
gen.outages = gen.outages[!(`Forced Outage Rate` == 0 & `Mean Time to Repair` == 0),]
all.tabs = c(all.tabs,"gen.outages")

# generator parameters
generator.data = src.gen[,.(Generator = `GEN UID`,
                            category = Category,
                            Nodes_Node = `Bus ID`,
                            Fuels_Fuel = Fuel,
                            `Max Capacity` = `PMax MW`,
                            Units = ifelse(grepl('Storage|CSP',Category),0,1),
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

# generator-storage memberships
generator.memberships = src.storage[,.(Generator = `GEN UID`,Storage)]
generator.memberships[,membership:="Tail Storage_Storage"]
generator.memberships[grepl('HEAD',Storage),membership:="Head Storage_Storage"]
generator.memberships = data.table(dcast(generator.memberships,Generator ~ membership,
                                         value.var = c('Storage')))

all.tabs = c(all.tabs,"generator.memberships")
# tx AC line data
line.data = src.branch[,.(Line = UID, 
                         category = paste0('AC_',substr(`From Bus`,1,1)),
                        `Node From_Node` = `From Bus`, `Node To_Node` = `To Bus`, 
                         Resistance = R, Reactance = X,
                        `Max Flow` = `Cont Rating`, `Min Flow` = `Cont Rating` * -1, 
                         Units = 1)]
line.data[!(substr(`Node From_Node`,1,1) == substr(`Node To_Node`,1,1)),category := "Interregion_AC"]

# tx DC line data
dc.max.flow = as.numeric(src.dc_branch[Variable == 'Power demand (MW):',Value])
dc.nodes = unique(src.dc_branch[grepl('Converter bus',Filter),Filter])
dc.node.from = as.numeric(strsplit(dc.nodes[1],'=')[[1]][2])
dc.node.to = as.numeric(strsplit(dc.nodes[2],'=')[[1]][2])

dc.line.data = data.table(Line = paste0(dc.node.from,'_',dc.node.to,'_1'),
                          category = 'Interregion_DC',
                          `Node From_Node`=dc.node.from,`Node To_Node`=dc.node.to,
                          Resistance = 0,Reactance = NA,
                          `Max Flow`=dc.max.flow,
                          `Min Flow`=-1*dc.max.flow,
                          Units=1
                          )

rm(dc.max.flow,dc.nodes,dc.node.from,dc.node.to)

line.data = rbind(line.data,dc.line.data,fill=TRUE)

all.tabs = c(all.tabs,"line.data")

# node data
node.data = src.bus[,.(Node = `Bus ID`,category = Area, Voltage = BaseKV, `Load Participation Factor` = `MW Load`,Region_Region = Area, Zone_Zone = `Sub Area`,Units = 1,`Is Slack Bus` = ifelse(`Bus ID` == '113',-1,0)))]
node.data[,`Load Participation Factor`:=`Load Participation Factor`/sum(`Load Participation Factor`),by = c("Region_Region")]
node.data[is.nan(`Load Participation Factor`),`Load Participation Factor`:=0]
all.tabs = c(all.tabs,"node.data")

# region data
region.data = unique(node.data[,.(Region = `Region_Region`)])
# region.refnode.data = src.bus[`Bus Type`=='Ref',.(Region = Area, `Reference Node_Node` = as.character(`Bus ID`))]
# region.data = merge(region.data,region.refnode.data,all.x = TRUE,by = c('Region'))
# region.data[is.na(`Reference Node_Node`),`Reference Node_Node`:=""]
all.tabs = c(all.tabs,"region.data")
# rm(region.refnode.data)

# zone data
zone.data = unique(node.data[,.(Zone = `Zone_Zone`)])
all.tabs = c(all.tabs,"zone.data")

# Reserve Data
eligible.gens = src.reserves[,.(`Reserve Product`,`Eligible Gen Categories`)]
eligible.regions = src.reserves[,.(`Reserve Product`,`Eligible Regions`)]

eligible.gens[,`Eligible Gen Categories` := gsub("\\(",'',`Eligible Gen Categories`)]
eligible.gens[,`Eligible Gen Categories` := gsub("\\)",'',`Eligible Gen Categories`)]
eligible.regions[,`Eligible Regions` := gsub("\\(",'',`Eligible Regions`)]
eligible.regions[,`Eligible Regions` := gsub("\\)",'',`Eligible Regions`)]
eligible.gens = cbind(eligible.gens, setDT(tstrsplit(eligible.gens$`Eligible Gen Categories`,",")))[,`Eligible Gen Categories`:=NULL]
eligible.regions = cbind(eligible.regions, setDT(tstrsplit(eligible.regions$`Eligible Regions`,",")))[,`Eligible Regions`:=NULL]
eligible.gens = melt(eligible.gens,id.vars = 'Reserve Product',value.name = 'Eligible Gen Categories')[,variable:=NULL]
eligible.regions = melt(eligible.regions,id.vars = 'Reserve Product',value.name = 'Eligible Regions')[,variable:=NULL]

eligible.gens = merge(eligible.gens,eligible.regions[!is.na(`Eligible Regions`)],by = c('Reserve Product'),allow.cartesian = TRUE)

reserve.data = src.reserves[,.(Reserve = `Reserve Product`,
                               `Is Enabled` = 0,
                               Type = ifelse(grepl("Down",`Reserve Product`),2,1), 
                               Timeframe = `Timeframe (sec)`,
                               VoRS = 4000,
                               `Mutually Exclusive` = 1)]

reserve.enable = src.reserves[,.(Reserve = `Reserve Product`,
                                `Is Enabled` = -1,
                                scenario = paste0('Add ',`Reserve Product`),
                                scenario.cat = "Reserves")]

reserve.map = merge(src.gen[,.(Generator = `GEN UID`,`Category`,Bus = `Bus ID`)],
                    src.bus[,.(Bus = `Bus ID`,Region = as.character(`Area`))],
                    by = 'Bus')

reserve.memberships = merge(eligible.gens[,.(Reserve = `Reserve Product`,`Category` = `Eligible Gen Categories`,`Region` = `Eligible Regions`)],
                           reserve.map,by = c("Category","Region"),
                           allow.cartesian = T)[,c("Category","Region","Bus"):= NULL]
setnames(reserve.memberships,'Generator','Generators_Generator')

rm(reserve.map)

reserve.provisions = src.timeseries_pointers[Simulation=='DAY_AHEAD' & Object %in% unique(src.reserves$`Reserve Product`),
                        .(Reserve = Object,`Min Provision` = paste0('../',`Data File`))]

reserve.provisions.rt = src.timeseries_pointers[Simulation=='REAL_TIME' & Object %in% unique(src.reserves$`Reserve Product`),
                                                .(Reserve = Object,`Min Provision` = paste0('../',`Data File`),
                                                scenario = 'RT Run',scenario.cat = "Object properties")]
all.tabs <- c(all.tabs, "reserve.data","reserve.memberships","reserve.enable","reserve.provisions","reserve.provisions.rt")

# load
region.load.da = data.table(unique(src.bus[,.(Region = Area)]), 
                            src.timeseries_pointers[Object == 'Load' & Simulation == 'DAY_AHEAD',.(Load = paste0('../',`Data File`))],
                            scenario = "Load: DA",scenario.cat = "Object properties")
region.load.rt = data.table(unique(src.bus[,.(Region = Area)]), 
                            src.timeseries_pointers[Object == 'Load' & Simulation == 'REAL_TIME',.(Load = paste0('../',`Data File`))],
                            scenario = "Load: RT",scenario.cat = "Object properties")
all.tabs = c(all.tabs,"region.load.da","region.load.rt" )

# VG
gen.da.vg.fixed = src.timeseries_pointers[( grepl('hydro',Object,ignore.case = T) | grepl('rtpv',Object,ignore.case = T) ) & Simulation == 'DAY_AHEAD' & Parameter == 'PMax MW',.(Generator = Object, `Fixed Load` = paste0('../',`Data File`),scenario = "RE: DA",scenario.cat = "Object properties")]
gen.rt.vg.fixed = src.timeseries_pointers[( grepl('hydro',Object,ignore.case = T) | grepl('rtpv',Object,ignore.case = T) ) & Simulation == 'REAL_TIME' & Parameter == 'PMax MW',.(Generator = Object, `Fixed Load` = paste0('../',`Data File`),scenario = "RE: RT",scenario.cat = "Object properties")]

gen.da.vg = src.timeseries_pointers[( grepl('wind',Object,ignore.case = T) | grepl('_pv',Object,ignore.case = T) | grepl('csp',Object,ignore.case = T) | grepl('rtpv',Object,ignore.case = T) ) & Simulation == 'DAY_AHEAD' & Parameter == 'PMax MW',.(Generator = Object, Rating = paste0('../',`Data File`),scenario = "RE: DA",scenario.cat = "Object properties")]
gen.rt.vg = src.timeseries_pointers[( grepl('wind',Object,ignore.case = T) | grepl('_pv',Object,ignore.case = T) | grepl('csp',Object,ignore.case = T) | grepl('rtpv',Object,ignore.case = T) ) & Simulation == 'REAL_TIME' & Parameter == 'PMax MW',.(Generator = Object, Rating = paste0('../',`Data File`),scenario = "RE: RT",scenario.cat = "Object properties")]

storage.da.csp = src.timeseries_pointers[grepl('csp',Object,ignore.case = T) & Simulation == 'DAY_AHEAD' & Parameter == 'Natural_Inflow',.(Storage = Object, `Natural Inflow` = paste0('../',`Data File`),scenario = "RE: DA",scenario.cat = "Object properties")]
storage.rt.csp = src.timeseries_pointers[grepl('csp',Object,ignore.case = T) & Simulation == 'REAL_TIME' & Parameter == 'Natural_Inflow',.(Storage = Object, `Natural Inflow` = paste0('../',`Data File`),scenario = "RE: RT",scenario.cat = "Object properties")]
storage.csp = rbind(storage.da.csp,storage.rt.csp)
rm(storage.da.csp,storage.rt.csp)

all.tabs = c(all.tabs,"gen.da.vg.fixed","gen.rt.vg.fixed","gen.da.vg","gen.rt.vg","storage.csp")

# CSP and pumped storage
storage.data = src.storage[,.(Storage = `Storage`,
                             category = 'Storage',
                             `Max Volume`= `Max Volume GWh`,
                             `Initial Volume` = `Initial Volume GWh`,
                             `Decomposition Method` = 0, 
                             `End Effects Method` = c(1,2,2),
                             `Max Spill` = 1e+30)]
storage.data[grepl('CSP',Storage),category:='CSP Storage']
storage.props.rt = src.storage[,.(Storage = `Storage`,`Enforce Bounds`= 0,`End Effects Method` = 1,scenario = "RT Run",scenario.cat = "Object properties")]

generator.start.energy = src.storage[!is.na(`Start Energy`),.(Storage,
                                                            Generator = `GEN UID`,
                                                            `Flow at Start` = `Start Energy`)]

all.tabs = c(all.tabs, "storage.data","storage.props.rt","generator.start.energy")

for (tab in all.tabs) {
  
  write.csv(get(tab), file.path(output.dir, paste0(tab, ".csv")),
            quote = FALSE, row.names = FALSE)
  
}

rm(tab, all.tabs)

