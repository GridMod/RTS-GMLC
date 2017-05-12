**The workflow for creating the PLEXOS database is as follows:**

1.	Source parse_rts.R in the 1-parse-SourceData directory. This file will import data from the SourceData folder (and the other_inputs folder) and then write files out into the outputs subfolder which are used in the next step. parse_rts.R should not have to be edited, unless additional PLEXOS properties or objects are desired.
2.	Source run_PSSE2PLEXOS.R in the 2-create-excel directory. This file calls input_params.R and then create_plexos_db_from_raw_master_script.R. Input_params.R specifies what property files should be read in from the outputs subfolder in the previous step and if those properties should have scenarios, datafiles, etc. It is where the PLEXOS properties get specified. Create_plexos_db_from_raw_master_script.R is part of the PSSE2PLEXOS submodule and is the master script to create the PLEXOS database in .xlsx format. 

Steps 1 and 2 can both be accomplished by instead executing an R script (Create_RTS_spreadsheet.R) from the command line by calling the Rscript executable in the 'bin' directory. The command will look something like the following, executed from the directory in which Create_RTS_spreadsheet.R lives:

    $ C:/users/USERNAME/Documents/R/R-3.3.3/bin/Rscript.exe create_RTS_spreadsheet.R

3.	Import the .xlsx database into PLEXOS with the import tool. 

4.  IMPORTANT STEP: Then, manually switch the Base Unit System from Metric to Imperial (bottom left corner in Settings).

**The workflow for creating a MAGMA HTML PLEXOS run report is as follows:**

1.	Specify input data in input_data_rts.csv and ensure generators are mapped to region and zone correctly in gen_name_mapping_rts.csv. Generation type can also be specified by generator here, otherwise the PLEXOS categories in the database will be used by default.
2.	Make sure all file paths and options in the top section of run_html_output.R are correct. Source run_html_output.R to create HTML report in desired location.
