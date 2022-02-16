# Setup ----
library(shiny); library(shinydashboard); library(readr); library(dplyr); library(ggplot2); library(stringr); library(plotly); library(snakecase)

# Define UI ----
header <- dashboardHeader(
  title = "COVID-19 Global Data Dashboard",
  titleWidth = 400
)

sidebar <- dashboardSidebar(
  width = 400,
  actionButton("load", label = "Import data from Our World in Data"),
  selectInput("variable", "What variable", "(data not loaded)",
    multiple = FALSE, selected = "(data not loaded)"),
  selectInput("location", "Which location?", "(data not loaded)",
    multiple = TRUE, selected = "(data not loaded)"),
  dateRangeInput("daterange", "Date range:",
    start = "2020-01-01", end = "2022-12-31"),
  actionButton("makeplot", label = "Explore Visualization")
)

body <- dashboardBody(
  box(
    title = "Pandemic time-series", solidHeader = TRUE, width = 16,
    collapsible = TRUE,
    plotlyOutput("timeseries", height = 500, width = "auto")
  ),
  box(
    title = "Total reported cases (World)", solidHeader = TRUE, width = 6,
    div(style = "font-size:50px", textOutput("casetotal"))
  ),
  box(
    title = "Total reported deaths (World)", solidHeader = TRUE, width = 6,
    div(style = "font-size:50px", textOutput("deathtotal"))
  )
)

ui <- dashboardPage(skin = "purple", header, sidebar, body)

covid_data <- reactiveVal()
plot_data <- reactiveVal()

server <- function(input, output, session) {
  observeEvent(input$load, {
    url <- "https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/owid-covid-data.csv"
    owid_data <- readr::read_csv(url)

    # This reactive item now has is composed of the COVID-19 data.
    covid_data(owid_data)

    output$deathtotal <- renderText(
      owid_data %>%
        filter(location == "World", date == max(date)) %>%
        pull(total_deaths) %>%
        sum() %>%
        format(big.mark = ",")
    )

    output$casetotal <- renderText(
      owid_data %>%
        filter(location == "World", date == max(date)) %>%
        pull(total_cases) %>%
        sum() %>%
        format(big.mark = ",")
    )

    choices <- names(owid_data)
    names(choices) <- to_title_case(choices)
    updateSelectInput(session, "variable",
      choices = choices,
      selected = "total_cases_per_million"
    )
    updateSelectInput(session, "location",
      choices = unique(owid_data$location),
      selected = "World"
    )
  })

  observeEvent(input$makeplot, {
    # notice use of `input$` to pull the user input values into the function.
    # "if" stops outputs from being created if user hasn't clicked import
    if (length(covid_data()) != 0) {
      newdat <- covid_data() %>%
        filter(location %in% input$location,
          date >= input$daterange[1],
          date <= input$daterange[2])

      # This reactive item now has is composed of the filtered data.
      plot_data(newdat)
      # notice the use of plot_data() as the data object to signal a reactive dataset.
      output$timeseries <- renderPlotly({
        ggplot(data = plot_data(),
          aes_string("date", isolate(input$variable), color = "location")) +
          geom_point(size = 0.8, alpha = 0.8) +
          geom_line() +
          theme_bw() +
          labs(
            title = paste0(
              "Progression of the pandemic from ",
              input$daterange[1], " to ", input$daterange[2]
            ),
            x = "Date",
            y = isolate(snakecase::to_title_case(input$variable)),
            color = "Location"
          ) +
          guides(color = guide_legend(
            override.aes = list(lty = NA, size = 5, shape = 15)))
      })
    }
  })
}

shinyApp(ui, server)
