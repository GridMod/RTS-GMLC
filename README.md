# RTS-GMLC
Reliability Test System - Grid Modernization Lab Consortium 

### This repository is for the Reliability Test System Grid Modernization Lab Consortium (RTS-GMLC) which is an updated version of the RTS-96 test system. A summary of updates can be found in [GMLC_updates.md](https://github.com/GridMod/RTS-GMLC/blob/master/RTS-GMLC_updates.md).
![RTS-GMLC-layers](https://github.com/GridMod/RTS-GMLC/blob/master/rts_layers.png)

#### The [RTS_Data](https://github.com/GridMod/RTS-GMLC/tree/master/RTS_Data) folder contains data in an open `csv` format, and in grid modeling tool specific formats: 

1. [SourceData](https://github.com/GridMod/RTS-GMLC/tree/master/RTS_Data/SourceData) contains several `csv` files that describe all the RTS-GMLC data.
2. [FormattedData](https://github.com/GridMod/RTS-GMLC/tree/master/RTS_Data/FormattedData) contains folders for each tool specific data format. Currently, [MATPOWER](https://github.com/GridMod/RTS-GMLC/tree/master/RTS_Data/FormattedData/MATPOWER) and [PLEXOS](https://github.com/GridMod/RTS-GMLC/tree/master/RTS_Data/FormattedData/PLEXOS) formatted datasets are included. 
 - Each tool specific folder also cotntains a script that automates the conversion from `SourceData`.
 - Solutions obtained from each tool are contained in the `FormattedData/*tool*/*tool*_Solution` folder.


## Setup
```bash
git clone git@github.com:GridMod/RTS-GMLC.git
cd RTS-GMLC
git submodule init
git submodule update
```

