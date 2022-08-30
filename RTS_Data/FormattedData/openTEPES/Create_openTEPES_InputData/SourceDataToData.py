# Libraries
import itertools
import pandas as pd


def GettingDataTo_oTData(_path_data, _path_file, CaseName):

    # reading data from the folder SourceData
    df_Area          = pd.read_csv(_path_file+'/openTEPES_RTS-GMLC/oT_Dict_Area_'      +CaseName+'.csv')
    df_Node          = pd.read_csv(_path_file+'/openTEPES_RTS-GMLC/oT_Dict_Node_'      +CaseName+'.csv')
    df_NodeToZone    = pd.read_csv(_path_file+'/openTEPES_RTS-GMLC/oT_Dict_NodeToZone_'+CaseName+'.csv')
    df_ZoneToArea    = pd.read_csv(_path_file+'/openTEPES_RTS-GMLC/oT_Dict_ZoneToArea_'+CaseName+'.csv')

    # reading data from the folder timeseries_data_file
    df_load    = pd.read_csv(_path_data + '/timeseries_data_files/Load/DAY_AHEAD_regional_Load.csv')

    #%% Defining the set 'node to area' and 'area to node'
    ar               = []
    nd               = []
    ndzn             = []
    znar             = []
    for i in df_Area.index:
        ar.append(df_Area['Area'][i])
    for i in df_Node.index:
        nd.append(df_Node['Node'][i])
    for i in df_NodeToZone.index:
        ndzn.append((df_NodeToZone['Node'][i],df_NodeToZone['Zone'][i]))
    for i in df_ZoneToArea.index:
        znar.append((df_ZoneToArea['Zone'][i],df_ZoneToArea['Area'][i]))
    ar   = set(ar)
    nd   = set(nd)
    ndzn = set(ndzn)
    znar = set(znar)

    pNode2Area = pd.DataFrame(0, dtype=int, index=pd.MultiIndex.from_tuples(itertools.product(nd, ar), names=('Node', 'Area')), columns=['Y/N'])
    for i,j in ndzn:
        for k in ar:
            if (j,k) in znar:
                pNode2Area['Y/N'][i,k] = 1

    ndar = []
    for i,j in pNode2Area.index:
        if pNode2Area['Y/N'][i,j] == 1:
            ndar.append((i,j))
    ndar = set(ndar)

    # Defining load levels
    df_load['Month'    ] = df_load.Month.map("{:02}".format)
    df_load['Day'      ] = df_load.Day.map("{:02}".format)
    df_load['Period'   ] = df_load.Period.map("{:02}".format)
    LoadLevels           = [str(df_load['Month'][i])+str(df_load['Day'][i])+str(df_load['Period'][i]) for i in df_load.index]
    df_load['LoadLevel'] = pd.DataFrame({'LoadLevel': LoadLevels})

    pDemandPerArea       = df_load.iloc[: ,4 :]
    pDemandPerArea.columns = ['Area_1', 'Area_2', 'Area_3', 'LoadLevel']

