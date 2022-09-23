# SourceData

This folder contains six CSV files wit all RTS-GMLC (non-timeseries) data and problem formulation parameters, the contents of each file follow. Timeseries data can be found [here](https://github.com/GridMod/RTS-GMLC/tree/master/RTS_Data/timeseries_data_files).


## `bus.csv`

| Column       | Description                       |
|--------------|-----------------------------------|
| Bus ID       | Numeric Bus ID                    |
| Bus Name     | Bus name from RTS-96              |
| BaseKV       | Bus voltage rating                |
| Bus Type     | Bus control type                  |
| MW Load      | Real power demand                 |
| MVAR Load    | Reactive power demand             |
| V Mag        | Voltage magnitude setpoint        |
| V Angle      | Voltage angle setpoint in degrees |
| MW Shunt G   | Shunt conductance                 |
| MVAR Shunt B | Shunt susceptance                 |
| Area         | Area membership                   |
| Sub Area     | Sub area membership               |
| Zone         | Zone membership                   |
| lat          | Bus latitude location             |
| lng          | Bus longitude location            |


## `branch.csv`

| Column       | Description                           |
|--------------|---------------------------------------|
| ID           | Unique branch ID                      |
| From Bus     | From Bus ID                           |
| To Bus       | To Bus ID                             |
| R            | Branch resistance p.u.                |
| X            | Branch reactance p.u.                 |
| B            | Branch line charging susceptance p.u. |
| Cont Rating  | Continuous MW flow limit              |
| LTE Rating   | Long term MW flow limit               |
| STE Rating   | Short term MW flow limit              |
| Perm OutRate | Outage rate (occ/year)                          |
| Duration     | Mean outage duration (hrs)            |
| Tr Ratio     | Transformer winding ratio             |
| Tran OutRate | Transformer outage rate               |
| Length       | Line length (mi)                      |


## `gen.csv`

| Column                   | Description                                                      |
|--------------------------|------------------------------------------------------------------|
| GEN UID                  | Unique generator ID: Concatenated from Bus ID_Unit Type_Gen ID   |
| Bus ID                   | Connection Bus ID                                                |
| Gen ID                   | Index of generator units at each bus                             |
| Unit Group               | RTS-96 unit group definition                                     |
| Unit Type                | Unit Type                                                        |
| Fuel                     | Unit Fuel                                                        |
| MW Inj                   | Real power injection setpoint                                    |
| MVAR Inj                 | Reactive power injection setpoint                                |
| V Setpoint p.u.          | Voltage magnitude setpoint                                       |
| PMax MW                  | Maximum real power injection (Unit Capacity)                     |
| PMin MW                  | Minimum real power injection (Unit minimum stable level)         |
| QMax MVAR                | Maximum reactive power injection                                 |
| QMin MVAR                | Minimum reactive power injection                                 |
| Min Down Time Hr         | Minimum off time required before unit restart                    |
| Min Up Time Hr           | Minimum on time required before unit shutdown                    |
| Ramp Rate MW/Min         | Maximum ramp up and ramp down rate                               |
| Start Time Cold Hr       | Time since shutdown after which a cold start is required |
| Start Time Hot Hr        | Time since shutdown after which a hot start is required |
| Start Time Warm Hr       | Transition time between hot and cold statuses after a shutdown |
| Start Heat Cold MMBTU     | Heat required to startup from cold in million BTU per startup   |
| Start Heat Hot MMBTU      | Heat required to startup from hot in million BTU per startup    |
| FOR                      | Forced outage rate                                               |
| MTTF Hr                  | Meant time to forced outage                                      |
| MTTR Hr                  | Mean time to repair forced outage                                |
| Scheduled Maint Weeks    | Scheduled outages per year                                       |
| Fuel Price $/MMBTU       | Fuel price in Dollars per million BTU                            |
| Output_pct_0             | Output point 0 on heat rate curve as a percentage of PMax        |
| Output_pct_1             | Output point 1 on heat rate curve as a percentage of PMax        |
| Output_pct_2             | Output point 2 on heat rate curve as a percentage of PMax        |
| Output_pct_3             | Output point 3 on heat rate curve as a percentage of PMax        |
| HR_Avg_0                 | Average heat rate between 0 and output point 0 in BTU/kWh        |
| HR_Incr_1                | Incremental heat rate between output points 0 and 1 in BTU/kWh   |
| HR_Incr_2                | Incremental heat rate between output points 1 and 2 in BTU/kWh   |
| HR_Incr_3                | Incremental heat rate between output points 2 and 3 (PMax) in BTU/kWh           |
| Fuel Sulfur Content %    | Fuel Sulfur Content                                              |
| Emissions SO2 Lbs/MMBTU  | SO2 Emissions Rate                                               |
| Emissions NOX Lbs/MMBTU  | NOX Emissions Rate                                               |
| Emissions Part Lbs/MMBTU | Particulate Matter Emissions Rate                                |
| Emissions CO2 Lbs/MMBTU  | CO2 Emissions Rate                                               |
| Emissions CH4 Lbs/MMBTU  | CH4 Emissions Rate                                               |
| Emissions N2O Lbs/MMBTU  | N2O Emissions Rate                                               |
| Emissions CO Lbs/MMBTU   | CO Emissions Rate                                                |
| Emissions VOCs Lbs/MMBTU | VOC Emissions Rate                                               |
| Damping Ratio            | Damping coefficient of swing equation                            |
| Inertia MJ/MW            | Unit rotor inertia                                               |
| Base MVA                 | Unit equivalent circuit BaseMVA                                  |
| Transformer X p.u.       | Unit transformer reactance p.u.                                  |
| Unit X p.u.              | Unit reactance p.u.                                              |

*Startup Modeling Notes:*
 - Hot/Warm/Cold Startup Times reflect the time from a shutdown event until a hot/warm/cold heat state is reached.
 - Start Heat Hot/Warm/Cold represents the heat input required to startup from a hot/warm/cold heat state.

## `dc_branch.csv`

| Category                     | Variable                                         | Column Name                          |
|------------------------------|--------------------------------------------------|--------------------------------------|
| Branch Topology              | Unique ID                                        | UID                                  |
| Branch Topology              | From Bus ID                                      | From Bus                             |
| Branch Topology              | To Bus ID                                        | To Bus                               |
| Branch Control               | Control mode                                     | Control Mode                         |
| Branch Control               | DC line resistance (ohm):                        | R Line                               |
| Branch Control               | Power demand (MW):                               | MW Load                              |
| Branch Control               | Scheduled DC voltage (kV):                       | V Mag kV                             |
| Branch Control               | Compounding resistance (ohm):                    | R Compound                           |
| Branch Control               | Margin in per unit of desired DC power:          | Margin                               |
| Branch Control               | Metered end:                                     | Metered end                          |
| Branch Control               | Permanent Line Outage Rates (Outages/yr):        | Line FOR Perm                        |
| Branch Control               | Transient Line Outage Rates (Outages/yr):        | Line FOR Trans                       |
| Branch Control               | Permanent Outage Duration (hours):               | MTTR Line Hours                      |
| DC Station                   | Active  failure rate of a breaker (failure/year) | From Station FOR Active              |
| DC Station                   | Passive failure rate of a breaker (failure/year) | From Station FOR Passive             |
| DC Station                   | Maintenance rate of a breaker (outages/year)     | From Station Scheduled Maint Rate    |
| DC Station                   | Maintenance time of a breaker (hours)            | From Station Scheduled Maint Hours   |
| DC Station                   | Switching time - one or more components (hours)  | From Switching Time Hours            |
| DC Station                   | Active  failure rate of a breaker (failure/year) | To Station FOR Active                |
| DC Station                   | Passive failure rate of a breaker (failure/year) | To Station FOR Passive               |
| DC Station                   | Maintenance rate of a breaker (outages/year)     | To Station Scheduled Maint Rate      |
| DC Station                   | Maintenance time of a breaker (hours)            | To Station Scheduled Maint Dur Hours |
| DC Station                   | Switching time - one or more components (hours)  | To Switching Time Hours              |
| DC Branch Capacity           | Prob                                             | Line Outage Prob 0                   |
| DC Branch Capacity           | Prob                                             | Line Outage Prob 1                   |
| DC Branch Capacity           | Prob                                             | Line Outage Prob 2                   |
| DC Branch Capacity           | Prob                                             | Line Outage Prob 3                   |
| DC Branch Capacity           | lambda (event/yr)                                | Line Outage Rate 0                   |
| DC Branch Capacity           | lambda (event/yr)                                | Line Outage Rate 1                   |
| DC Branch Capacity           | lambda (event/yr)                                | Line Outage Rate 2                   |
| DC Branch Capacity           | lambda (event/yr)                                | Line Outage Rate 3                   |
| DC Branch Capacity           | Dur. (hr.)                                       | Line Outage Dur 0                    |
| DC Branch Capacity           | Dur. (hr.)                                       | Line Outage Dur 1                    |
| DC Branch Capacity           | Dur. (hr.)                                       | Line Outage Dur 2                    |
| DC Branch Capacity           | Dur. (hr.)                                       | Line Outage Dur 3                    |
| DC Branch Capacity           | Loading Point 1 for Outage Curve                                         | Line Outage Loading 1                |
| DC Branch Capacity           | Loading Point 2 for Outage Curve                                         | Line Outage Loading 2                |
| DC Branch Capacity           | Loading Point 3 for Outage Curve                                          | Line Outage Loading 3                |
| DC Branch Rectifier Inverter | Number of bridges in series:                     | From Series Bridges                  |
| DC Branch Rectifier Inverter | Nominal maximum firing angle:                    | From Max Firing Angle                |
| DC Branch Rectifier Inverter | Minimum steady state firing angle:               | From Min Firing Angle                |
| DC Branch Rectifier Inverter | Commutating transformer resistance/bridge (ohm): | From R Commutating                   |
| DC Branch Rectifier Inverter | Commutating transformer reactance/bridge (ohm):  | From X Commutating                   |
| DC Branch Rectifier Inverter | Primary base AC voltage (kV):                    | From baseKV                          |
| DC Branch Rectifier Inverter | Transformer ratio:                               | From Tr Ratio                        |
| DC Branch Rectifier Inverter | Tap setting:                                     | From Tap Setpoint                    |
| DC Branch Rectifier Inverter | Max tap setting:                                 | From Tap Max                         |
| DC Branch Rectifier Inverter | Min tap setting:                                 | From Tap Min                         |
| DC Branch Rectifier Inverter | Rectifier tap step:                              | From Tap Step                        |
| DC Branch Rectifier Inverter | Number of bridges in series:                     | To Series Bridges                    |
| DC Branch Rectifier Inverter | Nominal maximum firing angle:                    | To Max Firing Angle                  |
| DC Branch Rectifier Inverter | Minimum steady state firing angle:               | To Min Firing Angle                  |
| DC Branch Rectifier Inverter | Commutating transformer resistance/bridge (ohm): | To R Commutating                     |
| DC Branch Rectifier Inverter | Commutating transformer reactance/bridge (ohm):  | To X Commutating                     |
| DC Branch Rectifier Inverter | Primary base AC voltage (kV):                    | To baseKV                            |
| DC Branch Rectifier Inverter | Transformer ratio:                               | To Tr Ratio                          |
| DC Branch Rectifier Inverter | Tap setting:                                     | To Tap Setpoint                      |
| DC Branch Rectifier Inverter | Max tap setting:                                 | To Tap Max                           |
| DC Branch Rectifier Inverter | Min tap setting:                                 | To Tap Min                           |
| DC Branch Rectifier Inverter | Rectifier tap step:                              | To Tap Step                          |


## `simulation_objects.csv`

| Column                | Description               |
|-----------------------|---------------------------|
| Simulation_Parameters | Simulation parameter name |
| Description           | Description               |


## `timeseries_pointers.csv`

| Column     | Description                                                                                |
|------------|--------------------------------------------------------------------------------------------|
| Simulation | Simulation name                                                                            |
| Object     | Unique generator ID: Concatenated from Bus ID_Unit Type_Gen ID, or other object ID/name    |
| Parameter  | Parameter from gen.csv columns                                                             |
| Data File  | pointer to datafile with timeseries values (must be consistent with simulation resolution) |

## `storage.csv`
| Column          | Description                                     |
|-----------------|-------------------------------------------------|
| GEN UID         | Gen ID associated with storage                  |
| Storage         | Storage object name                             |
| Max Volume GWh  | Energy storage capacity                         |

## `reserves.csv`
| Column              | Description                                     |
|---------------------|-------------------------------------------------|
| Reserve Product     | Reserve product name                            |
| Timeframe (sec)     | Response time to satisfy reserve requirement    |
| Eligible Gen Types  | Parameter from gen.csv columns                  |
