# RTS-GMLC updates relative to RTS-96
The Reliability Test System of the Grid Modernization Laboratory Consoritum (RTS-GMLC) is based upon the 1979 and 1996 Reliaiblity Test Systems ([RTS-96](http://ieeexplore.ieee.org/document/780914/?arnumber=780914&tag=1)). The RTS-GMLC features several key changes from the RTS-96 to enable simulations of hourly and 5-minute operations for a year:

1. The changes documented in [Hedman et. al](http://smartgridcenter.tamu.edu/ratc/web/wp-content/uploads/2014/10/J7.pdf) increase the congestion occurance in economic dispatch problems:

  1. Remove the following transmission lines: [111-113](https://github.nrel.gov/PCM/RTS-2016/blob/master/nesta_case73_ieee_rts.m#L356), [211-213](https://github.nrel.gov/PCM/RTS-2016/blob/master/nesta_case73_ieee_rts.m#L396), and [311-313](https://github.nrel.gov/PCM/RTS-2016/blob/master/nesta_case73_ieee_rts.m#L434)
  2. The bus load for nodes 13, 14, 15 ,19, and 20 should be changed to the following in each region: 

    ```
    Bus		 Pd
    13		 745
    14		 80
    15		 132
    19		 75
    20		 53
    ``` 
  3. Reduce the capcity of lines [114-116](https://github.nrel.gov/PCM/RTS-2016/blob/master/nesta_case73_ieee_rts.m#L362), [214-216](https://github.nrel.gov/PCM/RTS-2016/blob/master/nesta_case73_ieee_rts.m#L401), and [314-316](https://github.nrel.gov/PCM/RTS-2016/blob/master/nesta_case73_ieee_rts.m#439) to ```350 MW```, each
  4. Add the following generating units in each region:
  
    ```
    Bus		Pmax
    1		100 MW
    7		100 MW
    15		100 MW
    15		155 MW
    23		155 MW
    ```
  
2. Generated relative node locations, based upon line distances to enable network geo-location for load, wind, solar, and hydro timeseries data population.
  1. Nominally chose a southwestern U.S. location for data population ![RTS-GMLC](https://github.com/GridMod/RTS-GMLC/blob/master/node_re_basemap.png)
  2. Regional load profile shapes derived from WECC TEPPC 2024 case used for the [LCGS Study](http://www.nrel.gov/docs/fy16osti/64884.pdf) from Arizona Public Service Company (APS), Nevada Energy (NVE), and Los Angeles Division of Water and Power (LADWP) balancing areas.
  3. Wind, Utility PV, Rooftop PV, and Hydro generation profiles were selected from the [LCGS Study](http://www.nrel.gov/docs/fy16osti/64884.pdf) datasets.
  
3. Replaced some Coal and Oil generation in the RTS-96 with NG-CT and NG-CC generators 
  1. Generator operations parameters (Capacity, Min Gen, Ramp Rate, etc.): averages from [LCGS Study](http://www.nrel.gov/docs/fy16osti/64884.pdf)
  2. Startup parameters:[Wartsila](http://www.wartsila.com/energy/learning-center/technical-comparisons/combustion-engine-vs-gas-turbine-startup-time), [Gas Power Journal](http://gastopowerjournal.com/documents/110918_kraftwerkstechnisches_kolloquium_ccpp_as_ideal_so2.pdf), [Siemens](http://www.energy.siemens.com/us/pool/hq/power-generation/power-plants/gas-fired-power-plants/combined-cycle-powerplants/Flexible_future_for_combined_cycle_US.pdf), [GE](https://powergen.gepower.com/services/upgrade-and-life-extension/heavy-duty-gas-turbine-upgrades-f-class/ka26-fast-start.html)
  
