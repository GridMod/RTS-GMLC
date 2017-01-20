
# Main setup file for general PLEXOS run analysis.

# -----------------------------------------------------------------------
if (!require(pacman)){
  install.packages("pacman", dependencies=TRUE, repos = "http://cran.rstudio.com/")
  library(pacman)
}else{
  library(pacman)
}
p_load(ggplot2, reshape2, plyr, lubridate, scales, RSQLite, grid, knitr, markdown, grid, gridExtra, RColorBrewer, snow,
       doParallel, xtable, data.table, dplyr, extrafont, tidyr, stringr, rplexos, rmarkdown, yaml)

# -----------------------------------------------------------------------
# set rplexos tiebreak to take first values rather than last values. Can be set to 'first','last','all'
# This is the requisite behavior for partitioned databases
options('rplexos.tiebreak' = 'first')

# -----------------------------------------------------------------------
# Size for plot text
text.plot = 11

# -----------------------------------------------------------------------
# Set ggplot theme
theme_set(theme_bw())

# Color scheme for line plots
scen.pal = c("goldenrod2", "blue", "firebrick3", "darkblue", "deeppink", "chartreuse2", "seagreen4")

# -----------------------------------------------------------------------

# What sections to run code for. Assign a logical to each chunk run selector. 
run.sections = na.omit(inputs$Sections.to.Run)
if(1 %in% run.sections)  {total.gen.stack=TRUE}                 else {total.gen.stack=FALSE} 
if(2 %in% run.sections)  {zone.gen.stacks=TRUE}                 else {zone.gen.stacks=FALSE}
if(3 %in% run.sections)  {region.gen.stacks=TRUE}               else {region.gen.stacks=FALSE}
if(4 %in% run.sections)  {individual.region.stacks.log=TRUE}    else {individual.region.stacks.log=FALSE}
if(5 %in% run.sections)  {key.period.dispatch.total.log=TRUE}   else {key.period.dispatch.total.log=FALSE}
if(6 %in% run.sections)  {key.period.dispatch.zone.log=TRUE}    else {key.period.dispatch.zone.log=FALSE}
if(7 %in% run.sections)  {key.period.dispatch.region.log=TRUE}  else {key.period.dispatch.region.log=FALSE}
if(8 %in% run.sections)  {daily.curtailment=TRUE}               else {daily.curtailment=FALSE}
if(9 %in% run.sections)  {daily.curtailment.type=TRUE}          else {daily.curtailment.type=FALSE}
if(10 %in% run.sections) {interval.curtailment=TRUE}            else {interval.curtailment=FALSE}
if(11 %in% run.sections) {interval.curtailment.type=TRUE}       else {interval.curtailment.type=FALSE}
if(12 %in% run.sections) {annual.generation.table=TRUE}         else {annual.generation.table=FALSE}
if(13 %in% run.sections) {annual.curtailment.table=TRUE}        else {annual.curtailment.table=FALSE}
if(14 %in% run.sections) {annual.cost.table=TRUE}               else {annual.cost.table=FALSE}
if(15 %in% run.sections) {region.zone.flow.table=TRUE}          else {region.zone.flow.table=FALSE}
if(16 %in% run.sections) {interface.flow.table=TRUE}            else {interface.flow.table=FALSE}
if(17 %in% run.sections) {interface.flow.plots=TRUE}            else {interface.flow.plots=FALSE}
if(18 %in% run.sections) {key.period.interface.flow.plots=TRUE} else {key.period.interface.flow.plots=FALSE}
if(19 %in% run.sections) {annual.reserves.table=TRUE}           else {annual.reserves.table=FALSE}
if(20 %in% run.sections) {reserves.plots=TRUE}                  else {reserves.plots=FALSE}
if(21 %in% run.sections) {reserve.stack=TRUE}                   else {reserve.stack=FALSE}
if(22 %in% run.sections) {region.zone.gen.table=TRUE}           else {region.zone.gen.table=FALSE}
if(23 %in% run.sections) {capacity.factor.table=TRUE}           else {capacity.factor.table=FALSE}
if(24 %in% run.sections) {price.duration.curve=TRUE}            else {price.duration.curve=FALSE}
if(24 %in% run.sections) {res.price.duration.curve=TRUE}        else {res.price.duration.curve=FALSE}
if(25 %in% run.sections) {commit.dispatch.zone=TRUE}            else {commit.dispatch.zone=FALSE}
if(26 %in% run.sections) {commit.dispatch.region=TRUE}          else {commit.dispatch.region=FALSE}
if(33 %in% run.sections) {revenue.plots=TRUE}                   else {revenue.plots=FALSE}
if(27 %in% run.sections) {annual.res.short.table=TRUE}          else {annual.res.short.table=FALSE}
if(28 %in% run.sections) {curtailment.diff.table=TRUE}          else {curtailment.diff.table=FALSE}
if(30 %in% run.sections) {runtime.table=TRUE}                   else {runtime.table=FALSE}
if(31 %in% run.sections) {compare.dispatch.zone=TRUE}           else {compare.dispatch.zone=FALSE}
if(32 %in% run.sections) {compare.dispatch.region=TRUE}         else {compare.dispatch.region=FALSE}
if(33 %in% run.sections) {line.flow.table=TRUE}                 else {line.flow.table=FALSE}
if(34 %in% run.sections) {line.flow.plots=TRUE}                 else {line.flow.plots=FALSE}
if(35 %in% run.sections) {key.period.line.flow.plots=TRUE}      else {key.period.line.flow.plots=FALSE}
if(36 %in% run.sections) {installed.cap.plot=TRUE}              else {installed.cap.plot=FALSE}


# -----------------------------------------------------------------------
# Read in the data from the input_data.csv file that was just loaded

# location of database
# db.loc = file.path(as.character(na.exclude(inputs$Database.Location))) 
# db.day.ahead.loc = file.path(as.character(na.exclude(inputs$DayAhead.Database.Location)))
if (length(db.day.ahead.loc)==0 | !exists('db.day.ahead.loc')) { db.day.ahead.loc = db.loc }
has.multiple.scenarios = (length(db.loc)>1)

# Using CSV file to map generator types to names?
use.gen.type.mapping.csv = as.logical(na.exclude(inputs$Using.Gen.Type.Mapping.CSV))
if (length(use.gen.type.mapping.csv)==0) { 
  use.gen.type.mapping.csv = FALSE
  message('\nMust select TRUE or FALSE for if using generator generation type mapping file!') 
}

# Reassign zones based on region to zone mapping file?
reassign.zones = as.logical(na.exclude(inputs$reassign.zones))
if (length(reassign.zones)==0) { 
  reassign.zones = FALSE
  message('\nMust select TRUE or FALSE for if reassigning what regions are in what zones!')
}

# Generation type order for plots
gen.order = (as.character(na.omit(inputs$Gen.Order))) 
# Add Curtailment if not included
if (! 'Curtailment' %in% gen.order){
  gen.order = c('Curtailment',gen.order)
}

# Types of renewables to be considered for curtailment calculations
re.types = as.character(na.omit(inputs$Renewable.Types.for.Curtailment)) 
if (length(re.types)==0) { 
  message('\nNo variable generation types specified for curtailment.')
  re.types = 'none_specified'
}

# Types of generation to be plotted in the DA-RT committmet dispatch plots
da.rt.types = as.character(na.omit(inputs$DA.RT.Plot.Types))
if (length(da.rt.types)==0) {
  message('\nNo generation types specified for DA-RT plots. Plots will not be created.')
}

# Names of key periods
period.names = as.character(na.omit(inputs$Key.Periods)) 
if (length(period.names)==0) {
  message('\nNo key periods specified. No plots will be created for these.')
}

# Number of key periods
n.periods = length(period.names) 

# Start and end times for key periods
if(length(na.omit(inputs$Start.Time)) > 0){
  # Check if year is provided as 4-digit or 2-digit year
  if(nchar(strsplit(as.character(inputs$Start.Time[1]),'[ ,/]')[[1]][3])==2){
    start.end.times = data.table(start = as.POSIXct( na.omit(inputs$Start.Time), format = '%m/%d/%y %H:%M', tz='UTC'), 
                                 end = as.POSIXct( na.omit(inputs$End.Time), format = '%m/%d/%y %H:%M', tz='UTC' ) )
  }else if(nchar(strsplit(as.character(inputs$Start.Time[1]),'[ ,/]')[[1]][3])==4){
    start.end.times = data.table(start = as.POSIXct( na.omit(inputs$Start.Time), format = '%m/%d/%Y %H:%M', tz='UTC'), 
                                 end = as.POSIXct( na.omit(inputs$End.Time), format = '%m/%d/%Y %H:%M', tz='UTC' ) )
  }
  # If is NA, try without hour and minute in date format
  if (any(is.na(start.end.times))){
    if(nchar(strsplit(as.character(inputs$Start.Time[1]),'[ ,/]')[[1]][3])==2){
      start.end.times.temp = data.table(start = as.POSIXct( na.omit(inputs$Start.Time), format = '%m/%d/%y', tz='UTC'), 
                                        end = as.POSIXct( na.omit(inputs$End.Time), format = '%m/%d/%y', tz='UTC' ) )
    }else if(nchar(strsplit(as.character(inputs$Start.Time[1]),'[ ,/]')[[1]][3])==4){
      start.end.times.temp = data.table(start = as.POSIXct( na.omit(inputs$Start.Time), format = '%m/%d/%Y', tz='UTC'), 
                                        end = as.POSIXct( na.omit(inputs$End.Time), format = '%m/%d/%Y', tz='UTC' ) )
    }
    start.end.times[is.na(start), start:=start.end.times.temp[is.na(start.end.times$start),start]]
    start.end.times[is.na(end), end:=start.end.times.temp[is.na(start.end.times$end),end]]
  }
}

# Location for saved figures
tryCatch({
  dir.create(fig.path.name)
  fig.path.name
}, warning = function(w){
  if(!dir.exists(fig.path.name)){
    print("Cannot create that figure directory, putting figures in subdirectory 'plots' in database location")
    # If figure path does not exist, assume figures should go in a directory 
    # called "plots" in the folder containing the database
    file.path(db.loc,'plots')
  } else{
    fig.path.name
  }
},
error = function(e){
  print("Cannot create that figure directory, putting figures in subdirectory 'plots' in database location")
  # If figure path does not exist, assume figures should go in a directory 
  # called "plots" in the folder containing the database
  file.path(db.loc,'plots')
})
# Ensure path has a / at the end
fig.path.name = file.path(fig.path.name,.Platform$file.sep)

# Zones to ignore for plotting
ignore.zones = as.character(na.omit(inputs$Ignore.Zones))

# Regions to ignore for plotting
ignore.regions = as.character(na.omit(inputs$Ignore.Regions))

# Interfaces to look at flows for
interfaces = as.character(na.omit(inputs$Interfaces.for.Flows))
if (length(interfaces)==0) {
  message('\nNo interfaces specified. No interface data will be shown.')
} else if (any(interfaces == 'ALL')){
  interfaces = unique(query_class_member(db,'Interface')$name)
}
# Update scen.pal to account for larger number of interfaces. Give warning about large number of entries
if (length(interfaces) > length(scen.pal)){
  message('\nYou have specified a large number of interfaces. Color palette may be hard to differentiate.')
  scen.pal = rainbow(length(interfaces))
}

# lines to look at flows for
lines = as.character(na.omit(inputs$Lines.for.Flows))
if (length(lines)==0) {
  message('\nNo lines specified. No line data will be shown.')
} else if (any(lines == 'ALL')){
  lines = unique(query_class_member(db,'Line')$name)
}
# Update scen.pal to account for larger number of lines. Give warning about large number of entries
if (length(lines) > length(scen.pal)){
  message('\nYou have specified a large number of lines. Color palette may be hard to differentiate.')
  scen.pal = rainbow(length(lines))
}

run.rplx=F
run.rplx.all=F
first.missing.db=T
for (i in 1:length(db.loc)) { 
  if(length(list.files(pattern = "\\.zip$",path=db.loc[i]))!=0 ) {
    if(length(list.files(pattern = "\\.db$",path=db.loc[i]))==0) {
      message(paste0('The .db file is absent from ',db.loc[i]))
      run.rplx=T
    } else if(any(file.info(file.path(db.loc[i],list.files(pattern = "\\.db$",path=db.loc[i])))$mtime <
                  file.info(file.path(db.loc[i],list.files(pattern = "\\.zip$",path=db.loc[i])))$mtime, na.rm=TRUE)) {
      message(paste0('The db is older than the zip or the .db file in ',db.loc[i]))
      run.rplx=T
    } else {message(paste0('\nFound .db solution file: ', list.files(pattern='\\.db$',path=db.loc[i]), '\n'))}
    if(run.rplx) {
      if(first.missing.db){
        run.rplx.all = (readline('Do you want to run the rPLEXOS db creation tool for all zip files without db files? (y/n):')=='y' | !interactive())
        first.missing.db=F
      }
      if(run.rplx.all){
        message('Running process_folder')
        process_folder(db.loc[i])
      } else if(readline('Do you want to run the rPLEXOS db creation tool now? (y/n):')=='y' | !interactive()){
        message('Running process_folder')
        process_folder(db.loc[i])
      } else {message('You need to run rPLEXOS to process your solution or point to the correct solution folder.')}
    } 
  } else if (length(list.files(pattern = '\\.db$', path=db.loc[i]))!=0 ) {
    message(paste0('\nFound .db solution file: ', list.files(pattern='\\.db$',path=db.loc[i]), '\n'))
  } else {message('No .zip or .db file... are you in the right directory?')}
}
# -----------------------------------------------------------------------
# Open the database file ( must already have created this using rplexos ) 
d = basename(db.loc)
if (length(na.omit(inputs$Scenario.Name))>0){
  scenario.names = as.character(inputs$Scenario.Name[!is.na(inputs$Scenario.Name)])
}
if (length(scenario.names)!=length(db.loc)){
  print("You specified a different number of scenario names than databases.")
  print("Using database names as scenarios")
  scenario.names = basename(db.loc)
}
# Remove trailing / if present
if (substr(db.loc,nchar(db.loc),nchar(db.loc))=='/'){
  db.loc <- substr(db.loc,1,nchar(db.loc)-1)
}
db = plexos_open(db.loc, scenario.names)
# db = db[1,] # This line queries only the first solution .db file if there are multiple in one location. 
attributes(db)$class = c("rplexos","data.frame","tbl_df")

# Open the day ahead database file
# Remove trailing / if present
if (substr(db.day.ahead.loc,nchar(db.day.ahead.loc),nchar(db.day.ahead.loc))=='/'){
  db.day.ahead.loc <- substr(db.day.ahead.loc,1,nchar(db.day.ahead.loc)-1)
}
db.day.ahead = tryCatch(plexos_open(db.day.ahead.loc, scenario.names), error = function(cond) { return(data.frame('ERROR'))})
# db.day.ahead = db.day.ahead[1,] # This line queries only the first solution .db file if there are multiple in one location. 
attributes(db.day.ahead)$class = c('rplexos', 'data.frame', 'tbl_df')


# reference scenario, used if comparing scenarios
if (has.multiple.scenarios){
  if ('ref.scenario' %in% names(inputs)){
    ref.scenario = as.character(inputs$ref.scenario[!is.na(inputs$ref.scenario)])
    if (length(ref.scenario)>1){
      message('\nYou have more than one reference scenario. This is likely to cause problems with comparison calculations')
    } else{
      if (length(ref.scenario)==0 & has.multiple.scenarios){
        message('\nYou have not provided a reference scenario. Comparison plots will not work.')
      }
    }
  } else {
    message('\nYou did not specify a reference scenario for your comparisons. We will use the first scenario listed.')
    ref.scenario <- scenario.names[1]
  }
} else{ ref.scenario = scenario.names[1]}


# get available properties
properties = data.table(query_property(db))
if (typeof(db.day.ahead)!='character'){
  properties.day.ahead = data.table(query_property(db.day.ahead))
}

# Read mapping file to map generator names to region and zone (can be same file as gen name to type).
if (is.na(inputs$Gen.Region.Zone.Mapping.Filename)[1]){
  warning(paste("You did not supply a Region-Zone mapping. We will create one for you from the rplexos database",
                "However, rplexos reassigns Zone names to the Region category. If you do not want this behavior,",
                "please create your own mapping file. You may use the file tools/make_region_zone_csv.py to do so,",
                "which will require COAD to be installed and part of your path."))
  gen.mapping <- query_generator(db)
  region.zone.mapping = data.table(unique(gen.mapping[,c('name','region','zone')]))
  setnames(region.zone.mapping, c("region","zone"), c("Region","Zone"))
} else{
  region.zone.mapping = data.table(read.csv(as.character(na.exclude(inputs$Gen.Region.Zone.Mapping.Filename)[1]), 
                                            stringsAsFactors=FALSE))
  if(length(na.exclude(inputs$Gen.Region.Zone.Mapping.Filename))>1){
    warning("More than one Gen.Region.Zone.Mapping.Filename found... I'll create a unique combination for you.")
    for (i in 2:length(na.exclude(inputs$Gen.Region.Zone.Mapping.Filename))){
      region.zone.mapping = rbindlist(list(region.zone.mapping,data.table(read.csv(as.character(na.exclude(inputs$Gen.Region.Zone.Mapping.Filename)[i]), 
                                                                          stringsAsFactors=FALSE))),fill=TRUE)
    }
  }
  if ( typeof(region.zone.mapping$Region)!="character" | typeof(region.zone.mapping$Zone)!="character" ) {
    region.zone.mapping$Region = as.character(region.zone.mapping$Region)
    region.zone.mapping$Zone = as.character(region.zone.mapping$Zone)
  }
}
region.zone.mapping = unique(region.zone.mapping[, .(name, Region, Zone)])
setkey(region.zone.mapping,name)
rz.unique = unique(region.zone.mapping[,.(Region,Zone)])


# Create generator name to type mapping
if ( length(inputs$CSV.Gen.Type.File.Location[!is.na(inputs$CSV.Gen.Type.File.Location)]) > 0 ) {
  # Read mapping file to map generator names to generation type
  gen.type.mapping = data.table(read.csv(as.character(na.exclude(inputs$CSV.Gen.Type.File.Location)), 
                                         stringsAsFactors=FALSE))
  gen.type.mapping = unique(gen.type.mapping[,.(name, Type)])
  gen.type.mapping = setNames(gen.type.mapping$Type, gen.type.mapping$name)
  } else {
  # Assign generation type according to PLEXOS category
    sql <- "SELECT DISTINCT name, category FROM key WHERE class = 'Generator'"
    gen.cat.plexos = query_sql(db,sql) 
    gen.cat.plexos = unique(gen.cat.plexos[,c("name","category")])
    # If PLEXOS Gen Category mapping defined use that
    if (length(inputs$PLEXOS.Gen.Category[!is.na(inputs$PLEXOS.Gen.Category)]) > 0) {
      gen.cat.mapping = data.table(name = as.character(na.omit(inputs$PLEXOS.Gen.Category)), 
                                   Type = as.character(na.omit(inputs$PLEXOS.Desired.Type)) )  
      gen.cat.mapping = setNames(gen.cat.mapping$Type, gen.cat.mapping$name)
      gen.cat.plexos$Type = gen.cat.mapping[gen.cat.plexos$category]
      gen.type.mapping = setNames(gen.cat.plexos$Type, gen.cat.plexos$name)
      } else{
        # If csv not provided and PLEXOS mapping not defined, use PLEXOS categories
        message("Generator Type mapping not provided. Will use PLEXOS categories")
        gen.type.mapping = setNames(gen.cat.plexos$category, gen.cat.plexos$name)
    }
  if (length(gen.type.mapping)==0) { message('\nIf not using generator name to type mapping CSV, you must specify PLEXOS categories and desired generation type.') }
}

  # Set plot color for each generation type. Use rainbow() if mapping not provided
if(all(is.na(inputs$Gen.Type)) | all(is.na(inputs$Plot.Color))){
  types <- unique(gen.type.mapping)
  gen.color <- setNames(rainbow(length(types)), types)
} else{
  Gen.col = data.table(Type = na.omit(inputs$Gen.Type), Color = na.omit(inputs$Plot.Color) )
  gen.color<-setNames(as.character(Gen.col$Color),Gen.col$Type)
}
# Add Curtailment if not included
if (! 'Curtailment' %in% names(gen.color)){
  gen.color['Curtailment'] = 'red'
}

# Calculate First and last day of simulation and interval length
model.timesteps = model_timesteps(db)
model.intervals = model.timesteps[,.(scenario,timestep)]

# Check to make sure no overlapping periods are created
if (nrow(model.timesteps[, .(unique(start)), by=.(scenario)]) > nrow(model.timesteps)){
  message("Warning: You have overlapping solutions")
}
model.timesteps = model.timesteps[,.(start=min(start),end=max(end)),by=.(scenario)]
# Check and make sure all scenarios have same start and end times
if (!(length(unique(model.timesteps$start))==1 & length(unique(model.timesteps$end))==1)){
  message("Warning: All specified scenarios do not have the same time horizons")
}
first.day = min(model.timesteps$start)
last.day = max(model.timesteps$end)

# Check to make sure all solutions have the same length
if (length(unique(model.intervals$timestep))!=1){
  message("Warning: Your databases do not have the same time intervals")
}
# Number of intervals per day
intervals.per.day = 24 / unique(as.numeric(model.intervals$timestep,units='hours'))

# Check to make sure all solutions have the same length
if (length(unique(model.intervals$timestep))!=1){
  message("Warning: Your databases do not have the same time intervals")
}
# Number of intervals per day
intervals.per.day = 24 / unique(as.numeric(model.intervals$timestep,units='hours'))




