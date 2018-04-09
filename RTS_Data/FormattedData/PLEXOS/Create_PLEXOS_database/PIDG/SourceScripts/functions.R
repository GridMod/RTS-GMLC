#------------------------------------------------------------------------------|
# General helper functions ----
#------------------------------------------------------------------------------|

### check_colname_cap 
# check to see if there are capitalization errors in category and notes cols, 
# fix if they exist (excluding first col, since scenario, variable are also
# objects)
check_colname_cap <- function(dt, version = NA) {
    
    # check capitalization
    cols.to.check <- c("category", "notes", "action", "escalator", "condition", 
                       "scenario", "variable", "memo", "date_from", "date_to")
    
    dt.names <- names(dt)[-1]
    
    for (col in cols.to.check) {
        
        col.names <- dt.names[tolower(dt.names) == col]
        
        if (length(col.names) > 0 && col.names != col) {
            setnames(dt, col.names, col)
        }
    }
    
    # optionally check version
    if (!is.na(version)) {
        if (version == 7 & 
            ("escalator" %in% dt.names | "condition" %in% dt.names)) {
            stop(paste0("Error: you have specified plexos.version == 7 ",
                        "but you have version 6 column names in your input ",
                        "data ('escalator' and/or 'condition'). Please ",
                        "either change these to version 7 names ('action') ",
                        "or specify plexos.version = 6"))
        } else if (version == 6 & "action" %in% dt.names) {
            stop(paste0("Error: you have specified plexos.version == 6 ",
                        "but you have a version 7 column name in your input ",
                        "data ('action'). Please either change these to ",
                        "version 6 names ('escalator' and/or 'condition') ",
                        "or specify plexos.version = 7"))
        }
    }
    
}

### check_for_dupes
# check to see if there are dupes and error out if there are. 
# pass in dt and cols (character vector) to consider
# assumes first col is named by type
check_for_dupes <- function(dt, cols) {
    
    if (anyDuplicated(dt, by = cols) != 0) {
        
        type <- names(dt)[1]
        
        dupes <- dt[duplicated(dt, by = cols), unique(get(type))]
        
        stop(paste0("The following ", type, "s are duplicated in ", 
                    type, ".data.table: ", paste(dupes, collapse = ", "), 
                    ". Please remove duplicates."))
        
    }
}

### fix_db_colnames
# helper function for fixing capitalization in db queries
fix_db_colnames <- function(x) {
    
    # one underscore means space, two means underscore (change to -), 
    # cap words after space
    x <- gsub("\\_{2}", "-", x)
    x <- gsub("\\_", " ", x)
    
    s <- strsplit(x, " ")[[1]]
    x <- paste(toupper(substring(s, 1, 1)), substring(s, 2),
               sep = "", collapse = " ")
    
    # replace the placeholder - with _ and capitalize word after _
    x <- gsub("-", "_", x)
    
    s <- strsplit(x, "_")[[1]]
    x <- paste(toupper(substring(s, 1, 1)), substring(s, 2),
               sep = "", collapse = "_")
    
    # hard cord exceptions - may need to add to this
    if (x == "Voll") x <- "VoLL"
    if (x == "Vors") x <- "VoRS"
    if (grepl(" At ", x)) x <- gsub(" At ", " at ", x)
    
    return(x)
}


### read_data
# read in data. if argument is csv, will use fread. if not, will send as a query
# to database. Internally, will run checks to pull data. If checks succeed, 
# function will return data. If not, will return NA.
read_data <- function(to_data, dir = inputfiles.dir, con = conn, 
                      fix.db.colnames = TRUE, ...) {
    
    if (is.data.table(to_data)) {
        
        to.return <- to_data
        
        # change global path to data so doesn't print entire data.table 
        # when printing message (this is probably bad practice...)
        data.name <- deparse(substitute(to_data))
        tab.message <- paste0("data.table in environment with colnames: ",
                              paste(names(to.return), collapse = ", "))
        
        assign(data.name, tab.message, .GlobalEnv)
        
    } else {
        
        if (endsWith(to_data, ".csv")) {
            
            # pull data from csv if the csv exists
            if (file.exists(file.path(dir, to_data))) {
                to.return <- fread(file.path(dir, to_data), ...)
                
            } else {
                message(sprintf(">>  %s does not exist ... skipping", to_data))
                to.return <- NA
            }
            
        } else if (startsWith(tolower(to_data), "select")) {
            
            # pull data from a db if a connection exists
            if (exists("conn")) {
                
                # pull data from database and process colnames
                to.return <- dbGetQuery(con, to_data) 
                
                setDT(to.return)
                
                if (fix.db.colnames) {
                    setnames(to.return, 
                             names(to.return), 
                             sapply(names(to.return), fix_db_colnames))
                }
                
            } else {
                
                message(sprintf(">>  %s is a sql query, but no db connection exists ... skipping", 
                                to_data))
                to.return <- NA
            }
            
        } else {
            
            # this isn't a csv or a db query, so skip
            message(sprintf(">>  couldn't identify %s as a csv or sql query ... skipping", 
                            to_data))
            to.return <- NA
            
        }
    }
    
    return(to.return)
    
}

#------------------------------------------------------------------------------|
# Functions for creating and merging tables for data population ----
#------------------------------------------------------------------------------|

###initiallize_table
# initializes new .sheets table. Requires number of rows and fills in with 
# constants whatever informtion is provided by the user (can be NULL). Returns 
# created data.table. 
# This is useful for initializing tables with constants in several columns so 
# code can be condensed to one line
# Note: cols.list should be a list to allow data in different columns to be of 
# different types. If cols.vec is a list, nothing bad will happen, but all 
# numbers will be coerced into characters and that will throw a warning 
# (but not error) later.
initialize_table <- function (model.table, nrows, cols.list = list()) {
    
    # create dummy column to initialize table with proper number of rows
    new.table <- data.table(init.col = character(nrows))
    col.names <- colnames(model.table)
    
    for (col.name in names(cols.list)) {
      new.table[, eval(col.name) := cols.list[[col.name]]]
    }
    
    for (col.name in col.names[!(col.names %in% names(cols.list))]) {
      new.table[, eval(col.name) := NA_character_]
    }
    
    new.table[, init.col := NULL]
    
    return(new.table)
}


###merge_sheet_w_table
# Takes a .sheet table and another data.table, merges them, and returns the 
# populated .sheet table. Will preserve the order of the columns, which is
# important when these tables are being read into Plexos.
# Note: thiscon
merge_sheet_w_table <- function(sheet.table, table.to.merge) {
  
    sheet.cols <- colnames(sheet.table) 
    
    # convert all columns to character so that they will be same data type 
    # as .sheet table
    table.to.merge <- table.to.merge[, lapply(.SD, as.character)] 
    
    sheet.table <- merge(sheet.table, 
                         table.to.merge,
                         by = colnames(table.to.merge), 
                         all = TRUE)
    
    setcolorder(sheet.table, sheet.cols)
    
    return(sheet.table)
}

### add_scenario
# add scenarios to object properties if they don't already exist in category
add_scenarios <- function(scenarios, category = NA) {
    
    to.add <- data.table(Scenario = scenarios, category = category)
    
    to.add <- to.add[!(is.na(Scenario) | Scenario %in% c(" ", ""))]
    to.add <- to.add[!(Scenario %in% Objects.sheet[class == "Scenario", name])]
    
    to.add[category %in% c(" ", ""), category := NA]
    
    to.add <- unique(to.add)
    
    if (to.add[,.N] > 0) {
        
        import_objects(to.add)
    }
    
} 

#------------------------------------------------------------------------------|
# Functions to standardize and generalize data import ----
#------------------------------------------------------------------------------|

###import_table
# Takes a .csv file consisting of Objects, Categories, Memberships, Attributes, 
# Properties, and/or Reports tables delimited by "/ BEGIN, [name]" and 
# "/ END, [name]" lines, as well as a character specifying which table should be 
# output and returns a data.table with that information. 
# Not all tables are needed. Column names for tables with data must be spelled 
# and capitalized exactly as they are in .sheets tables. Order does not matter. 
# Any column called "notes" will be deleted during import, so comments can be 
# stored in the .csv there
import_table_generic <- function(imported.csv.table, sheet.name) {
    
    if (!(sheet.name %in% c("Objects", "Categories", "Memberships", 
                            "Attributes","Properties", "Reports"))) {
        print("Please specify one of the following tables: 
              Objects, Categories, Memberships, Attributes, 
              Properties, Reports")} else {
                  
        #set up indices
        begin.index <- which(imported.csv.table[,toupper(V1)] == "/ BEGIN" & 
            imported.csv.table[,toupper(V2)] == toupper(sheet.name)) + 2
        end.index <- which(imported.csv.table[,toupper(V1)] == "/ END" & 
            imported.csv.table[,toupper(V2)] == toupper(sheet.name)) - 1
        colnames.index <- begin.index - 1
        
        if (length(colnames.index) == 0 || colnames.index >= end.index) {
            
          return(NULL)}
        
        #set up table
        requested.table <- imported.csv.table[begin.index:end.index,]
        
        setnames(requested.table, 
                 as.character(imported.csv.table[colnames.index,]))
        
        requested.table <- requested.table[,which(sapply(requested.table,
                                                         function(x) !all(x=="") & 
                                                                     !all(is.na(x)) )), 
                                           with=F]
        
        if ("notes" %in% colnames(requested.table)) {
          requested.table[,notes := NULL]}
        
        return(requested.table)
    }
} 


###import_table_compact
# Takes two arguments: data.table of information that has been read in from an
# external file and a string describing the objects contained in that file
# (currently, 'model' or 'horizon,' not case sensitive)
# 
# REQUIRED FILE FORMAT: 
# 
# first column is 'names', first row of that is 'category' (could have text or 
# not), other columns either names of objects or 'notes' for explanation of 
# any numbers. notes columns will be ignored.
# other than that, 'names' col is divided into chucks starting with these tags.
# data should start the row after these tags. order of tagged chunks does not
# matter.
# /START ATTRIBUTES
# /START MEMBERSHIPS
# /START SCENARIOS
# 
# data chunk should consist of: (attributes) plexos attribute name in 'names' 
# column, desired value in column corresponding to object name. (memberships)
# name of object class/collection* which is the child of object on column. name 
# of child object is in column. (scenarios) scenarios that should be attached
# to models listed under models. extra, blank rows will be ignored.
# 
# *will only for for non-scenario memberships where object class == collection
import_table_compact <- function(input.table, object.type) {
    
    # can only handle models and horizons now. yell if user selected smthing else
    if (!(tolower(object.type) %in% c('model', 'horizon', 'production',
                                      'transmission', 'performance', 'mt schedule', 
                                      'st schedule'))) {
        warning(paste0("In compact.generic.import.files, an incorrect object type",
                       " was selected. Please choose from (not case sensitive): ",
                       "model, horizon, production, transmission, performance, ",
                       "mt schedule, st schedule"))
    }
    
    # set object.type to properly capitalized version (Model, Horizon, etc)
    # this is used to fill class cols later
    object.type <- paste0(toupper(substr(object.type, 1, 1)), 
                          tolower(substr(object.type, 2, nchar(object.type))))
    
    # treat special case of MT or ST schedule
    if (grepl('schedule', tolower(object.type))) {
        object.type.parts <- strsplit(object.type, ' ')[[1]]
        object.type <- paste0(toupper(object.type.parts[1]), ' ', 
                              toupper(substr(object.type.parts[2], 1, 1)), 
                              tolower(substr(object.type.parts[2], 2, 
                                             nchar(object.type.parts[2]))))
    }
    
    # ---- SET UP DATA FOR USE LATER
    
    # pull all object names, which are stored as column names (except first col)
    all.objects <- colnames(input.table)
    all.objects <- all.objects[all.objects != 'names' & all.objects != 'notes']
    
    # remove notes columns
    input.table <- input.table[,.SD, .SDcols = c('names', all.objects)]
    
    # grab /START of attributes, memberships, and scenarios and put them in 
    # ordered vector for index comparison later. also grab total numrows
    start.attrib <- input.table[names == '/START ATTRIBUTES', which = TRUE]
    start.memb <- input.table[names == '/START MEMBERSHIPS', which = TRUE]
    start.scen <- input.table[names == '/START SCENARIOS', which = TRUE]
    all.start.ind <- sort(c(start.attrib, start.memb, start.scen))
    
    nrows <- input.table[,.N]
    
    
    # ---- ADD TO OBJECTS SHEET
    
    # grab category information and put these all together in objects.sheet
    objcat <- input.table[names == 'category', .SD, .SDcols = all.objects]
    
    objcat[objcat == "" | objcat == " "] <- NA
    
    # transpose to be in long form so can be put into initialize_table
    objcat <- melt(objcat, 
                   measure.vars = all.objects, 
                   variable.name = 'name', 
                   value.name = 'category')
    
    # create objects table and merge with Objects.sheet
    to.object.sheet <- initialize_table(Objects.sheet, 
                                        nrow(objcat), 
                                        list(class = object.type, 
                                             name = objcat$name, 
                                             category = objcat$category))
    
    Objects.sheet <<- merge_sheet_w_table(Objects.sheet, to.object.sheet)
    
    
    # ---- ADD TO ATTRIBUTE SHEET (if there is a /START ATTRIBUTES tag)
    
    if (length(start.attrib) > 0) {
        # find where attribs section ends, either next /START index or the last row
        last.row.ind <- if (any(all.start.ind > start.attrib)) {
            # get first ind larger than start.attib, end of attribs is previous row
            all.start.ind[all.start.ind > start.attrib][1] - 1 } else nrows
        
        attribs.raw <- input.table[(start.attrib + 1) : last.row.ind]
        
        # melt to be in better format
        attribs.raw <- melt(attribs.raw, 
                            id.vars = 'names', 
                            variable.name = 'name')
        
        # remove blanks
        attribs.raw <- attribs.raw[value != ""]
        
        to.attrib.sheet <- initialize_table(Attributes.sheet, 
                                            nrow(attribs.raw), 
                                            list(name = attribs.raw$name, 
                                                 class = object.type, 
                                                 attribute = attribs.raw$names, 
                                                 value = attribs.raw$value))
        
        Attributes.sheet <<- merge_sheet_w_table(Attributes.sheet, to.attrib.sheet)
        
    }
    
    
    # ADD TO (non-scenario) MEMBERSHIPS SHEET
    
    if (length(start.memb) > 0) {
        # find where membs section ends, either next /START index or the last row
        last.row.ind <- if (any(all.start.ind > start.memb)) {
            # get first ind larger that start.memb, end of membs is previous row
            all.start.ind[all.start.ind > start.memb][1] - 1 } else nrows
        
        membs.raw <- input.table[(start.memb + 1) : last.row.ind]
        
        # melt to be in better format
        membs.raw <- melt(membs.raw, 
                          id.vars = 'names', 
                          variable.name = 'name', 
                          value.name = 'child')
        
        # remove blanks
        membs.raw <- membs.raw[child != ""]
        
        to.memb.sheet <- initialize_table(Memberships.sheet, 
                                          nrow(membs.raw), 
                                          list(parent_class = object.type, 
                                               parent_object = membs.raw$name, 
                                               collection = membs.raw$names, 
                                               child_class = membs.raw$names, 
                                               child_object = membs.raw$child))
        
        Memberships.sheet <<- merge_sheet_w_table(Memberships.sheet, to.memb.sheet)
        
    }
    
    # ----- ADD TO (scenario) MEMBERSHIPS SHEET
    
    if (length(start.scen) > 0) {
        # find where membs section ends, either next /START index or the last row
        last.row.ind <- if (any(all.start.ind > start.scen)) {
            # get first ind larger that start.memb, end of membs is previous row
            all.start.ind[all.start.ind > start.scen][1] - 1 } else nrows
        
        scens.raw <- input.table[(start.scen + 1) : last.row.ind]
        
        # melt to be in better format
        scens.raw <- melt(scens.raw, 
                          id.vars = 'names', 
                          variable.name = 'name', 
                          value.name = 'child')
        
        # remove blanks
        scens.raw <- scens.raw[child != ""]
        
        to.scen.sheet <- initialize_table(Memberships.sheet, 
                                          nrow(scens.raw), 
                                          list(parent_class = object.type, 
                                               parent_object = scens.raw$name, 
                                               collection = 'Scenarios', 
                                               child_class = 'Scenario', 
                                               child_object = scens.raw$child))
        
        Memberships.sheet <<- merge_sheet_w_table(Memberships.sheet, to.scen.sheet)
        
    }
}


##merge_property_by_fuel
# Takes an input table containing properties of generators indexed by fuel, 
# name of property column, Plexos name of property. Merges this with 
# gen.names,table, then returns a two column data.table, which contains
# Generator.Name and a column with the property in question whose column name
# is the Plexos name for that property.
# 
# If property.name is NULL, take property name to be the name of the column
# Note: Name of fuel column must be "Fuel"
merge_property_by_fuel <- function(input.table, 
                                   mult.by.max.cap = FALSE, 
                                   mult.by.num.units = FALSE, 
                                   cap.band.col = NA, band.col = NA, 
                                   memo.col = NA) {
    
    all.cols <- colnames(input.table)
    
    non.prop.cols <- na.omit(c(cap.band.col, band.col, memo.col, 
                               "scenario", "notes", "scenario.cat", "action", 
                               "escalator", "condition", "variable", 
                               "category"))
    
    prop.cols <- all.cols[!(all.cols %in% non.prop.cols)] 

    # make sure all non.prop.cols are actually in the dt
    non.prop.cols <- all.cols[!(all.cols %in% prop.cols)] 
    
    if (!all(prop.cols %in% all.cols)) {
        
        stop(paste0("At least one listed prop.col is not in associated inputfile ", 
                    "Cannot merge this table.\n\tListed prop.cols: ", 
                    paste(prop.cols, collapse = ", "), "\n\tColumns in table: ",
                    paste(all.cols, collapse = ", ")))
    }

    # make sure Fuel column exists before merging
    if (!("category" %in% colnames(input.table))) {

        stop(paste0("There is no 'category' column in the input table. ", 
                    "Cannot merge this table. Property name is: ", prop.cols, "."))
    }

    #This caused errors... need to determine how to insert memos into PLEXOS
    #if (!is.na(memo.col)) prop.cols <- c(prop.cols, memo.col)
    
    
    # split property by max capacity if needed
    if (is.na(cap.band.col)) {
        
        # if cap.band.col is NA, then don't need to split properties by max
        # capacity, so can do a regular merge with generator.data.table
        # if band.col exists, include it in the merge and allow.cartesian, b/c
        # merged table will probably be big enough to throw an error
        tmp.gen.data <- unique(generator.data.table[!(Units == 0 & 
                                                          grepl("GRTPV|GPV|Gwind", Generator) & 
                                                          !(Generator %in% c("GRTPV_Jammu_Kashmir_MRE_39", "GRTPV_Maharashtra_MRE_73"))),
                                                    .(Generator, 
                                                      category,
                                                      `Max Capacity`, 
                                                      Units)])
        
        generator.data.table <- merge(tmp.gen.data,
                                      input.table[,.SD,
                                                  .SDcols = c(non.prop.cols,
                                                              prop.cols)],
                                      by = "category",
                                      allow.cartesian = TRUE)  
        
    } else {
        
        # is a cap.band.col is give, use that to split up property distribution
        # when merging
        
        # create vectors of breaks for each category type (with min == -1 and 
        # max == max capacity in generator.data.table)
        maxes <- generator.data.table[,.(maxcap = max(`Max Capacity`)), 
                                      by = .(category)]
        all.cats <- input.table[,unique(category)]
        
        category.breaks <- list()
        for (cat in all.cats) {
            
         unique.breaks <- input.table[category == cat, unique(get(cap.band.col))]
         
         if (any(!is.na(unique.breaks))) {
             
             unique.breaks <- c(-1, unique.breaks)
         } else {
             
             unique.breaks <- c(-1, maxes[category == cat, maxcap])
         }
         
         unique.breaks <- sort(na.omit(unique.breaks))
         
         category.breaks[[cat]] <- unique.breaks
        }
        
        # now that we have breaks for each cat, add column to generator.data.table 
        # and input.table that sorts gens, so can merge by that and cat
        suppressWarnings(generator.data.table[, breaks.col := NULL]) # reset
        
        for (cat in all.cats) {
            
            # add capacity even to NA cols in input.table, so they get sorted right
            if (cat %in% maxes$category) {
                input.table[category == cat & is.na(get(cap.band.col)),
                            breaks.col := cut(c(0, maxes[category == cat, as.integer(maxcap)]),
                                              breaks = c(-1, maxes[category == cat, as.integer(maxcap)]))[[1]]]
                
                # add breaks col
                input.table[category == cat & !is.na(get(cap.band.col)), 
                            breaks.col := cut(get(cap.band.col), breaks = category.breaks[[cat]])]
                
                generator.data.table[category == cat, breaks.col := cut(`Max Capacity`,
                                                                         breaks = category.breaks[[cat]])]
                
                generator.data.table <- unique(rbind(generator.data.table[,.(Generator, category, Units, `Max Capacity`, breaks.col)], 
                                                     generator.data.table[category == cat, 
                                                                          .(Generator, category, Units, `Max Capacity`, 
                                                                            breaks.col = cut(c(0, maxes[category == cat, as.integer(maxcap)]),
                                                                                             breaks = c(-1, maxes[category == cat, as.integer(maxcap)]))[[1]])]))
            }
        }
        
        # finally, merge input.table with generator.data.table
        # similarly, if there is a band col, include it and allow.cartesian
        generator.data.table <- merge(generator.data.table[,.(Generator, 
                                                              category,
                                                              `Max Capacity`, 
                                                              Units,
                                                              breaks.col)], 
                                      input.table[,.SD,
                                                  .SDcols = c(non.prop.cols, 
                                                              prop.cols, 
                                                              "breaks.col")],
                                      by = c("category", "breaks.col"), 
                                      allow.cartesian = TRUE)
        
    }
    # if this property should be multiplied by max capacity, do it
    if (mult.by.max.cap) {
        for (colname in prop.cols) {
            generator.data.table[,c(colname) := get(colname) * `Max Capacity`]
        }
    }
    
    # if this property should be multiplied by number of units, do it
    if (mult.by.num.units) {
        for (colname in prop.cols) {
            generator.data.table[,c(colname) := get(colname) * Units]
        }
    }
    
    return.cols = c('Generator', prop.cols, non.prop.cols)
    return.cols = return.cols[!(return.cols %in% c("category", cap.band.col))]
    
    # return generator + property
    return(generator.data.table[,.SD, 
                                .SDcols = return.cols[!is.na(return.cols)]])
}


##import_properties
# Shortcut for creating addition to Properties.Sheet table, given inputs of a 
# certain form.
# 
# Takes a table of (col1) Object Name and (cols 2-n) property values (where 
# plexos property name are the column names), name of object class and 
# collection, melts this into long form, then merges with Properties.sheet
# 
# overwrite.cols can be any column in Properties sheet except value. That column
# will also be overwritten
import_properties <- function(input.table, 
                              object.class = NA, 
                              names.col = NA, 
                              collection.name = NA, 
                              parent.col = NA,
                              scenario.name = NA,
                              scenario.cat = NA,
                              pattern.col = NA,
                              period.id = 0, datafile.col = NA, 
                              date_from.col = NA, overwrite = FALSE, 
                              overwrite.cols = NA, band.col = NA, 
                              memo.col = NA) {
    
    # get all property column names (everything but object names column and 
    # pattern column, if applicable)
    all.cols <- colnames(input.table)
   
    # names.col, object.class, collection.name are optional. if they don't
    # exist, assume names.col is first column, class is names.col, and 
    # collection is names.col with an s
    if (is.na(names.col)) names.col <- all.cols[1]
    
    if (is.na(object.class)) object.class <- names.col
    
    if (is.na(collection.name)) collection.name <- paste0(object.class, "s")    
    
    non.prop.cols <- c(names.col, parent.col, pattern.col, period.id, 
                       date_from.col,band.col, memo.col, "scenario", "notes", 
                       "scenario.cat", "action", "escalator", "condition", 
                       "variable", "category")
    
    # check to make sure all given columns exist
    given.cols <- na.omit(c(names.col, parent.col, pattern.col,
                            date_from.col, band.col, memo.col, 
                            datafile.col))
    
    if (!all(given.cols %in% all.cols)) {
        stop(paste0("At least one given column name is not in input table. ",
                    "Cannot merge this table.\n\tGiven columns: ",
                    paste(given.cols, collapse = ", "),
                    "\n\tColumns in table: ",
                    paste(all.cols, collapse = ", ")))
    }
    
    if (!is.na(overwrite.cols) & 
        !all(overwrite.cols %in% colnames(Properties.sheet))) {
            stop(paste0("Overwrite.cols given but at least one is not a column ",
                        "in Properties.sheet.\n\tgiven overwrite.cols: ",
                        paste(overwrite.cols, collapse = ", "),
                        "\n\tProperties.sheet columns: ",
                        paste(colnames(Properties.sheet), collapse = ", ")))
        }
    
    # if any columns contain datafiles, mark them here to can deal with later
    if (!is.na(datafile.col[1])) {
        setnames(input.table, datafile.col, paste0("datafile_", datafile.col))}
    
    if (is.na(parent.col)) parent.col <- "System"

    prop.cols <- all.cols[!(all.cols %in% non.prop.cols)] 
    
    if(length(prop.cols) > 0){
        
        # change all variables to character
        input.table <- input.table[,lapply(.SD,as.character)]
        
        # melt input table. results in table with 3 columns: (names.col), 
        # property, value
        input.table <- melt(input.table, measure.vars = prop.cols, 
                            variable.name = "property")
        # remove missing values
        input.table <- input.table[!(is.na(value) | is.na(property) | value == "" |
                                         property == "")]
        
        # create properties table with these properties
        props.tab <- initialize_table(Properties.sheet, 
                                      nrow(input.table), 
                                      list(
                                          parent_class = parent.col,
                                          parent_object = ifelse(parent.col == "System", 
                                                                 parent.col, 
                                                                 list(input.table[,get(parent.col)])),
                                          collection = collection.name, 
                                          child_class = object.class, 
                                          child_object = input.table[, .SD, 
                                                                     .SDcols = names.col], 
                                          property = input.table[, property], 
                                          value = input.table[, value], 
                                          band_id = ifelse(is.na(band.col),
                                                           1,
                                                           list(input.table[,get(band.col)]))))
        
        # if have datafile cols, move the filepointer to the datafile column and set 
        # property value to zero
        
        props.tab[grepl("datafile_",property),filename := value]
        props.tab[grepl("datafile_",property),
                  c("value", "property") := 
                      .("0", gsub("datafile_", "", property))]
        
        # add pattern column if specified
        if (!is.na(pattern.col)) {
            props.tab[, pattern := input.table[,.SD, .SDcols = pattern.col]]
        }
        
        #adding a date_from col if specified
        if (!is.na(date_from.col)) {
            props.tab[, date_from := input.table[, .SD, .SDcols = date_from.col]]
        }
        
        # add period type id column if specified
        if (!is.na(period.id)) {
            props.tab[, period_type_id := as.character(period.id)]
        }
        
        # change period.id if the property calls for it. assumes particular
        # format of *Hour|Day|Week|Month|Year properties
        if (any(grepl("(Hour|Day|Week|Month|Year)$", prop.cols))) {
            props.tab[grepl("Hour$", property), period_type_id := "6"]
            props.tab[grepl("Day$", property), period_type_id := "1"]
            props.tab[grepl("Week$", property), period_type_id := "2"]
            props.tab[grepl("Month$", property), period_type_id := "3"]
            props.tab[grepl("Year$", property), period_type_id := "4"] 
        }

        # add scenario name if specified
        if (!is.na(scenario.name)) {
            props.tab[,scenario := paste0("{Object}", scenario.name)] 
        }
        
        # add scenario column if specified
        if ("scenario" %in% names(input.table)) {
            
            if (!is.na(scenario.name)) {
                message(paste0("scenario.name given but there is also a ",
                               "scenario column. whereever there is data in ",
                               "the scenario column, it will overwrite ",
                               "scenario.name"))
            }
            
            props.tab[,scenario.temp := input.table[,scenario]]
            props.tab[!(is.na(scenario.temp) | scenario.temp %in% c("", " ")), 
                      scenario := paste0("{Object}", scenario.temp)]
            props.tab[,scenario.temp := NULL]
            
        }

        if (any(!is.na(props.tab$scenario))) {
            
            if ("scenario" %in% names(input.table) &
                "scenario.cat" %in% names(input.table)) {
                scens.to.add <- unique(input.table[,.(scenario, category = scenario.cat)])
            } else {
                scens.to.add <- data.table(scenario = character(), 
                                           category = character())
            }
            
            # add on any scenarios not in input.table
            all.scens <- unique(props.tab[!is.na(scenario),
                                          gsub("\\{Object\\}", "", scenario)])
            all.scens <- all.scens[!(all.scens %in% scens.to.add$scenario)]
            
            if (length(all.scens) > 0) {
                scens.to.add <- rbind(scens.to.add, 
                                      data.table(scenario = all.scens, 
                                                 category = NA))
                scens.to.add <- unique(scens.to.add)
            }
            
            # add category to non-categorized scenarios if was passed in
            if (!is.na(scenario.cat)) {
                scens.to.add[is.na(category), category := scenario.cat]
            }
            
            # finally, add scenario objects
            add_scenarios(scens.to.add$scenario, 
                          category = scens.to.add$category)
        }

        if ("action" %in% names(input.table)) {
          props.tab[,action := input.table$action]}
        
        if ("escalator" %in% names(input.table)) {
            props.tab[,escalator := input.table$escalator]}
        
        if ("condition" %in% names(input.table)) {
            props.tab[,condition := input.table$condition]}
        
        if ("variable" %in% names(input.table)) {
            
            props.tab[,variable.temp := input.table[,variable]]
            props.tab[!(is.na(variable.temp) | variable.temp %in% c("", " ")), 
                      variable := paste0("{Object}", variable.temp)]
            props.tab[,variable.temp := NULL]
        }
        
        # add memo column if specified
        if (!is.na(memo.col)) {
            props.tab[, memo := input.table[,get(memo.col)]]
        }
        
        # merge with Properties.sheet
        if (overwrite == FALSE) {
             
            Properties.sheet <<- merge_sheet_w_table(Properties.sheet, props.tab)
            
        } else {
            
            # if given, check to make sure all overwrite.cols are in Properties.sheet
            if (!is.na(overwrite.cols[1])) {
                if (!all(overwrite.cols %in% colnames(Properties.sheet))) {
                    message(sprintf(paste0(">>  Not all overwrite columns %s are",
                                           " in Properties.sheet; ",
                                           "cannot merge ... skipping")), 
                            paste0(overwrite.cols, collapse = ", "))
                    
                    return()
                }
            }
            
            # merge everything but the value column, allow new data to overwrite old 
            # value col (or any specified excluded columns)
            
            sheet.cols <- colnames(Properties.sheet) 
            props.tab.cols <- colnames(props.tab)
            
            # convert all columns to character so that they will be same data type 
            # as .sheet table
            props.tab <- props.tab[, lapply(.SD, as.character)] 
            
            Properties.sheet <- merge(Properties.sheet, 
                                      props.tab, 
                                      by = props.tab.cols[!(props.tab.cols %in% na.omit(c('value', overwrite.cols)))], 
                                      all = TRUE)
            
            # this should give two value columns. where data exists in value.y, use it
            # then delete duplicate columns
            Properties.sheet[!is.na(value.y), value.x := value.y]
            Properties.sheet[,value := value.x][,c('value.x', 'value.y') := NULL]
            
            # do the same for other excluded columns
            if (!is.na(overwrite.cols)) {
                
                for (cname in overwrite.cols) {
                    
                    Properties.sheet[!is.na(get(paste0(cname, ".y"))),
                                     paste0(cname, ".x") := get(paste0(cname, ".y"))]
                    Properties.sheet[,(cname) := get(paste0(cname, ".x"))]
                    Properties.sheet[,paste0(cname, c(".x", ".y")) := NULL]
                    
                }
            }
            
            # set Properties sheet back to normal
            setcolorder(Properties.sheet, sheet.cols)
            
            # reassign Properties.sheet
            Properties.sheet <<- Properties.sheet
            
        }
    }
}

##import_memberships
#
# input.table: dt of memberships to be created. currently can only be in a 
#              format of one parent object type in one col (colname of parent 
#              objects must be their class, i.e. "Generator") and all other 
#              cols the children. child object colnames must be of format 
#              collection_childclass (i.e. "Head Storage_Storage"). A "notes" 
#              column will be ignored, but no other cols should be included.
# object.col: character name of column containing parent objects. if not given, 
#             first column will be used.

import_memberships <- function(input.table, 
                               object.col = NA) {
    
    # get object col if not given
    if (is.na(object.col)) object.col <- names(input.table)[1] 
    
    # make sure notes is capitalized correctly if it exists, then delete it
    check_colname_cap(input.table)
    
    if ("notes" %in% names(input.table)) input.table[, notes := NULL]
    
    # loop through other columns, add them as memberships to objs in first col
    # should probably just melt this instead of looping
    all.membs <- initialize_table(model.table = Memberships.sheet, 
                                  nrows = 0)
    
    child.cols <- names(input.table[,!object.col, with = FALSE])
    
    for (cname in child.cols) {
            
        # child object class and collection?
        cur.coll <- tstrsplit(cname, "_")[[1]]
        cur.chclass <- tstrsplit(cname, "_")[[2]]
        
        # get data, clear out NAs - is this slow? probably not, but can maybe 
        # just subset in initialize_table
        cur.data <- input.table[!duplicated(input.table, by = c(object.col, cname)) & 
                                    !is.na(get(cname)) & 
                                    !(get(cname) %in% c("", " ")),
                                .(parent.objs = get(object.col), 
                                  child.objs = get(cname))]
        
        # temp table for this iteration's data
        cur.membs <- initialize_table(Memberships.sheet, 
                                      nrows = nrow(cur.data))
        
        cur.membs[, parent_class := object.col]
        cur.membs[, child_class := cur.chclass]
        cur.membs[, collection := cur.coll]
        cur.membs[, parent_object := cur.data$parent.objs]
        cur.membs[, child_object := cur.data$child.objs]
        
        # add to full table
        all.membs <- rbindlist(list(all.membs, cur.membs))
    }
    
    # add this to Memberships.sheet
    Memberships.sheet <<- merge_sheet_w_table(Memberships.sheet, all.membs)
    
}

##import_objects
#
# input.table: dt of objects to be created. colname of objects should be their 
#              PLEXOS class (i.e. "Generator"). a "category" column is optional
#              (if not given, object will not be categorized). Any other columns
#              will be ignored
# object.col: character with name of column containing objects to be created. 
#             if not given, first col of input.table will be used.
             
import_objects <- function(input.table, 
                           object.col = NA) {
    
    # get object col if not given
    if (is.na(object.col)) object.col <- names(input.table)[1] 
    
    # make sure category is capitalized correctly if it exists
    check_colname_cap(input.table)
    
    # add category col if not given
    if (!("category" %in% names(input.table))) input.table[,category := NA]
    
    # add to Objects.sheet (in global environment)
    to.objects <- initialize_table(Objects.sheet, 
                                   nrow(input.table),
                                   list(class = object.col,
                                        name = input.table[[object.col]],
                                        category = input.table$category))
    
    
    Objects.sheet <<- merge_sheet_w_table(Objects.sheet, to.objects)
}


##import_constraint
#shortcut for importing a table of constraints (all of the same type) and 
# adding objects, categories, attributes, memberships, and properties to sheets.
# constraint.table must have the format:
#   obj.col= column defining objects for which to define constraints
#   constraint.col = column declaring constraint names
#   category.col = column declaring constraint categories
#   prop.col = column declaring the property to which the constraint applies
#   sense.col = sense value defining the inequality (-1='<=')
# data files should be saved as : DataFiles\Constraint_Category\Constraint_name.csv
#  with one file for every defined constraint
import_constraint = function(constraint.table,obj.col = 'generator.name',
                             constraint.type = 'RHS Month',collection='Generators',
                             child_class='Generator',constraint.col = 'constraint',
                             category.col = 'category',prop.col = 'property',
                             sense.col = 'sense', scenario.col='scenario') {
    
    if (constraint.type == 'RHS') period_type_id = 0
    if (constraint.type == 'RHS Hour') period_type_id = 6
    if (constraint.type == 'RHS Day') period_type_id = 1
    if (constraint.type == 'RHS Week') period_type_id = 2
    if (constraint.type == 'RHS Month') period_type_id = 3
    if (constraint.type == 'RHS Year') period_type_id = 4
    
    if (constraint.type %in% c()) error(paste0("please set constraint.type to ", 
                                               "RHS, RHS Hour, RHS Day, ",
                                               "RHS Month, RHS Week, or RHS ",
                                               "Year. import_constraint doesn't",
                                               "currently know how to handle ", 
                                               "RHS Custom"))
    
    new.object.table = data.table(expand.grid(name = unique(constraint.table[,get(constraint.col)]),
                                              class = c('Constraint','Data File')),
                                  description = NA,
                                  key = 'name')
    
    setkeyv(constraint.table,constraint.col)
    new.object.table[constraint.table,category := get(category.col)]
    
    scenario.list = NA
    if (scenario.col %in% names(constraint.table)) {
        
        scenario.list = unique(constraint.table[,.SD,.SDcols = c(scenario.col, category.col)])
        
        new.object.table = rbind(new.object.table,
                                 data.table(expand.grid(name = scenario.list[,get(scenario.col)],
                                                        category = scenario.list[,get(category.col)],
                                                        class = c('Scenario')),
                                            description = NA))
    } else {
        
        constraint.table[,eval(scenario.col) := NA]
    }
    
    new.category.table = constraint.table[!duplicated(constraint.table[,.(get(category.col))]),
                                          .(class = c('Constraint','Data File'),
                                            category = get(category.col))]
    
    new.attribute.table = constraint.table[!duplicated(constraint.table[,.(get(constraint.col))]),
                                           .(name = get(constraint.col),
                                             class = 'Data File', 
                                             attribute = 'Enabled', 
                                             value = -1)]
    
    new.membership.table = constraint.table[!duplicated(constraint.table[,.(get(obj.col))]),
                                            .(parent_class = 'Constraint',
                                              child_class,
                                              collection,
                                              parent_object = get(constraint.col),
                                              child_object = get(obj.col))]
    
    constraint.table[!is.na(get(scenario.col)),
                     eval(scenario.col) := paste0('{Object}', get(scenario.col))]
    
    new.properties.table = constraint.table[!duplicated(constraint.table[,.(get(obj.col),get(constraint.col))]), 
                                            .(parent_class = 'Constraint',
                                              child_class, 
                                              collection,
                                              parent_object = get(constraint.col),
                                              child_object = get(obj.col),
                                              property = get(prop.col),
                                              band_id = 1,
                                              value = 1,
                                              filename = NA,
                                              period_type_id = NA,
                                              scenario = get(scenario.col))]
    
    sense.props = constraint.table[!duplicated(constraint.table[,.(get(constraint.col))]),
                                   .(parent_class = 'System',
                                     child_class = 'Constraint',
                                     collection = 'Constraints',
                                     parent_object = 'System',
                                     child_object = get(constraint.col),
                                     property = 'Sense',
                                     band_id = 1,
                                     value = get(sense.col),
                                     filename = NA,
                                     period_type_id = NA,
                                     scenario = get(scenario.col))]
    
    constraint.props = constraint.table[!duplicated(constraint.table[,.(get(constraint.col))]),
                                        .(parent_class = 'System',
                                          child_class = 'Constraint',
                                          collection = 'Constraints',
                                          parent_object = 'System',
                                          child_object = get(constraint.col),
                                          property = constraint.type,
                                          band_id = 1,
                                          value = 0,
                                          filename = paste0('{Object}', get(constraint.col)),
                                          period_type_id,
                                          scenario = get(scenario.col))]
    
    datafile.props = constraint.table[!duplicated(constraint.table[,.(get(constraint.col))]),
                                      .(parent_class = 'System',
                                        child_class = 'Data File',
                                        collection = 'Data Files',
                                        parent_object = 'System',
                                        child_object = get(constraint.col),
                                        property = 'Filename',
                                        band_id = 1,
                                        value = 0,
                                        filename = paste('DataFiles', 
                                                         gsub(' ', '_', get(category.col)),
                                                         paste0(gsub(' ', '_', get(constraint.col)), '.csv'),
                                                         sep = '\\'),
                                        period_type_id = NA,
                                        scenario = get(scenario.col))]
    
    new.properties.table = rbind(new.properties.table,
                                 sense.props,
                                 constraint.props,
                                 datafile.props)
    
    Objects.sheet <<- merge_sheet_w_table(Objects.sheet,new.object.table)
    Categories.sheet <<- merge_sheet_w_table(Categories.sheet,new.category.table)
    Attributes.sheet <<- merge_sheet_w_table(Attributes.sheet,new.attribute.table)
    Memberships.sheet <<- merge_sheet_w_table(Memberships.sheet,new.membership.table)
    Properties.sheet <<- merge_sheet_w_table(Properties.sheet,new.properties.table)
}


# create interleave pointers
make_interleave_pointers <- function(parent.model, child.model, 
                                     filepointer.scenario, datafileobj.scenario, 
                                     template.fuel = NA, 
                                     template.object = NA,
                                     add.scen.to.model = TRUE,
                                     interleave = TRUE) {
    
    # check to make sure both models exist (warn, skip if not)
    if (!(parent.model %in% Objects.sheet$name &
          child.model %in% Objects.sheet$name)) {
        
        message(sprintf(paste0(">>  attempted to add interleaved models %s and",
                               " %s, but at least one does not exist in the database"), 
                        parent.model, child.model))
        return()
    }
    
    # make sure don't mess with global copy (this is a small table; copying is ok)
    template.fuel <- copy(template.fuel)
    
    # create interleaved membership between models - maybe consider 
    # restructuring so that don't have to merge each time with 
    # Memberships.sheet?
    if (interleave) {
        int.to.memberships = initialize_table(Memberships.sheet, 
                                              1, 
                                              list(parent_class = "Model", 
                                                   child_class = "Model", 
                                                   collection = "Interleaved", 
                                                   parent_object = parent.model, 
                                                   child_object = child.model))
        
        Memberships.sheet <<- merge_sheet_w_table(Memberships.sheet, 
                                                  int.to.memberships)
    }
    
    # use template to create properties with pointers under scenario
    
    if (is.data.table(template.fuel)) {
        template.fuel.copy <- copy(template.fuel)
        
        # first, replace the placeholder "[DA MODEL]" in placeholders filepointers
        # with name of parent model (in a copy of the template)
        template.fuel.cols = colnames(template.fuel.copy)
        
        template.fuel.cols = template.fuel.cols[template.fuel.cols != "Fuel"]
        
        template.fuel.copy[, (template.fuel.cols) := 
                               lapply(.SD, function(x) gsub("\\[DA MODEL\\]", 
                                                            parent.model, 
                                                            x)), 
                           .SDcols = template.fuel.cols]
        
        # get the filepointer associated with each property and add it to the
        # datafile under current scenario
        pointers = template.fuel.copy[,lapply(.SD, function(x) na.omit(x)[1]), 
                                      .SDcols = -1] 
        
        # HEREHERE this is where names get set and used as datafile obj names
        # can modify names and properties here
        
        pointers = melt(pointers, measure.vars = colnames(pointers), 
                        variable.name = "Data File", value.name = "filename")
     
        import_properties(pointers, 
                          datafile.col = "filename",
                          scenario.name = filepointer.scenario, 
                          scenario.cat = "Interleaved filepointers")
        
        # what needs to be attached to the actual properties is the name of the
        # datafile object, not the file path. change values in the table from 
        # file paths to name of datafile objects, then add these to properties 
        # sheet, overwriting what already exists
        
        for (j in names(template.fuel.copy)[-1]) {
            set(template.fuel.copy, 
                which(!is.na(template.fuel.copy[[j]])), j, 
                paste0("{Object}", j))        
        }
        
        # set names back to just properies so can pass to import_properties
        nmes <- gsub("Pass ", "", copy(names(template.fuel.copy)))
        nmes <- tstrsplit(nmes, ": ")[[1]]
        names(nmes) <- copy(names(template.fuel.copy))
        
        # handle duplicated columns by combining them. does not allow dupliacate
        # filepointers for same property for same fuel type
        duped <- nmes[duplicated(nmes)]
        duped <- nmes[nmes %in% duped]
        
        if (length(duped) > 0) {
            
            # make sure works if multiple properties have duplicates
            for (prop in unique(duped)) {
                
                cur.duped <- duped[duped == prop]
                
                # iterate through cols, fill in first col with rest, where is.na
                first.duped <- cur.duped[1]
                rest.duped <- cur.duped[-1]
                
                for (colname in names(rest.duped)) {
                    
                    # replace values
                    template.fuel.copy[is.na(get(names(first.duped))),
                                  (names(first.duped)) := get(colname)]
                    
                    template.fuel.copy[,(colname) := NULL]
                    
                }
                
                # set first col name to property
                setnames(template.fuel.copy, names(first.duped), first.duped)
                
                nmes <- nmes[!(nmes %in% duped[duped == prop])]
            }
            
        }
        
        # setnames with old and new
        setnames(template.fuel.copy, names(nmes), nmes)
        
        
        
        # map by fuel, then add to properties sheet with given scenario
        # for now, fix colnames
        if ("Fuel" %in% names(template.fuel.copy)) {
            setnames(template.fuel.copy, "Fuel", "category")
        }
        
        cur.mapped.tab = merge_property_by_fuel(template.fuel.copy)
        
        prop.cols <- names(cur.mapped.tab)
        prop.cols <- prop.cols[prop.cols != "Generator"]
        
        import_properties(cur.mapped.tab, 
                          datafile.col = prop.cols,
                          overwrite = TRUE, 
                          overwrite.cols = "filename",
                          scenario.name = datafileobj.scenario, 
                          scenario.cat = "Interleaved filepointers")
    }

    if (is.data.table(template.object[[1]])) {
        # template.object is a list, so loop through
        # assume first column is objects and object class is name of column
        
        for (template.object.table in template.object) {
            # check to make sure this hasn't been changed to NA
            if (!is.data.table(template.object.table)) next 
            
            # proceed
            template.object.copy <- copy(template.object.table)
            
            template.object.cols = colnames(template.object.copy)
            
            object.class.col = template.object.cols[1]
            template.object.cols = template.object.cols[-1]
            
            template.object.copy[, (template.object.cols) := 
                                     lapply(.SD, function(x) gsub("\\[DA MODEL\\]", 
                                                                  parent.model, 
                                                                  x)),
                                 .SDcols = template.object.cols]
            
            # get the filepointer associated with each property and add it to the
            # datafile under current scenario
            pointers = template.object.copy[,lapply(.SD, function(x) na.omit(x)[1]), 
                                            .SDcols = -1] 
            
            setnames(pointers,
                     names(pointers),
                     paste("Pass", names(pointers)))
            
            pointers = melt(pointers, 
                            measure.vars = colnames(pointers), 
                            variable.name = "DataFileObj", 
                            value.name = "filename")
            
            import_properties(pointers, 
                              object.class = "Data File", 
                              names.col = "DataFileObj", 
                              collection.name = "Data Files", 
                              datafile.col = "filename",
                              scenario.name = filepointer.scenario, 
                              scenario.cat = "Interleaved filepointers")
            
            # what needs to be attached to the actual properties is the name of the
            # datafile object, not the file path. change values in the table from 
            # file paths to name of datafile objects, then add these to properties 
            # sheet, overwriting what already exists
            
            for (j in names(template.object.copy)[-1])
                set(template.object.copy, 
                    which(!is.na(template.object.copy[[j]])), j, 
                    paste("{Object}Pass", j)) 
            
            import_properties(template.object.copy, 
                              object.class = object.class.col,
                              names.col = object.class.col, 
                              collection.name = paste0(object.class.col, "s"), 
                              datafile.col = template.object.cols,
                              overwrite = TRUE, 
                              overwrite.cols = "filename",
                              scenario.name = datafileobj.scenario, 
                              scenario.cat = "Interleaved filepointers")
        } 
    }
    
    # optionally add scenario to model
    # note: there is currently no way to pass in FALSE to this variable, but
    # I'm putting this is so we can add that option later if needed
    if (add.scen.to.model) {
        RTscen.to.memberships = initialize_table(Memberships.sheet, 2, 
                                                 list(parent_class = "Model", 
                                                      child_class = "Scenario", 
                                                      collection = "Scenarios", 
                                                      parent_object = child.model, 
                                                      child_object = c(filepointer.scenario, 
                                                                       datafileobj.scenario)))
        
        Memberships.sheet <<- merge_sheet_w_table(Memberships.sheet, 
                                                  RTscen.to.memberships)
    }
    
}

