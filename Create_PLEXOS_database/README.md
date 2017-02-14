This is a self-contained set of scripts and csvs that makes a plexos database from the data we have for the RTS 2016. Some information about how this works:

1. script in **1-parse-matpower** should be run first. this parses *all* inputfiles, including UW files and the .mpc case, into csvs that can be read by PSSE2PLEXOS
2. script in **2-create-excel** should be run to pull the results of step 1 and spit out an excel file and data_check folder.

That means that all inputs are in **1-parse-matpower/inputs.** Changes in csv files anywhere else will be overwritten next time things are run.

Then, then excel file and data_files folder are all that are needed to create a plexos database.

### notes about subfolders

**1-parse-matpower**: run `parse-matpower.R.` This will parse what's in the .m file and call `create_other_inputs_rts2016.R,` which adds in information that is not in the m file. Those scripts use the **inputs** folder and dump all results into **outputs**

**2-create-excel**: run `run_PSSE2PLEXOS.R`. This requires a pointer to the location of the `PSSE2PLEXOS` repo somewhere on your computer. This repo should be on the `psse2plx_data_check` branch. Adjusting `input_params.R` if needed, then running `run_PSSE2PLEXOS.R` will spit out the excel file and data_checks folder one level up.