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
    "zone.data.csv",
    "storage.data.csv"
)

# add memberships between objects
memberships.list <- list(
)

# add properties to objects. 
object.property.list <- list(
    
    # load filepointers
    list("region.load.da.csv", datafile.col = c("Load")),
    list("region.load.rt.csv", datafile.col = c("Load")),

    # VG and hydro generator profiles
    list("gen.da.vg.csv", datafile.col = c("Rating")),
    list("gen.rt.vg.csv", datafile.col = c("Rating")),
    list("gen.da.vg.fixed.csv", datafile.col = c("Fixed Load")),
    list("gen.rt.vg.fixed.csv", datafile.col = c("Fixed Load")),
    list("storage.csp.csv", datafile.col = c("Natural Inflow")),

    # generator properties
    "gen.outages.csv",
    "gen.cost.data.base.csv",
    list("gen.cost.data.csv",band.col = c("Band")),
    "storage.props.rt.csv",

    # reserve filepointers
    list("reserve.provisions.csv",datafile.col = c('Min Provision')),
    list("reserve.provisions.rt.csv",datafile.col = c('Min Provision'))

)

# reserves - keep for now
reserve.files <- list(
  reserves = 'reserve.data.csv',
  reserve.generators = 'reserve.generators.csv'
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


