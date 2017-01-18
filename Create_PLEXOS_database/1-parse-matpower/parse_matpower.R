pacman::p_load(data.table)

setwd(dirname(sys.frame(1)$ofile))

file.p <- "inputs/RTS.m"

# other.inputs <- "create_other_inputs.R" # old 
other.inputs <- "create_other_inputs_rts2016.R"# new

output.dir <- "outputs"

#------------------------------------------------------------------------------|
#------------------------------------------------------------------------------|
# nesta opf format parser - based on NESTA v0.6.0
# -----------------------------------------------
# 
#   format requirements:
#       - one function that creates and returns a matlab struct of 
#         tables and strings
#       - comments that procede tables are two lines. 
#               first: %% data_description
#               second: % col1  col2    col3, etc
#               
#       - colnames have no spaces
#       - function definition has an output, an equal sign, and no arguments
#       - fields are either one-liner strings or tables that begin with 
#           'strucname.name = [' and end with '];'
#                   
#------------------------------------------------------------------------------|
#------------------------------------------------------------------------------|


#------------------------------------------------------------------------------|
# helper functions ---- 
#------------------------------------------------------------------------------|
func.obj.init <- function(dt) {
    # args: data.table with a column called orig.text
    # use: finds where function is defined
    # result: global environent variables: case.name, struct.name (to be used 
    #   for building list of elemnts), and stuct.list (empty list to be 
    #   populated as the rest of the file is parsed)
    
    # find function definition
    funct.decl <- which(grepl("^function.*=", dt$orig.text))
    
    if (length(funct.decl) == 0) {
        stop(paste("It looks like there is either no function declaration",
                   "in this file or that no function declarations define",
                   sprintf("an output. Please check your file, %s", file.p)))
    } else if (length(funct.decl) > 1) {
        stop(paste("It looks like there is more than one function definition",
                   "in this file. This script cannot handle that at the moment.",
                   sprintf("Please check your file, %s", file.p)))
    }

    # initialize global variables to be accessed by other functions
    case.name <- dt[funct.decl, tstrsplit(orig.text, "=")[[2]]]
    case.name <<- gsub(" ", "", case.name)
    
    struct.name <- dt[funct.decl, tstrsplit(orig.text, "=")[[1]]]
    struct.name <<- gsub("function| ", "", struct.name)
    
    struct.list <<- list()
    
}

func.find.objs <- function(dt, strct.strng) {
    # find indices for all fields added to the structure
    # assumes has one one-liners and tables. 
    #   one.lines: index will be index of the line where everything is defined
    #   tables: begin index is line with table name; row names are one up;
    #       data starts one down
    #           end index is line after last line of data

    # 
    file.dt[grepl(paste0("^[^%]*",strct.strng, "\\..*="), orig.text),
            obj.new := TRUE]
    file.dt[grepl("=.*\\[", orig.text) & obj.new == TRUE, tag := "table.beg"]
    file.dt[grepl("\\].*;", orig.text) & is.na(obj.new), tag := "table.end"]
    file.dt[obj.new & is.na(tag), tag := "one.line"]
    
    # grab info
    file.dt[,index := .I]
    field.loc <- file.dt[!is.na(tag),.(tag, index)]
    
    # clean up
    file.dt[,c("obj.new", "index", "tag") := NULL]
    
    return(field.loc)
}

func.build.list <- function(dt, obj.locs) {
    # from already created tables, pull out elements and add them to a list
    # of all objects in the .m file
    
    if (nrow(obj.locs[!(tag %in% c("one.line", "table.beg", "table.end"))])) {
        stop(paste("Input obj.locs table has at least one tag that isn't",
                   "one.line, table.beg, table.end. Don't know how to handle",
                   "that. Please check the table"))
    }

    for (i in seq(nrow(obj.locs))) {
        
        # get object name            
        i.str <- dt[obj.locs[i, index], orig.text]
        
        i.name <- tstrsplit(i.str, "=")[[1]]
        i.name <- gsub(paste0(" |", struct.name, "\\."), "", i.name)  
        
        # get value, which changes based on type
        if (obj.locs[i,tag] == "one.line") {
  
            i.value <- tstrsplit(i.str, "=")[[2]]
            i.value <- gsub(" |;|\\'", "", i.value)
            
            struct.list[[i.name]] <- i.value
            
        } else if (obj.locs[i, tag] == "table.beg") {
            
            # get and clean table (collapse spaces into tabs, break into table)
            i.table <- dt[obj.locs[i, index+1]:obj.locs[i+1, index-1],
                          # tstrsplit(gsub(";","",gsub("\\s+", "\t", orig.text)), "\t| ")]
                          tstrsplit(gsub(";","", orig.text), "\t|\\s+")]
            
            # deal with nans if needed
            for (j in names(i.table)) {
                set(i.table, which(i.table[[j]] == "nan"), j, NA)
            }
            
            # remove first col if is blank
            if (all(i.table[[1]] == "" | is.na(i.table[[1]]))) {
               i.table[, (1) := NULL] # this is sloppy
            }
            
            # get prev line, assuming is colnames
            i.colnames <- dt[obj.locs[i, index-1]]
            
            if (!grepl("%", i.colnames)) {
                
                message(paste0("couldn't find column names in line above ",
                              "table beginning. please check format of table ",
                              struct.name, ".", i.name, ". In the mean time, ",
                              "labelling columns with generic names."))
                
               i.colnames <- paste("V", 1:ncol(i.table), 
                                   sep = "", collapse = "\t")                
                
            } 
            
            # set new column nanes
            i.colnames <- unlist(tstrsplit(i.colnames, "\t|\\s+"))           
            i.colnames <- i.colnames[!grepl("%", i.colnames)]
            
            # treat gencost as a special case
            if (i.name == "gencost") {
                
                # set names for first four (non-variable) columns
                setnames(i.table, 
                         names(i.table[,.SD, .SDcols = 1:4]),
                         c("model", "startup", "shutdown", "n"))
                
                # determine if is piecewise linear or polynomial
                if (length(unique(i.table$model)) > 1) {
                    stop("I don't know how to handle multiple gen cost types yet")
                }
                
                if (unique(i.table$model) == "1") {
                    
                    # name using model "1" scheme (n = number of piecewise
                    # linear segments and subsequent cols are named 
                    # p0, c0,...,p(n-1),c(n-1)
                    tab.names <- names(i.table)
                    tab.names <- tab.names[grepl("^V", tab.names)]
                    
                    if (length(tab.names) != 2 * as.numeric(i.table[,max(n)])) {
                        stop(paste0("max2 * (n) is not equal to the number of extra ",
                                    "columns in gen.cost. Please verify data is", 
                                    "in the right format"))
                    }
                    
                    new.names.p <- paste0("p", 0:(length(tab.names)/2 - 1))
                    new.names.f <- paste0("f", 0:(length(tab.names)/2 - 1))
                    
                    new.names <- c(rbind(new.names.p, new.names.f))
                    
                    setnames(i.table, 
                             tab.names, 
                             new.names)
                    
                }
                
                if (unique(i.table$model) == "2") {
                    
                    # name using model "2" scheme (n = number of coefficients
                    # in polynomial and subsequent cols are named c(n-1) - c0)
                    tab.names <- names(i.table)
                    tab.names <- tab.names[grepl("^V", tab.names)]
                    
                    if (length(tab.names) != i.table[,max(n)]) {
                        stop(paste0("max(n) is not equal to the number of extra ",
                                    "columns in gen.cost. Please verify data is", 
                                    "in the right format"))
                    }
                    
                    new.names <- paste0("c", (length(tab.names) - 1):0)
                    
                    setnames(i.table, 
                             tab.names, 
                             new.names)
                    
                }
            
            } else { # any table but gencost
                
                # adjust name setting if there is an error
                tryCatch(setnames(i.table, colnames(i.table), i.colnames), 
                         
                         error =  function(e) {
                             if (length(i.colnames) < length(colnames(i.table))) {
                                 message(paste0("not enough new colnames for table ", 
                                                struct.name, ".", i.name, 
                                                ". leaving some cols unnameed. ",
                                                "please check table."))
                                 
                                 setnames(i.table,
                                          colnames(i.table)[seq_along(i.colnames)],
                                          i.colnames)
                                 
                             } else {
                                 message(paste0("too many new colnames for table ", 
                                                struct.name, ".", i.name, 
                                                ". exluding extras. ",
                                                "please check table."))
                                 setnames(i.table,
                                          colnames(i.table),
                                          i.colnames[seq_along(colnames(i.table))])                             
                             }}
                )                
            }
            

            
            
            # now that table is created and renames, add to list
            struct.list[[i.name]] <- i.table
            
        } else if (obj.locs[i, tag] == "table.beg") {
            
            next
            
        }
    }
    
    return(struct.list)

}

#------------------------------------------------------------------------------|
# read in and parse file ---- 
#------------------------------------------------------------------------------|

# read in file
file.dt <- data.table(orig.text = readLines(file.p))

# get rid of blanks at beginnings of lines and blank lines
file.dt[,orig.text := gsub("^\\s+|^\t", "", orig.text)]
file.dt <- file.dt[orig.text != ""]

# pull out name, object name
#   creates vars case.name, struct.name, struct.list
func.obj.init(file.dt)

# prep for real parsing
if (!(exists("case.name")|exists("struct.name")|exists("struct.list"))) {
    stop(paste("At least one of case.name, struct.name, and struct.list",
               "doesn't exist. Please initialize these by running",
               "func.obj.init"))
}

# id where new objects are
field.loc <- func.find.objs(file.dt, struct.name)

# for all objects, grab and put in list
struct.list <- func.build.list(file.dt, field.loc)

#------------------------------------------------------------------------------|
# reformat for use in scripts ---- 
#------------------------------------------------------------------------------|

# regions
region.refnode.data <- struct.list$areas[,.(Region = area, 
                                            `Region.Reference Node` = refbus)]

# nodes
node.data <- struct.list$bus[,.(Node = bus_i, Voltage = baseKV, Region = area, 
                                       Zone = zone)]

# node lpf TODO
node.data <- struct.list$bus[,.(Node = bus_i, Voltage = baseKV, Region = area, 
                                       Zone = zone)]

# generators
generator.data <- struct.list$gen[,.(Node = bus, Units = status, 
                                     `Max Capacity` = Pmax, 
                                     `Min Stable Level` = Pmin)]

generator.data[,id := 1:.N, by = Node]
generator.data[,Generator := paste0(Node, "_", id)]
generator.data[,id := NULL]

# change synchronous condenser max capacity from NA to 0
generator.data[is.na(`Max Capacity`), `Max Capacity` := '0']

gencost <- struct.list$gencost

# lines
line.data <- struct.list$branch[,.(`Node From` = fbus, `Node To` = tbus,
                                   Resistance = r, Reactance = x, 
                                   `Max Flow` = rateA, rateA, rateB, rateC,
                                   Units = status)]

line.data[,id := 1:.N, by = .(`Node To`, `Node From`)]
line.data[,Line := paste0(`Node From`, "_", `Node To`, "_", id)]
line.data[,id := NULL]

line.data[,`Min Flow` := -1 * as.numeric(`Max Flow`)]

all.tabs <- c()

source(other.inputs)
# make new create_other_inputs file
# - min gen
# - forced outage rate
# - heat rate
# - fuel price
# - start cost (adjust)
# - add VG
# - attach load
# - attach hydro

#------------------------------------------------------------------------------|
# write out ----
#------------------------------------------------------------------------------|

if (!dir.exists(output.dir)) {
    dir.create(output.dir, recursive = TRUE)
}


all.tabs <- c(all.tabs, "region.refnode.data", "node.data", "generator.data", "line.data")

for (tab in all.tabs) {

    write.csv(get(tab), file.path(output.dir, paste0(tab, ".csv")),
              quote = FALSE, row.names = FALSE)

}

rm(tab, all.tabs)
