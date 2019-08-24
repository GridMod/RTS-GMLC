import geojson, json, random
import pandas as pd
import numpy as np
from copy import deepcopy


bus_df = pd.read_csv('../../SourceData/bus.csv')
buses = list(bus_df.T.to_dict().values())

bus_features = []

bus_table = {}
gen_count = {}

for x in buses:
    bus_table[x['Bus ID']] = x
    gen_count['Bus ID'] = 0

    xy = x['lng'], x['lat']
    props = deepcopy(x)
    props.pop('lng')
    props.pop('lat')
    geom = geojson.Point(xy)
    f = geojson.Feature(geometry=geom, properties=props)
    bus_features.append(f)

bus_collect = geojson.FeatureCollection(features=bus_features)

with open('../../FormattedData/GIS/bus.geojson', 'w') as io:
    json.dump(bus_collect, io, indent=4)


##### Process branches #####
branch_df = pd.read_csv('../../SourceData/branch.csv')
branches = list(branch_df.T.to_dict().values())

branch_features = []

for x in branches:
    bf = bus_table[x['From Bus']]
    bt = bus_table[x['To Bus']]    

    pf = bf['lng'], bf['lat']
    pt = bt['lng'], bt['lat']
    xy = pf, pt

    geom = geojson.LineString(xy)
    f = geojson.Feature(geometry=geom, properties=x)
    branch_features.append(f)

branch_collect = geojson.FeatureCollection(features=branch_features)

with open('../../FormattedData/GIS/branch.geojson', 'w') as io:
    json.dump(branch_collect, io, indent=4)




##### Process generators #####
gen_df = pd.read_csv('../../SourceData/gen.csv')
gens = list(gen_df.T.to_dict().values())

gen_features = []
gen_conn_features = []
d = 0.1

for x in gens:
    b = bus_table[x['Bus ID']]
    theta = random.uniform(-np.pi, np.pi)
    A = random.uniform(0,d)
    dx = A*np.cos(theta)
    dy = A*np.sin(theta)

    pg = b['lng'] + dx, b['lat'] + dy 
    geom = geojson.Point(pg)
    f = geojson.Feature(geometry=geom, properties=x)
    gen_features.append(f)

    pb = b['lng'], b['lat'] 
    xy = pb, pg
    geom = geojson.LineString(xy)
    f = geojson.Feature(geometry=geom, properties=x)
    gen_conn_features.append(f)

gen_collect = geojson.FeatureCollection(features=gen_features)
gen_conn_collect = geojson.FeatureCollection(features=gen_conn_features)

with open('../../FormattedData/GIS/gen.geojson', 'w') as io:
    json.dump(gen_collect, io, indent=4)

with open('../../FormattedData/GIS/gen_conn.geojson', 'w') as io:
    json.dump(gen_conn_collect, io, indent=4)

# import ipdb; ipdb.set_trace()