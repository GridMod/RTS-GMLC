# Libraries
import time
import pandas as pd


def GettingDataTo_oTDict(_path_data, _path_file, CaseName):
    print('Transforming data to get the oT_Dict files ****')

    StartTime = time.time()

    # reading data from the folder SourceData
    df_bus    = pd.read_csv(_path_data+'/SourceData/bus.csv'   )
    df_branch = pd.read_csv(_path_data+'/SourceData/branch.csv')
    df_gen    = pd.read_csv(_path_data+'/SourceData/gen.csv'   )

    # reading data from the folder timeseries_data_file
    df_TS_CSP = pd.read_csv(_path_data + '/timeseries_data_files/CSP/DAY_AHEAD_Natural_Inflow.csv')


    # Extracting regions
    pRegions = pd.Series(['Region_1'])
    pRegions.to_frame(name='Region').to_csv(_path_file+'/RTS-GMLC/oT_Dict_Region_'+CaseName+'.csv', sep=',', index=False)

    # Extracting areas
    IdxAreas  = df_bus['Area'].unique()
    pAreas     = pd.Series(['Area_'+str(int(i)) for i in IdxAreas])
    pAreas.to_frame(name='Area').to_csv(_path_file+'/RTS-GMLC/oT_Dict_Area_'+CaseName+'.csv', sep=',', index=False)

    # Extracting zones
    IdxZones  = df_bus['Zone'].unique()
    pZones     = pd.Series(['Zone_'+str(int(i)) for i in IdxZones])
    pZones.to_frame(name='Zone').to_csv(_path_file+'/RTS-GMLC/oT_Dict_Zone_'+CaseName+'.csv', sep=',', index=False)

    # Extracting nodes
    IdxNodes  = df_bus['Bus ID'].unique()
    pNodes     = pd.Series(['Node_'+str(int(i)) for i in IdxNodes])
    pNodes.to_frame(name='Node').to_csv(_path_file+'/RTS-GMLC/oT_Dict_Node_'+CaseName+'.csv', sep=',', index=False)

    # From Node to Zone
    Nodes = ['Node_' + str(int(df_bus['Bus ID'][i])) for i in df_bus.index]
    Zones = ['Zone_' + str(int(df_bus['Zone'  ][i])) for i in df_bus.index]
    pNodeToZone = pd.DataFrame({'Node': Nodes, 'Zone': Zones})
    pNodeToZone.to_csv(_path_file+'/RTS-GMLC/oT_Dict_NodeToZone_'+CaseName+'.csv', sep=',', index=False)

    # From Zone to Area
    Areas = ['Area_' + str(int(df_bus['Area'][i])) for i in df_bus.index]
    pZoneToArea = pd.DataFrame({'Zone': Zones, 'Area': Areas}).set_index(['Zone', 'Area'])
    pZoneToArea = pZoneToArea[~pZoneToArea.index.duplicated(keep='first')].reset_index()
    pZoneToArea.to_csv(_path_file+'/RTS-GMLC/oT_Dict_ZoneToArea_'+CaseName+'.csv', sep=',', index=False)

    # From Area to Region
    pAreaToRegion = pAreas.to_frame('Area')
    pAreaToRegion['Region'] = 'Region_1'
    pAreaToRegion.to_csv(_path_file + '/RTS-GMLC/oT_Dict_AreaToRegion_' + CaseName + '.csv', sep=',', index=False)

    # Defining circuits
    pCircuit = pd.Series(['eac1', 'eac2', 'eac3', 'eac4'])
    pCircuit.to_frame(name='Circuit').to_csv(_path_file + '/RTS-GMLC/oT_Dict_Circuit_' + CaseName + '.csv', sep=',', index=False)

    # Determining generators
    IdxGenerator = df_gen['GEN UID'].unique()
    pGenerator   = pd.Series([i for i in IdxGenerator])
    pGenerator.to_frame(name='Generator').to_csv(_path_file+'/RTS-GMLC/oT_Dict_Generation_'+CaseName+'.csv', sep=',', index=False)

    # Defining line types
    pLineType = pd.Series(['AC', 'DC'])
    pLineType.to_frame(name='LineType').to_csv(_path_file + '/RTS-GMLC/oT_Dict_Line_' + CaseName + '.csv', sep=',', index=False)

    # Defining load levels
    df_TS_CSP['Month' ] = df_TS_CSP.Month.map("{:02}".format)
    df_TS_CSP['Day'   ] = df_TS_CSP.Day.map("{:02}".format)
    df_TS_CSP['Period'] = df_TS_CSP.Period.map("{:02}".format)
    LoadLevels   = [str(df_TS_CSP['Month'][i])+str(df_TS_CSP['Day'][i])+str(df_TS_CSP['Period'][i]) for i in df_TS_CSP.index]
    pLoadLevels  = pd.DataFrame({'LoadLevel': LoadLevels})
    pLoadLevels.to_csv(_path_file + '/RTS-GMLC/oT_Dict_LoadLevel_' + CaseName + '.csv', sep=',', index=False)

    # Defining the Period
    IdxPeriod    = df_TS_CSP['Year'].unique()
    pPeriod      = pd.Series([i for i in IdxPeriod])
    pPeriod.to_frame(name='Period').to_csv(_path_file+'/RTS-GMLC/oT_Dict_Period_'+CaseName+'.csv', sep=',', index=False)

    # Defining the Scenario
    pScenarios   = pd.Series(['sc01'])
    pScenarios.to_frame(name='Scenario').to_csv(_path_file+'/RTS-GMLC/oT_Dict_Scenario_'+CaseName+'.csv', sep=',', index=False)

    # Defining the Stage
    pStage       = pd.Series(['st0'])
    pStage.to_frame(name='Stage').to_csv(_path_file+'/RTS-GMLC/oT_Dict_Stage_'+CaseName+'.csv', sep=',', index=False)

    # Defining the storage type
    pStorageType = pd.Series(['Daily', 'Weekly'])
    pStorageType.to_frame(name='StorageType').to_csv(_path_file+'/RTS-GMLC/oT_Dict_Storage_'+CaseName+'.csv', sep=',', index=False)

    # Defining the generation technologies
    IdxTechno    = df_gen['Fuel'].unique()
    pTechnology  = pd.Series([i for i in IdxTechno])
    pTechnology.to_frame(name='Technology').to_csv(_path_file+'/RTS-GMLC/oT_Dict_Technology_'+CaseName+'.csv', sep=',', index=False)

    oT_Dict_Time    = time.time() - StartTime
    print('oT_Dict files generation               ... ', round(oT_Dict_Time), 's')