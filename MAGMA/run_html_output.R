
#------------------------------------------------------------------------------|
# USER INPUT: set input parameters ----
#------------------------------------------------------------------------------|
magma.dir      = 'C:/users/moconnel/documents/MAGMA'
db.location    = 'solution'
da.db.location = '< da.db.location=FALSE if not making DA-RT plots>'
da.db.location = FALSE
input.csv      = 'input_data_rts.csv'
output.dir     = 'reports'
fig.path.name  = 'plots/'
output.name    = 'HTML_output_RTS_year_DA.html'
query.data     = TRUE
load.data      = '<Name of file to load if query.data=FALSE >'
save.data      = FALSE
save.data.name = '<Name of file to save data. Will save in output.dir>'
#------------------------------------------------------------------------------|
# Run code to create HTML
#------------------------------------------------------------------------------|
setwd(magma.dir)
library(data.table)
input.file.dir = dirname(sys.frame(1)$ofile)

# Load inputs
inputs = read.csv(file.path(input.file.dir, input.csv))
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
       output_file=output.name, output_dir = file.path(input.file.dir, output.dir,''))

if (save.data){
	save(list=ls(), file=file.path(input.file.dir, output.dir,save.data.name))
}