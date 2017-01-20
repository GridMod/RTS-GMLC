# Load required packages
if (!require(pacman)){
  install.packages(pacman)
  library(pacman)
}else{
  library(pacman)
}
p_load(ggplot2, reshape2, plyr, lubridate, scales, RSQLite, grid, knitr, markdown, grid, gridExtra, RColorBrewer, snow,
       doParallel, xtable, data.table, dplyr, extrafont, tidyr, stringr, rplexos, rmarkdown)

theme_set(theme_bw())

process_inputs <- function(input){
  has.multiple.scenarios
  rz.unique
  gen.color<-setNames(as.character(Gen.col$Color),Gen.col$Type)
  n.periods (if needed)
  
  # Open the database file ( must already have created this using rplexos ) 
  db = plexos_open(db.loc, basename(db.loc))
  # db = db[1,] # This line queries only the first solution .db file if there are multiple in one location. 
  attributes(db)$class = c("rplexos","data.frame","tbl_df")
  
  # Open the day ahead database file
  db.day.ahead = tryCatch(plexos_open(db.day.ahead.loc, basename(db.day.ahead.loc)), error = function(cond) { return(data.frame('ERROR'))})
  # db.day.ahead = db.day.ahead[1,] # This line queries only the first solution .db file if there are multiple in one location. 
  attributes(db.day.ahead)$class = c('rplexos', 'data.frame', 'tbl_df')
  
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
}