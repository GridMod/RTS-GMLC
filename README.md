# RTS-GMLC
Reliability Test System - Grid Modernization Lab Consortium

### This repository is for the Reliability Test System Grid Modernization Lab Consortium (RTS-GMLC) which is an updated version of the RTS-96 test system. A summary of updates can be found [here](https://github.com/GridMod/RTS-GMLC/blob/master/RTS-GMLC_updates.md).
#### The repository has three main sections: 

1. RTS_Data. Contains the MATPOWER caseformat file [RTS.m](https://github.com/GridMod/RTS-GMLC/blob/master/RTS_Data/RTS.m) network data, along with several extra .csv files with timeseries data, fuel price data, and inter-temporal generator parameters.
2. Create_PLEXOS_database. This is a set of scripts, including a git submodule from the PSSE2PLEXOS repository which creates an excel .xlsx file containing data and the proper format to import into PLEXOS as a database. The input data is a combination of a RTS-2016 matpower .m file, updated RTS-2016 data, and additional data for use in PLEXOS simulations.
3.	HTML_Report. This is a set of scripts, including a git submodule from the MAGMA repository which creates plots and an .HTML file containing tables and plots analyzing a PLEXOS solution file. 

**The workflow for creating the PLEXOS database is as follows:**

1.	Source parse_matpower.R in the 1-parse-matpower directory. This file will import data from the inputs subfolder which contains the RTS.m matpower file (RTS-2016 data). Then it calls the create_other_inputs_rts2016.R file.  In this file R will pull data from input csv files in the inputs subfolder as well some updated RTS-2016 data that is manually added for our PLEXOS simulations, and then write files out into the outputs subfolder which are used in the next step. The create_other_inputs_rts2015.R file adds PLEXOS specific properties. Parse_matpower.R should not have to be edited, but create_other_inputs_rts2016.R can be if additional PLEXOs properties or objects are desired.
2.	Source run_PSSE2PLEXOS.R in the 2-create-excel directory. This file calls input_params.R and then create_plexos_db_from_raw_master_script.R. Input_params.R specifies what property files should be read in from the outputs subfolder in the previous step and if those properties should have scenarios, datafiles, etc. It is where the PLEXOS properties get specified. Create_plexos_db_from_raw_master_script.R is part of the PSSE2PLEXOS submodule and is the master script to create the PLEXOS database in .xlsx format. 
3.	Import the .xlsx database into PLEXOS with the import tool. If applicable, then manually switch the Base Unit System from Metric to Imperial (bottom left corner in Settings).

**The workflow for creating a MAGMA HTML PLEXOS run report is as follows:**

1.	Specify input data in input_data_rts.csv and ensure generators are mapped to region and zone correctly in gen_name_mapping_rts.csv. Generation type can also be specified by generator here, otherwise the PLEXOS categories in the database will be used by default.
2.	Make sure all file paths and options in the top section of run_html_output.R are correct. Source run_html_output.R to create HTML report in desired location.
