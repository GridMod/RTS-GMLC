# coding: utf-8

import os
import pandas as pd
import numpy as np

curr_dir = os.path.dirname(os.path.realpath(__file__))


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


def create_rts_MATPOWER_file(folder):

        _generators = pd.read_csv(os.path.join(folder,'gen.csv'))
        buses = pd.read_csv(os.path.join(folder,'bus.csv'))
        branchdata =pd.read_csv(os.path.join(folder,'branch.csv'))


        pivot_heat_rate = pd.DataFrame(_generators[['Output_pct_0', 'Output_pct_1', 'Output_pct_2', 'Output_pct_3',
                                                     'Inc_Heat_Rate_0', 'Inc_Heat_Rate_1', 'Inc_Heat_Rate_2', 'Inc_Heat_Rate_3', 
                                                     'Net_Heat_Rate_0', 'Net_Heat_Rate_1', 'Net_Heat_Rate_2', 'Net_Heat_Rate_3']])

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
        _generators = pd.concat([_generators,pivot_heat_rate['io_cost']],axis=1)

        NaN = pd.np.NaN



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
            if b['Bus Type'] == 'PQ':
                bus['type'] = 1
            elif b['Bus Type'] == 'PV':
                bus['type']  = 2
            elif b['Bus Type'] == 'Ref':
                bus['type']  = 3
            else:
                bus['type'] = 4
            bus['Pd'] = b['MW Load']
            bus['Qd'] = b['MVAR Load']
            bus['Gs'] = b['MW Shunt G']
            bus['Bs'] = b['MVAR Shunt B']
            bus['area'] = b['Area']
            bus['Vm'] = b['V Mag']
            bus['Va'] = b['V Angle']
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
            gen['bus'] = g['Bus ID']
            gen['Pg'] = g['MW Inj']
            gen['Qg'] = g['MVAR Inj']
            gen['Qmax'] = g['QMax MVAR']
            gen['Qmin'] = g['QMin MVAR']
            gen['Vg'] = g['V Setpoint p.u.']
            gen['mBase'] = 100.0 #default
            if g['Fuel'] in ['Wind','Solar','Hydro']:
                gen['status'] = 0
            else:
                gen['status'] = 1 #default
            gen['Pmax'] = g['PMax MW']
            gen['Pmin'] = g['PMin MW'] if not np.isnan(g['PMin MW']) else 0 #g['Output_pct_0'] * g['Unit Size']
            gen['Pc1'] = 0.0 #default
            gen['Pc2'] = 0.0 #default
            gen['Qc1min'] = 0.0 #default
            gen['Qc1max'] = 0.0 #default
            gen['Qc2min'] = 0.0 #default
            gen['Qc2max'] = 0.0 #default
            gen['ramp_agc'] = g['Ramp Rate MW/Min']
            gen['ramp_10'] = g['Ramp Rate MW/Min']
            gen['ramp_30'] = g['Ramp Rate MW/Min']
            gen['ramp_q'] = g['Ramp Rate MW/Min']
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
            gen['startup'] = (g['Start Heat Cold MBTU'] * g['Fuel Price $/MMBTU'] if not np.isnan(g['Start Heat Cold MBTU'] * g['Fuel Price $/MMBTU']) else 0.0) 
            gen['shutdown'] = (g['Start Heat Cold MBTU'] * g['Fuel Price $/MMBTU'] if not np.isnan(g['Start Heat Cold MBTU'] * g['Fuel Price $/MMBTU']) else 0.0)
            gen['cost'] = list()
            gen['cost'] = g['io_cost']
            if np.isnan(g['io_cost']).any():
                if g['Fuel'] == 'Sync_Cond':
                    print('Synchronous condensor!')
                    g['PMax MW'] = 1
                gen['cost'] = '{}\t0\t{}\t0\t{}\t0'.format(*(pd.np.linspace(0, g['PMax MW'], 3)))
                gen['ncost'] = 3
            else:
                gen['cost'] = '\t'.join(['{}\t{}'.format(x*g['PMax MW'], y*g['PMax MW']*g['Fuel Price $/MMBTU']/1000) for x, y in gen['cost']]) # BTU/kWh * (1000kWH/MWh) * MWh * $/MMBTU  * (1MMBTU/100000BTU) = 1/1000
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


