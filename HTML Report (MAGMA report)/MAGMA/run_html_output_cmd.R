#!/usr/bin/env Rscript
# This file can be used to run MAGMA from the command line
# Many arguments have default values that may be provided. 
# Run run_htmo_output_cmd.R --help for options and more details. 
# At a minimum, the database folder must be provided.

#------------------------------------------------------------------------------|
# Load initial packages
#------------------------------------------------------------------------------|
.libPaths('packages')
if (!require(optparse)){
  install.packages("optparse", dependencies = TRUE, repos="http://cran.rstudio.com/")
  library(optparse)
}else{
  library(optparse)
}
if (!require(stringr)){
  install.packages("stringr", dependencies = TRUE, repos="http://cran.rstudio.com/")
  library(stringr)
}else{
  library(stringr)
}

#------------------------------------------------------------------------------|
# Define inputs and default values
#------------------------------------------------------------------------------|
parser <- OptionParser()
parser <- add_option(parser, c("-d", "--Database.Location"), type='character', 
                     help="Location of database to process")
parser <- add_option(parser, c("-b", "--DayAhead.Database.Location"), default = NA, type='character',
                     help="Location of day ahead database to process")
parser <- add_option(parser, c("-z", "--reassign.zones"), default = TRUE,
                     help = "Re-assign zones from regions. If false, uses PLEXOS zones")
parser <- add_option(parser, c("-g", "--Gen.Region.Zone.Mapping.Filename"), default = NA, type='character',
                     help = "Filename to create Generator - Region - Zone mapping.
                             Default is NA, which will pull that mapping from the database")
parser <- add_option(parser, c("-f", "--CSV.Gen.Type.File.Location"), default = NA, type='character',
                     help = "CSV of generator name to type mapping. 
                             If neither CSV.Gen.Type.File.Location nor PLEXOS.Gen.Category
                             supplied, will use the categories in PLEXOS")
parser <- add_option(parser, c("-c", "--PLEXOS.Gen.Category"), default = NA, type='character',
                     help = "Comma separated list of Generator categories to be mapped with
                             PLEXOS.Desired.Type. Both must be provided for mapping. 
                             If neither CSV.Gen.Type.File.Location nor PLEXOS.Gen.Category
                             supplied, will use the categories in PLEXOS")
parser <- add_option(parser, c("-m", "--PLEXOS.Desired.Type"), default = NA, type='character',
                     help = "Comma separated list of desired Generator types to be mapped with
                             PLEXOS.Gen.Category. Both must be provided for mapping. 
                             If neither CSV.Gen.Type.File.Location nor PLEXOS.Gen.Category
                             supplied, will use the categories in PLEXOS")
parser <- add_option(parser, c("-t", "--Gen.Type"), default = NA, type='character',
                     help = "Generator Types as list, used with Plot.Color to create
                             mapping for generator color types in plots. 
                             If Gen.Order not defined, order of this variable will be used.")
parser <- add_option(parser, c("-p", "--Plot.Color"), default = NA, type='character',
                     help = "Generator Type Colors, used with Gen.Type to create
                             mapping for generator color types in plots.")
parser <- add_option(parser, c("-O", "--Gen.Order"), default = NA, type='character',
                     help = "Generator Order for plottting. Default is NA, which if selected
                             will use the order of generators from Gen.Type.")
parser <- add_option(parser, c("-r", "--Renewable.Types.for.Curtailment"), default = "PV,Wind,CSP,Solar",
                     help = "Generator types to use for Curtailment. Should be provided as
                             a comma separated list")
parser <- add_option(parser, c("-a", "--DA.RT.Plot.Types"), default = "PV, Wind, Coal, Hydro",
                     help = "Generator types to make DA RT plots for.")
parser <- add_option(parser, c("-k", "--key.period.csv"), default = NA, type='character', 
                     help = "CSV with key periods defined. Should have columsn Key.Period, Start.Time and End.Time")
parser <- add_option(parser, c("-s", "--Sections.to.Run"), default = "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23",
                     help = "Numbers of which plots to run as a comma separated list")
parser <- add_option(parser, c("-F", "--Fig.Path"), default = NA, type='character', 
                     help = "Path to save figures. If NA will save figures in 'plots' directory
                             in the DB directory")
parser <- add_option(parser, c("-R", "--Ignore.Regions"), default = NA, type='character', 
                     help = "List of regions to ignore")
parser <- add_option(parser, c("-Z", "--Ignore.Zones"), default = NA, type='character', 
                     help = "List of zones to ignore")
parser <- add_option(parser, c("-i", "--Interfaces.for.Flows"), default = NA, type='character', 
                     help = "List of interfaces to report data on")

parser <- add_option(parser, c("-o", "--output.name"), default = "output_plots.html",
                     help = "Name of output file")
parser <- add_option(parser, c("-u", "--output.dir"), default = NA, type='character',
                     help = "Directory of where to save outputs")
parser <- add_option(parser, c("-Q", "--query.data"), default = TRUE, type='logical',
                     help = "Query the data from databases or load from existing data")
parser <- add_option(parser, c("-D", "--load.data"), default = NA, type='character',
                     help = "Name of data to load. If query.data = FALSE, this must have a filename")

inputs <- parse_args(parser)
print(inputs)
#------------------------------------------------------------------------------|
# Process inputs
#------------------------------------------------------------------------------|

# Process inputs provided as lists
if(!is.na(inputs$PLEXOS.Gen.Category)){
   inputs$PLEXOS.Gen.Category = unlist(str_split(inputs$PLEXOS.Gen.Category,"(,\\s?)"))
}
if(!is.na(inputs$PLEXOS.Desired.Type)){
   inputs$PLEXOS.Desired.Type = unlist(str_split(inputs$PLEXOS.Desired.Type,"(,\\s?)"))
}
if(all(is.na(inputs$Gen.Type)) | all(is.na(inputs$Plot.Color))){
    message("No Generator Type to Color mapping provided. Default colors in R will be used.")
} else{
   inputs$Gen.Type = unlist(str_split(inputs$Gen.Type,"(,\\s?)"))
   inputs$Plot.Color = unlist(str_split(inputs$Plot.Color,"(,\\s?)"))
}
if(!is.na(inputs$Renewable.Types.for.Curtailment)){
   inputs$Renewable.Types.for.Curtailment = unlist(str_split(inputs$Renewable.Types.for.Curtailment,"(,\\s?)"))
}
if(!is.na(inputs$DA.RT.Plot.Types)){
   inputs$DA.RT.Plot.Types = unlist(str_split(inputs$DA.RT.Plot.Types,"(,\\s?)"))
}
if(!is.na(inputs$Sections.to.Run)){
   inputs$Sections.to.Run = as.integer(unlist(str_split(inputs$Sections.to.Run,"(,\\s?)")))
}
if(!is.na(inputs$Ignore.Regions)){
   inputs$Ignore.Regions = unlist(str_split(inputs$Ignore.Regions,"(,\\s?)"))
}
if(!is.na(inputs$Ignore.Zones)){
   inputs$Ignore.Zones = unlist(str_split(inputs$Ignore.Zones,"(,\\s?)"))
}

# If NA, Gen.Order is set from Gen.Type
if(is.na(inputs$Gen.Order)){
    inputs$Gen.Order = inputs$Gen.Type
}
# Process Key periods
if(is.na(inputs$key.period.csv)){
    inputs$Key.Periods = NA
} else{
    key.periods = read.csv(inputs$key.period.csv)
    inputs$Key.Periods = key.periods$Key.Periods
    inputs$Start.Time = key.periods$Start.Time
    inputs$End.Time = key.periods$End.Time
}
# Assign plot directory if not already set
if(is.na(inputs$Fig.Path)){
    dir.create(file.path(inputs$Database.Location, 'plots'), showWarnings = FALSE)
    inputs$Fig.Path = file.path(inputs$Database.Location, 'plots')
}
# Assign output directory if not set
if(is.na(inputs$output.dir)){
    inputs$output.dir = inputs$Database.Location
}

# Determine if data needs to be queried
if(!inputs$query.data & is.na(inputs$load.data)){
    stop("You must either query data or load existing data")
}

#------------------------------------------------------------------------------|
# Set environmental path to point to pandoc
#------------------------------------------------------------------------------|
Sys.setenv(
  PATH = paste( Sys.getenv("PATH"), file.path(getwd(),'packages'), 
                sep = .Platform$path.sep )
)
#------------------------------------------------------------------------------|
# Run code to create HTML
#------------------------------------------------------------------------------|
# Sourcing the setup file and required functions
source(file.path('query_functions.R'))
source(file.path('create_plots','plot_functions.R'))
source(file.path('setup_plexosAnalysis.R'))
# Either query data from database or load existing data
if (inputs$query.data){
    source(file.path('setup_dataQueries.R'), echo=TRUE)
} else{
    load(inputs$load.data)
}

render(input=file.path('HTML_output.Rmd'), c("html_document"), 
       output_file=inputs$output.name, output_dir = file.path(inputs$output.dir))



