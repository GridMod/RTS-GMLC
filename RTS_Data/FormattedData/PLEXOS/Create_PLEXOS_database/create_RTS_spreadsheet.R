
SourceData = normalizePath(file.path('../../../SourceData/'))
output.dir = normalizePath(file.path('./1-parse-matpower/outputs/'))
source('1-parse-matpower/parse_rts.R')
setwd('2-create-excel')
source('run_PSSE2PLEXOS.R')
setwd('..')
