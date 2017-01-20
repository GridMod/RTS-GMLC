
#------------------------------------------------------------------------------|
# USER INPUT: set input parameters ----
#------------------------------------------------------------------------------|
magma.dir        = paste0(dirname(sys.frame(1)$ofile),'/MAGMA')
input.csv        = '../input_data_rts.csv'
db.loc           = '../solution'
output.dir       = '../reports'
fig.path.name    = '../plots/'
output.name      = 'HTML_output_RTS_year_DA2.html'
db.day.ahead.loc = NULL
query.data       = TRUE
save.data        = FALSE
load.data        = '<Name of file to load if query.data=FALSE >'
save.data.name   = '<Name of file to save data. Will save in output.dir>'
reassign.zones   = FALSE
use.gen.type.csv = FALSE
gen.type.csv.loc = NULL
gen.region.zone  = '../gen_name_mapping_WECC_RTS.csv'
#------------------------------------------------------------------------------|
# Run code to create HTML
#------------------------------------------------------------------------------|
setwd(magma.dir)
library(data.table)

# Load inputs
inputs = read.csv(file.path(input.csv))
inputs[inputs==""]=NA
inputs = data.table(inputs)

# Sourcing the setup file and required functions
source(file.path('query_functions.R'))
source(file.path('plot_functions.R'))
source(file.path('setup_plexosAnalysis.R'))
if (query.data){
    source(file.path('setup_dataQueries.R'))
} else{
    load(load.data)
}
render(input=file.path('HTML_output.Rmd'), c("html_document"),
       output_file=output.name, output_dir = file.path(output.dir,''))

if (save.data){
	save(list=ls(), file=file.path(output.dir,save.data.name))
}