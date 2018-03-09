import sys
import os
from datetime import datetime, timedelta
import pandas as pd
import math

from collections import namedtuple

copper_sheet = True

if len(sys.argv) > 1:
    if sys.argv[1] == "output-network":
        print("Generating template with transmission network")
        copper_sheet=False
    else:
        print("Unknown argument=%s specified - ignored" % sys.argv[1])

Generator = namedtuple('Generator',
                       ['ID', # integer 
                        'Bus',
                        'UnitGroup',
                        'UnitType',
                        'Fuel',
                        'MinPower',
                        'MaxPower',
                        'MinDownTime',
                        'MinUpTime',
                        'RampRate',         # units are MW/minute
                        'StartTimeCold',    # units are hours
                        'StartTimeWarm',    # units are hours
                        'StartTimeHot',     # units are hours
                        'StartCostCold',    # units are MBTU 
                        'StartCostWarm',    # units are MBTU
                        'StartCostHot',     # units are MBTU
                        'NonFuelStartCost', # units are $
                        'FuelPrice',        # units are $ / MMBTU
                        'OutputPct0',  
                        'OutputPct1',
                        'OutputPct2',
                        'OutputPct3',
                        'HeatRateAvg0',
                        'HeatRateIncr1',
                        'HeatRateIncr2',
                        'HeatRateIncr3'],
                       verbose=False)

Bus = namedtuple('Bus',
                 ['ID', # integer
                  'Name',
                  'BaseKV',
                  'Type',
                  'MWLoad',
                  'Area',
                  'SubArea',
                  'Zone',
                  'Lat',
                  'Long'],
                 verbose=False)

Branch = namedtuple('Branch',
                    ['ID',
                     'FromBus',
                     'ToBus',
                     'R',
                     'X', # csv file is in PU, multiple by 100 to make consistent with MW
                     'B', 
                     'ContRating'],
                    verbose=False)

TimeSeriesPointer = namedtuple('TimeSeriesPointer',
                               ['Object',
                                'Simulation',
                                'Parameter',
                                'DataFile'],
                               verbose=False)

DateTimeValue = namedtuple('DateTimeValue',
                           ['DateTime', 'Value'],
                           verbose=False)

Load = namedtuple('Load',
                  ['DateTime',
                   'Area1',
                   'Area2',
                   'Area3'],
                  verbose=False)

generator_dict = {} # keys are ID
bus_dict = {} # keys are ID
branch_dict = {} # keys are ID
timeseries_pointer_dict = {} # keys are (ID, simulation-type) pairs

generator_df = pd.read_table("gen.csv", header=0, sep=',')
bus_df = pd.read_table("bus.csv", header=0, sep=',')
branch_df = pd.read_table("branch.csv", header=0, sep=',')
timeseries_pointer_df = pd.read_table("timeseries_pointers.csv", header=0, sep=',')

for generator_index in generator_df.index.tolist():
    this_generator_dict = generator_df.loc[generator_index].to_dict()
    new_generator = Generator(this_generator_dict["GEN UID"],
                              int(this_generator_dict["Bus ID"]),
                              this_generator_dict["Unit Group"],
                              this_generator_dict["Unit Type"],
                              this_generator_dict["Fuel"],
                              float(this_generator_dict["PMin MW"]),
                              float(this_generator_dict["PMax MW"]),
                              # per Brendan, PLEXOS takes the ceiling at hourly resolution for up and down times.
                              int(math.ceil(this_generator_dict["Min Down Time Hr"])),
                              int(math.ceil(this_generator_dict["Min Up Time Hr"])),
                              this_generator_dict["Ramp Rate MW/Min"],
                              int(this_generator_dict["Start Time Cold Hr"]),
                              int(this_generator_dict["Start Time Warm Hr"]),
                              int(this_generator_dict["Start Time Hot Hr"]),
                              float(this_generator_dict["Start Heat Cold MBTU"]),
                              float(this_generator_dict["Start Heat Warm MBTU"]),                                    
                              float(this_generator_dict["Start Heat Hot MBTU"]),
                              float(this_generator_dict["Non Fuel Start Cost $"]),
                              float(this_generator_dict["Fuel Price $/MMBTU"]),
                              float(this_generator_dict["Output_pct_0"]),
                              float(this_generator_dict["Output_pct_1"]),
                              float(this_generator_dict["Output_pct_2"]),
                              float(this_generator_dict["Output_pct_3"]),
                              float(this_generator_dict["HR_avg_0"]),
                              float(this_generator_dict["HR_incr_1"]),
                              float(this_generator_dict["HR_incr_2"]),
                              float(this_generator_dict["HR_incr_3"]))
    
    generator_dict[new_generator.ID] = new_generator

bus_id_to_name_dict = {}

for bus_index in bus_df.index.tolist():
    this_bus_dict = bus_df.loc[bus_index].to_dict()
    new_bus = Bus(int(this_bus_dict["Bus ID"]),
                  this_bus_dict["Bus Name"],
                  this_bus_dict["BaseKV"],
                  this_bus_dict["Bus Type"],
                  float(this_bus_dict["MW Load"]),
                  int(this_bus_dict["Area"]),
                  int(this_bus_dict["Sub Area"]),
                  this_bus_dict["Zone"],
                  this_bus_dict["lat"],
                  this_bus_dict["lng"])
    bus_dict[new_bus.Name] = new_bus
    bus_id_to_name_dict[new_bus.ID] = new_bus.Name

# compute aggregate load per area, and then compute 
# load participation factors from each bus from that data.
region_total_load = {}
for this_region in range(1,4):
    this_region_total_load = 0.0
    for bus_name, bus_spec in bus_dict.items():
        if bus_spec.Area == this_region:
            this_region_total_load += bus_spec.MWLoad
    region_total_load[this_region] = this_region_total_load

bus_load_participation_factor_dict = {}

for bus_name, bus_spec in bus_dict.items():
    bus_load_participation_factor_dict[bus_name] = bus_spec.MWLoad / region_total_load[bus_spec.Area]

for branch_index in branch_df.index.tolist():
    this_branch_dict = branch_df.loc[branch_index].to_dict()
    new_branch = Branch(this_branch_dict["UID"],
                        this_branch_dict["From Bus"],
                        this_branch_dict["To Bus"],
                        float(this_branch_dict["R"]),
                        float(this_branch_dict["X"]) / 100.0, # nix per unit
                        float(this_branch_dict["B"]),
                        float(this_branch_dict["Cont Rating"]))
    branch_dict[new_branch.ID] = new_branch

for timeseries_pointer_index in timeseries_pointer_df.index.tolist():
    this_timeseries_pointer_dict = timeseries_pointer_df.loc[timeseries_pointer_index].to_dict()
    new_timeseries_pointer = TimeSeriesPointer(this_timeseries_pointer_dict["Object"],
                                               this_timeseries_pointer_dict["Simulation"],
                                               this_timeseries_pointer_dict["Parameter"],
                                               this_timeseries_pointer_dict["Data File"])

    timeseries_pointer_dict[(new_timeseries_pointer.Object, new_timeseries_pointer.Simulation)] = new_timeseries_pointer

target_year = 2020
target_month = 7
target_day = 12

target_datetime = datetime(target_year, target_month, target_day)
target_plus_one_datetime = target_datetime + timedelta(days=2)

filtered_timeseries = {} # maps renewables generator ID to list of DateTimeValue tuples

for gen_name, gen_spec in generator_dict.items():
    if gen_spec.Fuel == "Solar" or gen_spec.Fuel == "Wind" or gen_spec.Fuel == "Hydro":
        if (gen_spec.ID, "DAY_AHEAD") not in timeseries_pointer_dict:
            print("***WARNING - No timeseries pointer entry found for generator=%s" % gen_spec.ID)
        else:
            print("Time series for generator=%s will be loaded from file=%s" % (gen_spec.ID, timeseries_pointer_dict[(gen_spec.ID,"DAY_AHEAD")].DataFile))
            renewables_timeseries_df = pd.read_table(timeseries_pointer_dict[(gen_spec.ID,"DAY_AHEAD")].DataFile, 
                                                     header=0, 
                                                     sep=',', 
                                                     parse_dates=[[0, 1, 2, 3]],
                                                     date_parser=lambda *columns: datetime(*map(int,columns[0:3]), int(columns[3])-1))
            this_source_timeseries_df = renewables_timeseries_df.loc[:,["Year_Month_Day_Period", gen_spec.ID]]
            this_source_timeseries_df = this_source_timeseries_df.rename(columns = {"Year_Month_Day_Period" : "DateTime"})

            start_mask = this_source_timeseries_df["DateTime"] >= target_datetime
            end_mask = this_source_timeseries_df["DateTime"] < target_plus_one_datetime
            this_source_masked_timeseries_df = this_source_timeseries_df[start_mask & end_mask]

            renewables_timeseries_dict = this_source_masked_timeseries_df.to_dict(orient='split')
            renewables_timeseries = []
            for this_row in renewables_timeseries_dict["data"]:
                renewables_timeseries.append(DateTimeValue(this_row[0],
                                                           float(this_row[1])))
            filtered_timeseries[gen_spec.ID] = renewables_timeseries

load_timeseries_spec = timeseries_pointer_dict[("Load","DAY_AHEAD")]
load_timeseries_df = pd.read_table(load_timeseries_spec.DataFile, 
                                   header=0, 
                                   sep=',', 
                                   parse_dates=[[0, 1, 2, 3]],
                                   date_parser=lambda *columns: datetime(*map(int,columns[0:3]), int(columns[3])-1))
load_timeseries_df = load_timeseries_df.rename(columns = {"Year_Month_Day_Period" : "DateTime"})
start_mask = load_timeseries_df["DateTime"] >= target_datetime
end_mask = load_timeseries_df["DateTime"] < target_plus_one_datetime
masked_load_timeseries_df = load_timeseries_df[start_mask & end_mask]
load_dict = masked_load_timeseries_df.to_dict(orient='split')
load_timeseries = []
for load_row in load_dict["data"]:
    load_timeseries.append(Load(load_row[0],
                                float(load_row[1]),
                                float(load_row[2]),
                                float(load_row[3])))

unit_on_time_df = pd.read_table("../FormattedData/PLEXOS/PLEXOS_Solution/DAY_AHEAD Solution Files/noTX/on_time_7.12.csv",
                                header=0,
                                sep=",")
unit_on_time_df_as_dict = unit_on_time_df.to_dict(orient="split")
unit_on_t0_state_dict = {} 
for i in range(0,len(unit_on_time_df_as_dict["columns"])):
    gen_id = unit_on_time_df_as_dict["columns"][i]
    unit_on_t0_state_dict[gen_id] = int(unit_on_time_df_as_dict["data"][0][i])

print("Writing Prescient template file")

minutes_per_time_period = 60

dat_file = open("rts_gmlc.dat","w")

print("param NumTimePeriods := 48 ;", file=dat_file)
print("", file=dat_file)
print("param TimePeriodLength := 1 ;", file=dat_file)
print("", file=dat_file)
print("set StageSet := Stage_1 Stage_2 ;", file=dat_file)
print("", file=dat_file)
print("set CommitmentTimeInStage[Stage_1] := 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 ;", file=dat_file)
print("", file=dat_file)
print("set CommitmentTimeInStage[Stage_2] := ;", file=dat_file)
print("", file=dat_file)
print("set GenerationTimeInStage[Stage_1] := ;", file=dat_file)
print("", file=dat_file)
print("set GenerationTimeInStage[Stage_2] := 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 ;", file=dat_file)
print("", file=dat_file)

print("set Buses := ", file=dat_file)
if copper_sheet:
    print("CopperSheet", file=dat_file)
else:
    for bus_id in bus_dict.keys():
        print("%s" % bus_id, file=dat_file)
print(";", file=dat_file)

print("", file=dat_file)

print("set TransmissionLines := ", file=dat_file)
if copper_sheet:
    pass
else:
    for branch_id in branch_dict.keys():
        print("%s" % branch_id, file=dat_file)
print(";", file=dat_file)

print("", file=dat_file)

print("param: BusFrom BusTo ThermalLimit Impedence :=", file=dat_file)
if copper_sheet:
    pass
else:
    for branch_id, branch_spec in branch_dict.items():
        print("%15s %15s %15s   %10.8f      %10.8f" % (branch_spec.ID, bus_id_to_name_dict[branch_spec.FromBus], bus_id_to_name_dict[branch_spec.ToBus], branch_spec.ContRating, branch_spec.X), file=dat_file)

print(";", file=dat_file)

print("", file=dat_file)

print("set ThermalGenerators := ", file=dat_file)
for gen_id, gen_spec in generator_dict.items():
    if gen_spec.Fuel == "Oil" or gen_spec.Fuel == "Coal" or gen_spec.Fuel == "NG" or gen_spec.Fuel == "Nuclear":
        print("%s" % gen_id, file=dat_file)
print(";", file=dat_file)

print("", file=dat_file)

if copper_sheet:
    print("set ThermalGeneratorsAtBus[CopperSheet] := ", file=dat_file)
    for gen_id, gen_spec in generator_dict.items():
        if gen_spec.Fuel == "Oil" or gen_spec.Fuel == "Coal" or gen_spec.Fuel == "NG" or gen_spec.Fuel == "Nuclear":
            print("%s" % gen_id, file=dat_file)
    print(";", file=dat_file)
    print("", file=dat_file)
else:
    for bus_name in bus_dict.keys():
        print("set ThermalGeneratorsAtBus[%s] := " % bus_name, file=dat_file)
        for gen_id, gen_spec in generator_dict.items():
            if bus_dict[bus_name].ID == gen_spec.Bus:
                if gen_spec.Fuel == "Oil" or gen_spec.Fuel == "Coal" or gen_spec.Fuel == "NG" or gen_spec.Fuel == "Nuclear":
                    print("%s" % gen_id, file=dat_file)
        print(";", file=dat_file)
        print("", file=dat_file)

print("set NondispatchableGenerators := ", file=dat_file)
for gen_id, gen_spec in generator_dict.items():
    if gen_spec.Fuel == "Solar" or gen_spec.Fuel == "Wind" or gen_spec.Fuel == "Hydro":
        print("%s" % gen_id, file=dat_file)
print(";", file=dat_file)

print("", file=dat_file)

if copper_sheet:
    print("set NondispatchableGeneratorsAtBus[CopperSheet] := ", file=dat_file)
    for gen_id, gen_spec in generator_dict.items():
        if gen_spec.Fuel == "Solar" or gen_spec.Fuel == "Wind" or gen_spec.Fuel == "Hydro":
            print("%s" % gen_id, file=dat_file)
    print(";", file=dat_file)
    print("", file=dat_file)
else:
    for bus_name in bus_dict.keys():
        print("set NondispatchableGeneratorsAtBus[%s] := " % bus_name, file=dat_file)
        for gen_id, gen_spec in generator_dict.items():
            if bus_dict[bus_name].ID == gen_spec.Bus:
                if gen_spec.Fuel == "Solar" or gen_spec.Fuel == "Wind" or gen_spec.Fuel == "Hydro":
                    print("%s" % gen_id, file=dat_file)
        print(";", file=dat_file)
        print("", file=dat_file)

print("param MustRun := ", file=dat_file)
for gen_id, gen_spec in generator_dict.items():
    if gen_spec.Fuel == "Nuclear":
        print("%s 1" % gen_id, file=dat_file)
print(";", file=dat_file)

print("", file=dat_file)

print("param ThermalGeneratorType := ", file=dat_file)
for gen_id, gen_spec in generator_dict.items():
    if gen_spec.Fuel == "Nuclear":
        print("%s N" % gen_id, file=dat_file)
    elif gen_spec.Fuel == "NG":
        print("%s G" % gen_id, file=dat_file)
    elif gen_spec.Fuel == "Oil":
        print("%s O" % gen_id, file=dat_file)
    elif gen_spec.Fuel == "Coal":
        print("%s C" % gen_id, file=dat_file)
    else:
        pass
print(";", file=dat_file)

print("", file=dat_file)

print("param NondispatchableGeneratorType := ", file=dat_file)
for gen_id, gen_spec in generator_dict.items():
    if gen_spec.Fuel == "Wind":
        print("%s W" % gen_id, file=dat_file)
    elif gen_spec.Fuel == "Solar":
        print("%s S" % gen_id, file=dat_file)
    elif gen_spec.Fuel == "Hydro":
        print("%s H" % gen_id, file=dat_file)
    else:
        pass
print(";", file=dat_file)

print("", file=dat_file)

print("param: MinimumPowerOutput MaximumPowerOutput MinimumUpTime MinimumDownTime NominalRampUpLimit NominalRampDownLimit StartupRampLimit ShutdownRampLimit := ", file=dat_file)
for gen_id, gen_spec in generator_dict.items():
    if gen_spec.Fuel == "Oil" or gen_spec.Fuel == "Coal" or gen_spec.Fuel == "NG" or gen_spec.Fuel == "Nuclear":
        print("%15s %10.2f %10.2f %2d %2d %10.2f %10.2f %10.2f %10.2f" % (gen_id, 
                                                                          gen_spec.MinPower,
                                                                          gen_spec.MaxPower,
                                                                          gen_spec.MinUpTime,
                                                                          gen_spec.MinDownTime,
                                                                          gen_spec.RampRate * float(minutes_per_time_period),
                                                                          gen_spec.RampRate * float(minutes_per_time_period),
                                                                          gen_spec.MinPower,
                                                                          gen_spec.MinPower),
              file=dat_file)
print(";", file=dat_file)

print("", file=dat_file)

for gen_id, gen_spec in generator_dict.items():
    if gen_spec.Fuel == "Oil" or gen_spec.Fuel == "Coal" or gen_spec.Fuel == "NG" or gen_spec.Fuel == "Nuclear":
        # per Brenan: the following replicates that in PLEXOS runs of RTS-GMLC
        print("set StartupLags[%s] := %d ;" % (gen_id, gen_spec.MinDownTime), file=dat_file)
        print("set StartupCosts[%s] := %12.2f ;" % (gen_id, gen_spec.StartCostCold * gen_spec.FuelPrice + gen_spec.NonFuelStartCost), file=dat_file)        
print("", file=dat_file)

print("param ShutdownFixedCost := ", file=dat_file)
for gen_id, gen_spec in generator_dict.items():
    if gen_spec.Fuel == "Oil" or gen_spec.Fuel == "Coal" or gen_spec.Fuel == "NG" or gen_spec.Fuel == "Nuclear":
        # per Brenan: the following replicates that in PLEXOS runs of RTS-GMLC
        print("%s %12.2f" % (gen_id, gen_spec.StartCostCold * gen_spec.FuelPrice), file=dat_file)
print(";", file=dat_file)        

print("", file=dat_file)

for gen_id, gen_spec in generator_dict.items():
    if gen_spec.Fuel == "Oil" or gen_spec.Fuel == "Coal" or gen_spec.Fuel == "NG" or gen_spec.Fuel == "Nuclear":
        # Per Brendan, round the power points to the nearest 100kW
        # IMPT: These quantities are MW
        x0 = round(gen_spec.OutputPct0 * gen_spec.MaxPower,1)
        x1 = round(gen_spec.OutputPct1 * gen_spec.MaxPower,1)
        x2 = round(gen_spec.OutputPct2 * gen_spec.MaxPower,1)
        x3 = round(gen_spec.OutputPct3 * gen_spec.MaxPower,1)
        print("set CostPiecewisePoints[%s] := %12.1f %12.1f %12.1f %12.1f ;" % (gen_id, x0, x1, x2, x3),
              file=dat_file)
        # NOTES:
        # 1) Fuel price is in $/MMBTU
        # 2) Heat Rate quantities are in BTU/KWH 
        # 3) 1+2 => need to convert both from BTU->MMBTU and from KWH->MWH
        y0 = gen_spec.FuelPrice * ((gen_spec.HeatRateAvg0 * 1000.0 / 1000000.0) * x0)
        y1 = gen_spec.FuelPrice * (((x1-x0) * (gen_spec.HeatRateIncr1 * 1000.0 / 1000000.0))) + y0
        y2 = gen_spec.FuelPrice * (((x2-x1) * (gen_spec.HeatRateIncr2 * 1000.0 / 1000000.0))) + y1
        y3 = gen_spec.FuelPrice * (((x3-x2) * (gen_spec.HeatRateIncr3 * 1000.0 / 1000000.0))) + y2
        print("set CostPiecewiseValues[%s] := %12.2f %12.2f %12.2f %12.2f ;" % (gen_id, y0, y1, y2, y3),
              file=dat_file)

print("", file=dat_file)

print("param: UnitOnT0State PowerGeneratedT0 :=", file=dat_file)
for gen_id, gen_spec in generator_dict.items():
    if gen_spec.Fuel == "Sync_Cond" or gen_spec.Fuel == "Hydro" or gen_spec.Fuel == "Wind" or gen_spec.Fuel == "Solar":
        continue
    if gen_id not in unit_on_t0_state_dict:
        print("***WARNING - No T0 initial condition found for generator=%s" % gen_id)
        continue
    if unit_on_t0_state_dict[gen_id] < 0:
        power_generated_t0 = 0.0
    else:
        power_generated_t0 = gen_spec.MinPower 
    print("%15s %3d %12.2f" % (gen_id, unit_on_t0_state_dict[gen_id], power_generated_t0),
          file=dat_file)
print(";", file=dat_file)

print("", file=dat_file)

print("param Demand := ", file=dat_file)
if copper_sheet:
    for i in range(1,len(load_timeseries)+1):
        this_load_spec = load_timeseries[i-1]
        print("%15s %2d %12.2f" % ("CopperSheet",
                                   i, 
                                   this_load_spec.Area1 + this_load_spec.Area2 + this_load_spec.Area3),
              file=dat_file)
else:
    for i in range(1,len(load_timeseries)+1):
        this_load_spec = load_timeseries[i-1]
        for bus_name, bus_spec in bus_dict.items():
            this_bus_load = 0.0
            if bus_spec.Area == 1:
                this_bus_load = this_load_spec.Area1
            elif bus_spec.Area == 2:
                this_bus_load = this_load_spec.Area2
            else:
                this_bus_load = this_load_spec.Area3
            this_bus_load *= bus_load_participation_factor_dict[bus_name]
                
            print("%15s %2d %12.2f" % (bus_name,
                                       i, 
                                       this_bus_load),
              file=dat_file)            
print(";", file=dat_file)

print("", file=dat_file)

print("param: MinNondispatchablePower MaxNondispatchablePower := ", file=dat_file)
for gen_name, gen_spec in generator_dict.items():
    if gen_spec.Fuel == "Solar" or gen_spec.Fuel == "Wind" or gen_spec.Fuel == "Hydro":
        if gen_name not in filtered_timeseries:
            print("***WARNING - No time series found for renewable generator=%s" % gen_name)
            continue
        this_timeseries = filtered_timeseries[gen_name]
        for i in range(1, len(this_timeseries)+1):
            data_point = this_timeseries[i-1]
            # both hydro and rooftop PV are must-take
            if gen_spec.UnitType == "HYDRO" or gen_spec.UnitType == "RTPV":
                min_value = data_point.Value
            else:
                min_value = 0.0
            print("%15s %2d %12.2f %12.2f" % (gen_name, i, min_value, data_point.Value),
                  file=dat_file)

print(";", file=dat_file)

print("", file=dat_file)

dat_file.close()

print("Prescient template written to rts_gmlc.dat")

print("")

print("Writing Prescient sources file")

sources_file = open("sources.txt","w")
for gen_id, gen_spec in generator_dict.items():
    if gen_spec.Fuel != "Hydro" and gen_spec.Fuel != "Wind" and gen_spec.Fuel != "Solar":
        continue
    if gen_spec.UnitType == "CSP":
        continue
    source_string = None
    if gen_spec.Fuel == "Hydro":
        source_string = "hydro"
    elif gen_spec.Fuel == "Solar":
        source_string = "solar"
    else:
        source_string = "wind"
    forecasts_actuals_filename = "timeseries_data_files" + os.sep + gen_id + "_forecasts_actuals.csv"
    fraction_nondispatchable = 0.0
    if gen_spec.UnitType == "HYDRO" or gen_spec.UnitType == "RTPV":
        fraction_nondispatchable = 1.0
        
    print("Source(%s," % gen_id, file=sources_file)
    print("source_type=\"%s\"," % source_string, file=sources_file)
    print("forecasts_file=\"%s\"," % forecasts_actuals_filename, file=sources_file)
    print("actuals_file=\"%s\"," % forecasts_actuals_filename, file=sources_file)
    print("is_deterministic=\"%s\"," % "True", file=sources_file)
    print("frac_nondispatch=\"%f\"" % fraction_nondispatchable, file=sources_file)
    print(");", file=sources_file)
    print("", file=sources_file)

if copper_sheet:
    print("Source(CopperSheet,", file=sources_file)
    print("source_type=\"load\",", file=sources_file)
    print("forecasts_file=\"timeseries_data_files/Load_forecasts_actuals.csv\",", file=sources_file)
    print("actuals_file=\"timeseries_data_files/Load_forecasts_actuals.csv\"", file=sources_file)
    print(");", file=sources_file)
else:
    for bus_name, bus_spec in bus_dict.items():
        bus_id = bus_spec.ID
        bus_load_filename_prefix = "Bus_%d_Load_zone%d" % (bus_id, bus_spec.Area)
        print("", file=sources_file)
        print("Source(%s," % bus_name, file=sources_file)
        print("source_type=\"load\",", file=sources_file)
        print("forecasts_file=\"timeseries_data_files/%s_forecasts_actuals.csv\"," % bus_load_filename_prefix, file=sources_file)
        print("actuals_file=\"timeseries_data_files/%s_forecasts_actuals.csv\"" % bus_load_filename_prefix, file=sources_file)        
        print(");", file=sources_file)

sources_file.close()

print("Prescient sources file written to sources.txt")

