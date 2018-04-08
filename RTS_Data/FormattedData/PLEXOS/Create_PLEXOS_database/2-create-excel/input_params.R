#------------------------------------------------------------------------------|
# input file parameters ----
#------------------------------------------------------------------------------|
# For information about the contents and required format of these input files, 
# see PIDG README

# create objects
objects.list <- list(
    "node.data.csv",
    "line.data.csv",
    "generator.data.csv",
    "fuel.data.csv",
    "region.data.csv",
    "zone.data.csv"
)

# add memberships between objects
memberships.list <- list(
)

# add properties to objects. 
object.property.list <- list(
    
    # load
    list("region.load.da.csv",
         list(datafile.col = "Load",
              scenario.name = "Load: DA")),
    list("region.load.rt.csv",
         list(datafile.col = "Load",
              scenario.name = "Load: RT")),
    "node.lpf.csv",
    
    # VG and hydro generator profiles
    list("gen.da.vg.csv",
         list(datafile.col = "Rating",
              scenario.name = "RE: DA")),    
    list("gen.rt.vg.csv",
         list(datafile.col = "Rating",
              scenario.name = "RE: RT")),    
    list("gen.da.vg.fixed.csv",
         list(datafile.col = "Fixed Load",
              scenario.name = "RE: DA")),
    list("gen.rt.vg.fixed.csv",
         list(datafile.col = "Fixed Load",
              scenario.name = "RE: RT")),
    list("storage.csp.csv",
         list(datafile.col = "Natural Inflow",
              scenario.name = "RE: DA")),
    list("storage.props.csv"),
    list("storage.props.rt.csv",
         list(scenario.name = "RT Run")),
    
    # generator properties
    list("gen.outages.csv", 
         list(scenario.name = "Gen Outages")),
    list("gen.cost.data.base.csv"),
    list("gen.cost.data.csv",
         list(band.col = "Band")),    
    
    # reserve profiles
    list("reserve.provisions.csv",
         list(datafile.col = 'Min Provision')),
    list("reserve.provisions.rt.csv",
         list(datafile.col = 'Min Provision',
              scenario.name = 'RT Run'))

)

# reserves - keep for now
reserve.files <- list(
  reserves = 'reserve.data.csv',
  reserve.generators = 'reserve.generators.csv',
  reserve.regions = 'reserve.regions.csv'
)

# define as many files as needed for generic imports
generic.import.files <- c(
    "STSched_MTSched_Perf_Transm_Prod.csv",
    "import_report.csv",
    "storage_objs_csp.csv"
)

# compact generic files format (different file for each object type)
compact.generic.import.files <- list(
    c("import_models.csv", "model"),
    c("import_horizons.csv", "horizon")
)

# pass any interleaved models here to create DA->RT file pointers
interleave.models.list <- list(
    list('da_rt.csv',
         template.fuel = 'da_rt_filepointer_template.csv',
         interleave = FALSE)
)


