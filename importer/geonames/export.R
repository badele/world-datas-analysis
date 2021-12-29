suppressPackageStartupMessages({
  library(here)
  library(tidyr)
  library(dplyr)
  library(RSQLite)
  library(lubridate)
})

scriptdir <- here()
exportdir <- paste0(scriptdir,"/dataset/geonames/")
sqldb <- paste0(scriptdir, '/db/world-datas-analysis.db')

source(paste0(scriptdir,"/lib/R/file.R"))

# Make image directory
dir.create(exportdir,recursive=TRUE, showWarnings = FALSE)

# Init connexion
con <- dbConnect(RSQLite::SQLite(), sqldb)

# Country
country <- dbGetQuery(con, "SELECT * FROM v_geonames_country")
country <- country %>%
  mutate(area=round(area,0)) %>%
  as.data.frame()

write_fwf(country,paste0(exportdir,"country.txt"))
