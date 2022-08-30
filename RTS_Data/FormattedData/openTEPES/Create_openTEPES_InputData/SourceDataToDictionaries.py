# Libraries
import os
import time
import pandas as pd


def GetDictionaries(_path_data, _path_file, CaseName):

    # reading the bus information
    df_bus = pd.read_csv(_path_data+'/SourceData/bus.csv')

    # Extracting regions
    pRegions = pd.Series(['Region_1'])
    pRegions.to_frame('Region').to_csv(_path_file+'/openTEPES_RTS-GMLC/oT_Dict_Region_'+CaseName+'.csv', sep=',', index=False)

    # Extracting areas
    IdxAreas  = df_bus['Area'].unique()
    pAreas     = pd.Series(['Area_'+str(int(i)) for i in IdxAreas])
    pAreas.to_frame('Area').to_csv(_path_file+'/openTEPES_RTS-GMLC/oT_Dict_Area_'+CaseName+'.csv', sep=',', index=False)

    # Extracting zones
    IdxZones  = df_bus['Zone'].unique()
    pZones     = pd.Series(['Zone_'+str(int(i)) for i in IdxZones])
    pZones.to_frame('Zone').to_csv(_path_file+'/openTEPES_RTS-GMLC/oT_Dict_Zone_'+CaseName+'.csv', sep=',', index=False)

    # Extracting nodes
    IdxNodes  = df_bus['Bus ID'].unique()
    pNodes     = pd.Series(['Node_'+str(int(i)) for i in IdxNodes])
    pNodes.to_frame('Node').to_csv(_path_file+'/openTEPES_RTS-GMLC/oT_Dict_Node_'+CaseName+'.csv', sep=',', index=False)

    # From Node to Zone
    Nodes = ['Node_' + str(int(df_bus['Bus ID'][i])) for i in df_bus.index]
    Zones = ['Zone_' + str(int(df_bus['Zone'  ][i])) for i in df_bus.index]
    pNodeToZone = pd.DataFrame({'Node': Nodes, 'Zone': Zones})
    pNodeToZone.to_csv(_path_file+'/openTEPES_RTS-GMLC/oT_Dict_NodeToZone_'+CaseName+'.csv', sep=',', index=False)

    # From Zone to Area
    Areas = ['Area_' + str(int(df_bus['Area'][i])) for i in df_bus.index]
    pZoneToArea = pd.DataFrame({'Zone': Zones, 'Area': Areas}).set_index(['Zone', 'Area'])
    pZoneToArea = pZoneToArea[~pZoneToArea.index.duplicated(keep='first')].reset_index()
    pZoneToArea.to_csv(_path_file+'/openTEPES_RTS-GMLC/oT_Dict_ZoneToArea_'+CaseName+'.csv', sep=',', index=False)

    # From Area to Region
    pAreaToRegion = pAreas.to_frame('Area')
    pAreaToRegion['Region'] = 'Region_1'
    pAreaToRegion.to_csv(_path_file + '/openTEPES_RTS-GMLC/oT_Dict_AreaToRegion_' + CaseName + '.csv', sep=',', index=False)

    # Determining number of circuits
