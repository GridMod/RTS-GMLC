# RTS-GMLC
Reliability Test System - Grid Modernization Lab Consortium 

### This repository is for the Reliability Test System Grid Modernization Lab Consortium (RTS-GMLC) which is an updated version of the RTS-96 test system. A summary of updates can be found in [GMLC_updates.md](https://github.com/GridMod/RTS-GMLC/blob/master/RTS-GMLC_updates.md).
This repository, and the associated data has been developed to facilitate Production Cost Modeling. Reliability calculations using the updated RTS-GMLC data in this repository amd the RTS3 program, provided by [Gene Preston](http:/egpreston.com) can be found [here](http://egpreston.com/NEWRTS.zip).
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

## DATA USE DISCLAIMER AGREEMENT
*(“Agreement”)*

These data (“Data”) are provided by the National Renewable Energy Laboratory (“NREL”), which is operated by Alliance for Sustainable Energy, LLC (“ALLIANCE”) for the U.S. Department Of Energy (“DOE”).

Access to and use of these Data shall impose the following obligations on the user, as set forth in this Agreement.  The user is granted the right, without any fee or cost, to use, copy, and distribute these Data for any purpose whatsoever, provided that this entire notice appears in all copies of the Data.  Further, the user agrees to credit DOE/NREL/ALLIANCE in any publication that results from the use of these Data.  The names DOE/NREL/ALLIANCE, however, may not be used in any advertising or publicity to endorse or promote any products or commercial entities unless specific written permission is obtained from DOE/NREL/ ALLIANCE.  The user also understands that DOE/NREL/Alliance is not obligated to provide the user with any support, consulting, training or assistance of any kind with regard to the use of these Data or to provide the user with any updates, revisions or new versions of these Data.

**YOU AGREE TO INDEMNIFY DOE/NREL/ALLIANCE, AND ITS SUBSIDIARIES, AFFILIATES, OFFICERS, AGENTS, AND EMPLOYEES AGAINST ANY CLAIM OR DEMAND, INCLUDING REASONABLE ATTORNEYS' FEES, RELATED TO YOUR USE OF THESE DATA.  THESE DATA ARE PROVIDED BY DOE/NREL/Alliance "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL DOE/NREL/ALLIANCE BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER, INCLUDING BUT NOT LIMITED TO CLAIMS ASSOCIATED WITH THE LOSS OF DATA OR PROFITS, WHICH MAY RESULT FROM AN ACTION IN CONTRACT, NEGLIGENCE OR OTHER TORTIOUS CLAIM THAT ARISES OUT OF OR IN**

