# Libraries
import os
import time
import pandas as pd


def GetDictionaries(_path_data, _path_file):

    # reading the bus information
    df = pd.read_csv(_path_data+'/SourceData/bus.csv')

