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
  print("Try to download categories")

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
  print("Try to download instances informations")

  url <- "https://vigilo-bf7f2.firebaseio.com/citylist.json"
  file_content <- paste("[", readLines(url, warn = FALSE), "]")
  jinstances <- jsonlite::fromJSON(file_content, simplifyVector = FALSE)
  df <- Reduce(rbind, jinstances[[1]])

  scopenames <- names(jinstances[[1]])
  instances <- data.frame(scopename = scopenames, df, row.names = NULL)

  instances <- instances %>%
    filter(prod == TRUE)
  nb_instances <- nrow(instances)

  # Get only compatible version> 0.0.11
  versions <- c(rep("0.0.0"),nb_instances)
  compatibles <- c(rep(FALSE,nb_instances))
  for (idx in seq_len(nrow(instances)))
  {
    tryCatch(
      {
        print(paste("Try get ",instances$scope[idx],"instance version"))

        url <- paste0(instances$api_path[idx], "/get_version.php")
        jcontent <- jsonlite::fromJSON(url)
        versions[idx] <- jcontent$version
        compatibles[idx] <- compareVersion("0.0.11",jcontent$version) == -1
      },
      error = function(cond) {
      }
    )
  }

  instances$version <- versions  
  instances$compatible <- compatibles  

  instances <- instances %>%
    filter(compatible==TRUE)
  nb_instances <- nrow(instances)

  # Get limitbox
  # "coordinate_lat_min": "50.371981",
  # "coordinate_lat_max": "50.526368",
  # "coordinate_lon_min": "3.837876",
  # "coordinate_lon_max": "4.153979"
  instance_isup <- c(rep(FALSE,nb_instances))
  lat_mins <- c(rep(0,nb_instances))  
  lat_maxs <- c(rep(0,nb_instances))
  lon_mins <- c(rep(0,nb_instances))
  lon_maxs <- c(rep(0,nb_instances))

  for (idx in seq_len(nrow(instances)))
  {
    tryCatch(
      {
        print(paste("Try to download",instances$scope[idx],"instance observations"))

        url <- paste0(instances$api_path[idx], "/get_scope.php?scope=",instances$scope[idx])
        jcontent <- jsonlite::fromJSON(url)

        lat_mins[idx] <- jcontent$coordinate_lat_min
        lat_maxs[idx] <- jcontent$coordinate_lat_max
        lon_mins[idx] <- jcontent$coordinate_lon_min
        lon_maxs[idx] <- jcontent$coordinate_lon_max
        instance_isup <- TRUE
      },
      error = function(cond) {
      }
    )
  }

  # Filter compatible versions
  
  instances$isup <- instance_isup  
  instances$lat_min <- lat_mins
  instances$lat_max <- lat_maxs
  instances$lon_min <- lon_mins
  instances$lon_max <- lon_maxs
  instances <- instances %>%
    filter(isup)


  # Remove prod column and add scopid column
  instances$scopeid <- seq_len(nrow(instances))
  
  instances <- instances %>%
    subset(select=-c(prod,isup,compatible)) %>%
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

    # If no observations, continue
    if (length(observations)==0) next

    # Save observations
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

options(timeout = 10)

download_categories()
instances <- download_instances()
download_observations(instances)
concatenate_observations()