**The workflow to create the input data for openTEPES based on the RTS-GMLC is as follows:**

1. Run the python script Create_openTEPES_RTS-GMLC.py in the openTEPES directory. This file will import data from the SourceData folder and then write files out into the subfolder *RTS-GMLC*, which are used in the next step. 
2. The files (CSV files) in the subfolder *RTS-GMLC* are in the openTEPES format which are classified between dictionaries and data. Then, the openTEPES should be installed by:
```
pip install openTEPES
```
3. Execute the openTEPES following the instruction (those written in its repository). Give the path of the subfolder *openTEPES* and the CaseName (RTS-GMLC).
4. The solution will be on the subfolder *RTS-GMLC* in CSV and HTML files.
