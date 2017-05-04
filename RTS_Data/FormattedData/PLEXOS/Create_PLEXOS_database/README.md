This is a self-contained set of scripts and csvs that makes a plexos database from the data we have for the RTS 2016. Some information about how this works:

The `create_RTS_spreadsheet.R` script performs the following:
1. cleans the `1-parse-SourceData/outputs/` folder
2. copies the `1-parse-SourceDat/extra_inputs/` contents to the `1-parse-SourceData/outputs/` folder
3. runs script in **1-parse-SourceData** tos parses *all* inputfiles into csvs that can be read by PSSE2PLEXOS
4. runs script in **2-create-excel** to pull the results of step 1 and spit out an excel file and data_check folder.

That means that all inputs are in **1-parse-SourceDatar/outputs** Changes in csv files anywhere else will be overwritten next time things are run.

Then, then excel file and data_files folder are all that are needed to create a plexos database.

This command line method is not recommended for debugging
	> [filepath to R]/bin/Rscript.exe Create_RTS_spreadsheet.R



