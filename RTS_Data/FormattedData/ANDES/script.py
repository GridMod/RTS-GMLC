# coding: utf-8

import os
import andes
curr_dir = os.path.dirname(os.path.realpath(__file__))

def create_rts_ANDES_file(folder):
    system = andes.main.run_case(os.path.join(folder, 'RTS-GMLC.raw'),
                                 convert='xlsx')