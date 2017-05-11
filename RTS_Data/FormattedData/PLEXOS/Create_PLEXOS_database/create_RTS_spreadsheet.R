if(interactive()){setwd(dirname(parent.frame(2)$ofile))}
source('1-parse-SourceData/parse_rts.R')
setwd('2-create-excel')
source('run_PSSE2PLEXOS.R')
setwd('..')
