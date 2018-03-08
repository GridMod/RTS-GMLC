from pyomo.core import *

import pyomo.util.plugin

import math

class UCPrettyPrint(pyomo.util.plugin.SingletonPlugin):

   pyomo.util.plugin.implements(IPyomoScriptPostprocess)

   def apply(self, **kwds):

      options=kwds.pop('options')
      instance=kwds.pop('instance')
      results=kwds.pop('results')

      average_demand = sum(value(instance.Demand[b,t]) for b in instance.Buses for t in instance.TimePeriods) / float(len(instance.Demand))
      minimum_demand = min(value(instance.Demand[b,t]) for b in instance.Buses for t in instance.TimePeriods)
      maximum_demand = max(value(instance.Demand[b,t]) for b in instance.Buses for t in instance.TimePeriods)

      print("")
      print("Minimum demand=%5.2f" % minimum_demand)
      print("Average demand=%5.2f" % average_demand)
      print("Maximum demand=%5.2f" % maximum_demand)
      if minimum_demand > 0.0:
         print("Average-to-min ratio=%5.2f" % (average_demand / minimum_demand))
      print("Peak-to-average ratio=%5.2f" % (maximum_demand / average_demand))

      total_t0_power_output = 0.0
      for g in sorted(instance.ThermalGenerators):    
         total_t0_power_output += value(instance.PowerGeneratedT0[g])
      print("")
      print("Power generated at T0=%8.2f" % total_t0_power_output)

      total_max_power_output = 0.0
      for g in sorted(instance.ThermalGenerators):    
         total_max_power_output += value(instance.MaximumPowerOutput[g])
      print("")
      print("Max power output of thermal fleet=%8.2f" % total_max_power_output)

      print("")
      print("Maximum nondispatchable power available")
      for t in range(1, 25):
         print("%2d : %5.2f" % (t, sum(value(instance.MaxNondispatchablePower[g, t]) for g in instance.AllNondispatchableGenerators)))

      print("")
      print("Unit On                                                            Total startup cost  Total shutdown cost  Total no-load cost  Total production cost")
      for g in sorted(instance.ThermalGenerators):
         min_cost = sum(value(instance.MinimumProductionCost[g]) * value(instance.UnitOn[g,t]) for t in range(1,25))
         total_cost = sum(value(instance.ProductionCost[g,t]) for t in range(1,25))
         print("%20s: " % str(g).ljust(8),end="")
         for t in range(1,25):
            print("%1d " % (value(instance.UnitOn[g,t])),end="")
         print(" %9.2f" % sum(value(instance.StartupCost[g, t]) for t in range(1,25)),end="")
         print("            %9.2f" % sum(value(instance.ShutdownCost[g, t]) for t in range(1,25)),end="")
         print("            %9.2f" % min_cost,end="")
         print("            %9.2f" % total_cost,end="")

         print("")

      print("")
      print("Power Generated")
      for g in sorted(instance.ThermalGenerators):
         print("%20s: " % str(g).ljust(8),end="")
         for t in range(1,25):
            print("%6.2f " % (math.fabs(value(instance.PowerGenerated[g,t]))),end="")
         print("")

      print("")
      print("Maximum Power Available")
      for g in sorted(instance.ThermalGenerators):
         print("%20s: " % str(g).ljust(8),end="")
         for t in range(1,25):
            print("%6.2f " % (math.fabs(value(instance.MaximumPowerAvailable[g,t]))), end="")
         print("")

      print("")
      print("Production Costs")
      for g in sorted(instance.ThermalGenerators):
         print("%20s:" % str(g).ljust(8),end="")
         for t in range(1,25):
            print("%8.2f " % (value(instance.MinimumProductionCost[g]) * value(instance.UnitOn[g,t]) + value(instance.ProductionCost[g,t])), end="")
         print("")

      print("")
      print("Renewables Curtailment")
      for g in sorted(instance.AllNondispatchableGenerators):
         print("%20s: " % str(g).ljust(8),end="")
         for t in range(1,25):
            print("%6.2f " % (value(instance.MaxNondispatchablePower[g,t]) - value(instance.NondispatchablePowerUsed[g,t])), end="")
         print("")

      print("")
      print("Time: thermal generated : thermal available : nondispatch used : nondispatch excess : demand : reserve requirements : thermal excess")
      for t in range(1, 25):
         total_thermal_generated = sum(value(instance.PowerGenerated[g,t]) for g in instance.ThermalGenerators)
         total_thermal_available = sum(value(instance.MaximumPowerAvailable[g,t]) for g in instance.ThermalGenerators)
         total_nondispatch_used = sum(value(instance.NondispatchablePowerUsed[g,t]) for g in instance.AllNondispatchableGenerators)
         total_nondispatch_available = sum(value(instance.MaxNondispatchablePower[g,t]) for g in instance.AllNondispatchableGenerators)
         total_demand = sum(value(instance.Demand[b, t]) for b in  instance.Buses)
         thermal_excess = total_thermal_available - total_thermal_generated - value(instance.ReserveRequirement[t])
         print("%2d : %10.2f           %10.2f          %10.2f        %10.2f           %10.2f      %10.2f      %10.2f" % (int(t), 
                                                                                                                         math.fabs(total_thermal_generated), 
                                                                                                                         math.fabs(total_thermal_available), 
                                                                                                                         math.fabs(total_nondispatch_used),
                                                                                                                         math.fabs(total_nondispatch_available) - math.fabs(total_nondispatch_used),
                                                                                                                         math.fabs(total_demand), 
                                                                                                                         math.fabs(value(instance.ReserveRequirement[t])), 
                                                                                                                         math.fabs(thermal_excess)))

      print("")
