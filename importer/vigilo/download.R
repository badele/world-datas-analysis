suppressPackageStartupMessages({
  library(rio)
  library(httr)
  library(dplyr)
  library(RSQLite)
  library(jsonlite)
})

# Commons vars
dlfolder <- "./downloaded/vigilo/"
dbfolder <- "./db/"

# Make export directory
dir.create(dlfolder,recursive=TRUE, showWarnings = FALSE)

################################################################################
# Function
################################################################################

# Get categories
download_categories <- function() {
  url <- "https://vigilo-bf7f2.firebaseio.com/categorieslist.json"
  jcategories <- jsonlite::fromJSON(url)

  # Format
  jcategories <- jcategories %>%
    mutate_at(vars("catdisable"), ~replace(., is.na(.), 0)) 
  #jcategories$catdisable <- as.logical(jcategories$catdisable)

  # Export CSV
  rio::export(jcategories, paste0(dlfolder, "category.csv"))
}

# Get all instances
download_instances <- function() {
  # Get instances
  url <- "https://vigilo-bf7f2.firebaseio.com/citylist.json"
  file_content <- paste("[", readLines(url, warn = FALSE), "]")
  jinstances <- jsonlite::fromJSON(file_content, simplifyVector = FALSE)
  df <- Reduce(rbind, jinstances[[1]])

  scopenames <- names(jinstances[[1]])
  instances <- data.frame(scopename = scopenames, df, row.names = NULL)

  instances <- instances %>%
    filter(prod == TRUE)

  # Get only compatible version> 0.0.11
  versions <- c()
  compatibles <- c()
  for (idx in seq_len(nrow(instances)))
  {
    tryCatch(
      {
        url <- paste0(instances$api_path[idx], "/get_version.php")
        jcontent <- jsonlite::fromJSON(url)
        compatibles <- c(
          compatibles,
          compareVersion(jcontent$version, "0.0.11")
        ) == 1
      },
      finally = {
        versions <- c(versions, jcontent$version)
      }
    )
  }

  # Filter compatible versions
  instances$version <- versions
  instances <- instances %>%
    filter(compatibles)

  # Remove prod column and add scopid column
  instances$scopeid <- seq_len(nrow(instances))
  instances <- instances %>%
    subset(select=-c(prod)) %>%
    relocate("scopeid")
  
  # Export CSV
  rio::export(instances, paste0(dlfolder, "instance.csv"))

  return(instances)
}

# Download observations
download_observations <- function(instances) {
  for (idx in seq_len(nrow(instances))) {
    filename <- paste0(dlfolder, "/obs_", instances$scope[idx], ".csv")
    url <- paste0(
      instances$api_path[idx],
      "/get_issues.php?scope=",
      instances$scope[idx],
      "&format=json"
    )

    # Add instanceid column
    observations <- jsonlite::fromJSON(url)
    observations$instanceid <- idx 
    observations <- observations %>%
    relocate("instanceid")

    rio::export(observations, filename)
  }
}

concatenate_observations <- function() {
  observations <- list.files(
    path = "downloaded/vigilo/",
    pattern = "obs_",
    full.name = TRUE
  ) %>%
    lapply(rio::import) %>%
    bind_rows()

  rio::export(observations, paste0(dlfolder, "observation.csv"))
}

################################################################################
# Main
################################################################################

download_categories()
instances <- download_instances()
download_observations(instances)
concatenate_observations()