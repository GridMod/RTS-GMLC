
library(rplexos)
library(reshape2)

db = plexos_open(list.files(pattern = "\\.db$"))

commitment = query_interval(db, 'Generator', 'Units Generating')
generation = query_interval(db, 'Generator', 'Generation')

commitment = dcast(commitment, time~name, value.var='value')
generation = dcast(generation, time~name, value.var='value')

write.csv(commitment, 'PLEXOS_RT_solution_commitment.csv', row.names = FALSE)
write.csv(generation, 'PLEXOS_RT_solution_generation.csv', row.names = FALSE)