# Libraries
import os
import pandas as pd

import Create_openTEPES_InputData as ID

CaseName = 'RTS-GMLC'

# Setting up the path
_path_data = os.path.abspath(os.path.join(os.path.dirname( __file__ ), '..', '..'))
_path_file = os.path.dirname(__file__)

print('*** Creating the case RTS-GLC in openTEPES format ****')

ID.GettingDataTo_oTDict(_path_data, _path_file, CaseName)

ID.GettingDataTo_oTData(_path_data, _path_file, CaseName)

print('*** End                                           ****')
