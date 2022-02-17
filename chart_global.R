# load packages and read data for chart
library(ggplot2)
library(readr)
library(dplyr)
library(snakecase)

d <- read_csv("https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/owid-covid-data.csv")

# our potential inputs
variable <- "new_deaths_smoothed_per_million"
locations <- c("Africa", "Asia", "Europe", "North America",
  "Oceania", "South America")
date_range <- as.Date(c("2020-01-01", "2022-12-31"))

# Our Chart
ggplot(data = filter(d, location %in% locations,
  date >= date_range[1], date <= date_range[2]),
  aes_string("date", variable, color = "location")) +
  geom_point(size = 0.8, alpha = 0.8) +
  geom_line() +
  theme_bw() +
  labs(
    x = "Date",
    y = to_title_case(variable),
    color = "Location"
  ) +
  guides(color = guide_legend(
    override.aes = list(lty = NA, size = 5, shape = 15)))
