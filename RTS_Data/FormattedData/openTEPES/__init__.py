"""
Open Generation, Storage, and Transmission Operation and Expansion Planning Model with RES and ESS (openTEPES)


    Args:
        case:   Name of the folder where the CSV files of the case are found
        dir:    Main path where the case folder can be found
        solver: Name of the solver

    Returns:
        Output results in CSV files that are found in the case folder.

    # Examples:
    #     >>> import openTEPES as oT
    #     >>> oT.routine("9n", "C:\\Users\\UserName\\Documents\\GitHub\\openTEPES", "glpk")
"""
# __version__ = "4.8.0"

from .openTEPES_Main             import main
from .openTEPES                  import *
from .openTEPES_InputData        import *
from .openTEPES_ModelFormulation import *
from .openTEPES_OutputResults    import *
from .openTEPES_ProblemSolving   import *
