#------------------------------------------------------------------------------|
# delete all existing objects in current environment
rm(list=ls())

# this is not set up now, but could be configured to take any or all of the 
# following variables as arguments from a command line call

#------------------------------------------------------------------------------|
# USER INPUT: set input parameters ----
#------------------------------------------------------------------------------|
# file paths can be absolute or relative to location of this script

# location of PIDG
pidg.dir <- '..'

# directory to export to
outputfiles.dir <- 'outputs'

# directory of input files
inputfiles.dir <- 'inputs'

input.params <- 'input_params.R'

output.wb.name <- "example.xlsx"
export.wb <- TRUE

# check data and save summary plots
data.check.plots <- FALSE


#------------------------------------------------------------------------------|
# end USER INPUT ----
#------------------------------------------------------------------------------|
#------------------------------------------------------------------------------|

# set working directory

if (interactive()) {
    t=try(dirname(sys.frame(1)$ofile),silent = T)
    if(inherits(t, "try-error")) {
        warning("Make sure you are in the PIDG submodule path")
    } else {
        script.dir = dirname(sys.frame(1)$ofile)
        setwd(script.dir)
    }
} else {
    dir = getSrcDirectory(function(x) {x})
    m <- regexpr("(?<=^--file=).+", commandArgs(), perl=TRUE)
    script.dir <- dirname(regmatches(commandArgs(), m))
    if(length(script.dir) == 0) 
        stop("can't determine script dir: please call the script with Rscript")
    if(length(script.dir) > 1) 
        stop("can't determine script dir: more than one '--file' argument detected")
    setwd(script.dir)
}

# run
print(getwd())
source(file.path(pidg.dir, 'driver.R'))
