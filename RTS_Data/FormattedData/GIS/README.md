# Workflow for Creating a QGIS Project from Source Files
This script converts the raw CSV files into a set of geojson files for visualization.
A QGIS 3 project file, RTS-GMLC.qgs is also included.

## Requirements
This script requires Python 3.7 with the following packages
1. json
2. geojon
3. pandas
4. numpy

## Running
The script is run from this subdirectory with no arguments:
`python csv2geojson.py`

By default the script will add a random offset to each generator for ease of visualization. 
To keep generators at their bus locations, change `d = 0.1` to `d = 0.0`

## Outputs
This will produce a set of geojson files
1. bus.csv: Point layer with bus data
2. branch.csv: LineString layer with branch data
3. gen.csv: Point layer with generator data
4. gen_conn.csv: LineString layer with duplicate of generator data. 
   Connects generator locations to their repspective buses.

