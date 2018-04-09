# Run to check data and summarize the compiled database 

# define print width
p.width = 250

# function to adjust width of output to txt file
withOptions <- function(optlist, expr)
{
  oldopt <- options(optlist)
  on.exit(options(oldopt))
  expr <- substitute(expr)
  eval.parent(expr)
}

# by default, generate plots
if(!exists("data.check.plots")){
    
    message(paste(">>  data.check.plots does not exist; exporting data check", 
                  "plots by default. To suppress this and decrease runtime, set", 
                  "data.check.plots to TRUE.")) 

    data.check.plots <- TRUE
}

# list of missing items
missing.items.list <- c()

# create unique directory to save warnings and summary output
data.check.dir <- file.path(outputfiles.dir,
                            paste0(gsub("\\.xls|\\.xlsx", "", output.wb.name), 
                                   "_data_check"))

dir.create(data.check.dir, showWarnings = F, recursive = TRUE)

# create a warnings file 
warnings <- file.path(data.check.dir,"warnings.txt")
file.create(warnings)
sink(warnings) 
cat("***Warnings***")
sink()

# create a fatal warnings file
fatal.warnings <- file.path(data.check.dir,"fatal.warnings.txt")
file.create(fatal.warnings)
sink(fatal.warnings) 
cat("***Fatal Warnings***")
sink()

# create file to summarize database
db.summary <- file.path(data.check.dir, "db.summary.txt")
file.create(db.summary)
sink(db.summary) 
cat("**Database Summary Report**\n")
cat("---------------------------","\n\n")
sink()

#------------------------------------------------------------------------------#
# High-level database summary ----
#------------------------------------------------------------------------------#

message("summarizing database")

obj.summary <- Objects.sheet[,.N, by = class]
setnames(obj.summary, c("class", "N"), c("Object class", "# objects"))

nodes.summary <- Memberships.sheet[parent_class == "Node" & 
                                       child_class %in% c("Region", "Zone") ,.N, 
                                   by = .(parent_class, child_class, child_object)]
nodes.summary[,parent_class := NULL]
setnames(nodes.summary,
         c("child_class", "child_object", "N"), 
         c("", "Region/Zone", "# nodes"))

# write to file
sink(db.summary, append = TRUE) 
cat("\nSummary of database components")
cat("\n------------\n\n")
cat("Number of objects of each type:\n")
print(obj.summary,
      row.names = F, 
      n = nrow(obj.summary))
cat("\n")
cat("Number of nodes in each region and/or zone:\n")
print(nodes.summary,
      row.names = F, 
      n = nrow(nodes.summary))
cat("\n\n")
sink()


#------------------------------------------------------------------------------#
# Add gen-fuel memberships to db summary ----
#------------------------------------------------------------------------------#

gen.fuel <- Memberships.sheet[parent_class == "Generator" & 
                                  collection %in% c("Fuels", "Start Fuels"),
                              .(Generator = parent_object, 
                                collection, 
                                fuel = child_object)]

# add collection
gen.fuel <- merge(gen.fuel, 
                  Objects.sheet[class == "Generator", .(Generator = name, category)], 
                  by = "Generator",
                  all = TRUE)

gen.fuel <- gen.fuel[,.N, by = .(category, collection, fuel)]

# prep for export
setorder(gen.fuel, category)

# export
sink(db.summary, append = TRUE)
cat("Summary of generator/fuel memberships")
cat("\n------------\n\n")
print(gen.fuel,
      row.names = F, 
      n = nrow(gen.fuel))
cat("\n\n")
sink()

# clean up
rm(gen.fuel)

#------------------------------------------------------------------------------#
# Check generator properties ----
#------------------------------------------------------------------------------#

if (Objects.sheet[class == "Generator", .N] > 0) {
    message("checking generator properties")
    
    ### pull generator capacity by fuel and state
    generator.map <- Objects.sheet[class == "Generator", 
                                   .(Generator = name, 
                                     `Generator category` = category, 
                                     scenario = NA_character_)]
    
    generator.map <- merge(generator.map,
                           Properties.sheet[child_class == "Generator" &
                                                property == "Max Capacity",
                                            .(Generator = child_object,
                                              `Max Capacity` = value, 
                                              scenario)], 
                           by = c("Generator", "scenario"), all.x = T)
    
    # pull generator fuels
    generator.map <- merge(generator.map,
                           Memberships.sheet[parent_class == "Generator" &
                                                 collection == "Fuel",
                                             .(Generator = parent_object,
                                               Fuel = child_object)],
                           by = "Generator", all = T)
    
    # pull generator start fuels
    generator.map <- merge(generator.map,
                           Memberships.sheet[parent_class == "Generator" &
                                                 collection == "Start Fuel",
                                             .(Generator = parent_object,
                                               `Start Fuel` = child_object)],
                           by = "Generator", all = T)
    
    # pull generator nodes
    generator.map <- merge(generator.map,
                           Memberships.sheet[parent_class == "Generator" &
                                                 child_class == "Node",
                                             .(Generator = parent_object,
                                               Node = child_object)],
                           by = "Generator", all.x = T)
    
    # pull regions
    generator.map <- merge(generator.map,
                           Memberships.sheet[parent_class == "Node" &
                                                 child_class == "Region",
                                             .(Node = parent_object,
                                               Region = child_object)],
                           by = "Node", all.x = T)
    
    # pull RE units and scenarios
    generator.map <- merge(generator.map,
                           Properties.sheet[child_class == "Generator" &
                                                property == "Units",
                                            .(Generator = child_object,
                                              Units = value, 
                                              scenario)], 
                           by = c("Generator", "scenario"), all.x = T)
    
    # clean up scenario name
    generator.map[,scenario := gsub("{Object}", "",scenario, fixed = T)]
    generator.map[,scenario := ifelse(is.na(scenario),"No scenario",scenario)]
    
    # flag generators with missing missing nodes, regions, fuels, capacity, units
    
    gens.missing.units <- unique(generator.map[is.na(Units), .(Generator, Units, `Generator category`)])
    gens.missing.capacity <- unique(generator.map[is.na(`Max Capacity`), .(Generator, `Max Capacity`, `Generator category`)])
    gens.missing.node <- unique(generator.map[is.na(Node), .(Generator, Node)])
    
    # add to missing items list
    missing.items.list <- c(missing.items.list, "gens.missing.units", 
                            "gens.missing.capacity",
                            "gens.missing.node")
    
    # change colums that can be numeric to numeric
    generator.map <- generator.map[, lapply(.SD, function(x) {
        if (!is.na(suppressWarnings(as.numeric(x[1])))) {
            suppressWarnings(as.numeric(x))} else x
    })]
    
    # if don't have max capacity or units, sub in 0 so next lines don't break
    if (all(is.na(generator.map$`Max Capacity`))) {
        generator.map[, `Max Capacity` := NULL] # is a char column
        generator.map[, `Max Capacity` := 0]
    }
    
    if (all(is.na(generator.map$Units))) {
        generator.map[, Units := NULL] # is a char column
        generator.map[, Units := 0]
    }
    
    if (!is.numeric(generator.map$`Max Capacity`)) {
        generator.map[, `Max Capacity` := as.numeric(`Max Capacity`)] # is a char column
    }
    
    if (!is.numeric(generator.map$Units)) {
        generator.map[, Units := as.numeric(Units)] # is a char column
    }
    
    
    # summarize generator properties by fuel and save to OutputFiles
    generator.fuels.region <- generator.map[,.(total.cap.x.units = sum(`Max Capacity`*Units),
                                               avg.capacity = mean(`Max Capacity`),
                                               total.capacity = sum(`Max Capacity`),
                                               min.capacity = min(`Max Capacity`),
                                               max.capacity = max(`Max Capacity`),
                                               sd.capacity = sd(`Max Capacity`),
                                               avg.units = mean(Units),
                                               total.units = sum(Units),
                                               min.units = min(Units),
                                               max.units = max(Units),
                                               sd.units = sd(Units)),
                                            by = .(`Generator category`, Fuel, `Start Fuel`,  Region, scenario)]
    
    generator.fuels.summary <- generator.map[,.(total.cap.x.units = sum(`Max Capacity`*Units),
                                                avg.capacity = mean(`Max Capacity`),
                                                total.capacity = sum(`Max Capacity`),
                                                min.capacity = min(`Max Capacity`),
                                                max.capacity = max(`Max Capacity`),
                                                sd.capacity = sd(`Max Capacity`),
                                                avg.units = mean(Units),
                                                total.units = sum(Units),
                                                min.units = min(Units),
                                                max.units = max(Units),
                                                sd.units = sd(Units)),
                                             by = .(`Generator category`, Fuel, `Start Fuel`, scenario)]
    
    # tidy up
    setorder(generator.fuels.region, Region, `Generator category`, Fuel, `Start Fuel`, scenario)
    setorder(generator.fuels.summary, `Generator category`, Fuel, `Start Fuel`, scenario)
    
    sink(db.summary, append = TRUE)
    cat("Summary of generators in database")
    cat("\n------------\n\n")
    cat(sprintf("To see this information by region, see %s/generator.summary.by.fuel.region.csv\n\n", data.check.dir))
    print(generator.fuels.summary,
          row.names = F, 
          n = nrow(generator.fuels.summary))
    cat("\n\n")
    sink()
    
    write.csv(generator.fuels.region,
              file = file.path(data.check.dir, "generator.summary.by.fuel.region.csv"),
              quote = F, row.names = F)
    
    
}

# plot generator capacity plus existing RE by state
if(data.check.plots){
  message("...exporting regional capacity plots")
  
  # alpabetize regions
  region.names <- unique(generator.map$Region)[order(unique(generator.map$Region))]
  
  pb <- txtProgressBar(min = 0, max = length(unique(generator.map$Region)), style = 3)
  pdf(file.path(data.check.dir,"regional.capacity.plots.pdf"),
      width = 12, height = 8)
  stepi = 0

  for(i in region.names){
    plot.data <- generator.map[Region == i, ]
    plot.data <- plot.data[which(`Max Capacity`*Units > 0), ]
    plot.data <- arrange(plot.data, scenario)
    plot <- ggplot(data = plot.data) +
      geom_bar(aes(x = Fuel, y = `Max Capacity`*Units, fill = scenario), stat = "identity") +
      ggtitle(paste0(i," Generation Capacity by Fuel")) +
      theme(axis.text.x = element_text(angle = 45, hjust = 1)) + 
      ylab("Max Capacity (MW)")
      
      suppressWarnings(
        plot(plot)
      )
      stepi = stepi + 1
      setTxtProgressBar(pb, stepi)
  }
  dev.off()
  rm(stepi)
}

#------------------------------------------------------------------------------#
# Identify islands and isolated nodes ----
#------------------------------------------------------------------------------#

message("checking isolated nodes")

# check for nodes missing region and/or zone
nodes = Objects.sheet[class == "Node",.(Node = name)]

nodes = merge(nodes, 
              Memberships.sheet[parent_class == "Node" & 
                                  child_class == "Region",
                                .(Node = parent_object, Region = child_object)],
              by = "Node", all = T)

nodes = merge(nodes, 
              Memberships.sheet[parent_class == "Node" & 
                                  child_class == "Zone",
                                .(Node = parent_object, Zone = child_object)],
              by = "Node", all = T)

node.missing.region <- nodes[is.na(Region), .(Node, Region, Fatal = T)]
node.missing.zone <- nodes[is.na(Zone), .(Node, Zone)]

missing.items.list <- c(missing.items.list,"node.missing.region", 
                        "node.missing.zone")

# check for nodes with more than one region or zone memberships
duplicated.node.names <- nodes[duplicated(Node),Node]
duplicated.nodes <- nodes[Node %in% duplicated.node.names]

if(nrow(duplicated.nodes) > 0){
  sink(fatal.warnings, append = T) 
  cat("WARNING: at least one node is assigned to more than one region and/or zone.")
  cat("\n Check these nodes: \n")
  print(duplicated.nodes, quote = F, row.names = F)
  sink()
}


# Identify islands - extract all edges (lines and transformers)
lines.from <- Memberships.sheet[parent_class == "Line" & 
                                  collection == "Node From",
                                .(line = parent_object, from = child_object)]

lines.to <- Memberships.sheet[parent_class == "Line" & 
                                collection == "Node To",
                              .(line = parent_object, to = child_object)]

lines <- merge(lines.from, lines.to, by = "line")

# add transformers

tfmr.from <- Memberships.sheet[parent_class == "Transformer" & 
                                 collection == "Node From",
                               .(line = parent_object, from = child_object)]

tfmr.to <- Memberships.sheet[parent_class == "Transformer" & 
                               collection == "Node To",
                             .(line = parent_object, to = child_object)]

tfmrs <- merge(tfmr.from, tfmr.to, by = "line")

# combine lines and transformers to create network edges
edges <- rbind(lines, tfmrs)[,.(from,to)]

# create graph object
if (!anyDuplicated(nodes$Node)) {
    network <- graph.data.frame(edges, directed = F, vertices = nodes)
}

if (nrow(edges) > 0 & nrow(nodes) > 0) {
  
  # retrieve list of isolated nodes
  components <- components(network)
  
  names(components$csize) <- 1:length(components$csize)
  
  components.table <- data.table(Node.Name = names(components$membership),
                                 component.id = components$membership)
  
  components.table[,csize := 
                     components$csize[which(names(components$csize) == component.id)],
                   by = "component.id"]
  
  # grab scenarios on nodes
  nodes <- merge(nodes,
                 Properties.sheet[child_class == "Node" & property == "Units",
                                  .(child_object, scenario)], 
                 by.x = "Node", by.y = "child_object", all = T)
  
  components.table[,node.in.scenario := 
                     ifelse(Node.Name %in% 
                              nodes[!is.na(scenario),Node], 1, 0)]
  
  island.nodes <- components.table[csize != max(csize), .(Node.Name = Node.Name)]
  island.nodes <- merge(island.nodes, 
                        Memberships.sheet[parent_class == "Node" & 
                                        child_class == "Region", 
                                    .(Node.Name = parent_object, 
                                      Region = child_object)], 
                        by = "Node.Name", 
                        all.x = TRUE)
  
  island.nodes[,`In scenario?` := 
                  ifelse(Node.Name %in% 
                           components.table[node.in.scenario != 0, Node.Name], "Yes", "No")]
  
  write.csv(island.nodes,  
            file = file.path(data.check.dir,"isolated.nodes.csv"),
            quote = F, row.names = F)
  
  # Export a report table
  
  components.table <- components.table[,.(`Component size` = max(csize), 
               `Nodes in 'Remove Isolated Nodes' scenario` = sum(node.in.scenario)),
                by = "component.id"]
  
  components.table[,component.id := NULL]
  
  # components.report.dir <- file.path(data.check.dir,"isolated.nodes.report.txt")
  
  sink(db.summary, append = TRUE) 
  cat(sprintf("Summary of connected components in network of %s database.", ifelse(exists("choose.db"), choose.db, "the")))
  cat(paste0("\n","------------","\n\n"))
  cat("This analysis is done on the base network - scenarios on Lines/Transformers are ignored.")
  cat("\n")
  cat(sprintf("List of nodes that belong to islands saved in %s/isolated.nodes.csv", data.check.dir))
  cat("\n")
  cat("Islands are any groups of nodes not connected to the largest connected component.")
  cat("\n\n")
  print(setorder(components.table, -`Component size`, `Nodes in 'Remove Isolated Nodes' scenario`),
        row.names = F, 
        n = nrow(components.table))
  cat("\n\n")
  sink()
}

# check that LPFs sum to 1 for each region ----
node.lpf <- Properties.sheet[child_class == "Node" & 
                               property == "Load Participation Factor",
                             .(Node = child_object, LPF = as.numeric(value),
                               scenario, pattern)]

node.lpf <- merge(node.lpf, 
                  Memberships.sheet[parent_class == "Node" & 
                                      child_class == "Region",
                                    .(Node = parent_object, Region = child_object)],
                  by = "Node", all.x = T)

# sum LPF by region 
region.lpf <- node.lpf[,.(region.lpf = sum(LPF)), 
                       by = .(Region, scenario, pattern)]

# generate warning if LPF does not sum to 1 in all regions
if(region.lpf[round(region.lpf, 3) != 1,.N] > 0){
  sink(warnings, append = T) 
  cat("\n\n")
  cat(paste0("WARNING: LPF does not sum to one (1) in at least one region."))
  cat("\n\n")
  print(region.lpf[round(region.lpf, 3) != 1, .(Region, 
                                                region.lpf = sprintf("%.6f", region.lpf), 
                                                scenario, 
                                                pattern)], 
        row.names = F,
        n = nrow(region.lpf))
  sink()
}

# clean up working evnironment
rm(network, edges, lines, lines.from, lines.to, tfmrs, tfmr.to, tfmr.from)

# check that gen PFs sum to 1 for each generator ----
node.genpf <- Properties.sheet[child_class == "Node" & 
                                  parent_class == "Generator" &
                                  property == "Generation Participation Factor",
                              .(Node = child_object, 
                                genPF = as.numeric(value),
                                Generator = parent_object,
                                scenario, 
                                pattern)]

# sum LPF by region
gen.genpf <- node.genpf[,.(gen.genpf = sum(genPF)), 
                        by = .(Generator, scenario, pattern)]

# generate warning if LPF does not sum to 1 in all regions
if(gen.genpf[round(gen.genpf, 3) != 1,.N] > 0){
    sink(warnings, append = T) 
    cat("\n\n")
    cat(paste0("WARNING: generation PF does not sum to one (1) for at least one generator"))
    cat("\n\n")
    print(gen.genpf[round(gen.genpf, 3) != 1, .(Generator, 
                                                 gen.genpf = sprintf("%.6f", gen.genpf), 
                                                 scenario, 
                                                 pattern)], 
          row.names = F,
          n = nrow(gen.genpf[round(gen.genpf, 3) != 1]), 
          width = p.width)
    sink()
}


# check for negative min stable levels ----
problem.row.mask = Properties.sheet[,property == "Min Stable Level" & 
                                        as.numeric(value) < 0]

if (any(problem.row.mask)) {
    sink(fatal.warnings, append = T) 
    cat("\n\n")
    cat(paste0("WARNING: there are negative min stable levels in Properties.sheet\n"))
    print(Properties.sheet[problem.row.mask],
          row.names = F,
          n = nrow(Properties.sheet[problem.row.mask]))
    sink()
}

rm(problem.row.mask)


#------------------------------------------------------------------------------#
# Check line and tfmr properties ----
#------------------------------------------------------------------------------#

line.map <- Objects.sheet[class %in% c("Line","Transformer"), 
                          .(Line = name, Region = category)]

# get line max flow
line.map <- merge(line.map,
                  Properties.sheet[child_class == "Line" &
                                     property == "Max Flow",
                                   .(Line = child_object, `Max Flow` = value)],
                  by = "Line", all.x = T)


# get line min flow
line.map <- merge(line.map,
                  Properties.sheet[child_class == "Line" &
                                     property == "Min Flow",
                                   .(Line = child_object, `Min Flow` = value)],
                  by = "Line", all.x = T)

# get node.to.kV and node.from.kV
# Node From
line.map <- merge(line.map,
                  Memberships.sheet[parent_class %in% c("Line","Transformer") & 
                              child_class == "Node" & collection == "Node From",
                             .(Line = parent_object, Node.From = child_object)],
                  by = "Line")

line.map <- merge(line.map,
                  Properties.sheet[child_class == "Node" & property == "Voltage",
                              .(Node.From = child_object, Node.From.kV = value)],
                  by = "Node.From")

# Node To
line.map <- merge(line.map,
                  Memberships.sheet[parent_class %in% c("Line","Transformer") & 
                                child_class == "Node" & collection == "Node To",
                               .(Line = parent_object, Node.To = child_object)],
                  by = "Line")

line.map <- merge(line.map,
                  Properties.sheet[child_class == "Node" & property == "Voltage",
                                  .(Node.To = child_object, Node.To.kV = value)],
                  by = "Node.To")

# pull reactance and resistance
line.map <- merge(line.map,
                  Properties.sheet[child_class %in% c("Line","Transformer")
                                   & property == "Reactance",
                                   .(Line = child_object, Reactance = value,
                                     reac.scenario = scenario)],
                  by = "Line")

line.map <- merge(line.map,
                  Properties.sheet[child_class %in% c("Line","Transformer")
                                   & property == "Resistance",
                                   .(Line = child_object, Resistance = value,
                                     resis.scenario = scenario)],
                  by = "Line")

# identify transformers
line.map[, tfmr := ifelse(grepl("tfmr",Line),"Transformer","Line")]

# clean-up scenario name
line.map[,resis.scenario:=gsub("{Object}","Scenario: ",resis.scenario,fixed = T)]
line.map[is.na(resis.scenario),resis.scenario:="No scenario"]

line.map[,reac.scenario:=gsub("{Object}","Scenario: ",reac.scenario,fixed = T)]
line.map[is.na(reac.scenario),reac.scenario:="No scenario"]

# # change columns that can be numeric to numeric
# line.map <- line.map[, lapply(.SD, function(x) {
#   if (!is.na(suppressWarnings(as.numeric(x[1])))) {
#     suppressWarnings(as.numeric(x))} else x
# })]

# flag any lines with missing Node.From and/or Node.To
lines.missing.nodes <- line.map[is.na(Node.From) | is.na(Node.To),
                                .(Line, 
                                  Node = paste("From:",Node.From,"To:", Node.To),
                                  Fatal = T)]

missing.items.list <- c(missing.items.list,"lines.missing.nodes")

if(data.check.plots){
  # plots of min and max flow by voltage (using Node.From.kV)
  line.maxflow.plot <- ggplot(data = line.map,
                              aes(x = factor(Node.From.kV), y = `Max Flow`)) +
    geom_jitter(alpha=0.3, color="tomato", height = 0) +
    geom_boxplot(alpha = 0) +
    xlab("Node From Voltage (kV)") +
    ylab("Max Flow (MW)")
  
  line.minflow.plot <- ggplot(data = line.map,
                              aes(x = factor(Node.From.kV), y = `Min Flow`)) +
    geom_jitter(alpha=0.3, color="tomato", height = 0) +
    geom_boxplot(alpha = 0) +
    xlab("Node From Voltage (kV)") +
    ylab("Min Flow (MW)")
  
  # plots of reactance and resistance by voltage and scenario
  line.reactance.plot <- ggplot(data = line.map,
                                aes(x = factor(Node.From.kV), y = Reactance)) +
    geom_jitter(alpha=0.3, color="tomato", height = 0) +
    geom_boxplot(alpha = 0) +
    facet_wrap(tfmr ~ reac.scenario, scales = "free") +
    xlab("Node From Voltage (kV)")
  
  line.resistance.plot <- ggplot(data = line.map, 
                                 aes(x = factor(Node.From.kV), y = Resistance)) +
    geom_jitter(alpha=0.3, color="tomato", height = 0) +
    geom_boxplot(alpha = 0) +
    facet_wrap(tfmr ~ resis.scenario, scales = "free") +
    xlab("Node From Voltage (kV)")
  
  # add to list of plots
  line.plots <- c("line.maxflow.plot", "line.minflow.plot",
                        "line.reactance.plot","line.resistance.plot")
  
  ### export line plots to DataCheck folder
  message("...exporting line property plots")
  pb <- txtProgressBar(min = 0, max = length(line.plots), style = 3)
  pdf(file.path(data.check.dir,"line.plots.pdf"),
      width = 12, height = 8)
  for(i in 1:length(line.plots)){
    suppressWarnings(
      plot(get(line.plots[i]))
    )
    setTxtProgressBar(pb, i)
  }
  dev.off()
}

#------------------------------------------------------------------------------#
# check for fatal import/run errors ----
#------------------------------------------------------------------------------#

message("checking for other data issues")

# ** make sure there are no blanks in required values in Properties.sheet ----
problem.row.mask = Properties.sheet[, 
                                    !complete.cases(list(parent_object, child_object, parent_class, 
                                                         child_class, collection, property, value, band_id))]

if (any(problem.row.mask)) {
  sink(fatal.warnings, append = T) 
  cat("\n\n")
  cat(paste0("WARNING: the following entries in property sheet are missing at ",
             "least one of: parent_object, child_object, parent_class, ",
             "child_class, collection, property, value, band_id. This will not ",
             "import.\n"))
  print(Properties.sheet[problem.row.mask,
                         .(parent_object, child_object, parent_class, 
                           child_class, collection, property, value, band_id)],
        row.names = F,
        n = nrow(Properties.sheet[problem.row.mask,]))
  sink()
}

# ** make sure there are no blanks in Memberships.sheet ----
problem.row.mask = !complete.cases(Memberships.sheet)

if (any(problem.row.mask)) {
  sink(fatal.warnings, append = T) 
  cat("\n\n")
  cat("WARNING: the following membership sheet value(s) are missing.\n ",
        "This will not import.", 
        "This may be caused by models being multiply defined in generic import ",
        "sheets, among other things.\n")
  print(Memberships.sheet[problem.row.mask], 
        row.names = F, 
        n = nrow(Memberships.sheet[problem.row.mask]))
  sink()
}

# ** make sure there are no blanks in Objects.sheet ----
problem.row.mask = !complete.cases(Objects.sheet[,.(class, name)])

if (any(problem.row.mask)) {
    sink(fatal.warnings, append = T) 
    cat("\n\n")
    cat("WARNING: the following objects sheet value(s) are missing.\n ",
        "This will not import.\n")
    print(Objects.sheet[problem.row.mask], 
          row.names = F, 
          n = nrow(Objects.sheet[problem.row.mask]))
    sink()
}

# ** make sure there are no blanks in Attributes.sheet ----
problem.row.mask = !complete.cases(Attributes.sheet)

if (any(problem.row.mask)) {
    sink(fatal.warnings, append = T) 
    cat("\n\n")
    cat("WARNING: the following attributes sheet value(s) are missing.\n ",
        "This will not import.\n")
    print(Attributes.sheet[problem.row.mask], 
          row.names = F, 
          n = nrow(Attributes.sheet[problem.row.mask]))
    sink()
}

# ** make sure there are no blanks in Reports.sheet ----
problem.row.mask = !complete.cases(Reports.sheet)

if (any(problem.row.mask)) {
    sink(fatal.warnings, append = T) 
    cat("\n\n")
    cat("WARNING: the following reports sheet value(s) are missing.\n ",
        "This will not import.\n")
    print(Reports.sheet[problem.row.mask], 
          row.names = F, 
          n = nrow(Reports.sheet[problem.row.mask]))
    sink()
}

# ** make sure no region has no nodes ----
all.regions <- Objects.sheet[class == "Region",name]
regions.w.nodes <- Memberships.sheet[parent_class == "Node" & collection == 
                                       "Region",child_object]
if (!all(all.regions %in% regions.w.nodes)) {
  sink(fatal.warnings, append = T) 
  cat("\n\n")
  cat("WARNING: the following region(s) have no nodes. This will not import.\n")
  print(all.regions[!(all.regions %in% regions.w.nodes)], 
        row.names = F, 
        n = nrow(all.regions[!(all.regions %in% regions.w.nodes)]))
  sink()
}

# ** make sure no object name has more than 50 characters ----
if (any(Objects.sheet[!is.na(name),nchar(name) > 50])) {
  sink(fatal.warnings, append = T) 
  cat("\n\n")
  cat("WARNING: the following object(s) have names with > 50 characters. This will not import.\n")
  print(Objects.sheet[nchar(name) > 50], 
        row.names = F, 
        n = nrow(Objects.sheet[nchar(name) > 50]))
  sink()
}

# ** check for properties that periods that require non-NA period_type_ids ----
# have only tested a couple of these,
period_id_props = Properties.sheet[grepl("(Hour|Day|Week|Month|Year)$", property)]

period_id_props[, problem := NA]
period_id_props[grepl("Hour$", property) & period_type_id != "6", problem := TRUE]
period_id_props[grepl("Day$", property) & period_type_id != "1", problem := TRUE]
period_id_props[grepl("Week$", property) & period_type_id != "2", problem := TRUE]
period_id_props[grepl("Month$", property) & period_type_id != "3", problem := TRUE]
period_id_props[grepl("Year$", property) & period_type_id != "4", problem := TRUE]

period_id_props = period_id_props[problem == TRUE]

# assuming that all properties that require non-0 period_type_ids follow
# this pattern
problem.rows = period_id_props[grepl("^(Max Energy|Target)", property)]

if (nrow(problem.rows) > 0) {
  sink(fatal.warnings, append = T) 
  cat("\n\n")
  cat(paste0("WARNING: the following property does not correspond to the ",
               "right period_type_id (Hour: 6, Day: 1, Week: 2, Month: 3, Year: 4). ",
               "This will not import.\n"))
  print(problem.rows, row.names = F, n = nrow(problem.rows), width = p.width)
  sink()
}

rm(problem.rows, period_id_props)

# ** check for duplicated objects ----
dupes = duplicated(Objects.sheet, by = c("class", "name"))

if (any(dupes)) {
    sink(fatal.warnings, append = T) 
    cat("\n\n")
    cat(paste0("WARNING: the following obejcts are defined twice. ",
               "This may not import.\n"))
    print(Objects.sheet[dupes], 
          row.names = F, 
          n = nrow(Objects.sheet[dupes]),
          width = p.width)
    sink()
}

rm(dupes)

# ** check for duplicated Properties.sheet definitions (by scenario) ----
dupes = duplicated(Properties.sheet, 
                   by = c("parent_object", "child_object", "parent_class",
                          "child_class", "property", "scenario", 
                          "band_id", "pattern", "date_from", "date_to"))

if (any(dupes)) {
  sink(fatal.warnings, append = T) 
  cat("\n\n")
  cat(paste0("WARNING: the following properties are defined twice for ", 
               "the same object in the same scenario. This may import but ",
               "will not run.\n"))
  print(Properties.sheet[dupes], 
        row.names = F, 
        n = nrow(Properties.sheet[dupes]))
  sink()
}

rm(dupes)

# ** check for duplicated Memberships.sheet definitions ----
dupes = duplicated(Memberships.sheet, 
                   by = c("parent_object", "child_object", "collection", 
                          "parent_object", "child_object"))

if (any(dupes)) {
    sink(fatal.warnings, append = T) 
    cat("\n\n")
    cat(paste0("WARNING: the following memberships are defined twice for ", 
               "the same objects. This may import but may not run.\n"))
    print(Memberships.sheet[dupes], 
          row.names = F, 
          n = nrow(Memberships.sheet[dupes]))
    sink()
}

rm(dupes)

# ** check for duplicated Attributes.sheet definitions ----
dupes = duplicated(Attributes.sheet, 
                   by = c("name", "class", "attribute"))

if (any(dupes)) {
    sink(fatal.warnings, append = T) 
    cat("\n\n")
    cat(paste0("WARNING: the following properties are defined twice for ", 
               "the same object in the same scenario. This may import but ",
               "may not run.\n"))
    print(Attributes.sheet[dupes], 
          row.names = F, 
          n = nrow(Attributes.sheet[dupes]))
    sink()
}

rm(dupes)

# ** check for duplicated Reports.sheet definitions ----
dupes = duplicated(Reports.sheet, 
                   by = c("object", "parent_class", "child_class",
                          "collection", "property", "phase_id"))

if (any(dupes)) {
    sink(fatal.warnings, append = T) 
    cat("\n\n")
    cat(paste0("WARNING: the following report properties are defined twice for ", 
               "the same report object for the same phase_id. This may import but ",
               "may not run.\n"))
    print(Reports.sheet[dupes], 
          row.names = F, 
          n = nrow(Reports.sheet[dupes]))
    sink()
}

rm(dupes)

# ** make sure that all child objects in Properties.sheet exist as objects ----
object.list = unique(Properties.sheet[,.(child_class, child_object)])

object.list <- merge(Objects.sheet[,.(obj.id = 1:.N, 
                                      child_class = class, 
                                      child_object = name)],
                     object.list,
                     all.y = TRUE)

object.list = object.list[is.na(obj.id), .(child_class, child_object)]

if (object.list[,.N] > 0) {
    
    to.print <- merge(Properties.sheet, 
                      object.list, 
                      by = c("child_class", "child_object"))
    
    sink(fatal.warnings, append = T) 
    cat("\n\n")
    cat(paste0("WARNING: the following child_object(s) have defined properties ",
               "but are not defined in Objects.sheet. This may result in PLEXOS",
               " assigning these properties to other object. This may not run.\n"))
    print(to.print, 
          row.names = F, 
          n = nrow(to.print))
    sink()
    
    rm(to.print)
}

rm(object.list)

# ** make sure that all parent objects in Properties.sheet exist as objects ----
object.list = unique(Properties.sheet[parent_object != "System",
                                      .(parent_class, parent_object)])

object.list <- merge(Objects.sheet[,.(obj.id = 1:.N, 
                                      parent_class = class, 
                                      parent_object = name)],
                     object.list,
                     all.y = TRUE)

object.list = object.list[is.na(obj.id), .(parent_class, parent_object)]

if (object.list[,.N] > 0) {
    
    to.print <- merge(Properties.sheet, 
                      object.list, 
                      by = c("parent_class", "parent_object"))
    
    sink(fatal.warnings, append = T) 
    cat("\n\n")
    cat(paste0("WARNING: the following parent object(s) have defined properties ",
               "but are not defined in Objects.sheet. This may result in PLEXOS",
               " assigning these properties to other object. This may not run.\n"))
    print(to.print, 
          row.names = F, 
          n = nrow(to.print))
    sink()
    
    rm(to.print)
}

rm(object.list)

# ** make sure that all objects in Memberships.sheet exist as objects ----
object.list = unique(rbind(Memberships.sheet[,.(class = child_class, 
                                                name = child_object)], 
                           Memberships.sheet[,.(class = parent_class, 
                                                name = parent_object)]))

object.list <- merge(Objects.sheet[,.(obj.id = 1:.N, class, name)],
                     object.list,
                     all.y = TRUE)

object.list = object.list[is.na(obj.id), .(class, name)]

if (object.list[,.N] > 0) {
    
    to.print <- rbind(merge(Memberships.sheet, 
                            object.list[,.(parent_class = class, 
                                           parent_object = name)], 
                            by = c("parent_class", "parent_object")), 
                      merge(Memberships.sheet, 
                            object.list[,.(child_class = class, 
                                           child_object = name)], 
                            by = c("child_class", "child_object")))
    
    sink(fatal.warnings, append = T) 
    cat("\n\n")
    cat(paste0("WARNING: the following object(s) have defined memberships but ",
               "are not defined in Objects.sheet. This may not import or run.\n"))
    print(to.print, 
          row.names = F, 
          n = nrow(to.print))
    sink()
    
    rm(to.print)
}

rm(object.list)

# ** make sure that all objects in Attributes.sheet exist as objects ----
object.list = unique(Attributes.sheet[,.(class, name)])

object.list <- merge(Objects.sheet[,.(obj.id = 1:.N, class, name)],
                     object.list,
                     all.y = TRUE)

object.list = object.list[is.na(obj.id), .(class, name)]

if (object.list[,.N] > 0) {
    
    to.print <- merge(Attributes.sheet, 
                      object.list, 
                      by = c("class", "name"))
    
    sink(fatal.warnings, append = T) 
    cat("\n\n")
    cat(paste0("WARNING: the following object(s) have defined attributes but ",
               "are not defined in Objects.sheet. This may result in PLEXOS ",
               "assigning these attributes to other object. This may not run.\n"))
    print(to.print, 
          row.names = F, 
          n = nrow(to.print))
    sink()
    
    rm(to.print)
}

rm(object.list)

# ** make sure that all objects in Reports.sheet exist as objects ----
object.list = Reports.sheet[,unique(object)]

object.list = object.list[!(object.list %in% Objects.sheet[,name])]

if (length(object.list) > 0) {
    sink(fatal.warnings, append = T) 
    cat("\n\n")
    cat(paste0("WARNING: the following report object(s) are present in Reports.sheet but ",
               "are not defined in Objects.sheet. This may not run.\n"))
    print(Reports.sheet[object %in% object.list,], 
          row.names = F, 
          n = nrow(Reports.sheet[object %in% object.list,]))
    sink()
}

rm(object.list)

# ** make sure all scenarios have {Object} in front of them ----
non.object.scens = Properties.sheet[,
                                    !(grepl("^\\{Object\\}", scenario) | is.na(scenario) | scenario == "")]

if (any(non.object.scens)) {
  sink(fatal.warnings, append = T) 
  cat("\n\n")
  cat(paste0("WARNING: the following scenario entries need an object tag ",
               "(i.e. '{Object}Scenario A' instead of 'Scenario A' This will",
               " not be read correctly by PLEXOS.\n"))
  print(Properties.sheet[non.object.scens], 
        row.names = F, 
        n = nrow(Properties.sheet[non.object.scens]))
  sink()
}

rm(non.object.scens)

# ** make sure all data files have either slashes or {Object} ----
non.object.dfs = Properties.sheet[, !(grepl("^\\{Object\\}", filename) | 
                                          is.na(filename) | 
                                          grepl("[/\\\\]", filename))]

if (any(non.object.dfs)) {
  sink(fatal.warnings, append = T) 
  cat("\n\n")
  cat(paste0("WARNING: the following datafile entries do not appear to be ",
             "file paths and so need object tags (i.e. '{Object}datafile A' ",
             "instead of 'datafile A' This will not be read correctly by ",
             "PLEXOS. (note: if these are actually file paths and contain no ",
             "slashes, you can ignore this message)\n"))
  print(Properties.sheet[non.object.dfs], 
        row.names = F,
        n = nrow(Properties.sheet[non.object.dfs]))
  sink()
}

rm(non.object.dfs)

# ** make sure all variables have {Object} in front of them ----
non.object.vars = Properties.sheet[,!(grepl("^\\{Object\\}", variable) | 
                                          is.na(variable) | 
                                          variable == "")]

if (any(non.object.vars)) {
    sink(fatal.warnings, append = T) 
    cat("\n\n")
    cat(paste0("WARNING: the following variable entries need an object tag ",
               "(i.e. '{Object}Variable A' instead of 'Variable A' This will",
               " not be read correctly by PLEXOS.\n"))
    print(Properties.sheet[non.object.vars], 
          row.names = F, 
          n = nrow(Properties.sheet[non.object.vars]), 
          width = p.width)
    sink()
}

rm(non.object.vars)

# ** make sure scenario objects in Properties.sheet exist as objects ----
object.scens <- Properties.sheet[, unique(scenario)]
object.scens <- object.scens[grepl("^\\{Object\\}", object.scens)]
object.scens <- gsub("\\{Object\\}", "", object.scens)

object.scens <- object.scens[!(object.scens %in% Objects.sheet[,name])]

if (length(object.scens) > 0) {
    sink(fatal.warnings, append = T) 
    cat("\n\n")
    cat(paste0("WARNING: the following scenarios(s) are tagged in  properties but ",
               "are not defined in Objects.sheet. This may not import.\n"))
    print(Properties.sheet[scenario %in% paste0("{Object}", object.scens)], 
          row.names = F, 
          n = nrow(Properties.sheet[scenario %in% paste0("{Object}", object.scens),]))
    sink()
}

rm(object.scens)

# ** make sure datafile objects in Properties.sheet exist as objects ----
object.dfs <- Properties.sheet[, unique(filename)]
object.dfs <- object.dfs[grepl("^\\{Object\\}", object.dfs)]
object.dfs <- gsub("\\{Object\\}", "", object.dfs)

object.dfs <- object.dfs[!(object.dfs %in% Objects.sheet[,name])]

if (length(object.dfs) > 0) {
    sink(fatal.warnings, append = T) 
    cat("\n\n")
    cat(paste0("WARNING: the following datafile object(s) are tagged in  properties but ",
               "are not defined in Objects.sheet. This may not import.\n"))
    print(Properties.sheet[filename %in% paste0("{Object}", object.dfs)], 
          row.names = F, 
          n = nrow(Properties.sheet[filename %in% paste0("{Object}", object.dfs),]))
    sink()
}

rm(object.dfs)

# ** make sure variable objects in Properties.sheet exist as objects ----
colname <- ifelse(plexos.version == 7, "variable", "escalator")

object.vars <- Properties.sheet[, unique(get(colname))]
object.vars <- object.vars[grepl("^\\{Object\\}", object.vars)]
object.vars <- gsub("\\{Object\\}", "", object.vars)

object.vars <- object.vars[!(object.vars %in% Objects.sheet[,name])]

if (length(object.vars) > 0) {
    sink(fatal.warnings, append = T) 
    cat("\n\n")
    cat(paste0("WARNING: the following ", colname, "(s) are tagged in  properties ",
               "but are not defined in Objects.sheet. This may not import.\n"))
    print(Properties.sheet[get(colname) %in% paste0("{Object}", object.vars)], 
          row.names = F, 
          n = nrow(Properties.sheet[get(colname) %in% paste0("{Object}", object.vars)]))
    sink()
}

rm(object.vars, colname)

# ** make sure no value is non-numeric ----
nonnum.value = suppressWarnings(Properties.sheet[,is.na(as.numeric(value))])

if (any(nonnum.value)) {
  sink(fatal.warnings, append = T) 
  cat("\n\n")
  cat(paste0("WARNING: the following Properties.sheet rows have non-numeric ",
             "'value' entries. This will not import.\n"))
  print(Properties.sheet[nonnum.value], 
        row.names = F,
        n = nrow(Properties.sheet[nonnum.value]))
  sink()
}

rm(nonnum.value)

# ** generate warnings and save .csv files for missing data ----
for(item in missing.items.list){
  if(nrow(get(item)) > 0){
    write.csv(get(item), 
              file = file.path(data.check.dir,paste0(item,".csv")),
              row.names = F, quote = F)
    
    object.name <- names(get(item))[1]
    missing.data <- names(get(item))[2]
    
    if("Fatal" %in% names(get(item))){
    sink(fatal.warnings, append = T) 
    } else{sink(warnings, append = T) }
    
    cat("\n\n")
    cat(sprintf("WARNING: At least one %s ", object.name))
    cat(sprintf("is missing %s.\n", missing.data))
    cat(sprintf("See file %s/%s.csv", data.check.dir, item))
    sink()
  }
}

#------------------------------------------------------------------------------|
# write out warnings ----
#------------------------------------------------------------------------------|

# show data check reports 
if(data.check.plots == TRUE){
    file.show(db.summary)
}
    
if(length(readLines(warnings, warn = F)) > 1){
    file.show(warnings)
}

if(length(readLines(fatal.warnings, warn = F)) > 1){
    file.show(fatal.warnings)
}


