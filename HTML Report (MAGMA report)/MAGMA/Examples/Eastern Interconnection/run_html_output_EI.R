
#------------------------------------------------------------------------------|
# USER INPUT: set input parameters ----
#------------------------------------------------------------------------------|
magma.dir = 'C:/Users/moconnel/documents/MAGMA'
input.csv = '//plexossql/data/moconnel/MAGMA/input_data_example_EI.csv'
output.dir = '//plexossql/data/moconnel/MAGMA/reports'
fig.path.name = '<Path to save figures>'
output.name = 'HTML_output_EI.html'
query.data = TRUE
load.data = '<Name of file to load if query.data=FALSE >'
#------------------------------------------------------------------------------|
# Run code to create HTML
#------------------------------------------------------------------------------|
setwd(magma.dir)
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
	   output_file=output.name, output_dir = file.path(output.dir))