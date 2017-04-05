
SourceData = normalizePath(file.path('../../../SourceData/'))

source('1-parse-matpower/parse_matpower.R')
setwd('../2-create-excel')
source('run_PSSE2PLEXOS.R')
setwd('..')
