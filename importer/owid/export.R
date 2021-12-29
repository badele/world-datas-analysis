suppressPackageStartupMessages({
  library(here)
  library(tidyr)
  library(dplyr)
  library(RSQLite)
  library(lubridate)
})

scriptdir <- here()
exportdir <- paste0(scriptdir,"/dataset/owid/")
sqldb <- paste0(scriptdir, '/db/world-datas-analysis.db')

source(paste0(scriptdir,"/lib/R/file.R"))

# Make image directory
dir.create(exportdir,recursive=TRUE, showWarnings = FALSE)

# Init connexion
con <- dbConnect(RSQLite::SQLite(), sqldb)

# Gapminder population
population <- dbGetQuery(con, "SELECT * FROM v_owid_data_values WHERE variableId=72")
population <- population %>%
  arrange(year,Country) %>%
  select(Country, year, value) %>%
  pivot_wider(names_from = Country, values_from = value) %>%
  replace(is.na(.), 0) %>% # Fix fwf export
  as.data.frame()

write_fwf(population,paste0(exportdir,"owid-gapminder-population.txt"),replace_na="")
