library(shiny)


shinyUI(fluidPage(
  
  # Application title
  titlePanel("Multi-area Grid Metrics Analyzer"),
  
  # Sidebar with a slider input for the number of bins
  sidebarLayout(
    sidebarPanel(
      selectInput("region", "Region:", unique(plot.data.all$Region)),
      selectInput("period", "Period:", unique(plot.data.all$Period)),
      selectInput("type",   "Type:",   unique(plot.data.all$Type)),
      
      conditionalPanel(condition = "input.conditionedPanels=='plots'",
                       numericInput("text.size", "Text size for figures:", 12)
                       ),
      conditionalPanel(condition = "input.conditionedPanels=='tables'",
                       numericInput("obs", "Number of observations to view:", 10)
                       )
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
      tabsetPanel(
        tabPanel("Inputs",
                 p("This code generates figures and tables from a PLEXOS solution file."),
                 p("This output was generated on ", format(Sys.time(), '%d %B %Y')), br(),
                 br(),
                 h1("Inputs:"), 
                 
                 numericInput("n.scenarios", 
                              label = 'Number of scenarios to analyze', value=1), 
                 textInput("db.loc",
                           label = 'Location of PLEXOS solution file or processed database'),
                 radioButtons("Using.Gen.Type.Mapping.CSV", 
                              label = "Get Gen-Type mapping from .csv?", 
                              choices = list('TRUE','FALSE')),
                 radioButtons("reassign.zones", 
                              label = "Re-assign Zones?", 
                              choices = list('TRUE','FALSE')),
                 checkboxGroupInput("run.sections",
                                    label = "Select plots to create",
                                    choices = list('total.gen.stack'=TRUE,
                                                   'zone.gen.stacks'=TRUE,
                                                   'region.gen.stacks'=TRUE,
                                                   'individual.region.stacks.log'=TRUE,
                                                   'key.period.dispatch.total.log'=TRUE,
                                                   'key.period.dispatch.zone.log'=TRUE,
                                                   'key.period.dispatch.region.log'=TRUE,
                                                   'daily.curtailment'=TRUE,
                                                   'interval.curtailment'=TRUE,
                                                   'annual.generation.table'=TRUE,
                                                   'annual.cost.table'=TRUE,
                                                   'region.zone.flow.table'=TRUE,
                                                   'interface.flow.table'=TRUE,
                                                   'interface.flow.plots'=TRUE,
                                                   'key.period.interface.flow.plots'=TRUE,
                                                   'annual.reserves.table'=TRUE,
                                                   'reserves.plots'=TRUE,
                                                   'region.zone.gen.table'=TRUE,
                                                   'capacity.factor.table'=TRUE,
                                                   'price.duration.curve'=TRUE,
                                                   'commit.dispatch.zone'=TRUE,
                                                   'commit.dispatch.region'))),
        tabPanel("Plots", 
                 plotOutput("ann.gen.stack"),
                 plotOutput("ann.reg.gen.stack"),
                 value = 'plots'
                 ),
        
        tabPanel("Tables",
                 tableOutput("table"),
                 value = 'tables'
                 ),
        id = 'conditionedPanels'
      )
    )
  )
))

