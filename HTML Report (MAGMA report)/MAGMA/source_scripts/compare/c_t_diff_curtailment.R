# Check if this section was selected to run in the input file
if (curtailment.diff.table) {
# Run the cost query function
curt.diff = tryCatch( curtailment_diff(total.generation, total.avail.cap), error = function(cond) { return('ERROR: curtailment diff function not returning correct results.') })
} else { print('Section not run according to input file.') }

