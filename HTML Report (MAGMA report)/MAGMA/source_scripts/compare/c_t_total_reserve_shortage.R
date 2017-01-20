# Check if this section was selected to run in the input file
if (annual.res.short.table) {
# Run the cost query function
res.short.table = tryCatch( annual_reserves_short(total.reserve.provision, total.reserve.shortage), error = function(cond) { return('ERROR: reserve function not returning correct results.') })
} else { print('Section not run according to input file.') }

