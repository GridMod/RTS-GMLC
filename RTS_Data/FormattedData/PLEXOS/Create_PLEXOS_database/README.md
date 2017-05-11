This is a self-contained set of scripts and csvs that makes a plexos database from the data we have for the RTS 2016. Some information about how this works:

The `create_RTS_spreadsheet.R` script performs the following:
1. runs script in **1-parse-SourceData** to parse *all* inputfiles into csvs in the same 'outputs' folder that can be read by PSSE2PLEXOS 
 this script also cleans the **`1-parse-SourceData/outputs** folder and moves all contents to the same 'outputs folder.
2. runs script in **2-create-excel** to pull the results of the previous step and spit out an excel file and data_check folder.

That means that all inputs for step 2 are in **1-parse-SourceData/outputs** Changes in csv files anywhere else will be overwritten next time things are run.

Then, then excel file and data_files folder are all that are needed to create a plexos database.

The command line use of create_RTS_spreadsheet.R is not recommended for debugging, but can be useful for creating the spreadsheet without R:
	> [filepath to R]/bin/Rscript.exe Create_RTS_spreadsheet.R



