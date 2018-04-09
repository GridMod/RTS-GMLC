#------------------------------------------------------------------------------|
# get needed packages and functions ----
#------------------------------------------------------------------------------|

if (!require(pacman)) {
    install.packages("pacman")
}

if (!("openxlsx" %in% installed.packages()[, "Package"]) & export.wb == TRUE) {
    stop(paste0("You are attempting to export an Excel workbook (export.wb is",
                " set to TRUE) but openxlsx is not installed.", 
                " Either set export.wb to FALSE or, to export an excel file,", 
                " install openxlsx. Follow",
                " instructions here: https://github.com/awalker89/openxlsx", 
                " including installing Rtools from here:",  
                " https://cran.r-project.org/bin/windows/Rtools/", 
                " and making sure PATH variable was edited",  
                " (check the 'edit path' box during installation)"))
}

pacman::p_load(cowplot, ggplot2, data.table, igraph, openxlsx, RPostgreSQL,zoo) 


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
    rm(cl.args.vec, arg.name)
}

rm(cl.args)

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

# check for output.wb.name
if (!exists("output.wb.name")) {
    
    output.wb.name <- paste0("pidg_export_", gsub(" ","_",Sys.time()), ".xlsx")
    
    message(sprintf(paste("output.wb.name does not exist. if a workbook is",
                          "exported, it will be saved as %s"), 
                    output.wb.name))
}

# check for export.wb
if (!exists("export.wb")) {
    
    message("export.wb does not exist. setting to TRUE")
    export.wb <- TRUE
}

# check for data.check.plots
if (!exists("data.check.plots")) {
    
    message("data.check.plots does not exist. setting to TRUE")
    data.check.plots <- TRUE
}


#------------------------------------------------------------------------------|
# source functions and input parameters ----
#------------------------------------------------------------------------------|

source(file.path(pidg.dir, "SourceScripts/functions.R"))

# open connection to database if needed
if (exists("inputfiles.db")) {
    conn = dbConnect(drv = inputfiles.db$drv, 
                     host = inputfiles.db$host, 
                     dbname = inputfiles.db$dbname, 
                     user = inputfiles.db$user, 
                     password = inputfiles.db$password)
}

source(input.params)


#------------------------------------------------------------------------------|
# set defaults for required input parameter variables ----
#------------------------------------------------------------------------------|

# set plexos.version to 7 if not provided
if (!exists("plexos.version")) {
    
    message("plexos.version not provided. setting to 7.")
    plexos.version <- 7
}


#------------------------------------------------------------------------------|
# function definition ----
#------------------------------------------------------------------------------|

parse.in.place <- TRUE

runAllFiles <- function () {
    
    if (exists("raw.file.list")) {
        
        for (cur.raw.file in raw.file.list) {
            # hacky... move cur.raw.file to global env so scripts can find it
            cur.raw.file <<- cur.raw.file 
            
            message("importing PSSE files...")
            source(file.path(pidg.dir, "SourceScripts", "a-1-parse-psse.R"))
            source(file.path(pidg.dir, "SourceScripts", "a-2-reformat-psse.R"))
            
        }
    }
    
    # proceed with rest of data compilation
    message("creating tables...")
    source(file.path(pidg.dir, "SourceScripts", "b_create_sheet_tables.R"))
    
    message("populating tables...")
    source(file.path(pidg.dir, "SourceScripts", "c_data_population.R"))
    
    message("cleaning tables...")
    source(file.path(pidg.dir, "SourceScripts", "d_data_cleanup.R"))
    
    # check data, create plots if need to
    # by default, generate the plots
    if(data.check.plots == TRUE){
        message("checking data and creating summary plots...")
    }else{
        message("checking data...")
    }
    source(file.path(pidg.dir, "SourceScripts", "e_data_checks.R"))
    
    # export tables
    if (export.wb) {
        message("exporting tables...")
        source(file.path(pidg.dir, "SourceScripts", "f_export_to_excel.R"))
    } else {
        message("export.wb set to false. skipping export.")
    }
    
    message("done!")
    
}


#------------------------------------------------------------------------------|
# run PIDG ----
#------------------------------------------------------------------------------|

runAllFiles()


#------------------------------------------------------------------------------|
# close up ----
#------------------------------------------------------------------------------|

if (exists("inputfiles.db")) {
    dbDisconnect(conn)
}
