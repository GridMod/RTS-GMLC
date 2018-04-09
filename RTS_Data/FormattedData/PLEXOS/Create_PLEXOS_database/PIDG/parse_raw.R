#------------------------------------------------------------------------------|
# get needed packages and functions ----
#------------------------------------------------------------------------------|

if (!require(pacman)) {
    install.packages("pacman")
}

pacman::p_load(data.table,zoo) 

# be able to call this from within PIDG or externally to write out csv files
# - write out switch (keep in memory or write out to csv so can edit externally)
# end of parsing should be identical to input tables
# be v clear about what assumptions are being made
# then clean up inputs
# be able to loop through PSSE files
# 
# if time: comparer (otherwise do this thurs night)
# decide where outputs should go

#------------------------------------------------------------------------------|
# get command line args, if any ----
#------------------------------------------------------------------------------|

# read in command line args if they exist
cl.args <- commandArgs(trailingOnly = TRUE)

if (length(cl.args) > 0) {
    
    # process cl args into a named vector and assign to variables
    cl.args <- tstrsplit(cl.args, "=")
    
    cl.args.vec <- cl.args.raw[[2]] 
    names(cl.args.vec) <- cl.args.raw[[1]]
    
    for (arg.name in names(cl.args.vec)) {
        assign(arg.name, cl.args.vec[arg.name], .GlobalEnv)
    }
    
    # clean up
    rm(cl.args, cl.args.vec, arg.name)
}


#------------------------------------------------------------------------------|
# check inputs and set defaults ----
#------------------------------------------------------------------------------|

# check for pidg.dir
if (!exists("pidg.dir")) {
    stop(paste("pidg.dir does not exist. please set",
               "pidg.dir to the location of PIDG repo"))
}

if (!dir.exists(pidg.dir)) {
    stop(sprintf("pidg.dir is set to %s, but that directory does not exist", 
                 pidg.dir))
}

# check for input.params
if (!exists("input.params")) {
    stop(paste("input.params does not exist. please set input.params",
               "to the location of the input parameters file"))
}

if (!file.exists(input.params)) {
    stop(sprintf("input.params is set to %s, but that file does not exist",
                 input.params))
}

# check for existence inputfiles.dir (optional)
if (exists("inputfiles.dir")) {
    if (!dir.exists(inputfiles.dir)) {
        stop(sprintf("inputfiles.dir (%s) is defined but does not exist", 
                     inputfiles.dir))
    }
}

# check for existence of outputfiles.dir
if (exists("outputfiles.dir")) {
    
    if (!dir.exists(outputfiles.dir)) {
        dir.create(outputfiles.dir, recursive = TRUE)
    }
    
} else {
    
    message(sprintf(paste("outputfiles.dir does not exist. setting",
                          "outputfiles.dir to directory where input.params",
                          "(%s) lives"), 
                    input.params))
    
    outputfiles.dir <- dirname(input.params)
}

#------------------------------------------------------------------------------|
# source input parameters ----
#------------------------------------------------------------------------------|

source(input.params)

#------------------------------------------------------------------------------|
# function definition ----
#------------------------------------------------------------------------------|

# NOTE: this parsing makes lots of assumptions about how the PSS/E data should
# be interpretted. To see tables with all information, stop after 
# "a-1-parse-psse.R" and see a combination of the metadata file written out
# at the end and any environment variable with a name like Bus.data, Line.data.
# It would be nice to allow user to be able to supply their own version of 
# "a-2-reformat-psse.R" (or edit data between "a-1" and "a-2" or at least add 
# more options), but that's not currently implemented.

parse.in.place = FALSE

runPSSEparsing <- function () {
  
  if (exists("raw.file.list")) {
    
    for (cur.raw.file in raw.file.list) {
      # hacky... move cur.raw.file to global env so scripts can find it
      cur.raw.file <<- cur.raw.file 
      
      message("importing PSSE files...")
      source(file.path(pidg.dir, "SourceScripts", "a-1-parse-psse.R"))
      source(file.path(pidg.dir, "SourceScripts", "a-2-reformat-psse.R"))
      
    }
  }else{
    message('please provide a list of raw PSSE files in input.params (raw.file.list)')
  }
  
  message("done!")
  
}

#------------------------------------------------------------------------------|
# parse .raw PSS/E file ----
#------------------------------------------------------------------------------|

runPSSEparsing()

#------------------------------------------------------------------------------|
# write out ----
#------------------------------------------------------------------------------|

# either save to environment variables or save as csv files (or allow read.data
# to take data tables as well as csv, postgres?)