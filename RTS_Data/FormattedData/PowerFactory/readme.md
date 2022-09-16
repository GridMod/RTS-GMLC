
# The RTS-GMLC model in DIgSILENT PowerFactory format 


## Description

We have created a PowerFactory implementation of the RTS-GMLC model which was
originally developed by DOE/NREL/ALLIANCE (the Grid Modernization Lab
Consortium). The original model is hosted on GitHub
(https://github.com/GridMod/RTS-GMLC). The RTS-GMLC model itself is based on
the IEEE Reliability Test System (RTS).

RTS-GMLC stands for "Reliability Test System Grid Modernization Lab Consortium".


## Features

The PowerFactory implementation was developed with the goal to run DC optimal
power flow (OPF) and contingency-constrained optimal power flow (CC-OPF)
calculations on the RTS-GMLC model. The target is to study the consequences of
several security-of-supply scenarios in which part of the infrastructure could
be disrupted due to natural hazards or man-made threats. For this reason, the
model must be solved even in the event of major infrastructure disruptions and
grid-split situations, when only part of the load can be served.

As the DC OPF in PowerFactory can only control synchronous machines and we have
dispatchable wind and PV in our model, we need to use synchonous generators to
model those sources.

The base case (without any disruptions) is included as study case in the model.
Log output for running both OPF and CC-OPF are included in this publication.

Two line diagrams are provided: A schematic line diagram of the three areas,
distinguishing the two voltage levels, and a geographic line diagram as
situated in Southern California.


## Conversion of source data to PowerFactory format

We built the model in PowerFactory from scratch, using the original RTS-GMLC
source data as input. No scripted conversion was performed. Units of
various parameters were adjusted to fit the format of the PowerFactory
software (converting line lengths from miles to kilometers etc.).


## Copyright notice

This adaptation of the original RTS-GMLC model was created by the European
Commission, Joint Research Centre, Petten, Netherlands, in the years 2020-2022.
The contributors were Daniel Jung and Ricardo Fernandez-Blanco Carramolino.

We adapted the RTS-GMLC created by DOE/NREL/ALLIANCE. All changes done were of
technical nature to make the model run under DIgSILENT PowerFactory. We did not
add any essential features. Therefore we cannot claim originality or ownership
of the model. The copyright fully remains with DOE/NREL/ALLIANCE and their Data
Use Disclaimer Agreement remains valid which we print here below:


## DATA USE DISCLAIMER AGREEMENT
*(“Agreement”)*

These data (“Data”) are provided by the National Renewable Energy Laboratory
(“NREL”), which is operated by Alliance for Sustainable Energy, LLC
(“ALLIANCE”) for the U.S. Department Of Energy (“DOE”).

Access to and use of these Data shall impose the following obligations on the
user, as set forth in this Agreement. The user is granted the right, without
any fee or cost, to use, copy, and distribute these Data for any purpose
whatsoever, provided that this entire notice appears in all copies of the Data.
Further, the user agrees to credit DOE/NREL/ALLIANCE in any publication that
results from the use of these Data. The names DOE/NREL/ALLIANCE, however, may
not be used in any advertising or publicity to endorse or promote any products
or commercial entities unless specific written permission is obtained from
DOE/NREL/ ALLIANCE. The user also understands that DOE/NREL/Alliance is not
obligated to provide the user with any support, consulting, training or
assistance of any kind with regard to the use of these Data or to provide the
user with any updates, revisions or new versions of these Data.

**YOU AGREE TO INDEMNIFY DOE/NREL/ALLIANCE, AND ITS SUBSIDIARIES, AFFILIATES,
OFFICERS, AGENTS, AND EMPLOYEES AGAINST ANY CLAIM OR DEMAND, INCLUDING
REASONABLE ATTORNEYS' FEES, RELATED TO YOUR USE OF THESE DATA. THESE DATA ARE
PROVIDED BY DOE/NREL/Alliance "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
DOE/NREL/ALLIANCE BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES
OR ANY DAMAGES WHATSOEVER, INCLUDING BUT NOT LIMITED TO CLAIMS ASSOCIATED WITH
THE LOSS OF DATA OR PROFITS, WHICH MAY RESULT FROM AN ACTION IN CONTRACT,
NEGLIGENCE OR OTHER TORTIOUS CLAIM THAT ARISES OUT OF OR IN**


## Change log

v7: Some buses get dummy generators, avoiding a bug that prevents PowerFactory
from shedding all load in small islands at buses without generator.

v8: All buses with loads get dummy generators, so there is always at least one
intact generator connected to each bus with a load, albeit it's maximum output
being set to zero. This is important for keeping the problem feasible in the
presence of isolated areas without any intact generation (blackouts).

v9: Cleaned up study cases and documentation for first release. PDF file is
created using PowerFactory 2021 SP2.
