# coding: utf-8

import os
import pandas as pd
import numpy as np

curr_dir = os.path.dirname(os.path.realpath(__file__))


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
            if g['Fuel'] in ['Wind','Solar']:
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
            gen['startup'] = ((g['Start Heat Cold MBTU'] * g['Fuel Price $/MMBTU']) + g['Non Fuel Start Cost $'] if not np.isnan(g['Start Heat Cold MBTU'] * g['Fuel Price $/MMBTU']) else 0.0) 
            gen['shutdown'] = (g['Start Heat Cold MBTU'] * g['Fuel Price $/MMBTU'] if not np.isnan(g['Start Heat Cold MBTU'] * g['Fuel Price $/MMBTU']) else 0.0)
            gen['cost'] = list()
            gen['cost'] = g['io_cost']
            if all(v[1]  == 0.0 for v in g['io_cost']): #np.isnan(g['io_cost']).any():
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


