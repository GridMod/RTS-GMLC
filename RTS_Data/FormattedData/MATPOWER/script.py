# coding: utf-8

import os
import pandas as pd
import numpy as np
import calendar as cal

curr_dir = os.path.dirname(os.path.realpath(__file__))


def status_logger(func):

    def replace(*args, **kwargs):
        print('Running {}'.format(func.__name__))
        return func(*args, **kwargs)

    return replace


@status_logger
def create_bus_df(folder):

    buses = []
    with open(os.path.join(folder, 'Table-01.txt')) as input_data:
        # Skips text before the beginning of the interesting block:
        for line in input_data:
            if line.startswith('------------------------'):  # Or whatever test is needed
                break
        # Reads text until the end of the block:
        for line in input_data:  # This keeps reading the file
            if line in ['\n','\r\n']:
                break
            row = line.split()
            buses.append({'Bus ID':int(row[0]),
                                 'Bus Name':row[1],
                                 'Bus Type':int(row[2]),
                                 'MW Load':float(row[3]),
                                 'MVAR Load':float(row[4]),
                                 'GL':float(row[5]),
                                 'BL':float(row[6]),
                                 'Sub Area':float(row[7]),
                                 'BaseKV':float(row[8]),
                                 'Zone':float(row[9])})
    buses = pd.DataFrame(buses)

    return buses


@status_logger
def create_load_data(folder):

    # # Load data

    #read peak weekly Load data from Table-02
    weekly_peak_load = []
    with open(os.path.join(folder, 'Table-02.txt')) as input_data:
        # Skips text before the beginning of the interesting block:
        for line in input_data:
            if line.startswith('Week'):  # Or whatever test is needed
                break
        # Reads text until the end of the block:
        for line in input_data:  # This keeps reading the file
            if line in ['\n','\r\n']:
                continue
            row = line.split()
            weekly_peak_load.append({'week':int(row[0]),
                                 'peak load':float(row[1])})
    weekly_peak_load = pd.DataFrame(weekly_peak_load)


    #read daily load factor from Table-03
    #read peak weekly Load data from Table-02
    daily_peak_load = []
    with open(os.path.join(folder, 'Table-03.txt')) as input_data:
        # Skips text before the beginning of the interesting block:
        for line in input_data:
            if line.startswith('Day'):  # Or whatever test is needed
                break
        # Reads text until the end of the block:
        for line in input_data:  # This keeps reading the file
            if line in ['\n','\r\n']:
                continue
            row = line.split()
            daily_peak_load.append({'day':str(row[0]),
                                 'peak load':float(row[1])})
    daily_peak_load = pd.DataFrame(daily_peak_load)


    #read hourly and seasonal peak load adjustments from Table-04
    hourly_peak_load = []
    with open(os.path.join(folder, 'Table-04.txt')) as input_data:
        # Skips text before the beginning of the interesting block:
        for line in input_data:
            if line.startswith('-------------'):  # Or whatever test is needed
                break
        # Reads text until the end of the block:
        for line in input_data:  # This keeps reading the file
            if line in ['\n','\r\n']:
                continue
            hourly_peak_load.append(line.split())

    hourly_peak_load = pd.DataFrame(hourly_peak_load, columns = ['period',
                                                                      'Winter_Weekday',
                                                                      'Winter_Weekend',
                                                                      'Summer_Weekday',
                                                                      'Summer_Weekend',
                                                                      'Fall_Weekday',
                                                                      'Fall_Weekend'])


    #read bus load data from Table-05
    peak_load = []
    with open(os.path.join( folder, 'Table-05.txt')) as input_data:
        # Skips text before the beginning of the interesting block:
        for line in input_data:
            if line.startswith('-------------'):  # Or whatever test is needed
                break
        # Reads text until the end of the block:
        for line in input_data:  # This keeps reading the file
            if line.startswith('-------------'):
                break
            peak_load.append(line.split())


    peak_load = pd.DataFrame(peak_load, columns=['Area1', 'Area2', 'Area3', 'percent_sysload', 'MWLoad', 'MVarLoad', '_MWLoad', '_MVarLoad'])

    peak_load['MWLoad'] = peak_load['MWLoad'].apply(lambda x: float(x))
    peak_load['MVarLoad'] = peak_load['MVarLoad'].apply(lambda x: float(x))


    # # Generate load profile

    days=["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]

    import datetime


    for year in range(1996, 2016):
        t = datetime.datetime(year, 1, 1, 0)
        dayofweek = days[t.weekday()]


    # hourly_peak_load = hourly_peak_load.to_dict(orient='list')
    # weekly_peak_load = weekly_peak_load.to_dict(orient='list')
    # daily_peak_load = daily_peak_load.to_dict(orient='list')
    # peak_load = peak_load.to_dict(orient='list')


    days


    daily_peak_load_dict = dict()
    for d in daily_peak_load.to_dict(orient='records'):
        daily_peak_load_dict[d['day']] = d['peak load']

    daily_peak_load_dict


    weekly_peak_load_dict = dict()

    for d in weekly_peak_load.to_dict(orient='records'):
        weekly_peak_load_dict[int(d['week'])] = float(d['peak load'])

    weekly_peak_load_dict


    hourly_peak_load_df = hourly_peak_load
    peak_load_df = peak_load


    import datetime
    t = datetime.datetime(1996, 1, 1, 0)

    total_load = []
    for i in range(0, 8760):

        dayofweek = days[t.weekday()]

        if dayofweek <= 5:
            day='Weekday'
        else:
            day='Weekend'

        week = int(datetime.datetime.strftime(t,'%W'))

        if week > 52:
            week = 52

        if week <= 8 or week > 44:
            season = 'Winter'
        if week >= 18 and week <= 30:
            season = 'Summer'
        else:
            season = 'Fall'

        load = []
        for i, area in enumerate(peak_load_df['Area1']):
            load.append( float( hourly_peak_load_df['{}_{}'.format(season, day)][t.hour] ) / 100
                        * float( daily_peak_load_dict[dayofweek] ) / 100
                        * float( weekly_peak_load_dict[week] ) / 100
                        * float( peak_load_df['MWLoad'][i] ))


        total_load.append(load)
        t= t + datetime.timedelta(hours=1)


    total_load = pd.concat([pd.DataFrame(total_load, columns=peak_load['Area1']),
                               pd.DataFrame(total_load, columns=peak_load['Area2']),
                               pd.DataFrame(total_load, columns=peak_load['Area3'])], axis=1)


    # reformat for plexos input
    # need YEAR, MONTH, DAY, Period columns, where all are integers and DAY is day of the month and Period is hour of the day

    year = 2015
    days_per_yr = 366 if cal.isleap(year) else 365

    # get 8760/8784 month numbers
    month_list = []
    for i in range(1, 13):
        days_per_month = cal.monthrange(year, i)[1]
        month_list = month_list + [i for j in range(1, days_per_month + 1) for k in range(1,25)]

    # get 8760/8784 day numbers
    day_list = []
    for i in range(1, 13):
        days_per_month = cal.monthrange(year, i)[1]
        day_list = day_list + [j for j in range(1, days_per_month + 1) for k in range(1,25)]

    # get 8760/8784 hour numbers
    hour_list = []
    for i in range(1,days_per_yr+1):
        hour_list = hour_list + list(range(1,25))


    # add year, month, day, period cols to data frame

    total_load.insert(0, "Period", hour_list)
    total_load.insert(0, "DAY", day_list)
    total_load.insert(0, "MONTH", month_list)
    total_load.insert(0, "YEAR", year)

    return total_load


@status_logger
def create_gen_reliability(folder):

    # # Gen reliability

    gen_reliability = []
    with open(os.path.join(folder, 'Table-06.txt')) as input_data:
        # Skips text before the beginning of the interesting block:
        for line in input_data:
            if line.startswith('------------------------'):  # Or whatever test is needed
                break
        # Reads text until the end of the block:
        for line in input_data:  # This keeps reading the file
            if line in ['\n','\r\n']:
                break
            row = line.split()
            gen_reliability.append({'Unit Group':row[0],
                                 'Unit Size':float(row[1]),
                                 'Unit Type':row[2],
                                 'FOR':float(row[3]),
                                 'MTTF':float(row[4]),
                                 'MTTR':float(row[5]),
                                 'Scheduled Maint Weeks':float(row[6])})
    gen_reliability = pd.DataFrame(gen_reliability)

    return gen_reliability


@status_logger
def create_gen_data(folder):

    # # Gen data

    # TODO : use this instead?
    # >> pd.read_csv('./../UW_files_RTS2016/Table-07.txt', header=None, skiprows=5, skipfooter=5, delim_whitespace=True, engine='python', names=['Bus', 'Unit', 'ID', 'PG', 'QG', 'Qmax', 'Qmin', 'VS'])

    generators = []
    with open(os.path.join(folder, 'Table-07.txt')) as input_data:
        # Skips text before the beginning of the interesting block:
        for line in input_data:
            if line.startswith('------------------------'):  # Or whatever test is needed
                break
        # Reads text until the end of the block:
        for line in input_data:  # This keeps reading the file
            if line in ['\n','\r\n']:
                break
            row = line.split()
            generators.append({'Bus':int(row[0]),
                                 'Unit Group':str(row[1]),
                                 'ID':int(row[2]),
                                 'PG':float(row[3]),
                                 'QG':float(row[4]),
                                 'QMax':float(row[5]),
                                 'QMin':float(row[6]),
                                 'VS':float(row[7])})
    generators = pd.DataFrame(generators)
    return generators

@status_logger
def create_mingen_data(folder):

    # # Gen data

    # TODO : use this instead?
    # >> pd.read_csv('./../UW_files_RTS2016/Table-07.txt', header=None, skiprows=5, skipfooter=5, delim_whitespace=True, engine='python', names=['Bus', 'Unit', 'ID', 'PG', 'QG', 'Qmax', 'Qmin', 'VS'])

    mingen = []
    with open(os.path.join(folder, 'Table-06_mingen.txt')) as input_data:
        # Skips text before the beginning of the interesting block:
        for line in input_data:
            if line.startswith('-------------'):  # Or whatever test is needed
                break
        # Reads text until the end of the block:
        for line in input_data:  # This keeps reading the file
            if line in ['\n','\r\n']:
                break
            row = line.split()
            mingen.append({'Unit Group':str(row[0]),
                                 'Pmin':float(row[1])})
    mingen = pd.DataFrame(mingen)
    return mingen

@status_logger
def create_gen_start(folder):

    genstart = []
    with open(os.path.join(folder, 'Table-08.txt')) as input_data:
        # Skips text before the beginning of the interesting block:
        for line in input_data:
            if line.startswith('------------------------'):  # Or whatever test is needed
                break
        # Reads text until the end of the block:
        for line in input_data:  # This keeps reading the file
            if line in ['\n','\r\n']:
                break
            row = line.split()
            genstart.append({'Unit Group':str(row[0]),
                                 'Unit Size':float(row[1]),
                                 'Unit Type':str(row[2]),
                                 'Hot Start':float(row[3]),
                                 'Cold Start':float(row[4])})
    genstart = pd.DataFrame(genstart)
    return genstart



@status_logger
def create_heat_rate(folder):

    heat_rate = []
    with open(os.path.join(folder, 'Table-09.txt')) as input_data:
        # Skips text before the beginning of the interesting block:
        for line in input_data:
            if line.startswith('------------------------'):  # Or whatever test is needed
                break
        # Reads text until the end of the block:
        for line in input_data:  # This keeps reading the file
            if line in ['\n','\r\n']:
                break
            row = line.split()
            heat_rate.append({'Unit Size':float(row[0]),
                                 'Type':str(row[1]),
                                 'Fuel':str(row[2]),
                                 'Output_pct':float(row[3]),
                                 'Output_MW':float(row[4]),
                                 'Net_Heat_Rate':float(row[5]),
                                 'Inc_Heat_Rate':float(row[6])})
    heat_rate = pd.DataFrame(heat_rate)
    return heat_rate


@status_logger
def create_ramp_rate(folder):

    ramp_rate = []
    with open(os.path.join(folder, 'Table-10.txt')) as input_data:
        # Skips text before the beginning of the interesting block:
        for line in input_data:
            if line.startswith('------------------------'):  # Or whatever test is needed
                break
        # Reads text until the end of the block:
        for line in input_data:  # This keeps reading the file
            if line in ['\n','\r\n']:
                break
            row = line.split()
            ramp_rate.append({'Unit Group':str(row[0]),
                                 'Unit Size':float(row[1]),
                                 'Unit Type':str(row[2]),
                                 'Min_Down_Time':float(row[3]),
                                 'Min_Up_Time':float(row[4]),
                                 'Start_Time_Hot':float(row[5]),
                                 'Start_Time_Cold':float(row[6]),
                                 'Start_Time_Warm':float(row[7]),
                                 'Ramp_Rate':float(row[8])})
    ramp_rate = pd.DataFrame(ramp_rate)
    return ramp_rate


@status_logger
def create_gen_emissions(folder):
    gen_emissions = pd.read_csv(os.path.join(folder, 'Table-11.csv'))
    return gen_emissions


@status_logger
def create_branches(folder):

    # # Branches

    branches = []
    with open(os.path.join(folder, 'Table-12.txt')) as input_data:
        # Skips text before the beginning of the interesting block:
        for line in input_data:
            if line.startswith('------------------------'):  # Or whatever test is needed
                break
        # Reads text until the end of the block:
        for line in input_data:  # This keeps reading the file
            if line in ['\n','\r\n']:
                break
            row = line.split()
            branches.append({'ID':str(row[0]),
                                 'From Bus':float(row[1]),
                                 'To Bus':float(row[2]),
                                 'Length':float(row[3]),
                                 'Perm OutRate':float(row[4]),
                                 'Duration':float(row[5]),
                                 'Tran OutRate':float(row[6]),
                                 'R':float(row[7]),
                                 'X':float(row[8]),
                                 'B':float(row[9]),
                                 'Cont Rating':float(row[10]),
                                 'LTE Rating':float(row[11]),
                                 'STE Rating':float(row[12]),
                                 'Tr Ratio':float(row[13])})
    branches = pd.DataFrame(branches)
    return branches


@status_logger
def create_dc_data(folder):

    dc_branch_control = pd.read_csv(os.path.join(folder, 'Table-13a.csv'))
    dc_branch_rectInv = pd.read_csv(os.path.join(folder, 'Table-13b.csv'))
    dc_branch_capacity = pd.read_csv(os.path.join(folder, 'Table-13c.csv'))

    return dc_branch_control, dc_branch_rectInv, dc_branch_capacity


@status_logger
def create_dc_stations(folder):

    dc_stations = []
    with open(os.path.join(folder, 'Table-14.txt')) as input_data:
        # Skips text before the beginning of the interesting block:
        for line in input_data:
            if line in ['\n','\r\n']:  # Or whatever test is needed
                break
        # Reads text until the end of the block:
        for line in input_data:  # This keeps reading the file
            if line in ['\n','\r\n']:
                break
            row = line.split('=')
            dc_stations.append({
                    'Variable':str(row[0]),
                    'Value':float(row[1])
                })

    dc_stations = pd.DataFrame(dc_stations)

    return dc_stations


@status_logger
def create_dynamic_data(folder):
    # # Dynamic Data

    dynamics = []
    with open(os.path.join(folder, 'Table-15.txt')) as input_data:
        # Skips text before the beginning of the interesting block:
        for line in input_data:
            if line.startswith('----------------'):  # Or whatever test is needed
                break
        # Reads text until the end of the block:
        for line in input_data:  # This keeps reading the file
            if line in ['\n','\r\n']:
                break
            row = line.split()
            dynamics.append({'Unit Group':str(row[0]),
                                 'Unit Size':float(row[1]),
                                 'Unit Type':str(row[2]),
                                 'MVA Base':float(row[3]),
                                 'Unit X':float(row[4]),
                                 'Transformer X':float(row[5]),
                                 'Inertia':float(row[6]),
                                 'Damping Ratio':float(row[7])
                            })

    dynamics = pd.DataFrame(dynamics)
    return dynamics



@status_logger
def write_rts_files(data):

        buses = data['buses']
        bus_v_settings = pd.read_csv(os.path.join(curr_dir, './nesta_v_settings.csv'))
        bus_location = pd.read_csv(os.path.join(curr_dir, '../locate_nodes/rts_node_coords.csv'))[['bus','lat','lng']]
        bus_location.rename(columns={'bus':'Bus ID'},inplace=True)
        bus_location['Bus ID'] = bus_location['Bus ID'].map(int)

        total_load = data['total_load']

        generators =  data['gen_data']
        ramp_rate = data['ramp_rate']
        genstart =  data['gen_start']
        mingen = data['mingen']
        gen_reliability =  data['gen_reliability']
        vg_gens = pd.read_csv(os.path.join(curr_dir,'./vg_gens_maxMW.csv'))

        fuel_price = pd.read_csv(os.path.join(curr_dir, './fuel_prices.csv'))
        heat_rate = data['heat_rate']

        gen_emissions =  data['gen_emissions']
        dynamic_data =  data['dynamic_data']


        branchdata =  data['branches']
        dc_branch_control, dc_branch_rectInv, dc_branch_capacity =  data['dc_data']
        dc_stations =  data['dc_stations']




        def count(x):
            x['tranches'] = range(0, len(x))
            return x

        heat_rate = heat_rate.groupby(['Unit Size']).apply(count)

        pivot_heat_rate = heat_rate.pivot_table(index=['Unit Size'], columns=['tranches'])
        pivot_heat_rate = pivot_heat_rate.drop(['Output_MW'], axis=1)
        pivot_heat_rate['Output_pct'] = pivot_heat_rate['Output_pct'] / 100.0
        pivot_heat_rate.columns = ['{}_{}'.format(x, y) for x, y in zip(pivot_heat_rate.columns.get_level_values(0), pivot_heat_rate.columns.get_level_values(1))]

        def io(r):
            segments = 1
            x1 = np.linspace(r['Output_pct_0'], r['Output_pct_1'], segments+1)
            x2 = np.linspace(r['Output_pct_1'], r['Output_pct_2'], segments+1)
            x3 = np.linspace(r['Output_pct_2'], r['Output_pct_3'], segments+1)

            if r['Net_Heat_Rate_0'] <= 3412:
                r['Net_Heat_Rate_0'] = 3412

            y1 = ( x1 - x1.min() ) * r['Inc_Heat_Rate_0'] + r['Net_Heat_Rate_0'] *  x1.min()
            y2 = ( x2 - x2.min() ) * r['Inc_Heat_Rate_1'] + y1.max()
            y3 = ( x3 - x3.min() ) * r['Inc_Heat_Rate_2'] + y2.max()

            return zip(list(np.concatenate([x1[:-1], x2[:-1], x3[:-1]])), list(np.concatenate([y1[:-1], y2[:-1], y3[:-1]])))

        pivot_heat_rate['io_cost'] = pivot_heat_rate.apply(io, axis=1)


        NaN = pd.np.NaN


        # create bus.csv
        _bus = pd.merge(buses,bus_location,how='left',on='Bus ID')
        _bus = pd.merge(_bus,bus_v_settings,how='left',left_index=True,right_index=True)
        _bus['Area'] = _bus['Bus ID'].apply(lambda x: int(round(x/100)))
        _bus['Bus Type'] = _bus['Bus Type'].map({1:"PQ",2:"PV",3:"Ref"})
        _bus.rename(columns={'BL':'MVAR Shunt B',
                                 'GL':'MW Shunt G',
                                  'Vm':'V Mag',
                                  'Va':'V Angle'},inplace=True)
        cols = ['Bus ID', 'Bus Name', 'BaseKV', 'Bus Type', 'MW Load', 'MVAR Load',
                'V Mag', 'V Angle', 'MW Shunt G', 'MVAR Shunt B', 'Area', 
                'Sub Area', 'Zone', 'lat', 'lng']

        _bus[cols].to_csv(os.path.join(curr_dir,'RTS-GMLC-SourceData/bus.csv'),index=False)


        # create branch.csv
        cols = ['ID', 'From Bus', 'To Bus', 'R', 'X', 'B', 
                'Cont Rating',  'LTE Rating', 'STE Rating', 
                'Perm OutRate', 'Duration', 'Tr Ratio', 'Tran OutRate', 'Length']

        branchdata[cols].to_csv(os.path.join(curr_dir,'RTS-GMLC-SourceData/branch.csv'),index=False)


        # create gen.csv
        _generators = pd.merge(generators, ramp_rate, how='left', on=['Unit Group']).sort_values(['Bus', 'ID'],)
        _generators = pd.merge(_generators, genstart, how='left', on=['Unit Group', 'Unit Type', 'Unit Size'])
        _generators = pd.merge(_generators, mingen, how='left', on=['Unit Group'])

        _generators = pd.merge(_generators, gen_reliability, how='left', on=['Unit Group', 'Unit Type', 'Unit Size'])


        _generators = pd.merge(_generators, fuel_price, how='left', left_on='Unit Type', right_on='Fuel')

        _generators = pd.merge(_generators, pivot_heat_rate, how='left', left_on='Unit Size', right_index=True)

        _generators = pd.merge(_generators,gen_emissions.rename(columns={'IEEE-RTS Unit Group':'Unit Group'}),how='left',on = 'Unit Group',)
        # need to replace 'unit-specific' with NaN or Zero

        _generators = pd.merge(_generators,dynamic_data[['Unit Group','Damping Ratio','Inertia','MVA Base',
            'Transformer X','Unit X']],how='left',on = 'Unit Group')

        cols = ['Bus', 'ID', 'Unit Group', 'Unit Type', 'Fuel', 'PG', 'QG', 'VS', 'Unit Size', 'Pmin', 'QMax', 'QMin',
         'Min_Down_Time', 'Min_Up_Time', 'Ramp_Rate', 'Start_Time_Cold', 'Start_Time_Hot', 'Start_Time_Warm', 'Cold Start', 'Hot Start', 
         'FOR', 'MTTF', 'MTTR', 'Scheduled Maint Weeks', 
         'Price', 'Output_pct_0', 'Output_pct_1', 'Output_pct_2', 'Output_pct_3',
         'Inc_Heat_Rate_0', 'Inc_Heat_Rate_1', 'Inc_Heat_Rate_2', 'Inc_Heat_Rate_3',
         'Net_Heat_Rate_0', 'Net_Heat_Rate_1', 'Net_Heat_Rate_2', 'Net_Heat_Rate_3',
         'Fuel sulfur content (%)', 'SO2 (Lbs/MMBTU)', 'NOX (Lbs/MMBTU)',
         'Part (Lbs/MMBTU)', 'CO2 (Lbs/MMBTU)', 'CH4 (Lbs/MMBTU)', 'N2O (Lbs/MMBTU)', 'CO (Lbs/MMBTU)', 'VOCs (Lbs/MMBTU)',
         'Damping Ratio', 'Inertia', 'MVA Base', 'Transformer X', 'Unit X']

        _generators = _generators[cols]
        _generators.rename(columns={
             'Bus':                     'Bus ID',
             'ID':                      'Gen ID',
             'PG':                      'MW Inj',
             'QG':                      'MVAR Inj',
             'QMax':                    'QMax MVAR',
             'QMin':                    'QMin MVAR',
             'VS':                      'V Setpoint p.u.',
             'Min_Down_Time':           'Min Down Time Hr',
             'Min_Up_Time':             'Min Up Time Hr',
             'Ramp_Rate':               'Ramp Rate MW/Min',
             'Start_Time_Cold':         'Start Time Cold Hr',
             'Start_Time_Hot':          'Start Time Hot Hr',
             'Start_Time_Warm':         'Start Time Warm Hr',
             'Unit Size':               'PMax MW',
             'Cold Start':              'Start Heat Cold MBTU',
             'Hot Start':               'Start Heat Hot MBTU',
             'Pmin':                    'PMin MW',
             'MTTF':                    'MTTF Hr',
             'MTTR':                    'MTTR Hr',
             'Price':                   'Fuel Price $/MMBTU',
             'Fuel sulfur content (%)': 'Fuel Sulfur Content %',
             'SO2 (Lbs/MMBTU)':         'Emissions SO2 Lbs/MMBTU',
             'NOX (Lbs/MMBTU)':         'Emissions NOX Lbs/MMBTU',
             'Part (Lbs/MMBTU)':        'Emissions Part Lbs/MMBTU',
             'CO2 (Lbs/MMBTU)':         'Emissions CO2 Lbs/MMBTU',
             'CH4 (Lbs/MMBTU)':         'Emissions CH4 Lbs/MMBTU',
             'N2O (Lbs/MMBTU)':         'Emissions N2O Lbs/MMBTU',
             'CO (Lbs/MMBTU)':          'Emissions CO Lbs/MMBTU',
             'VOCs (Lbs/MMBTU)':        'Emissions VOCs Lbs/MMBTU',
             'Inertia':                 'Inertia MJ/MW',
             'MVA Base':                'Base MVA',
             'Transformer X':           'Transformer X p.u.',
             'Unit X':                  'Unit X p.u.'},inplace=True)

        #split the Unit Type to assign Unit Type and Fuel
        _generators['Fuel'] = _generators['Unit Type'].str.split('/').str[0]
        _generators['Unit Type'] = _generators['Unit Type'].str.split('/').str[1]
        _generators.loc[_generators['Fuel']=='Hydro','Unit Type'] = _generators.loc[_generators['Fuel']=='Hydro','Unit Type'].fillna('Hydro')
        _generators.loc[_generators['Fuel']=='Nuclear','Unit Type'] = _generators.loc[_generators['Fuel']=='Nuclear','Unit Type'].fillna('Nuclear')


        _generators.loc[_generators['Unit Group']=='Sync_Cond',('Unit Type','Fuel')] = ('Sync_Cond','Sync_Cond')
        _generators.loc[_generators['Unit Group']=='Sync_Cond'] = _generators.loc[_generators['Unit Group']=='Sync_Cond'].fillna(0)
        _generators.loc[_generators['Unit Type'].isin(['Hydro','Nuclear'])] = _generators.loc[_generators['Unit Type'].isin(['Hydro','Nuclear'])] .fillna(0)
        _generators['Unit Type'] = _generators['Unit Type'].str.upper()


        _vg_generators = pd.DataFrame(columns = list(_generators))
        _vg_generators['Bus ID'] = vg_gens['Generator'].str.split('_').str[0]
        _vg_generators['Gen ID'] = vg_gens['Generator'].str.split('_').str[2]
        _vg_generators['Gen ID'] = _vg_generators['Gen ID'].fillna(1)
        _vg_generators['Unit Type'] = vg_gens['Generator'].str.split('_').str[1]
        _vg_generators['Unit Type'] = _vg_generators['Unit Type'].str.upper()
        _vg_generators['Unit Group'] = _vg_generators['Unit Type']
        _vg_generators.loc[_vg_generators['Unit Type'].isin(['RTPV','PV','CSP']),'Fuel'] = 'Solar'
        _vg_generators.loc[_vg_generators['Unit Type'] == 'WIND','Fuel'] = 'Wind'
        _vg_generators['PMax MW'] = vg_gens['Max Capacity']
        _vg_generators['Ramp Rate MW/Min'] = vg_gens['Max Capacity']
        _vg_generators['V Setpoint p.u.'] = 1
        _vg_generators = _vg_generators.fillna(0)

        _generators = pd.concat([_generators,_vg_generators])

        _generators.insert(0,'GEN UID',_generators['Bus ID'].map(str) + '_' + _generators['Unit Type'] + '_' + _generators['Gen ID'].map(str))
        _generators.to_csv(os.path.join(curr_dir, 'RTS-GMLC-SourceData/gen.csv'),index=False)

        #write pointers file
        simulations = list(pd.read_csv(os.path.join(curr_dir,'RTS-GMLC-SourceData/simulation_objects.csv')))
        simulations = simulations[2:len(simulations)]

        timeseries_pointers = pd.DataFrame(columns = ['Simulation','GEN UID', 'Parameter','Data File'])
        for sim in simulations:
            _ts_parameters_1 = pd.DataFrame(columns = ['Simulation','GEN UID', 'Parameter','Data File'])
            _ts_parameters_2 = pd.DataFrame(columns = ['Simulation','GEN UID', 'Parameter','Data File'])

            #set max power output for all RE and hydro
            _ts_parameters_1['GEN UID'] = _generators.loc[_generators['Unit Type'].isin(['HYDRO','WIND','PV','RTPV','CSP']),'GEN UID']
            _ts_parameters_1['Simulation'] = sim
            _ts_parameters_1['Parameter'] = 'PMax MW'
            _ts_parameters_1['Data File'] = '../timeseries_data_files/' + _ts_parameters_1['GEN UID'].str.split('_').str[1] + '/' + _ts_parameters_1['Simulation'] + '_' + _ts_parameters_1['GEN UID'].str.split('_').str[1].str.lower() + '.csv'


            #set min power output for RTPV and Hydro
            _ts_parameters_2['GEN UID'] = _generators.loc[_generators['Unit Type'].isin(['HYDRO','RTPV']),'GEN UID']
            _ts_parameters_2['Simulation'] = sim
            _ts_parameters_2['Parameter'] = 'PMin MW'
            _ts_parameters_2['Data File'] = '../timeseries_data_files/' + _ts_parameters_2['GEN UID'].str.split('_').str[1] + '/' + _ts_parameters_2['Simulation'] + '_' + _ts_parameters_2['GEN UID'].str.split('_').str[1].str.lower() + '.csv'

            timeseries_pointers = pd.concat([timeseries_pointers,_ts_parameters_1,_ts_parameters_2])


        timeseries_pointers.to_csv(os.path.join(curr_dir,'RTS-GMLC-SourceData/timeseries_pointers.csv'),index=False)


def write_rts_MATPOWER_file(data):



        def s(string, padding = ' '):
            return '{:%^80}'.format(padding + string + padding)

        def l(string, string_list):
            string_list.append(string)

        string_list = []

        from functools import partial
        l = partial(l, string_list=string_list)

        l('function mpc = {}'.format('RTS96'))
        l('')

        l(s('RTS 96 Test Case'))
        l(s('By : Clayton Barrows, Ali Ehlen, Matt O Connell, and Dheepak Krishnamurthy'))
        l(s('%', padding=''))

        l('')
        l("mpc.version = '2';")
        l("mpc.baseMVA = 100.0;")

        l('''
%% area data
% area refbus
mpc.areas = [
        1    101;
        2    201;
        3    301;
            ];''')


        l('''
%% bus data
%	bus_i	type	Pd	Qd	Gs	Bs	area	Vm	Va	baseKV	zone	Vmax	Vmin
mpc.bus = [''')

        bus = dict()
        for i, b in buses.iterrows():
            bus['bus_i'] = b['Bus ID']
            bus['type'] = b['Bus Type']
            bus['Pd'] = b['MW Load']
            bus['Qd'] = b['MVAR Load']
            bus['Gs'] = b['GL']
            bus['Bs'] = b['BL']
            bus['area'] = int(round(b['Bus ID']/100)) #b['Sub Area']
            bus['Vm'] = bus_v_settings.Vm[i] #default = 1.0
            bus['Va'] = bus_v_settings.Va[i] #default = 0.0
            bus['baseKV'] = b['BaseKV']
            bus['zone'] = int(b['Zone'])
            bus['Vmax'] = 1.05 #default
            bus['Vmin'] = 0.95 #default
            l('\t{bus_i}\t{type}\t{Pd}\t{Qd}\t{Gs}\t{Bs}\t{area}\t{Vm}\t{Va}\t{baseKV}\t{zone}\t{Vmax}\t{Vmin}'.format(**bus))

        l('];')

        l('''
%% generator data
%	bus	Pg	Qg	Qmax	Qmin	Vg	mBase	status	Pmax	Pmin	Pc1	Pc2	Qc1min	Qc1max	Qc2min	Qc2max	ramp_agc	ramp_10	ramp_30	ramp_q	apf
mpc.gen = [''')

        gen = dict()


        for i, g in _generators.iterrows():
            gen['bus'] = g['Bus']
            gen['Pg'] = g['PG']
            gen['Qg'] = g['QG']
            gen['Qmax'] = g['QMax']
            gen['Qmin'] = g['QMin']
            gen['Vg'] = g['VS']
            gen['mBase'] = 100.0 #default
            gen['status'] = 1 #default
            gen['Pmax'] = g['Unit Size']
            gen['Pmin'] = g['Pmin'] if not np.isnan(g['Pmin']) else 0 #g['Output_pct_0'] * g['Unit Size']
            gen['Pc1'] = 0.0 #default
            gen['Pc2'] = 0.0 #default
            gen['Qc1min'] = 0.0 #default
            gen['Qc1max'] = 0.0 #default
            gen['Qc2min'] = 0.0 #default
            gen['Qc2max'] = 0.0 #default
            gen['ramp_agc'] = g['Ramp_Rate']
            gen['ramp_10'] = g['Ramp_Rate']
            gen['ramp_30'] = g['Ramp_Rate']
            gen['ramp_q'] = g['Ramp_Rate']
            gen['apf'] = 0.0 #default

            l('	{bus}	{Pg}	{Qg}	{Qmax}	{Qmin}	{Vg}	{mBase}	{status}	{Pmax}	{Pmin}	{Pc1}	{Pc2}	{Qc1min}	{Qc1max}	{Qc2min}	{Qc2max}	{ramp_agc}	{ramp_10}	{ramp_30}	{ramp_q}	{apf}'.format(**gen))

        l('];')

        l('''
%% branch data
%	fbus	tbus	r	x	b	rateA	rateB	rateC	ratio	angle	status	angmin	angmax
mpc.branch = [''')

        branch = dict()

        for i, b in branchdata.iterrows():
            branch['fbus'] = int(b['From Bus'])
            branch['tbus'] = int(b['To Bus'])
            branch['r'] = b['R']
            branch['x'] = b['X']
            branch['b'] = b['B']
            branch['rateA'] = b['Cont Rating']
            branch['rateB'] = b['Cont Rating']
            branch['rateC'] = b['Cont Rating']
            branch['ratio'] = b['Tr Ratio']
            branch['angle'] = 0.0 #default
            branch['status'] = 1 #default
            branch['angmin'] = -180 #default
            branch['angmax'] = 180 #default

            l('	{fbus}	{tbus}	{r}	{x}	{b}	{rateA}	{rateB}	{rateC}	{ratio}	{angle}	{status}	{angmin}	{angmax}'.format(**branch))

        l('];')


        l('''
%% generator cost data
%	1	startup	shutdown	n	P0,c(0)	...	Pn-1,c(n-1)
%	2	startup	shutdown	n	c(n-1)	...	c0

mpc.gencost = [''')

        gen = dict()

        for i, g in _generators.iterrows():
            gen['model'] = 1
            gen['startup'] = (g['Cold Start'] if not np.isnan(g['Cold Start'] * g['Price']) else 0.0) 
            gen['shutdown'] = (g['Cold Start']  if not np.isnan(g['Cold Start'] * g['Price']) else 0.0)
            gen['cost'] = list()
            gen['cost'] = g['io_cost']
            if np.isnan(g['io_cost']).any():
                if g['Unit Size'] == 0:
                    print('Synchronous condensor!')
                    g['Unit Size'] = 1
                gen['cost'] = '{}\t0\t{}\t0\t{}\t0'.format(*(pd.np.linspace(0, g['Unit Size'], 3)))
                gen['ncost'] = 3
            else:
                gen['cost'] = '\t'.join(['{}\t{}'.format(x*g['Unit Size'], y*g['Unit Size']*g['Price']/1000) for x, y in gen['cost']]) # BTU/kWh * (1000kWH/MWh) * MWh * $/MMBTU  * (1MMBTU/100000BTU) = 1/1000
                gen['ncost'] = len(g['io_cost'])
            l('	{model}	{startup}	{shutdown}	{ncost}	{cost}'.format(**gen))

        l('];')

        l('')
        l('')

        l('''
%% DC line data
% F_BUS T_BUS BR_STATUS PF PT QF QT VF VT PMIN PMAX QMINF QMAXF QMINT QMAXT LOSS0 LOSS1 MU_PMIN MU_PMAX MU_QMINF MU_QMAXF MU_QMINT MU_QMAXT
mpc.dcline = [
	113 316 1 0 0 0 0 1 1 0 inf -inf inf -inf inf 0 0 0 0 0 0 0 0
]
''')


        with open('./RTS.m', 'w') as f:
            f.write('\n'.join(string_list))


