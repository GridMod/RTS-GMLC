#------------------------------------------------------------------------------|
# ADD OBJECTS ----
#------------------------------------------------------------------------------|

#------------------------------------------------------------------------------|
# objects.list ----
#------------------------------------------------------------------------------|

if (exists("objects.list")) {
  
    for (elem in seq_along(objects.list)) {
        
        data.path <- objects.list[[elem]][[1]]
        
        cur.data <- read_data(data.path, sep = ",")
        
        if (is.data.table(cur.data)) {
        
            message(sprintf("... Adding objects/properties from %s", data.path))
          
            # do some cleaning/checking
            check_colname_cap(cur.data, version = plexos.version)
            
            if ("notes" %in% names(cur.data)) cur.data[, notes := NULL]
            
            # if any memberships, add those (there may be dupes in objects or
            # properties here)
            memb.cols <- names(cur.data)
            memb.cols <- c(memb.cols[1], memb.cols[grepl("_", memb.cols)])
            
            if (length(memb.cols) > 1) {
                
                # check_for_dupes(cur.data, memb.cols)
                
                import_memberships(cur.data[,memb.cols, with = FALSE])
            }
            
            # make sure there are no duplicates in the non-membership columns
            if (length(memb.cols) > 1) cur.data[, (memb.cols[-1]) := NULL]
            
            cur.data <- unique(cur.data) # this could be an efficiency thing
            # check_for_dupes(cur.data, names(cur.data[1]))
            
            # add objects
            obj.cols <- c(names(cur.data)[1], 
                          if ("category" %in% names(cur.data)) "category")
            
            import_objects(unique(cur.data[,obj.cols, with = FALSE]))
            
            # add properties (and args)
            excluded.cols <- c("notes", "category")
            
            excluded.cols <- excluded.cols[excluded.cols %in% names(cur.data)]
            
            if (length(excluded.cols) > 0) {
                cur.data <- cur.data[,!excluded.cols, with = FALSE]
            }
            
            # read in args if given
            if (length(objects.list[[elem]]) > 1) {
                
                # get all args but the first (a little gynmastics to account 
                # for the args being in a separate list or not)
                cur.args <- objects.list[[elem]][-1]
                
                if (is.list(cur.args) & all(is.null(names(cur.args)))) {
                    cur.args <- cur.args[[1]]
                }
                
            } else {
                
                cur.args <- list()
            }
            
            # add another element and coerce to a list
            suppressWarnings(cur.args$input.table <- cur.data)
            
            # add to properties sheet using input arguments
            do.call(import_properties, cur.args)
            
            rm(excluded.cols, memb.cols, cur.args)
            
        } # end if (is.data.table(cur.data))

    }
    
    # clean up
    rm(data.path, cur.data, elem)

} else {
    
    message(">>  objects.list does not exist ... skipping")
}


#------------------------------------------------------------------------------|
# generic.import.files----
#------------------------------------------------------------------------------|

#uses generic.import.files

all.sheets <- c("Objects", "Categories", "Memberships", "Attributes", 
                "Properties", "Reports")

import_and_merge <- function(imported.tab, sheet.name) {
    
    cur.tab <- import_table_generic(imported.tab, sheet.name)
    
    if (!is.null(cur.tab)) {
        
        assign(paste0(sheet.name, ".sheet"), 
               merge_sheet_w_table(get(paste0(sheet.name,".sheet")), cur.tab), 
               envir = .GlobalEnv)
    } 
}

#import and merge all generic import files
if (exists('generic.import.files')) {
    
    invisible(lapply(generic.import.files, function (x) {
        
        # read in data, change blanks to NA, and import into .sheet tables
        imported.file <- read_data(x[[1]],
                                   fill = TRUE, 
                                   header = FALSE, 
                                   strip.white = TRUE, 
                                   fix.db.colnames = FALSE)
        
        if (is.data.table(imported.file)) {
            
            message(sprintf("... importing from %s", x[[1]]))
            
            # hacky: if a table type is given, assume that table needs 
            # formatting (put header as first col, add begin and end tags) 
            if (length(x) > 1) {
                
                type <- x[[2]]
                
                # add headers as first row (useful for reading from db)
                if (names(imported.file)[1] != "V1") {
                    imported.file <- rbind(as.list(names(imported.file)), 
                                           imported.file)
                    
                    # change names to V1:Vn
                    setnames(imported.file, 
                             names(imported.file), 
                             paste0("V", 1:length(imported.file)))
                }
                
                # add / BEGIN and / END tags
                imported.file <- rbindlist(list(list(V1 = "/ BEGIN", 
                                                     V2 = type), 
                                                imported.file, 
                                                list(V1 = "/ END", 
                                                     V2 = type)), 
                                           fill = TRUE)
                
            }
            
            for (j in seq_len(ncol(imported.file)))
                set(imported.file, which(imported.file[[j]] == ""), j, NA)
            
            lapply(all.sheets, function(y) import_and_merge(imported.file, y))
            
        } # end if (is.data.table(imported.file)) 
    }))
} else { message('>>  no generic import files defined ... skipping') }

rm(import_and_merge, all.sheets)

#------------------------------------------------------------------------------|
# compact.generic.import.files ----
#------------------------------------------------------------------------------|
# uses compact.generic.import.files
# loop through compact generic input files and read in tables

if (exists('compact.generic.import.files')) {
    
    for (i in seq_along(compact.generic.import.files)) {
        
        cur.data <- read_data(compact.generic.import.files[[i]][[1]])
        
        if (is.data.table(cur.data)) {
            message(sprintf("... importing from %s", 
                            compact.generic.import.files[[i]][1]))
            
            cur.obj.type <- compact.generic.import.files[[i]][2]
            
            # read in file, add appropriate sections to object, attib, memb .sheet tables
            import_table_compact(cur.data, cur.obj.type)
            
        } # end if (is.data.table(cur.data))
    }
    
    # clean up
    if (exists("cur.data")) rm(cur.data)
    if (exists("cur.obj.type")) rm(cur.obj.type)
    
} else { message('>>  no compact generic import files defined ... skipping')}


#------------------------------------------------------------------------------|
# convenience function: interface.file.list ----
#------------------------------------------------------------------------------|

# uses interfaces.files.list
if(exists('interfaces.files.list')) {
    
    for (i in seq(interfaces.files.list)) {
        
        
        if (file.exists(file.path(inputfiles.dir, interfaces.files.list[[i]][1]))) {
            
            message(
                sprintf("... Adding interfaces from %s", interfaces.files.list[[i]][1]))
            
            # read in files from interface files in this iteration
            interface.names <- read_data(interfaces.files.list[[i]]['names'])
            interface.properties <- read_data(interfaces.files.list[[i]]['properties'])
            interface.memberships <- read_data(interfaces.files.list[[i]]['memberships'])
            interface.coefficients <- read_data(interfaces.files.list[[i]]['flowcoefs'])
            
            # Add interfaces to objects sheet
            import_objects(interface.names[, .(Interface = Interface.Name, 
                                               category)])
            
            # Add interface properties - changed to data.file. need to genericize, 
            # change to data file object so can put in 2014 and 2022 data files, etc 
            # import_properties(interface.properties, object.class = "Interface", 
            #   collection.name = "Interfaces", names.col = "Interface.Name")
            
            # add min and max flow datafile pointers 
            import_properties(interface.properties, object.class = "Interface", 
                              names.col = "Interface.Name", 
                              collection.name = "Interfaces", 
                              datafile.col = c("Min Flow", "Max Flow"))
            
            
            # Add interface-line memberships
            interface.to.membs <- interface.memberships[,.(Interface = Interface.Name, 
                                                           Lines_Line = Line)] 
            
            import_memberships(interface.to.membs)
            
            # Add flow coeffcienct to properties
            interface.coefficients.to.props <- 
                interface.coefficients[, .(Line, 
                                           Interface = Interface.Name, 
                                           `Flow Coefficient`)]
            
            import_properties(interface.coefficients.to.props, 
                              parent.col = "Interface")
            
        } else {
            message(sprintf(">>  %s does not exist ... skipping", 
                            interfaces.files.list[[i]][1]))
        }
    }
} else {
    message('>>  no interface files defined ... skipping')
}

#------------------------------------------------------------------------------|
# convenience function: reserve.files ----
#------------------------------------------------------------------------------|

# read in files from reserve.files specified in input_params

if(exists('reserve.files')) {
    
    reserves <- read_data(reserve.files$reserves)
    
    if (is.data.table(reserves)) {
        
        # read reserves file
        message(sprintf("... Adding reserves from %s", reserve.files$reserves))
        
        # add reserves to objects sheet
        import_objects(reserves[, .(Reserve)])
        
        # fix scenario name so is always lowercase
        check_colname_cap(reserves, version = plexos.version)
        
        # add scenario on 'Is Enabled' property
        if ("scenario" %in% names(reserves)) {
            
            reserve.scenarios <- unique(reserves[,scenario])
            
            for(i in reserve.scenarios){
                
                reserve.enabled <- reserves[scenario == i,.(Reserve,`Is Enabled`)]
                
                import_properties(reserve.enabled, object.class = 'Reserve', 
                                  names.col = 'Reserve', 
                                  collection.name = 'Reserves',
                                  scenario.name = i)
            }
            
            # turn off reserve when scenario not selected
            reserve.scenario.off <- reserves[,.(Reserve,`Is Enabled` = 0)]
            
            import_properties(reserve.scenario.off, 
                              object.class = 'Reserve',
                              names.col = 'Reserve',
                              collection.name = 'Reserves')
            
            # add reserve scenarios to objects.sheet
            add_scenarios(reserve.scenarios, category = "Reserves")
            
            # clean up
            rm(reserve.scenarios, reserve.enabled, reserve.scenario.off)
            
        } else if ("Is Enabled" %in% names(reserves)) {
            
            # add `Is Enabled` property without a scenario
            import_properties(reserves[,.(Reserve, `Is Enabled`)])
            
        } else {
            
            # give `Is Enabled` anyway, set to 1
            message(sprintf("'Is Enabled' property not given in %s ... setting to 1",
                            reserve.files$reserves))
        }
        
        # add reserve properties to properties .sheet
        excluded.cols <- c("Is Enabled","scenario")
        excluded.cols <- excluded.cols[excluded.cols %in% names(reserves)]
        
        reserve.properties <- reserves[,!excluded.cols, with = F]
        
        import_properties(reserve.properties, object.class = 'Reserve', 
                          names.col = 'Reserve', 
                          collection.name = 'Reserves')
        
        # clean up
        rm(excluded.cols, reserve.properties, reserves)
        
    } # end if (is.data.table(reserves))
    
    # add reserve generators 
    if (length(reserve.files$reserve.generators) > 0){
        
        reserve.generators <- read_data(reserve.files$reserve.generators)
        
        if (is.data.table(reserve.generators)) {
            
            # read reserve generators file
            message(sprintf("... Adding reserves from %s", 
                            reserve.files$reserve.generators))
            
            
            # add reserve-generator memberships to memberships.sheet
            reserve.to.gens.to.membs <- reserve.generators[,.(Reserve, 
                                                              Generators_Generator = Generator)]
            
            import_memberships(reserve.to.gens.to.membs)
            
            # add reserve-generator properties to properties.sheet
            cnames <- colnames(reserve.generators)
            
            if (length(cnames[!(cnames %in% c("Reserve", "Generator", "notes"))]) > 0) {
                
                if ("notes" %in% cnames) {
                    reserve.generators[,notes := NULL]
                }
                
                import_properties(reserve.generators, 
                                  names.col = "Generator",
                                  parent.col = "Reserve")
            }
            
            # clean up
            rm(reserve.generators, reserve.to.gens.to.membs, cnames)
        }
        
    }
    
    # add reserve regions
    if (length(reserve.files$reserve.regions) > 0){
        
        reserve.regions <- read_data(reserve.files$reserve.regions)
        
        if (is.data.table(reserve.regions)) {
            
            # read reserve regions file
            message(sprintf("... Adding reserves from %s", 
                            reserve.files$reserve.regions))
            
            
            # add reserve-region memberships to memberships.sheet
            reserve.to.regs.to.membs <- reserve.regions[,.(Reserve, 
                                                           Regions_Region = Region)]
            
            import_memberships(reserve.to.regs.to.membs)
            
            # add reserve.region properties to properties .sheet
            import_properties(reserve.regions, object.class = 'Region',
                              parent.col = 'Reserve',
                              names.col = 'Region', 
                              collection.name = 'Regions')
            
            # clean up
            rm(reserve.regions, reserve.to.regs.to.membs)
            
        } 
        
        # clean up
        rm(reserve.files)
    }
    
} else {
    
    message('>>  no reserves files defined ... skipping')
}


#------------------------------------------------------------------------------|
# convenience function: user-defined constraints ----
# -----------------------------------------------------------------------------|

if (exists('constraint.import.files')) {
    
    for (i in seq_along(constraint.import.files)) {
        
        cur.data <- read_data(constraint.import.files[[i]][[1]])
        
        if (is.data.table(cur.data)) {
            
            message(sprintf("... importing constraint from  %s", 
                            constraint.import.files[[i]][1]))
            
            import_constraint(cur.data)
            
        } else {
            
            message(sprintf(">>  %s does not exist ... skipping", 
                            constraint.import.files[[i]][1]))
            
        }
        
    }
    
} else { message('>>  no constraint import files defined ... skipping')}


#------------------------------------------------------------------------------|
# convenience function: placeholder for psse parsing ----
# -----------------------------------------------------------------------------|

# convenience functions from before that would be useful for PSS/E parsing
#     - gen by fuel, create fuels, recategorize gens 
#     - 0 MW lines by some standard limit
#     - remap region and zone, recreate objects, recategorize
# checker:
#     - negative min stable level
#     - neg reactance interregion line
#     - interregion transformer
# these may belong as optional pss/e parsing arguments

#------------------------------------------------------------------------------|
# Create generator.data.table ----
#------------------------------------------------------------------------------|
# this is used to map generators by category later on

generator.data.table <- unique(Objects.sheet[class == "Generator",
                                             .(Generator = name, category)])

generator.data.table <- merge(generator.data.table, 
                              Memberships.sheet[parent_class == "Generator" &
                                                    child_class == "Fuel" &
                                                    collection == "Fuels",
                                                .(Generator = parent_object,
                                                  Fuel = child_object)],
                              all.x = TRUE)

generator.data.table <- merge(generator.data.table,
                              Properties.sheet[property == "Units" & 
                                                   child_class == "Generator" & 
                                                   is.na(scenario),
                                               .(Generator = child_object,
                                                 Units = as.numeric(value))],
                              all.x = TRUE)

generator.data.table <- merge(generator.data.table,
                              Properties.sheet[property == "Max Capacity" & 
                                                   child_class == "Generator" & 
                                                   is.na(scenario),
                                               .(Generator = child_object,
                                                 `Max Capacity` = as.numeric(value))],
                              all.x = TRUE)
    
#------------------------------------------------------------------------------|
# ADD PROPERTIES AND MEMBERSHIPS ----
#------------------------------------------------------------------------------|

#------------------------------------------------------------------------------|
# memberships.list ----
#------------------------------------------------------------------------------|

if (exists("memberships.list")) {
    
    for (elem in memberships.list) {
      
        fname <- elem[[1]] 
        cur.dt <- read_data(fname)
        
        if (is.data.table(cur.dt)) {
            
            message(sprintf("... Adding memberships from %s", fname))
            
            # do some cleaning/checking
            check_for_dupes(cur.dt, names(cur.dt))
            check_colname_cap(cur.dt, version = plexos.version)
            
            # import memberships
            memb.cols <- names(cur.dt)
            memb.cols <- c(memb.cols[1], memb.cols[grepl("_", memb.cols)])
            
            if (length(memb.cols) > 1) {
                import_memberships(cur.dt[,memb.cols, with = FALSE])
            }
            
            # if there are property cols, import those, too
            non.prop.cols <- c(memb.cols, "notes")
            prop.cols <- names(cur.dt)[!(names(cur.dt) %in% non.prop.cols)] 
            
            if (length(prop.cols) > 0) {
                
                # read in other args if given
                if (length(elem) > 1) {
                    # get all args but the first (a little gynmastics to account 
                    # for the args being in a separate list or not)
                    cur.args <- elem[-1]
                    
                    if (is.list(cur.args) & all(is.null(names(cur.args)))) {
                        cur.args <- cur.args[[1]]
                    }
                } else {
                    cur.args <- list()
                }
                
                # set up and import properties. untested with multiple children
                suppressWarnings(cur.args$input.table <- cur.dt)
                cur.args$parent.col <- memb.cols[1]
                cur.args$names.col <- memb.cols[-1]
                cur.args$object.class <- tstrsplit(memb.cols[-1], "_")[[2]]
                cur.args$collection.name <- tstrsplit(memb.cols[-1], "_")[[1]]

                do.call(import_properties, cur.args)
                
            }
            
        }
    }
    
    # clean up
    rm(cur.dt, fname)
    
} else {
    
    message(">>  memberships.list does not exist ... skipping")
}

#------------------------------------------------------------------------------|
# convenience function: generator properties by category ----
#------------------------------------------------------------------------------|

if (exists("generator.property.by.fuel.list") & 
    !exists("generator.property.by.cat.list")) {
    
    message(">>  generator.property.by.fuel.list is defined, but it is ",
            "deprecated. changed to generator.property.by.cat.list. ", 
            "please redefine this variable next time.")
    
    generator.property.by.cat.list <- generator.property.by.fuel.list
    
} else if (exists("generator.property.by.fuel.list") & 
           exists("generator.property.by.cat.list"))  {
    
    message(paste0(">>  generator.property.by.fuel.list and ",
                   "generator.property.by.cat.list are both defined. ",
                   "generator.property.by.fuel.list is deprecated and will ",
                   "be ignored."))
}

# uses generator.property.by.cat.list
if (exists("generator.property.by.cat.list")) {
    
    for (elem in seq_along(generator.property.by.cat.list)) {

        cur.data <- read_data(generator.property.by.cat.list[[elem]][[1]])
        
        check_colname_cap(cur.data, version = plexos.version)
        
        if (is.data.table(cur.data)) {
            
            message(sprintf("... Adding properties from %s", 
                            generator.property.by.cat.list[[elem]][1]))
            
            # shifting from doing this by fuel to by category
            if ("Fuel" %in% names(cur.data)) {
                setnames(cur.data, "Fuel", "category")
                message(sprintf(paste0("in merge_property_by_fuel, please change",
                                      " 'fuel' to 'category' in %s. ",
                                      "I'll do this for you for now."),
                                generator.property.by.cat.list[[elem]][1]))
            }
            
            # set up arguments for merge_property_by_fuel
            if ("fuel.map.args" %in% names(generator.property.by.cat.list[[elem]])) {
                cur.map.fuel.args <- as.list(generator.property.by.cat.list[[elem]][["fuel.map.args"]])
            } else {
                cur.map.fuel.args <- list()
            }
            
            if ("prop.cols" %in% names(cur.map.fuel.args)) {
                message(sprintf(paste0("use of prop.cols is deprecated in ",
                                       "merge_property_by_fuel. I'll ",
                                       "auto-populate prop.cols. for the future,",
                                       " please remove prop.cols from input ",
                                       "params when you pass in %s"),
                                generator.property.by.cat.list[[elem]][1]))
                
                cur.map.fuel.args <- cur.map.fuel.args[names(cur.map.fuel.args) != "prop.cols"]
            }
            
            if ("notes" %in% names(cur.data)) cur.data[,notes := NULL]
            
            cur.map.fuel.args$input.table <- cur.data
            
            # merge properties fuel, produces table with list of generators in rows
            # and their properties in all other columns
            mapped.by.fuel <- do.call(merge_property_by_fuel, cur.map.fuel.args)
            
            # set up args for import_properties, using output of merge by fuel  
            if ("add.to.prop.args" %in% names(generator.property.by.cat.list[[elem]])) {
                cur.prop.sheet.args <- as.list(generator.property.by.cat.list[[elem]][["add.to.prop.args"]])
            } else {
                cur.prop.sheet.args <- list()
            }
            
            cur.prop.sheet.args$input.table <- mapped.by.fuel
            
            # add to properties sheet using input arguments and new table
            do.call(import_properties, cur.prop.sheet.args)
            
            if ('scenario.name' %in% names(cur.prop.sheet.args)) {
                # for now, just add any scenario here that doesn't already exist
                # need to deal with categories later
                
                add_scenarios(cur.prop.sheet.args[['scenario.name']], 
                              category = ifelse('scenario.cat' %in% names(cur.prop.sheet.args), 
                                                cur.prop.sheet.args[['scenario.cat']], 
                                                NA))
                
            }
            
            rm(cur.map.fuel.args, cur.prop.sheet.args, mapped.by.fuel)
            
        } # end if (is.data.table(cur.data))
    }
    
    # clean up
    rm(cur.data, elem)
}

#----------------------------------------------------------------------------|
# add object properties from object.property.list ----
#----------------------------------------------------------------------------|
# uses generator.property.file.list

if (exists("object.property.list")) {
    
    for (elem in seq_along(object.property.list)) {
        
        cur.data <- read_data(object.property.list[[elem]][[1]])
        
        if (is.data.table(cur.data)) {
            
            message(sprintf("... Adding properties from %s", 
                            object.property.list[[elem]][1]))
            
            # read in args if given
            if (length(object.property.list[[elem]]) > 1) {
                
                # get all args but the first (a little gynmastics to account 
                # for the args being in a separate list or not)
                cur.args <- object.property.list[[elem]][-1]
                
                if (is.list(cur.args) & all(is.null(names(cur.args)))) {
                    cur.args <- cur.args[[1]]
                }
                
            } else {
                
                cur.args <- list()
            }
            
            # add another element and coerce to a list
            suppressWarnings(cur.args$input.table <- cur.data)
            
            # clean, add to properties sheet using input arguments and new table
            check_colname_cap(cur.data, version = plexos.version)
            
            do.call(import_properties, cur.args)
            
            # add any scenario here that doesn't already exist
            # need to deal with categories later
            if ('scenario.name' %in% names(cur.args)) { 
                
                add_scenarios(cur.args[['scenario.name']], 
                              category = ifelse('scenario.cat' %in% names(cur.args), 
                                                cur.args[['scenario.cat']], 
                                                NA))
                
            }
            
            # clean up
            rm(cur.data)
            
        } # end if (is.data.table(cur.data))
    }
    
} else {
    message(">>  object.property.list does not exist ... skipping")
}

#------------------------------------------------------------------------------|
# convenience function: turn off objects except in scenario ----
#------------------------------------------------------------------------------|
# uses turn.off.except.in.scen.list
if (exists('turn.off.except.in.scen.list')) {
    
    for (elem in seq_along(turn.off.except.in.scen.list)) {
        
        cur.data <- read_data(turn.off.except.in.scen.list[[elem]][[1]])
        
        if (is.data.table(cur.data)) {
            
            message(sprintf(paste0("... Adding turning off objects from %s except",
                                   " for in scenario '%s'"), 
                            turn.off.except.in.scen.list[[elem]][1],
                            turn.off.except.in.scen.list[[elem]][['scenario.name']]))
            
            # turn off Units property of these objects
            cur.names <- turn.off.except.in.scen.list[[elem]][['names.col']]
            cur.class <- turn.off.except.in.scen.list[[elem]][['object.class']]
            cur.coll <- turn.off.except.in.scen.list[[elem]][['collection.name']]
            cur.scen <- turn.off.except.in.scen.list[[elem]][['scenario.name']]
            
            # turn off Units in bae
            cur.data[,Units := 0]
            
            import_properties(cur.data, 
                              names.col = cur.names, 
                              object.class = cur.class,
                              collection.name = cur.coll, 
                              overwrite = T)
            
            # turn on units in scenario. if a generator, pull units from 
            # generator.data.table
            # right now, code only supports maintaining multiple units for generators
            if (cur.class == 'Generator') {
                
                genunits <- generator.data.table[, .(Generator, Units)]
                cur.data <- merge(cur.data[,Units := NULL], genunits, 
                                  by.x = cur.names, by.y = 'Generator')
                
            } else cur.data[,Units := 1]
            
            import_properties(cur.data, 
                              names.col = cur.names, 
                              object.class = cur.class, 
                              collection.name = cur.coll, 
                              scenario.name = cur.scen)
            
            # add scenario as an object
            add_scenarios(cur.scen, category = "Generator status")
            
            # clean up
            rm(elem, cur.names, cur.class, cur.coll, cur.scen)
            
        } else {
            message(sprintf(">>  %s does not exist ... skipping", 
                            turn.off.except.in.scen.list[[elem]][1]))
        }
    }
} else {
    message('>>  turn.off.except.in.scen.list does not exist ... skipping')
}


#------------------------------------------------------------------------------|
# convenience function: remove isolated nodes ----
# -----------------------------------------------------------------------------|
if (exists('isolated.nodes.to.remove.args.list')) {
    for (i in seq_along(isolated.nodes.to.remove.args.list)) {
        # pull element from the list
        isolated.nodes.to.remove.args = isolated.nodes.to.remove.args.list[[i]]
        
        # get file, scenario, and category names
        isolated.nodes.to.remove.file = isolated.nodes.to.remove.args[1]
        cur.scenario = isolated.nodes.to.remove.args["scenario"]
        cur.category = isolated.nodes.to.remove.args["scenario.cat"]
        
        isolated.nodes.to.remove <- read_data(isolated.nodes.to.remove.file)
        
        if (is.data.table(isolated.nodes.to.remove)) {
            
            if (is.null(cur.scenario))
                cur.scenario = NA
            
            if (is.null(cur.category))
                cur.category = NA
            
            message(sprintf("... removing isolated nodes from  %s in scenario %s in category %s", 
                            isolated.nodes.to.remove.file,
                            cur.scenario,
                            cur.category))
            
            if (!is.na(cur.scenario)) {
                # scenario to objects
                scenario.remove.isolated <- 
                    initialize_table(Objects.sheet, 1, 
                                     list(class = "Scenario", 
                                          name = cur.scenario, 
                                          category = cur.category))
                
                Objects.sheet <- merge_sheet_w_table(Objects.sheet, 
                                                     scenario.remove.isolated)
            }
            
            # scenario to properties
            # uses isolated.nodes.to.remove.file
            # read in isolated nodes to remove file and change it to a veector
            isolated.nodes.to.remove[,Units:="0"]
            
            # turn off generators on isolated nodes
            isolated.generators.to.remove <- merge(isolated.nodes.to.remove, 
                                                   Memberships.sheet[parent_class == "Generator" &
                                                                       child_class == "Node" &
                                                                       collection == "Nodes",
                                                                     .(Generator = parent_object,
                                                                       Node.Name = child_object)],
                                                   by = 'Node.Name')[,.(Generator,Units)]
            
            if(!is.na(cur.scenario)){
                import_properties(isolated.nodes.to.remove, names.col = "Node.Name", 
                                  object.class = "Node", collection.name =  "Nodes",
                                  scenario.name = cur.scenario)
                
                import_properties(isolated.generators.to.remove, names.col = "Generator",
                                  object.class = "Generator", collection.name =  "Generators",
                                  scenario.name = cur.scenario)
                
            } else {
                import_properties(isolated.nodes.to.remove, names.col = "Node.Name", 
                                  object.class = "Node", collection.name =  "Nodes",
                                  overwrite = TRUE)
                
                import_properties(isolated.generators.to.remove, names.col = "Generator",
                                  object.class = "Generator", collection.name =  "Generators",
                                  overwrite = TRUE)
                
            }
            
            # recalculate relevant LPFs for other nodes 
            # pull node LPFs in base case (no scenario) from properties sheet for all 
            # nodes except the ones to be removed
            redo.lpfs.to.properties <- 
                Properties.sheet[property == "Load Participation Factor" & 
                                     !(child_object %in% isolated.nodes.to.remove$Node.Name) &
                                     is.na(scenario), 
                                 .(Node = child_object, pattern, value)]
            
            # add region for calculating LPF
            redo.lpfs.to.properties <-
                merge(redo.lpfs.to.properties, Memberships.sheet[parent_class == "Node" & collection == "Region",
                                                                 .(Node = parent_object, Region = child_object)], 
                      by = "Node")
            
            # recalculate LPF
            redo.lpfs.to.properties[,`Load Participation Factor`:=max(as.numeric(value)),by='Region']
            redo.lpfs.to.properties[`Load Participation Factor` > 0,
                                    `Load Participation Factor` := prop.table(as.numeric(value)), 
                                    by = c("Region","pattern")]
            redo.lpfs.to.properties <- redo.lpfs.to.properties[value != `Load Participation Factor`]
            
            # for nodes with LPFs that have changed, assign the new LPFs to the nodes
            # and attach the scenario
            redo.lpfs.to.properties[, c("value", "Region") := NULL]
            
            if(!is.na(cur.scenario)){
                import_properties(redo.lpfs.to.properties, names.col = "Node", 
                                  object.class = "Node", collection.name =  "Nodes",
                                  pattern.col = "pattern", scenario.name = cur.scenario)
            } else {
                import_properties(redo.lpfs.to.properties, names.col = "Node", 
                                  object.class = "Node", collection.name =  "Nodes",
                                  pattern.col = "pattern",overwrite = TRUE)
            }
            
            rm(redo.lpfs.to.properties, isolated.nodes.to.remove.args, 
               scenario.remove.isolated, isolated.generators.to.remove)
            
        } # end if (is.data.table(isolated.nodes.to.remove))
        
        # clean up
        rm(cur.category, cur.scenario, isolated.nodes.to.remove)
        
    }
} else {
    message(">>  isolated.nodes.to.remove.file does not exist ... skipping")
}

#------------------------------------------------------------------------------|
# convenience function: import model interleave ----
#------------------------------------------------------------------------------|

if (exists("interleave.models.list")) {
    # go through all files in this list
    for (item in interleave.models.list) {
        cur.fname = item[[1]]
        cur.template.fuel.name = item[["template.fuel"]]
        cur.template.object.name = item[["template.object"]]
        cur.interleave = item[["interleave"]]
        
        # correct interleave
        if (is.null(cur.interleave)) cur.interleave <- FALSE
        
        # make sure interleave file and template file both exist 
        if (all(
            file.exists(file.path(inputfiles.dir, cur.fname)) & 
            file.exists(file.path(inputfiles.dir, cur.template.fuel.name)) &
            ifelse(!is.null(cur.template.object.name[1]), 
                   file.exists(file.path(inputfiles.dir, cur.template.object.name)),
                   TRUE) # only check for cur.template.obj if it exists
        )) {
            
            if (is.null(cur.template.object.name[1])) {
                message(sprintf("... interleaving models in %s, using template in %s",
                                cur.fname, cur.template.fuel.name))
            } else {
                message(sprintf("... interleaving models in %s, using templates in %s and %s",
                                cur.fname, cur.template.fuel.name, 
                                paste0(cur.template.object.name, collapse = ", ")))
            }
            
            
            # do actual work  
            # parse this file
            cur.tab = read_data(cur.fname)
            cur.template.fuel = read_data(cur.template.fuel.name)
            
            # if cur.template.object exists, grab it, handling as a list since
            # could be any number of templates
            if (!is.null(cur.template.object.name[1])) (
                cur.template.object = lapply(cur.template.object.name, 
                                             function(x) read_data(x))
            )
            
            # need to make a datafile object for each property to be passed down
            # it will have filepointers to the datafile to be passed, in 
            # scenarios.
            # this datafile object will be attached with no scenario to that 
            # property of all applicable objects
            # NOTE tihs means that this formulation does not currently support
            #   one scenario where a property is passed to all generators and
            #   another scenario where the same property is passed to only half
            #   the generators (since the datafile object will be attached to
            #   all of the generators)
            
            # ---- first, process templates
            
            # if something exists in the "property" row, then process it. 
            # 1 - change names of datafile objects to include property
            # 2 - create name to property vector to map back to properties later
            #     (inside function)
            # 3 - if the object exists but its property doesn't, then add that 
            #     property back to the object
            
            if ("Attribute" %in% cur.template.fuel$Fuel) {
                
                # if this exists, add the propname to the colname to be able
                # to uniquely identify datafile objects with different 
                # properties, and keep track of what properties need to be added
                # later. The colon will be an indicator later about whether
                # names should be split
                
                # column names to set names
                props <- unlist(cur.template.fuel[Fuel == "Attribute"])
                props["Fuel"] <- ""
                props[props != ""] <- paste0(": ", props[props != ""])
                
                setnames(cur.template.fuel, 
                         paste0("Pass ", names(props), props))
                setnames(cur.template.fuel, "Pass Fuel", "Fuel") # hacky but... 
                
                # grab table of properties to set
                dfo.props <- cur.template.fuel[Fuel == "Attribute"]
                dfo.props <- melt(dfo.props, 
                                  measure.vars = colnames(dfo.props),
                                  variable.name = "name",
                                  value.name = "attribute")
                
                # get rid of NAs, blanks, the fuel column 
                dfo.props <- dfo.props[!is.na(attribute) & 
                                           !(attribute %in% c("", "Attribute"))]
                
                # separate names and properties and format to be added to 
                # attributes sheet
                dfo.props[,c("attribute", "value") := tstrsplit(attribute, 
                                                                "=| = | =|= ")]
                
                dfo.props[,class := "Data File"]
                
                # dfo props will be used later, after making sure all df objects
                # exist, to add attributes
                
                # remove attribute row from cur.template.fuel
                cur.template.fuel <- cur.template.fuel[Fuel != "Attribute"]
                
                
            } else {
                
                # set names with no property specification
                prop.cols <- names(cur.template.fuel)
                prop.cols <- prop.cols[prop.cols != "Fuel"]
                
                setnames(cur.template.fuel, prop.cols, paste("Pass", prop.cols))
            }
            
            # check if any of these datafile objets aren't in objects sheet. 
            # if they aren't, add them
            all.propnames <- names(cur.template.fuel)
            all.propnames <- all.propnames[all.propnames != "Fuel"]
            
            missing.propnames = all.propnames[
                !(all.propnames %in% Objects.sheet[class == "Data File", name])]
            
            if (length(missing.propnames) > 0) {
                dfobj.to.obects = initialize_table(Objects.sheet, 
                                                   length(missing.propnames), 
                                                   list(class = "Data File",
                                                        name = missing.propnames, 
                                                        category = "Pass properties"))
                
                Objects.sheet <- merge_sheet_w_table(Objects.sheet, dfobj.to.obects)
                
                rm(dfobj.to.obects)
            }
            
            # add specified properties to datafile objects, if they were 
            # specified
            if (exists("dfo.props") && nrow(dfo.props) > 0) {
                
                Attributes.sheet <- merge_sheet_w_table(Attributes.sheet, 
                                                        dfo.props)
            }
            
            # change blanks to NAs (easier to handle) and check that template 
            # doesn't have more than one file pointer per col
            if (length(which(cur.template.fuel == "")) > 0) {
                for (j in seq_len(ncol(cur.template.fuel))) {
                    set(cur.template.fuel,which(cur.template.fuel[[j]] == ""),j,NA)    
                }
            }
            
            if (cur.template.fuel[, any(sapply(.SD, function(x) length(unique(na.omit(x))) > 1)), 
                                  .SDcols = -1]) {
                
                message(sprintf(paste(">>  all filepointers in template %s are",
                                      "not identical. this will not be read correctly ... skipping"),
                                cur.template.fuel.name))
                
                cur.template.fuel <- NA
            }
            
            # same, but for object templates if they exist
            if (!is.null(cur.template.object.name)) {
                for (i in seq_along(cur.template.object)) {
                    
                    # change blanks to NA if there are any 
                    for (j in seq_len(ncol(cur.template.object[[i]]))) {
                        if (length(which(cur.template.object[[i]][[j]] == "") > 0)) {
                            set(i,which(cur.template.object[[i]][[j]] == ""),j,NA)    
                        }
                    }
                    
                    if (cur.template.object[[i]][,
                                                 any(sapply(.SD, function(x) length(unique(na.omit(x))) > 1)), .SDcols = -1]) {
                        
                        message(sprintf(paste(">>  all filepointers in template %s are",
                                              "not identical. this will not be read correctly ... skipping"),
                                        cur.template.object.name[i]))
                        
                        cur.template.object[[i]] <- NA
                        
                        break()
                    }
                    
                    # add datafile objects
                    
                    # set names with no property specification
                    cur.prop.cols <- names(cur.template.object[[i]])
                    cur.prop.cols <- cur.prop.cols[-1] 
                    
                    # setnames(cur.template.object[[i]], cur.prop.cols, 
                    #          paste("Pass", cur.prop.cols))
                    
                    # check for existence of datafile objects, add them if don't already exist
                    # check if any of these datafile objets aren't in objects sheet. 
                    # if they aren't, add them
                    cur.all.propnames <- paste("Pass", cur.prop.cols)
                    
                    missing.propnames = cur.all.propnames[
                        !(cur.all.propnames %in% Objects.sheet[class == "Data File", name])]
                    
                    if (length(missing.propnames) > 0) {
                        dfobj.to.obects = initialize_table(Objects.sheet, 
                                                           length(missing.propnames), 
                                                           list(class = "Data File",
                                                                name = missing.propnames, 
                                                                category = "Pass properties"))
                        
                        Objects.sheet <- merge_sheet_w_table(Objects.sheet, dfobj.to.obects)
                        
                        rm(dfobj.to.obects)
                    } 
                    
                }
                rm(i,j)
            }
            
            # ---- second, interleave models using templates
            
            for (i in 1:nrow(cur.tab)) {
                # pass to function that will add filepointers to datafile 
                # objects under the right scenario and add datafile objects to 
                # properties (with no scenario) if they aren't already there
                # NOTE this will overwrite data in these properties that is
                #   already defined
                make_interleave_pointers(
                    parent.model = cur.tab[i, parent.model],
                    child.model = cur.tab[i, child.model],
                    filepointer.scenario = cur.tab[i, filepointer.scenario],
                    datafileobj.scenario = cur.tab[i, datafileobj.scenario],
                    template.fuel = cur.template.fuel,
                    template.object = ifelse(exists("cur.template.object"), 
                                             cur.template.object, NA),
                    interleave = cur.interleave)
            }
            
            
            # rm(cur.fname, cur.template.fuel, cur.tab, 
            # all.propnames, missing.propnames, cur.template.fuel.name,
            # cur.template.object.name)
            # 
            # if (exists("cur.template.object)) rm(cur.template.object)
            
        } else {
            if (is.null(cur.template.object.name)) {
                message(sprintf(">>  %s or %s does not exist ... skipping", 
                                cur.fname, cur.template.fuel.name))
            } else 
                message(sprintf(">>  %s or %s or %s does not exist ... skipping", 
                                cur.fname, cur.template.fuel.name, 
                                paste0(cur.template.object.name, collapse = ", ")))
        }
    }
} else {
    message('>>  interleave.models.list does not exist ... skipping')
}
