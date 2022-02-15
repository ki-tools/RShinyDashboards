# Setup ----
library(shiny)
library(shinydashboard)
library(readr)
library(dplyr)
library(ggplot2)


# Define UI ----
header <- dashboardHeader(
  title = "COVID-19 NYT Data Dashboard",
  titleWidth = 400
)

sidebar <- dashboardSidebar(
  width = 400,
  actionButton("load", label = "Import New York Times data"),
  radioButtons("variable",
    label = "Cases or Deaths?",
    choices = c(
      "Number of Deaths" = "deaths",
      "Number of Cases" = "cases1000")),
  selectInput("state", "Which states?", state.name,
    multiple = TRUE, selected = "New York"),
  dateRangeInput("daterange", "Date range:",
    start = "2020-01-01", end = "2022-12-31"),
  actionButton("makeplot", label = "Explore Visualization")
)

body <- dashboardBody(
  box(
    title = "Pandemic time-series (USA)", solidHeader = TRUE, width = 16,
    collapsible = TRUE,
    plotOutput("timeseries", height = 500, width = "auto")
  ),
  box(
    title = "Total reported cases (USA)", solidHeader = TRUE, width = 6,
    div(style = "font-size:50px", textOutput("casetotal"))
  ),
  box(
    title = "Total reported deaths (USA)", solidHeader = TRUE, width = 6,
    div(style = "font-size:50px", textOutput("deathtotal"))
  )
)

# Run the application ----
ui <- dashboardPage(skin = "purple", header, sidebar, body)

nyt <- reactiveVal()
plotdata <- reactiveVal()

server <- function(input, output) {
  observeEvent(input$load, {
    url <- "https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-states.csv"
    fulldata <- readr::read_csv(url) %>%
      mutate(cases100k = cases / 1000)

    # This reactive item now has is composed of the NYT COVID-19 data.
    nyt(fulldata)

    output$deathtotal <- renderText(
      fulldata %>%
        filter(date == max(date)) %>%
        pull(deaths) %>%
        sum() %>%
        format(big.mark = ",")
    )

    output$casetotal <- renderText(
      fulldata %>%
        filter(date == max(date)) %>%
        pull(cases) %>%
        sum() %>%
        format(big.mark = ",")
    )
  })

  observeEvent(input$makeplot, {
    # notice use of `input$` to pull the user input values into the function.
    # "if" stops outputs from being created if user hasn't clicked import
    if (length(nyt()) != 0) {
      newdat <- nyt() %>%
        filter(state %in% input$state,
          date >= input$daterange[1],
          date <= input$daterange[2])

      # This reactive item now has is composed of the filtered data.
      plotdata(newdat)
      # notice the use of plotdata() as the data object to signal a reactive dataset.
      output$timeseries <- renderPlot({
        ggplot(data = plotdata(),
          aes(date, .data[[isolate(input$variable)]], color = state)) +
          geom_point(size = .8, alpha = .8) +
          geom_line() +
          theme_bw() +
          labs(
            title = paste0(
              "Progression of the pandemic from ",
              input$daterange[1], " to ", input$daterange[2]
            ),
            x = "Date",
            y = ifelse(isolate(input$variable) == "deaths",
              "Deaths", "Cases (1,000)"),
            color = "State"
          ) +
          guides(color = guide_legend(
            override.aes = list(lty = NA, size = 5, shape = 15)))
      })
    }
  })
}

shinyApp(ui, server)
