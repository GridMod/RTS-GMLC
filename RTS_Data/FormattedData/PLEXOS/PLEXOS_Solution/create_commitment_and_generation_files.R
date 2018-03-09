library(rplexos)
library(reshape2)

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Day ahead run data querying
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ( length(list.files(path = '../', pattern = c("DAY_AHEAD", "\\.db$")))>1 ) {
  message('More than one day ahead solution file found. Please include only the one to generate results for.')
}

db = plexos_open('../Model DAY_AHEAD_NO_TX Solution')
db = db[grep('DAY_AHEAD', db$filename),]
attributes(db)$class = c("rplexos","data.frame","tbl_df")

commitment = query_interval(db, 'Generator', 'Units Generating')
generation = query_interval(db, 'Generator', 'Generation')
cost = query_interval(db, 'Generator', 'Total Generation Cost')
price = query_interval(db, 'Node', 'Price')
flow = query_interval(db, 'Line','Flow')

commitment = dcast(commitment, time~name, value.var='value')
generation = dcast(generation, time~name, value.var='value')
cost = dcast(cost, time~name, value.var='value')
price = dcast(price, time~name, value.var='value')
flow = dcast(flow, time~name, value.var='value')

write.csv(commitment, 'DAY_AHEAD Solution Files/PLEXOS_DA_solution_commitment.csv', row.names = FALSE)
write.csv(generation, 'DAY_AHEAD Solution Files/PLEXOS_DA_solution_generation.csv', row.names = FALSE)
write.csv(cost, 'DAY_AHEAD Solution Files/PLEXOS_DA_solution_cost.csv',row.names = FALSE)
write.csv(price, 'DAY_AHEAD Solution Files/PLEXOS_DA_solution_price.csv', row.names = FALSE)
write.csv(flow, 'DAY_AHEAD Solution Files/PLEXOS_DA_solution_flow.csv', row.names = FALSE)

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Real time run data querying
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ( length(list.files(path = '../', pattern = c("REAL_TIME", "\\.db$")))>1 ) {
  message('More than one real time solution file found. Please include only the one to generate results for.')
}

db = plexos_open('../Model REAL_TIME Solution')
db = db[grep('REAL_TIME', db$filename),]
attributes(db)$class = c("rplexos","data.frame","tbl_df")

commitment = query_interval(db, 'Generator', 'Units Generating')
generation = query_interval(db, 'Generator', 'Generation')
price = query_interval(db, 'Node', 'Price')

commitment = dcast(commitment, time~name, value.var='value')
generation = dcast(generation, time~name, value.var='value')
price = dcast(price, time~name, value.var='value')

write.csv(commitment, 'REAL_TIME Solution Files/PLEXOS_RT_solution_commitment.csv', row.names = FALSE)
write.csv(generation, 'REAL_TIME Solution Files/PLEXOS_RT_solution_generation.csv', row.names = FALSE)
write.csv(price, 'REAL_TIME Solution Files/PLEXOS_RT_solution_price.csv', row.names = FALSE)
