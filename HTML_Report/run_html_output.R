
#------------------------------------------------------------------------------|
# USER INPUT: set input parameters ----
#------------------------------------------------------------------------------|
magma.dir        = paste0(dirname(sys.frame(1)$ofile), '../../..')
input.csv        = 'Examples/RTS-2016/input_data_rts.csv'
db.loc           = '<Location of solution file>'
output.dir       = 'Examples/RTS-2016/reports'
fig.path.name    = 'Examples/RTS-2016/plots/'
output.name      = 'HTML_output_RTS_year.html'
db.day.ahead.loc = '<Location of day ahead solution file (if not using one, should be NULL)>'
query.data       = TRUE
save.data        = FALSE
load.data        = '<Name of file to load if query.data=FALSE >'
save.data.name   = '<Name of file to save data. Will save in output.dir>'
reassign.zones   = FALSE
use.gen.type.csv = FALSE
gen.type.csv.loc = NULL
gen.region.zone  = 'Examples/RTS-2016/gen_name_mapping_WECC_RTS.csv'
#------------------------------------------------------------------------------|
# Run code to create HTML
#------------------------------------------------------------------------------|
setwd(magma.dir)

# Sourcing the setup file and required functions
source(file.path('query_functions.R'))
source(file.path('plot_functions.R'))

# Read CSV file with all inputs
inputs = read.csv(file.path(input.csv))
inputs[inputs==""]=NA

# Either query data from database or load existing data
source(file.path('setup_plexosAnalysis.R'))
if (query.data){
  source(file.path('setup_dataQueries.R'), echo=TRUE)
} else{
  load(load.data)
}

render(input=file.path('HTML_output.Rmd'), c("html_document"),
       output_file=output.name, output_dir = file.path(output.dir,''))

if (save.data){
  save(list=ls(), file=file.path(output.dir,save.data.name))
}
