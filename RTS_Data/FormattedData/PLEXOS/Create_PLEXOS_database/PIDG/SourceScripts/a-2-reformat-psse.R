
# pull out tables that we know how to parse and can be useful, parse those.

#------------------------------------------------------------------------------|
# setup ----
#------------------------------------------------------------------------------|

# clean environment of skipped and empty tables, rename tables to use

message("starting a-2")

if (exists('Bus.table')) {
    node.data.table <- Bus.table
}
if (exists('DC.line.table')) {
    line.dc.data.table <- DC.line.table
}
if (exists('Transformer.table')) {
    transformer.data.table <- Transformer.table
}
if (exists('Load.table')) {
 load.data.table <- Load.table
}
if (exists('Branch.table')) {
  line.data.table <- Branch.table
}
if (exists('Generator.table')) {
  generator.data.table <- Generator.table
}
if (exists('Zone.table')) {
  zone.data.table <- Zone.table
}
if (exists('Area.interchange.table')){
  region.data.table <- Area.interchange.table
}
if (exists('Owner.table')) {
  owner.data.table <- Owner.table
}


# clean up from initial parsing script
rm(list=c(skip.tables, done.tables))

rm(done.tables, skip.tables)

# track which to write out
reformatted.tables <- c()

#------------------------------------------------------------------------------|
# node.data.table ----
#------------------------------------------------------------------------------|

if (exists("node.data.table")) {
    ## rename columns, clean up node.data.table
    node.data.table <- node.data.table[,.(Node = paste(node.number, node.name, kV, sep = "_"),
                                          node.number, # for merging, delete later
                                          Voltage = kV,
                                          region.number,
                                          zone.number)]
    
    
    ## optionally, add region, zone, and owner names. otherwise, rename columns
  
    # regions
    if (exists("region.data.table")) {
        
        node.data.table <- merge(node.data.table, 
                                 region.data.table[,.(region.number, 
                                                      Region_Region = region.name)],
                                 by = "region.number",
                                 all.x = TRUE)
        
        node.data.table[,region.number := NULL]
        
        # add regions as objects
        region.data.table <- region.data.table[,.(Region = region.name)]
        reformatted.tables <- c(reformatted.tables, "region.data.table")
        
        
    } else {
        
        if ("region.number" %in% colnames(node.data.table)) {
            setnames(node.data.table, "region.number", "Region_Region") }
    }
    
    # zones
    if (exists("zone.data.table")) {
        
        node.data.table <- merge(node.data.table, 
                                 zone.data.table[,.(zone.number, 
                                                    Zone_Zone = zone.name)],
                                 by = "zone.number",
                                 all.x = TRUE)
        
        node.data.table[,zone.number := NULL]
        
        # add zones as objects
        zone.data.table <- zone.data.table[,.(Zone = zone.name)]
        reformatted.tables <- c(reformatted.tables, "zone.data.table")
        
    } else {
        
        if ("zone.number" %in% colnames(node.data.table)) {
            setnames(node.data.table, "zone.number", "Zone_Zone") }
    }
      
    # # owners
    # if (exists("owner.data.table")) {
    #     
    #     node.data.table <- merge(node.data.table, 
    #                              owner.data.table[,.(owner.number, 
    #                                                  Owner = owner.name)],
    #                              by = "owner.number",
    #                              all.x = TRUE)
    #     
    #     node.data.table[,owner.number := NULL]
    #     
    # } else {
    #     
    #     if ("owner.number" %in% colnames(node.data.table)) {
    #         setnames(node.data.table, "owner.number", "Owner") }
    # }
    
    
    # optionally add load
    if (exists("load.data.table")) { 
        load.data.table <- load.data.table[active.power.MW > 0,
                                           .(`Load Participation Factor` = sum(active.power.MW * status)), 
                                           by = node.number]
  
        # add node name
        node.data.table <- merge(node.data.table, 
                                 load.data.table, 
                                 by = "node.number", 
                                 all.x =TRUE)
        
        # nodes with no load get 0 LPF
        node.data.table[is.na(`Load Participation Factor`), 
                        `Load Participation Factor` := 0]
        
        # if region exists, normalize LPF by region
        if ("Region_Region" %in% names(node.data.table)) {
            node.data.table[,`Load Participation Factor` := `Load Participation Factor`/sum(`Load Participation Factor`), 
                            by = Region_Region]
        }
        # some regions have no load at all, resulting in an NaN LPF on individual nodes. Setting to 0.
        node.data.table[is.nan(`Load Participation Factor`), `Load Participation Factor` := 0] 
        
    }

    
    # since there is no status information in the .raw file for nodes, add Units = 1
    node.data.table[,Units := 1]
    
    # categorize nodes, by region (if exists. if not, then by voltage)
    if ("Region_Region" %in% names(node.data.table)) {
        node.data.table[,category := Region_Region]
    } else if ("Voltage" %in% names(node.data.table)) {
        node.data.table[,category := Voltage]
    }
    
    # add to list to write out
    reformatted.tables <- c(reformatted.tables, "node.data.table")
    
} else {
    stop(paste0("after PSS/E .raw file parsing, node.data.table doesn't exist.",
                "I can't add any data without node information"))
}

#------------------------------------------------------------------------------|
# line.data.table ----
#------------------------------------------------------------------------------|

if (exists("line.data.table")) {
    # assumes existence of node.data.table
    
    ## line data
    line.data.table <- line.data.table[,.(Line = paste(node.from.number, 
                                                       node.to.number, 
                                                       id, "CKT", sep = "_"),
                                          node.from.number, 
                                          node.to.number,
                                          Resistance = resistance.pu,
                                          Reactance = reactance.pu,
                                          ratingA = as.numeric(ratingA), 
                                          ratingB = as.numeric(ratingB),
                                          ratingC = as.numeric(ratingC),
                                          Units = status)]
    
    # choose line rating (either ratingB or the max of ratings A and C)
    line.data.table[,`Max Flow` := {temp = apply(line.data.table[,.(ratingA,ratingC)], 
                                                 1, max);
    ifelse(ratingB != "0", ratingB, temp)}]
    
    line.data.table[,c("ratingA", "ratingB", "ratingC") := NULL]
    
    # if Min Flow is not defined, PLEXOS defaults to -Max Flow, so not necessary
    line.data.table[,`Min Flow` := `Max Flow` * -1]
    
    # if DC lines exist, add them
    if (exists("line.dc.data.table")) {
        
        line.dc.data.table <- line.dc.data.table[,.(Line = paste(node.from.number, 
                                                                 node.to.number, 
                                                                 id.num, 
                                                                 "CKT", sep = "_"),
                                                    node.from.number, 
                                                    node.to.number,
                                                    Resistance = resistance.pu,
                                                    `Max Flow` = max.flow.MW,
                                                    `Min Flow` = as.numeric(max.flow.MW) * -1,
                                                    Units = 1
        )]
        
        line.data.table <- rbindlist(list(line.data.table, line.dc.data.table), 
                                     use.names = TRUE, 
                                     fill = TRUE)
    }
    
    
    # add Node From and Node To names
    line.data.table <- merge(line.data.table, 
                             node.data.table[,.(node.from.number = node.number, 
                                                `Node From_Node` = Node)],
                             by = "node.from.number", 
                             all.x = TRUE)
    
    
    line.data.table <- merge(line.data.table, 
                             node.data.table[,.(node.to.number = node.number, 
                                                `Node To_Node` = Node)],
                             by = "node.to.number", 
                             all.x = TRUE)
    
    
    # categorize lines
    line.data.table[is.na(Reactance), Type := "DC"]
    line.data.table[!is.na(Reactance), Type := "AC"]
    
    line.data.table[Type == "DC", Line := paste0(Line, "_DC")]
    
    # add category - by region and type or voltage and type or just type, 
    # depending on what's available
    if ("Region_Region" %in% names(node.data.table)) {
        node.region <- node.data.table[, Region_Region]
        names(node.region) <- node.data.table[, Node]
        
        line.data.table[,region_from := node.region[`Node From_Node`]]
        line.data.table[,region_to := node.region[`Node To_Node`]]
        
        line.data.table[region_from == region_to, 
                        category := paste0(Type, "_", region_from)]
        line.data.table[region_from != region_to, 
                        category := paste0("Interregion_", Type)]
        
        # clean up
        line.data.table[,c("region_from", "region_to") := NULL]
        rm(node.region)
        
    } else if ("Voltage" %in% names(node.data.table)) {
        node.kV <- node.data.table[, Voltage]
        names(node.kV) <- node.data.table[, Node]
        
        line.data.table[,kV_from := node.kV[`Node From_Node`]]
        line.data.table[,kV_to := node.kV[`Node To_Node`]]
        
        line.data.table[kV_from == kV_to, category := paste(kV_from, "_", Type)]
        line.data.table[kV_from != kV_to, category := paste("Inter-kV_", Type)]
        
        # clean up
        line.data.table[,c("kV_from", "kV_to") := NULL]
        rm(node.kV)
    } else {
        line.data.table[,category := Type]
    }
    
    # clean up
    line.data.table[,c("node.from.number", "node.to.number", "Type") := NULL]
    
    setcolorder(line.data.table, c("Line", "category", "Node From_Node", 
                                   "Node To_Node", "Units", "Max Flow", 
                                   "Min Flow", "Resistance", "Reactance"))
    
    # add to list to write out
    reformatted.tables <- c(reformatted.tables, "line.data.table")
}

#------------------------------------------------------------------------------|
# generator.data.table ----
#------------------------------------------------------------------------------|

if (exists("generator.data.table")) {
    
    # commenting out ownership stuff for now. should still be functional if 
    # want to add it back in later
    # gen.cols <- colnames(generator.data.table)
    # gen.owner.cols <- gen.cols[grepl("owner", gen.cols)]
    # 
    # if (length(gen.owner.cols) > 0) {
    #     
    #     # grab columns with ownership data to be merged with the full generator
    #     # table later
    #     gen.owners <- generator.data.table[,.SD, .SDcols = c("node.number", "id", 
    #                                                          gen.owner.cols)]
    #     
    #     
    #     
    # }

    generator.data.table <- generator.data.table[,.(node.number,
                                                    id,
                                                    `Max Capacity` = max.capacity.MW,
                                                    `Min Stable Level` = min.output.MW,
                                                    Units = status)]

    # # add ownership back in if it exists
    # if (length(gen.owner.cols) > 0) {
    #     
    #     generator.data.table <- merge(generator.data.table, gen.owners, 
    #                                   by = c("node.number", "id"),
    #                                   all.x = TRUE)
    #     
    #     # if owner.data.table exists, add real names for ownerships
    #     if (exists("owner.data.table")) {
    #         
    #         # need to merge for each owner.numberX column that exists. find 
    #         # out how many times we need to merge
    #         times.to.merge <- length(gen.owner.cols)/2
    #         
    #         # check this
    #         last.col <- gen.owner.cols[length(gen.owner.cols)]
    #         if (times.to.merge != as.numeric(substr(last.col, 
    #                                                 nchar(last.col),
    #                                                 nchar(last.col)))) {
    #             
    #             message(paste("Number of owner columns doesn't line up with.",
    #                           "owner column labels. Please check."))
    #         }
    #         
    #         for (i in seq_len(times.to.merge)) {
    #             
    #             # workaround to force owner.number to be numeric
    #             generator.data.table[, owner.number.temp := as.numeric(get(paste0("owner.number", i)))]
    #             generator.data.table[, (paste0("owner.number", i)) := NULL]
    #             generator.data.table[, (paste0("owner.number", i)) := owner.number.temp]
    #             generator.data.table[, owner.number.temp := NULL]
    #             
    #             # merge owner table in 
    #             generator.data.table <- merge(generator.data.table, 
    #                                           owner.data.table,
    #                                           by.x = paste0("owner.number", i),
    #                                           by.y = "owner.number",
    #                                           all.x = TRUE)
    #             
    #             # replace column names
    #             setnames(generator.data.table, 
    #                      "owner.name", 
    #                      paste0("Owner", i))
    #             
    #             setnames(generator.data.table, 
    #                      paste0("owner.fraction", i), 
    #                      paste0("Owner Fraction", i))
    #             
    #             generator.data.table[,(paste0("owner.number", i)) := NULL]
    #             
    #             
    #         }
    #         # clean up
    #         rm(i)
    #         
    #     } # end exists("owner.data.table")
    # } # end length(gen.owner.cols)
    # 
    # # clean up
    # rm(gen.cols, gen.owner.cols)
    
    # change to generator name
    generator.data.table <- merge(generator.data.table, 
                                  node.data.table[,.(node.number, Nodes_Node = Node)], 
                                  by = "node.number", 
                                  all.x = TRUE)
    
    generator.data.table[,Generator := paste("GEN", Nodes_Node, id, sep = "_")]
    
    # add category (region)
    if ("Region_Region" %in% names(node.data.table)) {
        node.region <- node.data.table[, Region_Region]
        names(node.region) <- node.data.table[, Node]
        
        generator.data.table[,category := node.region[Nodes_Node]]
        
        rm(node.region)
    } else {
        generator.data.table[,category := NA]
    }
        
    # clean up
    generator.data.table[,c("node.number", "id") := NULL]
    
    # reorder cols. ownership cols are optional and may not exist, so only reorder
    # required columns
    known.cols <- c("Generator", "category", "Nodes_Node", "Max Capacity", 
                    "Min Stable Level", "Units")
    all.cols <- colnames(generator.data.table)
    
    setcolorder(generator.data.table, 
                c(known.cols, all.cols[!(all.cols %in% known.cols)]))
    
    # clean up
    rm(all.cols, known.cols) 
    
    # add to list to write out
    reformatted.tables <- c(reformatted.tables, "generator.data.table")
    
}

#------------------------------------------------------------------------------|
# transformer.data.table ----
#------------------------------------------------------------------------------|

if (exists("transformer.data.table")) {
    transformer.data.table <- transformer.data.table[,.(Transformer = paste(node.from.number, 
                                                                            node.to.number, 
                                                                            id, 
                                                                            "tfmr", 
                                                                            sep = "_"),
                                                        node.from.number,
                                                        node.to.number,
                                                        Resistance = resistance.pu,
                                                        Reactance = reactance.pu,
                                                        Rating = rating.MW,
                                                        Units = status)]

    #to avoid merging errors
    transformer.data.table[,node.to.number:=as.numeric(node.to.number)]
    
    # add Node From and Node To names
    transformer.data.table <- merge(transformer.data.table, 
                                    node.data.table[,.(node.from.number = node.number,
                                                       `Node From_Node` = Node)],
                                    by = "node.from.number",
                                    all.x = TRUE)    
    
    transformer.data.table <- 
        merge(transformer.data.table, 
                                    node.data.table[,.(node.to.number = node.number,
                                                       `Node To_Node` = Node)],
                                    by = "node.to.number",
                                    all.x = TRUE)

    # add category - by region and type or voltage and type or just type, 
    # depending on what's available
    if ("Region_Region" %in% names(node.data.table)) {
        node.region <- node.data.table[, Region_Region]
        names(node.region) <- node.data.table[, Node]
        
        transformer.data.table[,region_from := node.region[`Node From_Node`]]
        transformer.data.table[,region_to := node.region[`Node To_Node`]]
        
#        transformer.data.table[region_from == region_to, category := region_from]
        transformer.data.table[region_from == region_to, category := as.character(region_from)]
        transformer.data.table[region_from != region_to, category := "Interregion"]
        
        # clean up
        transformer.data.table[,c("region_from", "region_to") := NULL]
        rm(node.region)
        
    } else {
        transformer.data.table[,category := NA]
    }
    
    # clean up
    transformer.data.table[,c("node.to.number", "node.from.number") := NULL]
    
    setcolorder(transformer.data.table, c("Transformer", "category", 
                                          "Node From_Node", "Node To_Node", 
                                          "Rating", "Resistance", "Reactance",
                                          "Units"))
    
    # add to list to write out
    reformatted.tables <- c(reformatted.tables, "transformer.data.table")
}

# clean up node
node.data.table[, node.number := NULL]
setorder(node.data.table, Node)

# write out (to objects.list or csv)

if(!exists("parse.in.place")){
  message('set parse.in.place = TRUE if using driver.R or FALSE if using parse_raw.R')
} else if (parse.in.place == TRUE) {
  
  # add to objects.list so will be ingested by PIDG (has to be list of lists
  # of data.tables to be processed correctly)
  if (exists("objects.list")) {
    objects.list <- c(objects.list, lapply(reformatted.tables, 
                                           function(x) list(get(x))))
  } else {
    objects.list <- lapply(reformatted.tables, 
                           function(x) list(get(x)))
  }
  
  # clean up
  to.clean <- c("line.dc.data.table", "load.data.table", "owner.data.table",
                "Two.terminal.dc.line.table")
  
  to.clean <- to.clean[to.clean %in% ls()]
  
  rm(list = c(to.clean, reformatted.tables))
  rm(to.clean, reformatted.tables)

}else if(parse.in.place == FALSE){
  
  for (tab.name in reformatted.tables) {
    
    get(tab.name)[,filename:=cur.raw.file]  
    
    if(file.exists(file.path(outputfiles.dir, paste0(tab.name, ".csv")))){
        
        if(cur.raw.file == raw.file.list[[1]]){
            message(paste0('adding raw.file.list contents to an existing ',tab.name,".csv"))
        }
        
        write.csv(rbind(fread(file.path(outputfiles.dir, paste0(tab.name, ".csv"))),get(tab.name)), 
                  file.path(outputfiles.dir, paste0(tab.name, ".csv")),
                  row.names = FALSE, 
                  quote = FALSE)
        
    }else{  
        
        write.csv(get(tab.name), 
                  file.path(outputfiles.dir, paste0(tab.name, ".csv")),
                  row.names = FALSE, 
                  quote = FALSE)
    }
  }
}else{
  
  message('set parse.in.place = TRUE if using driver.R or FALSE if using parse_raw.R')
  
}
