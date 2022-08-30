# Libraries
import pandas as pd


def GettingDataTo_oTData(_path_data, _path_file, CaseName):

    # reading data from the folder SourceData
    df_bus    = pd.read_csv(_path_data+'/SourceData/bus.csv'   )