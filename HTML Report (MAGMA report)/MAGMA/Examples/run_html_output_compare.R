
#------------------------------------------------------------------------------|
# USER INPUT: set input parameters ----
#------------------------------------------------------------------------------|
magma.dir = '<Main directory where MAGMA files are located>'
input.csv = '<This should point to your input data CSV file>'
output.dir = '<Directory where HTML reports should be saved>'
output.name = '<Desired output file name. Include .html at end.>'
query.data = '<TRUE if you want to create new queries or 
               FALSE if you want to load existing data>'
load.data = '<Name of file to load if query.data=FALSE>'
save.data = '<TRUE if you want to save all data at the end of MAGMA Run
              FALSE if you do not want to save data. Only html will be produced>'
save.data.name = '<Name of file to save data. Will save in output.dir>'
#------------------------------------------------------------------------------|
# Run code to create HTML
#------------------------------------------------------------------------------|
pacman::p_load(data.table)

setwd(magma.dir)
# Sourcing the setup file and required functions
source(file.path('query_functions.R'))
source(file.path('plot_functions.R'))
source(file.path('query_functions_compare.R'))

# Read CSV file with all inputs
inputs = read.csv(file.path(input.csv))
inputs[inputs==""]=NA
inputs = data.table(inputs)

# Either query data from database or load existing data
source(file.path('setup_plexosAnalysis.R'))
if (query.data){
    source(file.path('setup_dataQueries.R'), echo=TRUE)
} else{
    load(load.data)
}

render(input=file.path('HTML_output_compare.Rmd'), c("html_document"), 
       output_file=output.name, output_dir = file.path(output.dir,''))

if (save.data){
	save(list=ls(), file=file.path(output.dir,save.data.name))
}
