This directory contains scripts to create template and sources files corresponding to RTS-GMLC for use with the Prescient PCM.

The script is designed to be executed from the RTS_Data/SourceData directory in this repository. 

To execute, simply type "python ../FormattedData/Prescient/topysp.py". Upon completion, you will see the following two files in that directory:
1) rts_gmlc.dat - the Prescient template file.
2) sources.txt - the Prescient sources files.

Add the option "output-network" to generate a non-copper-sheet version of the RTS-GMLC.

To run a generated template file, use the following command line - this will instantiate the model, solve it, and output the basic solution properties:

pyomo --solver=gurobi --stream-solver prescient/models/knueven/ReferenceModel.py rts_gmlc.dat --postprocess=../FormattedData/Prescient/pyomosolprint.py
