library(pacman)
p_load(shiny, magrittr, plyr, stringi)

# Initialize the shiny server. This "function" reads in the input and output objects which are created in the user interface.
# It then carries out the appropriate action based on the inputs and displays the outputs. 
shinyServer(function(input, output) {

  # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  # Organizes each section into blocks that are used by the logic operators to control what is shown on the GUI
  genTypeSections = c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 22, 23, 25, 26)
  regionZoneSections = c(2, 6, 15, 22, 25)
  genStack = c(1, 2, 3, 4, 5, 6, 7, 25, 26, 9, 11, 21)
  keyPeriods = c(5, 6, 7, 18)
  interfacePlotSections = c(16, 17, 18)
  DA_RT_sections = c(25, 26)
  curtailmentSections = c(8, 9, 10, 11, 13)
  plotSections = c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 17, 18, 20, 21, 24, 25, 26)
  curtTypes = c(9, 11)
  reserveTypes = c(21)
  
  # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  # Create the DA_RT member of the output object. 
  # First check to see if either of the numbers in DA_RT_sections (above) are found in sectionsToRun3 (part of the input object, created in the user interface). 
  # If so that means those boxes were checked in the user interface and output$DA_RT is set to TRUE. 
  output$DA_RT = reactive({
    any(DA_RT_sections %in% input$sectionsToRun3)
  })
  outputOptions(output, 'DA_RT', suspendWhenHidden=FALSE)
  
  # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  # Looks for any of the sections in genTypeSections to be selected in the user interface sections ("sectionsToRun1, sectionsToRun2, sectionsToRun3") to run check boxes
  # If found, it sets output$genType to TRUE.
  output$genType = reactive({
    any(genTypeSections %in% input$sectionsToRun1 |
        genTypeSections %in% input$sectionsToRun2 |
        genTypeSections %in% input$sectionsToRun3)
  })
  outputOptions(output, 'genType', suspendWhenHidden=FALSE)
  
  # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  # Checks to see if curtailment by type is selected.
  # If found, it sets output$curtType to TRUE.
  output$curtType = reactive({
    any(curtTypes %in% input$sectionsToRun1 |
        curtTypes %in% input$sectionsToRun2 |
        curtTypes %in% input$sectionsToRun3)
  })
  outputOptions(output, 'curtType', suspendWhenHidden=FALSE)

  # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  # Checks to see if reserves by type is selected.
  # If found, it sets output$reserveType to TRUE.
  output$reserveType = reactive({
    any(reserveTypes %in% input$sectionsToRun1 |
        reserveTypes %in% input$sectionsToRun2 |
        reserveTypes %in% input$sectionsToRun3)
  })
  outputOptions(output, 'reserveType', suspendWhenHidden=FALSE)

  # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  # Checks for any sections that show zonal results. In the user interface if this is true it presents the option to reassign what regions make up what zones.
  output$zonesUsed = reactive({
    any(regionZoneSections %in% input$sectionsToRun1 |
        regionZoneSections %in% input$sectionsToRun2 |
        regionZoneSections %in% input$sectionsToRun3)
  })
  outputOptions(output, 'zonesUsed', suspendWhenHidden=FALSE)
  
  # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  # Checks for what sections will create a dispatch stack of generation. 
  # Allows the user (in the UI) to set the dispatch stack order, generation plot color, if the gen type should be considered in renewable calculations, and 
  # if it should be shown in the DA-RT plots.
  output$genStackPlot = reactive({
    any(genStack %in% input$sectionsToRun1 |
        genStack %in% input$sectionsToRun2 |
        genStack %in% input$sectionsToRun3)
  })
  outputOptions(output, 'genStackPlot', suspendWhenHidden=FALSE)
  
  # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  # Checks to see if any sections involving key periods are selected.
  # If so, output$keyPeriodPlots is TRUE and the UI will display the key period options.
  output$keyPeriodPlots = reactive({
    any(keyPeriods %in% input$sectionsToRun1 |
        keyPeriods %in% input$sectionsToRun2 |
        keyPeriods %in% input$sectionsToRun3)
  })
  outputOptions(output, 'keyPeriodPlots', suspendWhenHidden=FALSE)
  
  
  # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  # Checks to see if any sections involving interface data are selected.
  # If so, output$interfacePlots is TRUE and the UI will display the key period options.
  output$interfacePlots = reactive({
    any(interfacePlotSections %in% input$sectionsToRun1 |
        interfacePlotSections %in% input$sectionsToRun2 |
        interfacePlotSections %in% input$sectionsToRun3)
  })
  outputOptions(output, 'interfacePlots', suspendWhenHidden=FALSE)
  
  # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  # Checks to see if any sections involving curtailment calculations are selected. If so, output$curtailmentCalcs is TRUE.
  output$curtailmentCalcs = reactive({
    any(curtailmentSections %in% input$sectionsToRun1 |
        curtailmentSections %in% input$sectionsToRun2 |
        curtailmentSections %in% input$sectionsToRun3)
  })
  outputOptions(output, 'curtailmentCalcs', suspendWhenHidden=FALSE)
  
  # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  # Checks to see if any sections that produce a plot are selected. If so, output$plots is TRUE.
  output$plots = reactive({
    any(plotSections %in% input$sectionsToRun1 |
        plotSections %in% input$sectionsToRun2 |
        plotSections %in% input$sectionsToRun3)
  })
  outputOptions(output, 'plots', suspendWhenHidden=FALSE)
  
  # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  # This section runs when the create CSV button is pressed in the user interface.
  
  observeEvent(input$createCSV, {
    
    if( input$genTypeMapping == 1 ) { genTypeMapping = 'TRUE' } else { genTypeMapping = 'FALSE' }
    
    start.end.time = c( input$keyPeriodRange1, input$keyPeriodRange2, input$keyPeriodRange3, input$keyPeriodRange4, 
                                            input$keyPeriodRange5, input$keyPeriodRange6, input$keyPeriodRange7, input$keyPeriodRange8 )
    
    start.time = start.end.time[seq(1,length(start.end.time),2)]
    end.time = start.end.time[seq(2,length(start.end.time),2)]

    write_data = list(  Database.Location = input$db.loc,
                        DayAhead.Database.Location = input$DA.RT.db.loc,
                        Using.Gen.Type.Mapping.CSV = genTypeMapping,
                        reassign.zones = input$reassignZones,
                        Gen.Region.Zone.Mapping.Filename = input$regionZoneMappingFile,
                        CSV.Gen.Type.File.Location = input$genTypeMappingLocation,
                        PLEXOS.Gen.Category = c( input$plexosCategory1,  input$plexosCategory2,  input$plexosCategory3,
                                                 input$plexosCategory4,  input$plexosCategory5,  input$plexosCategory6,
                                                 input$plexosCategory7,  input$plexosCategory8,  input$plexosCategory9,
                                                 input$plexosCategory10, input$plexosCategory11, input$plexosCategory12,
                                                 input$plexosCategory13, input$plexosCategory14, input$plexosCategory15 ),
                        PLEXOS.Desired.Type = c( input$genType1,  input$genType2,  input$genType3,  input$genType4,  input$genType5,
                                                 input$genType6,  input$genType7,  input$genType8,  input$genType9,  input$genType10,
                                                 input$genType11, input$genType12, input$genType13, input$genType14, input$genType15 ),
                        Gen.Type = c( input$genOrder1,  input$genOrder2,  input$genOrder3,  input$genOrder4,  input$genOrder5,  input$genOrder6,  input$genOrder7,
                                      input$genOrder8,  input$genOrder9,  input$genOrder10, input$genOrder11, input$genOrder12, input$genOrder13, input$genOrder14,
                                      input$genOrder15, input$genOrder16, input$genOrder17, input$genOrder18, input$genOrder19, input$genOrder20 ),
                        Plot.Color = c( input$genTypeColor1,  input$genTypeColor2,  input$genTypeColor3,  input$genTypeColor4,  input$genTypeColor5, 
                                        input$genTypeColor6,  input$genTypeColor7,  input$genTypeColor8,  input$genTypeColor9,  input$genTypeColor10, 
                                        input$genTypeColor11, input$genTypeColor12, input$genTypeColor13, input$genTypeColor14, input$genTypeColor15, 
                                        input$genTypeColor16, input$genTypeColor17, input$genTypeColor18, input$genTypeColor19, input$genTypeColor20 ),
                        Gen.Order = c( input$genOrder1,  input$genOrder2,  input$genOrder3,  input$genOrder4,  input$genOrder5,  input$genOrder6,  input$genOrder7,
                                       input$genOrder8,  input$genOrder9,  input$genOrder10, input$genOrder11, input$genOrder12, input$genOrder13, input$genOrder14,
                                       input$genOrder15, input$genOrder16, input$genOrder17, input$genOrder18, input$genOrder19, input$genOrder20 ),
                        Renewable.Types.for.Curtailment = c( input$reType1,  input$reType2,  input$reType3,  input$reType4,  input$reType5, 
                                                             input$reType6,  input$reType7,  input$reType8,  input$reType9,  input$reType10,
                                                             input$reType11, input$reType12, input$reType13, input$reType14, input$reType15, 
                                                             input$reType16, input$reType17, input$reType18, input$reType19, input$reType20 ),	
                        DA.RT.Plot.Types = c( input$DA_RT_Type1,  input$DA_RT_Type2,  input$DA_RT_Type3,  input$DA_RT_Type4,  input$DA_RT_Type5, 
                                              input$DA_RT_Type6,  input$DA_RT_Type7,  input$DA_RT_Type8,  input$DA_RT_Type9,  input$DA_RT_Type10, 
                                              input$DA_RT_Type11, input$DA_RT_Type12, input$DA_RT_Type13, input$DA_RT_Type14, input$DA_RT_Type15, 
                                              input$DA_RT_Type16, input$DA_RT_Type17, input$DA_RT_Type18, input$DA_RT_Type19, input$DA_RT_Type20 ),	
                        Key.Periods = c( input$keyPeriodName1, input$keyPeriodName2, input$keyPeriodName3, input$keyPeriodName4, 
                                         input$keyPeriodName5, input$keyPeriodName6, input$keyPeriodName7, input$keyPeriodName8 ),
                        Start.Time = start.time,
                        End.Time = end.time,
                        Sections.to.Run = c( input$sectionsToRun1, input$sectionsToRun2, input$sectionsToRun3 ),
                        Fig.Path = input$figureLocation,
                        Ignore.Zones = c( input$ignoreZone1, input$ignoreZone2, input$ignoreZone3, input$ignoreZone4, input$ignoreZone5 ),
                        Ignore.Regions = c( input$ignoreRegion1, input$ignoreRegion2, input$ignoreRegion3, input$ignoreRegion4, input$ignoreRegion5 ),
                        Interfaces.for.Flows = c( input$interface1, input$interface2, input$interface3, input$interface4, input$interface5,
                                                  input$interface6, input$interface7, input$interface8, input$interface9, input$interface10 ) 
                        )
    
    write_data_df = as.data.frame(stri_list2matrix(write_data), stringsAsFactors=FALSE)
    names(write_data_df) = names(write_data)
    
    write_data_df$Plot.Color[which(write_data_df$Gen.Type=="")]=NA
    write_data_df$Start.Time[which(write_data_df$Key.Periods=="")]=NA
    write_data_df$End.Time[which(write_data_df$Key.Periods=="")]=NA

    write_data_df$Renewable.Types.for.Curtailment[which(write_data_df$Renewable.Types.for.Curtailment=="TRUE")] =
      write_data_df$Gen.Order[which(write_data_df$Renewable.Types.for.Curtailment=="TRUE")]
    write_data_df$Renewable.Types.for.Curtailment[which(write_data_df$Renewable.Types.for.Curtailment=="FALSE")]=NA
    
    write_data_df$DA.RT.Plot.Types[which(write_data_df$DA.RT.Plot.Types=="TRUE")] =
      write_data_df$Gen.Order[which(write_data_df$DA.RT.Plot.Types=="TRUE")]
    write_data_df$DA.RT.Plot.Types[which(write_data_df$DA.RT.Plot.Types=="FALSE")]=NA
    
    write.csv(write_data_df, paste0(input$csvLocation,'/input_data.csv'), row.names=FALSE)

  })
  
})