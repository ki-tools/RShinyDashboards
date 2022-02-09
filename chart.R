library(ggplot2)
library(readr)
library(dplyr)
library(lubridate)

# Our data (updates daily)
url <- "https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-states.csv"  # nolint
nyt <- read_csv(url) %>%
  mutate(cases100k = cases / 1000)

# Our potential inputs
variable <- c("deaths", "cases1000")[2] # what is on our y axis.
daterange <- c(ymd("2020-01-01"), ymd("2022-12-31")) # filter for x-axis
states <- c("New York", "Texas", "Florida") # which states to plot.

# Create a filtered dataset for plotting.
plotdata <- nyt  %>%
    filter(
      state %in% states,
      date >= daterange[1],
      date <= daterange[2])

# create the plot
# Notice the use of .data[[variable]] to select the column to place on the y-axis
ggplot(data = plotdata, aes(x = date, y = .data[[variable]], color = state)) +
  geom_point(size = .5, alpha = .8) +
  geom_line() +
  theme_bw() +
  guides(color = guide_legend(
    override.aes = list(lty = NA, size = 5, shape = 15))) +
  labs(
    title = paste0("Progression of the pandemic from ",
      daterange[1], " to ", daterange[2]),
    x = "Date",
    y = ifelse(variable == "deaths", "Deaths", "Cases (1,000)"),
    color = "State"
  )
