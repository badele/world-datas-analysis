suppressPackageStartupMessages({
  library(here)
  library(RSQLite)
})

scriptdir <- here()
exportdir <- paste0(scriptdir,"/dataset/vigilo/")
sqldb <- paste0(scriptdir, '/db/world-datas-analysis.db')

source(paste0(scriptdir,"/lib/R/file.R"))

# Make image directory
dir.create(exportdir,recursive=TRUE, showWarnings = FALSE)

# Get query
con <- dbConnect(RSQLite::SQLite(), sqldb)
data <- dbGetQuery(con, "SELECT name as instanceName, country, token, coordinates_lat, coordinates_lon, address, timestamp,cityname,catname  FROM v_vigilo_approved_observations")

# Export to Fixed with file
write_fwf(data,paste0(exportdir,"approved_observations.txt"))