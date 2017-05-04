#------------------------------------------------------------------------------|
rm(list=ls())

#------------------------------------------------------------------------------|
# USER INPUT: set input parameters ----
#------------------------------------------------------------------------------|
# file paths can be absolute or relative to location of this script

# directory of PSSE2PLEXOS master script - this is comp. specific because we
# don't have PSSE2PLEXOS as a submodule
# NOTE: be on the pssw2plx_data_checks branch
master.script.dir <- '../PSSE2PLEXOS'

# directory to export to
outputfiles.dir <- '..'

# directory of input files - point to result of matpower parsing
inputfiles.dir <- '../1-parse-SourceData/outputs'

input.params <- 'input_params.R'

# name of output workbook
output.wb.name <- "../rts_PLEXOS_5_3.xlsx"


# check data and save summary plots
data.check.plots <- TRUE


#------------------------------------------------------------------------------|
# end USER INPUT ----
#------------------------------------------------------------------------------|
#------------------------------------------------------------------------------|

#------------------------------------------------------------------------------|
# set working directory ----
#------------------------------------------------------------------------------|

# set working directory

if (interactive()) {
  t=try(dirname(sys.frame(1)$ofile),silent = T)
  if(inherits(t, "try-error")) {
    warning("Make sure you are in the PSSE2PLEXOS submodule path")
  } else {
    script.dir = dirname(parent.frame(2)$ofile)
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


#------------------------------------------------------------------------------|
# run ----
#------------------------------------------------------------------------------|

# run the scripts
args <- c(master.script.dir, input.params, inputfiles.dir, outputfiles.dir)

source(file.path(master.script.dir, 
  'create_plexos_db_from_raw_master_script.R'))
