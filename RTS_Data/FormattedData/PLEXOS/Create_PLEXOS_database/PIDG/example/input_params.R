#------------------------------------------------------------------------------|
# example parameters for test model
#------------------------------------------------------------------------------|

# optional
plexos.version <- 7

# import objects with their categories, memberships, and properties
objects.list <- list(
    "nodes.csv",
    "regions.csv",
    "lines.csv",
    "interfaces.csv",
    list("generators.csv", overwrite = TRUE, overwrite.cols = c(), parent.col = "something", scenario.name = "scenario", scenario.cat = "generic", datafile.col = c("Rating", "Other Rating"), band.col = "band")
)

memberships.list <- list(
    "interface_line_memberships.csv"    # memberhips and, if given, properties
)

object.property.list <- list(
    "min_stable_levels_scenarios.csv",    # simple
    "banded_heat_rates.csv",    # banded, load points
    "min_stable_level"    
    
)

generator.property.by.cat.list <- list(
    list("generation_properties.csv",
         list(),
         list())
)

generic.import.files <- list(
    "simulation_objects.csv",    # requires begin/end tags
    c("reports.csv", "Report")   # alternate method, no begin/end tags
)

compact.generic.import.files <- list(
    c("models", "model")
)