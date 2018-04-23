# RTS-GMLC updates relative to RTS-96
The Reliability Test System of the Grid Modernization Laboratory Consortium (RTS-GMLC) is based upon the 1979 and 1996 Reliability Test Systems ([RTS-96](http://ieeexplore.ieee.org/document/780914/?arnumber=780914&tag=1)). The RTS-GMLC features several key changes from the RTS-96 to enable simulations of hourly and 5-minute operations for a year:

1. The changes documented in [Hedman et. al](http://ieeexplore.ieee.org/stamp/stamp.jsp?arnumber=4957010) increase the congestion occurrence in economic dispatch problems:

  ***The RTS test system has three zones, distinguished by the hundredth digit in the zone number. 100, 200, and 300 represent the three zones. For example, when bus 13 is mentioned below, it refers to buses 113, 213 and 313.***

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
  3. Reduce the capacity of lines [114-116](https://github.nrel.gov/PCM/RTS-2016/blob/master/nesta_case73_ieee_rts.m#L362), [214-216](https://github.nrel.gov/PCM/RTS-2016/blob/master/nesta_case73_ieee_rts.m#L401), and [314-316](https://github.nrel.gov/PCM/RTS-2016/blob/master/nesta_case73_ieee_rts.m#439) to ```350 MW```, each
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
  3. The changes are summarized here:
  
  | Remove |       |       |      |            | Add    |       |       |     |       |
  |--------|-------|-------|------|------------|--------|-------|-------|-----|-------|
  | Region | BusID | Group | MW   | Type       | Region | BusID | Group | MW  | Type  |
  |   R1     | 107   | U100  | 80   | Oil/Steam  | R1     | 107   | U350  | 350 | GasCC |
  | R1     | 107   | U100  | 80   | Oil/Steam  | R1     | 113   | U55   | 55  | GasCT |
  | R1     | 107   | U100  | 80   | Oil/Steam  | R1     | 113   | U55   | 55  | GasCT |
  | R1     | 113   | U197  | 95.1 | Oil/Steam  | R1     | 113   | U55   | 55  | GasCT |
  | R1     | 113   | U197  | 95.1 | Oil/Steam  | R1     | 113   | U55   | 55  | GasCT |
  | R1     | 113   | U197  | 95.1 | Oil/Steam  | R1     | 118   | U350  | 350 | GasCC |
  | R1     | 115   | U12   | 12   | Oil/Steam  | R1     | 123   | U55   | 55  | GasCT |
  | R1     | 115   | U12   | 12   | Oil/Steam  | R1     | 123   | U55   | 55  | GasCT |
  | R1     | 115   | U12   | 12   | Oil/Steam  | R1     | 123   | U55   | 55  | GasCT |
  | R1     | 118   | U400  | 400  | Nuclear    |        |       |       |     |       |
  | R1     | 123   | U155  | 155  | Coal/Steam |        |       |       |     |       |
  | R2     | 201   | U76   | 76   | Coal/Steam | R2     | 201   | U50   | 50  | Hydro |
  | R2     | 207   | U100  | 80   | Oil/Steam  | R2     | 207   | U55   | 55  | GasCT |
  | R2     | 207   | U100  | 80   | Oil/Steam  | R2     | 207   | U55   | 55  | GasCT |
  | R2     | 207   | U100  | 80   | Oil/Steam  | R2     | 213   | U55   | 55  | GasCT |
  | R2     | 213   | U197  | 95.1 | Oil/Steam  | R2     | 213   | U55   | 55  | GasCT |
  | R2     | 213   | U197  | 95.1 | Oil/Steam  | R2     | 213   | U350  | 350 | GasCC |
  | R2     | 213   | U197  | 95.1 | Oil/Steam  | R2     | 215   | U50   | 50  | Hydro |
  | R2     | 215   | U155  | 155  | Coal/Steam | R2     | 215   | U50   | 50  | Hydro |
  | R2     | 215   | U12   | 12   | Oil/Steam  | R2     | 215   | U50   | 50  | Hydro |
  | R2     | 215   | U12   | 12   | Oil/Steam  | R2     | 215   | U55   | 55  | GasCT |
  | R2     | 215   | U12   | 12   | Oil/Steam  | R2     | 215   | U55   | 55  | GasCT |
  | R2     | 215   | U12   | 12   | Oil/Steam  | R2     | 218   | U350  | 350 | GasCC |
  | R2     | 215   | U12   | 12   | Oil/Steam  | R2     | 221   | U350  | 350 | GasCC |
  | R2     | 218   | U400  | 400  | Nuclear    | R2     | 223   | U55   | 55  | GasCT |
  | R2     | 221   | U400  | 400  | Nuclear    | R2     | 223   | U55   | 55  | GasCT |
  |        |       |       |      |            | R2     | 223   | U55   | 55  | GasCT |
  | R3     | 301   | U76   | 76   | Coal/Steam | R3     | 301   | U55   | 55  | GasCT |
  | R3     | 301   | U76   | 76   | Coal/Steam | R3     | 301   | U55   | 55  | GasCT |
  | R3     | 302   | U76   | 76   | Coal/Steam | R3     | 302   | U55   | 55  | GasCT |
  | R3     | 302   | U76   | 76   | Coal/Steam | R3     | 302   | U55   | 55  | GasCT |
  | R3     | 307   | U100  | 80   | Oil/Steam  | R3     | 307   | U55   | 55  | GasCT |
  | R3     | 307   | U100  | 80   | Oil/Steam  | R3     | 307   | U55   | 55  | GasCT |
  | R3     | 307   | U100  | 80   | Oil/Steam  | R3     | 313   | U350  | 350 | GasCC |
  | R3     | 313   | U197  | 95.1 | Oil/Steam  | R3     | 315   | U55   | 55  | GasCT |
  | R3     | 313   | U197  | 95.1 | Oil/Steam  | R3     | 315   | U55   | 55  | GasCT |
  | R3     | 313   | U197  | 95.1 | Oil/Steam  | R3     | 315   | U55   | 55  | GasCT |
  | R3     | 315   | U155  | 155  | Coal/Steam | R3     | 318   | U350  | 350 | GasCC |
  | R3     | 318   | U400  | 400  | Nuclear    | R3     | 321   | U350  | 350 | GasCC |
  | R3     | 321   | U400  | 400  | Nuclear    | R3     | 322   | U55   | 55  | GasCT |
  | R3     | 322   | U50   | 50   | Hydro      | R3     | 322   | U55   | 55  | GasCT |
  | R3     | 322   | U50   | 50   | Hydro      | R3     | 323   | U350  | 350 | GasCC |
  | R3     | 323   | U155  | 155  | Coal/Steam | R3     | 323   | U350  | 350 | GasCC |
  | R3     | 323   | U155  | 155  | Coal/Steam |        |       |       |     |       |
  | R3     | 323   | U350  | 350  | Coal/Steam |        |       |       |     |       |
  
