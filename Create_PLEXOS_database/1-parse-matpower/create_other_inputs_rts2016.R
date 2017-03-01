# run after parse_matpower (or sourced from parse_matpower)
# required input files are read in in each section

# make new create_other_inputs file
# - min gen
# - forced outage rate
# - heat rate
# - fuel price
# - start cost (adjust)
# - add VG
# - attach load
# - attach hydro
# - add reserves

# list of tables to write out in the end
if (!exists("all.tabs")) all.tabs <- c()
gen.params = fread('inputs/gen_params.csv')
gen.id = fread('inputs/gen_id.csv')

#------------------------------------------------------------------------------|
# temp? adjust regions/zones to match old NESTA RTS ----
#------------------------------------------------------------------------------|
# before, nodes were broken into 3 regions and regions==zones. Now, regions
# and zones are different. for now, making zones regions and regions what they
# were in the old case

node.data[, Zone := as.numeric(Region)]
node.data[, Region := substr(Region, 1, 1)] # just tens digit

# add to all.tabs
all.tabs <- c(all.tabs, "node.data")

#------------------------------------------------------------------------------|
# add load datafile pointers to nodes that have load on them ----
#------------------------------------------------------------------------------|

# hardcode reigonal filepointers

region.load.da <- data.table(Region = c(1:3), 
                             Load = "data_files\\load\\DA_hourly.csv")

region.load.rt <- data.table(Region = c(1:3), 
                             Load = "data_files\\load\\RT_5min.csv")

# add to all.tabs
all.tabs <- c(all.tabs, "region.load.da", "region.load.rt")

#------------------------------------------------------------------------------|
# add load participation factor for load nodes ----
#------------------------------------------------------------------------------|
# can leave node load in MW; psse2plexos will normalize

node.lpf <- struct.list$bus[,.(Node = bus_i, Load = Pd, Status = 1)]

# add to all.tabs
all.tabs <- c(all.tabs, "node.lpf")



#------------------------------------------------------------------------------|
# fuels and fuel price ----
#------------------------------------------------------------------------------|

# add unit type to generator
gen.fuel <- gen.id[,Generator := paste0(Bus, "_", ID)]

gen.fuel <- gen.fuel[,.(Generator, Type = Unit)]

# fuel type to unit type
fuels <- gen.params[,.(Type = Unit, Fuel)]

# fuel type to generator
gen.fuel <- merge(gen.fuel, fuels, all.x = TRUE, by='Type')

# leave only Generator and Fuel columns
gen.fuel[,Type := NULL]

# add fuel to synchronous condensers
gen.fuel[is.na(Fuel), Fuel := 'SynchCond']

# get fuel price (2010$/MMBtu)
fuel.price <- fread("inputs/fuel_prices.csv")
fuel.price[, Price := round(Price, 2)]

# add to get written out
all.tabs <- c(all.tabs, "gen.fuel", "fuel.price")

#------------------------------------------------------------------------------|
# generator outages by type ----
#------------------------------------------------------------------------------|

# read gen types
gen.type = gen.id[,Generator := paste0(Bus, "_", ID)]
gen.type = gen.type[,.(Generator, Unit)]

# read generator outage info
gen.outages = gen.params[, .(Unit, `Forced Outage Rate` = Outage, `Mean Time to Repair` = MTTR)]

# combine gens to outage
gen.outages = merge(gen.type, gen.outages, all.x=TRUE, by='Unit')
gen.outages = gen.outages[, .(Generator, `Forced Outage Rate`, `Mean Time to Repair`)]

# set outage for synchronous condensers to 0
gen.outages[is.na(`Forced Outage Rate`), ":=" (`Forced Outage Rate` = 0, `Mean Time to Repair` = 0)]

# add to get written out
all.tabs <- c(all.tabs, "gen.outages")

#------------------------------------------------------------------------------|
# cost data ----
#------------------------------------------------------------------------------|
#  
gen.cost.data <- cbind(generator.data[,.(Generator)],
                       struct.list$gencost)

# remove unneeded cols
model <- gen.cost.data[1,model]
gen.cost.data[,c("model", "startup", "shutdown", "n") := NULL]


if (model == 1) {
  
  # assumes heat rates are in $/hr and calculated using a dummy fuel price
  # of $1/MMBtu
  # converts from $/hr to MMBtu/MWh by diving by load point
  # ($/hr * 1 MMBtu/$1 * 1 hr/[loadpoint MW * hr = MWh])
  
  # reset names to be load point and heat rate for plexos
  names.to.convert <- names(gen.cost.data)
  names.to.convert <- names.to.convert[names.to.convert != "Generator"]
  
  names.converted <- gsub("p", "Load Point", names.to.convert)
  names.converted <- gsub("f", "Heat Rate", names.converted)   
  
  setnames(gen.cost.data, names.to.convert, names.converted)
  
  # names are almost plexos names, but have band id numbers at end
  # now, melt down, get band id, convert to real MMBtu/MWh 
  # there is probably a fancier/more efficient way to do this
  gen.cost.data <- melt(gen.cost.data, id.vars = "Generator", 
                        variable.factor = FALSE, value.factor = FALSE)
  gen.cost.data[, Band := as.numeric(substr(variable, 
                                            nchar(variable), 
                                            nchar(variable))) + 1]
  
  gen.cost.data[,variable := substr(variable, 1, nchar(variable) - 1)]
  
  # recast to get all Load Point and Heat Rate back as column names
  gen.cost.data[,value := as.numeric(value)]
  gen.cost.data <- data.table(dcast(gen.cost.data, Generator+Band~variable))
  
  gen.cost.data = merge(gen.cost.data,
                        merge(gen.fuel,
                              fuel.price,by='Fuel')[,.(Generator,Price)],
                        by='Generator')
  # heat rate is in $/hr, assuming fuel is $1/MMBtu. Convert to MMBtu/MWh
  gen.cost.data[, `Heat Rate` := `Heat Rate`/(`Load Point`*`Price`)][,Price:=NULL]
  
  # TODO HMMM SOMETHING IS WRONG WITH THESE HEAT RATE NUMBERS
  
} else if (model == 2) {
  # polynomial function coefficients
  
  # reset names to be plexos properties
  setnames(gen.cost.data, "c0", "Heat Rate Base")
  
  # reset numbering of c to index from 1
  names.to.convert <- names(gen.cost.data)
  
  names.converted <- names.to.convert[grepl("^c", names.to.convert)]
  names.converted <- gsub("c", "", names.converted)
  names.converted <- as.character(as.numeric(names.converted) + 1)
  
  names.converted <- paste("Heat Rate Incr", names.converted)
  
  setnames(gen.cost.data, 
           names.to.convert,
           names.converted)
  
} else {
  stop("heat rate model is not 1 or 2. not sure how to treat this data.")
}

# Round values to 1 decimal place
gen.cost.data[, c('Heat Rate', 'Load Point') := list(round(`Heat Rate`, 1), round(`Load Point`, 1))]

all.tabs <- c(all.tabs, "gen.cost.data")


#------------------------------------------------------------------------------|
# start costs ----
#------------------------------------------------------------------------------|
# requires that fuel.price and gen.fuel tables have been read in (see section
# "fuels and fuel price")

gen.startshut <- cbind(generator.data[,.(Generator)],
                   struct.list$gencost[,.(startup, shutdown)])

# start and shutdown costs are given in MMBtu. convert this to $ by
# adding gen fuel type and fuel prices, then multiplying by fuel price
gen.startshut <- merge(gen.startshut, gen.fuel, by = "Generator", all.x = TRUE)
gen.startshut <- merge(gen.startshut, fuel.price, by = "Fuel", all.x = TRUE)

gen.startshut[, Price := as.numeric(Price)]

# Use Oil/Steam price to calculate coal gen start and shutdown costs
gen.startshut[Fuel == "Coal/Steam", Price := fuel.price[Fuel == "Oil/Steam", Price]]

# calculate and add start and shutdown costs based on input heat and fuel price
gen.startshut[, `Start Cost` := Price * as.numeric(startup)]
gen.startshut[, `Shutdown Cost` := Price * as.numeric(shutdown)]

# save only plexos property columns
gen.startshut <- gen.startshut[,.(Generator, `Start Cost`, `Shutdown Cost`)]

# round values to integers
gen.startshut[, c('Start Cost', 'Shutdown Cost') := list(round(`Start Cost`), round(`Shutdown Cost`))]

all.tabs <- c(all.tabs, "gen.startshut")


#------------------------------------------------------------------------------|
# attach VG ----
#------------------------------------------------------------------------------|
# two things: 1. pass through filepointerts to VG rating files (these files
# are created manually based on site selection) 2. add a new generator for all 
# the VG gens
# assumes generator.data has already been made
# assumes gen.fuel is already made

# read in profiles to read out again (inefficient but at least treated the 
# same as all other property files...)
gen.da.vg <- fread("inputs/vg_gens_DA.csv")
gen.rt.vg <- fread("inputs/vg_gens_RT.csv")

# get vg max cap and add to total generator.table
vg.gens <- fread("inputs/vg_gens_maxMW.csv", colClasses = "character")

# add node
vg.gens[,Node := tstrsplit(Generator, "_")[[1]]]
vg.gens[, `Min Stable Level` := "0"]

generator.data <- merge(generator.data,
                        vg.gens,
                        by = c("Generator", "Max Capacity", "Node",
                               "Min Stable Level"),
                        all = TRUE)

# add units since don't have this in mpc file
generator.data[, Units := "1"]
# get rid of some PV/Wind units
disappear.units <- c("101_pv","101_pv_2","101_pv_3","101_pv_4","102_pv","103_pv","104_pv",
                     "119_pv","310_pv","310_pv_2","312_pv","314_pv","314_pv_2","314_pv_3",
                     "314_pv_4","319_pv","324_pv","324_pv_2","324_pv_3","118_rtpv","118_rtpv_8",
                     "308_rtpv","313_rtpv_11","320_rtpv","320_rtpv_2","320_rtpv_3","320_rtpv_4",
                     "320_rtpv_5","320_rtpv_6","314_pv_5","303_wind","317_wind")
generator.data[Generator %in% disappear.units, Units:="0"]


# add fuel types to these gens
vg.gen.fuel <- vg.gens[,.(Generator)]

vg.gen.fuel[grepl("_pv", Generator), Fuel := "PV"]
vg.gen.fuel[grepl("_rtpv", Generator), Fuel := "RTPV"]
vg.gen.fuel[grepl("_wind", Generator), Fuel := "Wind"]

gen.fuel <- rbind(gen.fuel, vg.gen.fuel)

# add these to all.tabs to be written out at the end
all.tabs <- c(all.tabs, "gen.da.vg", "gen.rt.vg")


#------------------------------------------------------------------------------|
# min gen ----
#------------------------------------------------------------------------------|

# have to match min gen to individual unit, because these are by size and fuel
gen.mingen <- merge(gen.id[, .(Generator, Unit, PG)],
                    gen.params[,.(Unit, MinGen)], 
                    by = "Unit",
                    all.x = TRUE)

# keep only relevant columns
gen.mingen <- gen.mingen[,.(Generator, `Min Stable Level` = MinGen)]

gen.mingen.rtpv <- gen.fuel[Fuel=='RTPV']
gen.mingen.rtpv[, Fuel := NULL]
gen.mingen.rtpv0 <- gen.mingen.rtpv
gen.mingen.rtpv0[, `Min Stable Level` := 0]

gen.mingen.rtpv = merge(gen.mingen.rtpv, generator.data[,.(Generator, `Max Capacity`)], by='Generator')
gen.mingen.rtpv[, `Min Stable Level` := as.numeric(`Max Capacity`)*0.6 ]
gen.mingen.rtpv[, `Max Capacity` := NULL]
gen.mingen.rtpv[, `Min Stable Level` := round(`Min Stable Level`)]

gen.mingen = rbind(gen.mingen, gen.mingen.rtpv)

# add to all.tabs to be written out
all.tabs <- c(all.tabs, "gen.mingen", "gen.mingen.rtpv0")

#------------------------------------------------------------------------------|
# attach hydro ----
#------------------------------------------------------------------------------|
# just like vg profiles, just read in to write out (to keep in same format as
# everything else and also in case we need to do something with it eventually)

gen.hydro <- fread("inputs/hydro_profiles.csv")

# add to all.tabs
all.tabs <- c(all.tabs, "gen.hydro")

#------------------------------------------------------------------------------|
# add reserves ----
#------------------------------------------------------------------------------|
eligible.gens <- c("Oil/Steam","Coal/Steam","Oil/CT","NG/CC","NG/CT","PV","Wind")

# add reserve(s) which is x% of load in each region and what gens can provide it
l.reserve <- c("Spin Up")
l.is.enabled <- c(1)
l.reserve.type <- c(1)
l.reserve.percent <- c(3.0)
l.scenario.name <- c("Add Spin Up")
l.reserve.violation <- c(4000.0)
l.reserve.timeframe.sec <- c(600.0)
l.mutually.exclusive <- c(1)

# add reserve(s) in which risk is defined with data file
d.reserve <- c("Flex Up","Flex Down","Reg Up","Reg Down")
d.is.enabled <- c(1,1,1,1)
d.reserve.type <- c(1,2,1,2)
d.scenario.name <- c("Add Flex Reserves","Add Flex Reserves","Add Regulation Reserves","Add Regulation Reserves")
d.reserve.violation <- c(4100,4100,3900,3900)
d.reserve.timeframe.sec <- c(1200.0,1200.0,300.0,300.0)
d.mutually.exclusive <- c(1,1,1,1)

reserve.data <- data.table('Reserve' = c(l.reserve,d.reserve),
                          'Is Enabled' = c(l.is.enabled,d.is.enabled),
                          'Type' = c(l.reserve.type,d.reserve.type),
                          'Scenario' = c(l.scenario.name,d.scenario.name),
                          'Timeframe' = c(l.reserve.timeframe.sec,d.reserve.timeframe.sec),
                          'VoRS' = c(l.reserve.violation,d.reserve.violation),
                          'Mutually Exclusive' = c(l.mutually.exclusive,d.mutually.exclusive))
reserve.generators <- gen.fuel[Fuel %in% eligible.gens,]
reserve.generators <- reserve.generators[,.(Reserve = c(rep(l.reserve,length(Generator)*length(l.reserve)),rep(d.reserve,each = length(Generator))),
                                            Generator = c(rep(Generator,times = length(l.reserve)+length(d.reserve))))]

reserve.regions <- region.refnode.data[]
reserve.regions <- reserve.regions[,.(Reserve = l.reserve,Region,`Load Risk` = l.reserve.percent)]

reserve.provisions <- fread('inputs/reserves.csv')
reserve.provisions.rt  <- fread('inputs/reserves_RT.csv')

# add to all.tabs
all.tabs <- c(all.tabs, "reserve.data","reserve.generators","reserve.regions","reserve.provisions","reserve.provisions.rt")

#------------------------------------------------------------------------------|
# ramps ----
#------------------------------------------------------------------------------|

gen.ramps <- struct.list$gen

# get generator col, ramp (choose ramp_30 [they are all the same], given in MW/min)
gen.ramps[,id := 1:.N, by = bus]
gen.ramps <- gen.ramps[, .(Generator = paste0(bus, "_", id), 
                  `Max Ramp Up` = ramp_30,
                  `Max Ramp Down` = ramp_30)]

# add to all.tabs to be written out
all.tabs <- c(all.tabs, "gen.ramps")

#------------------------------------------------------------------------------|
# min up/down ----
#------------------------------------------------------------------------------|

# times are in hours.
# requires that gen.unit.type has been read in

gen.minupdown <- merge(gen.id[,.(Generator, Unit)],
                   gen.params[,.(Unit, 
                                `Min Down Time` = MinDown, 
                                `Min Up Time` = MinUp)],
                   all.x = TRUE, by='Unit')

# leave only the relevant columns (Generator, Min Up Time, Min Down Time)
gen.minupdown[,Unit := NULL]

# add to all.tabs to be written out
all.tabs <- c(all.tabs, "gen.minupdown")

#------------------------------------------------------------------------------|
# DC Line ----
#------------------------------------------------------------------------------|

dc.line = data.table(`Node From`=113, `Node To`=316, Resistance=0, Reactance=NA, `Max Flow`=100, rateA=100, rateB=100, rateC=100, Units=NA, Line='113_316_1', `Min Flow`=-100)
line.data = rbind(line.data, dc.line, fill=TRUE) 

#------------------------------------------------------------------------------|
# simulation objects passthrough ----
#------------------------------------------------------------------------------|

file.copy(list.files("inputs/simulation_objects", full.names = TRUE), 
          output.dir,
          overwrite = TRUE)
