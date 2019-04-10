import os

import matplotlib.pyplot as mpl
import numpy as np
import pandas as pd

import pandapower as pp
import pandapower.converter as cv
import pandapower.plotting as plt

DIGITS = 5


def _read_csv(table):
    start_path = os.path.join("..", "..", "SourceData")
    return pd.read_csv(os.path.join(start_path, table + ".csv"))


def plot_net(net, ax=None):
    if ax is None:
        fig, ax = mpl.subplots(1, 1, figsize=(10, 7))
    mean_distance_between_buses = sum((net['bus_geodata'].max() - net[
        'bus_geodata'].min()).dropna() / 200)

    bus_size = mean_distance_between_buses * 1.
    ext_grid_size = mean_distance_between_buses * 1.
    trafo_size = mean_distance_between_buses * .1

    collections = list()
    if ax is None:
        fig, ax = plt.subplots(1, 1)

    # create plot collection to visualize results
    cmap, norm = plt.cmap_continous([(0.9, "blue"), (1.0, "green"), (1.1, "red")])
    collections.append(plt.create_bus_collection(net, size=bus_size, cmap=cmap, norm=norm))
    cmap, norm = plt.cmap_continous([(0., "green"), (50., "yellow"), (100., "red")])
    collections.append(plt.create_line_collection(net, use_bus_geodata=True, linewidth=1., cmap=cmap, norm=norm))
    collections.append(plt.create_trafo_collection(net, size=trafo_size, color="green", alpha=.5))
    collections.append(plt.create_ext_grid_collection(net, size=ext_grid_size, orientation=1.5))

    for idx in net.bus_geodata.index:
        x = net.bus_geodata.loc[idx, "x"]
        y = net.bus_geodata.loc[idx, "y"] + bus_size * 1.
        ax.text(x + 0.01, y, str(idx), fontsize=8, color="k")

    plt.draw_collections(collections, ax=ax)
    mpl.tight_layout()
    ax.axis('off')
    mpl.show()

    mpl.close()


def create_buses():
    busdata = _read_csv("bus")
    buses = np.zeros((len(busdata), 15), dtype=float)
    for ind, (i, b) in enumerate(busdata.iterrows()):
        buses[ind, 0] = b['Bus ID']
        if b['Bus Type'] == 'PQ':
            buses[ind, 1] = 1
        elif b['Bus Type'] == 'PV':
            buses[ind, 1] = 2
        elif b['Bus Type'] == 'Ref':
            buses[ind, 1] = 3
        else:
            buses[ind, 1] = 4
        buses[ind, 2] = b['MW Load']
        buses[ind, 3] = b['MVAR Load']
        buses[ind, 4] = b['MW Shunt G']
        buses[ind, 5] = b['MVAR Shunt B']
        buses[ind, 6] = b['Area']
        buses[ind, 7] = b['V Mag']
        buses[ind, 8] = b['V Angle']
        buses[ind, 9] = b['BaseKV']
        buses[ind, 10] = int(b['Zone'])
        buses[ind, 11] = 1.05  # default
        buses[ind, 12] = 0.95  # default
        buses[ind, 13] = DIGITS
    return buses


def create_branches():
    branchdata = _read_csv("branch")
    branches = np.zeros((len(branchdata), 14), dtype=float)
    for ind, (i, b) in enumerate(branchdata.iterrows()):
        branches[ind, 0] = int(b['From Bus'])
        branches[ind, 1] = int(b['To Bus'])
        branches[ind, 2] = b['R']
        branches[ind, 3] = b['X']
        branches[ind, 4] = b['B']
        branches[ind, 5] = b['Cont Rating']
        branches[ind, 6] = b['Cont Rating']
        branches[ind, 7] = b['Cont Rating']
        branches[ind, 8] = b['Tr Ratio']
        branches[ind, 9] = 0.0  # default
        branches[ind, 10] = 1  # default
        branches[ind, 11] = -180  # default
        branches[ind, 12] = 180  # default
        branches[ind, 13] = DIGITS
    return branches


def create_gens():
    gendata = _read_csv("gen")
    gens = np.zeros((len(gendata), 21), dtype=float)
    for ind, (i, g) in enumerate(gendata.iterrows()):
        gens[ind, 0] = g['Bus ID']
        gens[ind, 1] = g['MW Inj']
        gens[ind, 2] = g['MVAR Inj']
        gens[ind, 3] = g['QMax MVAR']
        gens[ind, 4] = g['QMin MVAR']
        gens[ind, 5] = g['V Setpoint p.u.']
        gens[ind, 6] = 100.0  # default
        if g['Fuel'] in ['Wind', 'Solar', 'Storage']:
            gens[ind, 7] = 0
        else:
            gens[ind, 7] = 1  # default
        gens[ind, 8] = g['PMax MW']
        gens[ind, 9] = g['PMin MW'] if not np.isnan(g['PMin MW']) else 0  # g['Output_pct_0'] * g['Unit Size']
        gens[ind, 10] = 0.0  # default
        gens[ind, 11] = 0.0  # default
        gens[ind, 12] = 0.0  # default
        gens[ind, 12] = 0.0  # default
        gens[ind, 13] = 0.0  # default
        gens[ind, 14] = 0.0  # default
        gens[ind, 15] = g['Ramp Rate MW/Min']
        gens[ind, 16] = g['Ramp Rate MW/Min']
        gens[ind, 17] = g['Ramp Rate MW/Min']
        gens[ind, 18] = g['Ramp Rate MW/Min']
        gens[ind, 19] = 0.0  # default
        gens[ind, 20] = DIGITS

    return gens


def create_ppc():
    ppc = dict()
    ppc["baseMVA"] = 100.
    # ppc["areas"] =
    ppc["bus"] = create_buses()
    ppc["branch"] = create_branches()
    ppc["gen"] = create_gens()

    return ppc


def add_additional_information(net):
    bus_data = _read_csv("bus")
    bus_index = net["bus"].loc[:, "name"].values == bus_data["Bus ID"]
    # bus names
    net["bus"].loc[:, "name"] = bus_data.loc[bus_index, "Bus Name"]

    # bus geodata
    net["bus_geodata"] = pd.DataFrame(index=np.arange(len(bus_data)), columns=["x", "y", "coords"])
    net["bus_geodata"].loc[:, ["x", "y"]] = bus_data.loc[bus_index, ["lat", "lng"]].values

    return net


def create_pp_from_ppc():
    # create ppc
    ppc = create_ppc()
    # convert it to a pandapower net
    net = cv.from_ppc(ppc, validate_conversion=False)
    net = add_additional_information(net)
    # run power flow
    pp.runpp(net)
    # save it
    pp.to_json(net, "pandapower_net.json")
    # plot it :)
    plot_net(net)


if __name__ == "__main__":
    create_pp_from_ppc()
