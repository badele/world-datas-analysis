suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(RSQLite)
  library(lubridate)
})

scriptdir <- here()
exportdir <- paste0(scriptdir,"/dataset/")
sqldb <- paste0(scriptdir, '/db/world-datas-analysis.db')

source(paste0(scriptdir,"/lib/R/file.R"))

# Make export directory
dir.create(exportdir,recursive=TRUE, showWarnings = FALSE)

# Init connexion
con <- dbConnect(RSQLite::SQLite(), sqldb)

replacechar <- function(df) {
  result <- df %>%
  mutate_if(is.character, ~gsub("\t", ' ', .)) %>% # Tabulation
  mutate_if(is.character,~iconv(., 'utf-8', 'ASCII//TRANSLIT', sub='~'))

  return(result)
}

# Variable
dataset <- dbGetQuery(con, "SELECT  * FROM wda_variable") %>% 
  replacechar()

write_fwf(dataset,paste0(exportdir,"variable.txt"))

# Provider
dataset <- dbGetQuery(con, "SELECT  * FROM wda_provider") %>%
  replacechar()

write_fwf(dataset,paste0(exportdir,"provider.txt"))

# Dataset
dataset <- dbGetQuery(con, "SELECT * FROM wda_dataset") %>%
  replacechar()

write_fwf(dataset,paste0(exportdir,"dataset.txt"))
