
#------------------------------------------------------------------------------|
# USER INPUT: set input parameters ----
#------------------------------------------------------------------------------|
magma.dir        = 'C:/users/moconnel/documents/MAGMA'
input.csv        = '//plexossql/data/moconnel/magma/input_data_rts.csv'
db.loc           = '//plexossql/data/moconnel/magma/solution/rts'
                     # '//plexossql/data/moconnel/magma/solution/2',
                     # '//plexossql/data/moconnel/magma/solution/3')
# db.loc = '//plexossql/data/moconnel/magma/solution/rts'
output.dir       = '//plexossql/data/moconnel/magma/reports'
fig.path.name    = '//plexossql/data/moconnel/magma/plots/'
output.name      = 'HTML_magma_RTS.html'
db.day.ahead.loc = '//plexossql/data/moconnel/magma/solution/rts/DA'
query.data       = TRUE
save.data        = FALSE
load.data        = '<Name of file to load if query.data=FALSE >'
save.data.name   = '<Name of file to save data. Will save in output.dir>'
reassign.zones   = FALSE
use.gen.type.csv = TRUE
gen.type.csv.loc = '//plexossql/data/moconnel/magma/gen_name_mapping_WECC_RTS.CSV'
gen.region.zone  = '//plexossql/data/moconnel/magma/gen_name_mapping_WECC_RTS.CSV'

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
