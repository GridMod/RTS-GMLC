library(shiny)

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  
  # Expression that generates a histogram. The expression is
  # wrapped in a call to renderPlot to indicate that:
  #
  #  1) It is "reactive" and therefore should re-execute automatically
  #     when inputs change
  #  2) Its output type is a plot
  source("~/projects/MAGMA/create_plots/plot_functions.R")
  output$ann.gen.stack <- renderPlot({
    p1<-gen_stack_plot(yr.gen, r.load)
    print(p1)
  })
  output$ann.reg.gen.stack <- renderPlot({
    p1<-gen_stack_plot(r.z.gen[Region==input$region,], r.load[name==input$region,])
    print(p1)
  })
  
  
  output$table <- renderTable({
    head(avg.curt, n=input$obs)
  })
})