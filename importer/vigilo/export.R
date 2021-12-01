suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(RSQLite)
  library(lubridate)
})

scriptdir <- here()
exportdir <- paste0(scriptdir,"/dataset/vigilo/")
sqldb <- paste0(scriptdir, '/db/world-datas-analysis.db')

source(paste0(scriptdir,"/lib/R/file.R"))

# Make image directory
dir.create(exportdir,recursive=TRUE, showWarnings = FALSE)


# Init connexion
con <- dbConnect(RSQLite::SQLite(), sqldb)

# Category
category <- dbGetQuery(con, "SELECT CategoryId as catid, catname, catname_en, catcolor, catdisable FROM vigilo_category")
write_fwf(category,paste0(exportdir,"categories.txt"))

# Instance
instance <- dbGetQuery(con, "SELECT InstanceId as instanceid, scope, name as instancename, api_path, country, version FROM vigilo_instance")
write_fwf(instance,paste0(exportdir,"instances.txt"))

obs <- dbGetQuery(con, "SELECT scope, token, coordinates_lat, coordinates_lon, address, timestamp,cityname,CategoryId as catid,approved  FROM vigilo_observation vo INNER JOIN vigilo_instance vi ON vo.InstanceID = vi.InstanceID")

obs <- obs %>%
  mutate(
    datetime = as.character(as_datetime(timestamp,origin="1970-01-01"))
  ) %>%
  relocate(datetime,.before = scope) %>%
  arrange(datetime) %>%
  select(-timestamp)

# Export to Fixed with file
write_fwf(obs,paste0(exportdir,"observations.txt"))