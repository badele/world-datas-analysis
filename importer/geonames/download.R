suppressPackageStartupMessages({
  library(rio)
  library(httr)
  library(dplyr)
  library(stringr)
})

# Commons vars
dlfolder <- "./downloaded/geonames/"
dbfolder <- "./db/"

# Make export directory
dir.create(dlfolder,recursive=TRUE, showWarnings = FALSE)

################################################################################
# Function
################################################################################

download_continent <- function() {
  continentkey <- c('AF','AS','EU','NA','OC','SA','AN')
  name <- c('Africa','Asia','Europe','North America','Oceania','South America','Antarctica')
  geoid <- c(6255146,6255147,6255148,6255149,6255151,6255150,6255152)

  continent <- data.frame(continentkey, name, geoid)

  # Export CSV
  rio::export(continent, paste0(dlfolder, "continent.csv"))
}

download_featureclass <- function() {
  featurecode <- c('A','H','L','P','R','S','T','U','V')
  name <- c('country, state, region,...','stream, lake, ...','parks,area, ...','city, village,...','road, railroad ','spot, building, farm','mountain,hill,rock,... ','undersea','forest,heath,...')

  featureclass <- data.frame(featurecode, name)

  # Export CSV
  rio::export(featureclass, paste0(dlfolder, "featureclass.csv"))
}

download_featurecode <- function() {

  featurecode <- read.csv(file="https://download.geonames.org/export/dump/featureCodes_en.txt",sep="\t",comment.char="",header=FALSE, stringsAsFactors = FALSE, encoding = "UTF-8", quote="")
  colnames(featurecode) <- c('code','info1','info2')

  # # Export CSV
  rio::export(featurecode, paste0(dlfolder, "featurecode.csv"))
}

download_countryinfo <- function() {

  maxsearchlines = 100
  url = "https://download.geonames.org/export/dump/countryInfo.txt"

  # Search last line comment
  file <- file(url, "r")
  lines <- readLines(file,n=maxsearchlines)
  idxrow <- str_which(lines,"#ISO\tISO3")
  close(file)

  # Read countries content
  countryinfo <- read.csv(file=url,sep="\t",comment.char="",header=FALSE, stringsAsFactors = FALSE, encoding = "UTF-8", quote="", skip=idxrow+1)
  colnames(countryinfo) <- c('iso2', 'iso3', 'isonum', 'fips', 'country', 'capital','area', 'countrypopulation', 'continent', 'tld', 'currencycode','currencyname', 'phone', 'postalcodeformat','postalcoderegex','language', 'GEOID', 'neighbours', 'equivfipscode')

  # Remove countrypopulation and relocate GEOID column
  countryinfo <- countryinfo %>%
    select(-countrypopulation) %>%
    relocate(GEOID,.before=iso2)

  # # Export CSV
  rio::export(countryinfo, paste0(dlfolder, "country.csv"))
}

download_allcountries <- function() {
  url = "https://download.geonames.org/export/dump/allCountries.zip"
  temp <- tempfile()

  # Download compressed file
  download.file(url,temp)
  unziped <- unz(temp, "allCountries.txt")

  # Read uncompressed file
  allcountries <- read.csv(unziped,sep="\t",comment.char="",header=FALSE, stringsAsFactors = FALSE, encoding = "UTF-8", quote="")
  colnames(allcountries) <- c('GEOID', 'name', 'asciiname', 'alternatenames', 'latitude', 'longitude','featureclass',  'featurecode', 'countrycode', 'cc2', 'adm1','adm2','adm3','adm4','population', 'elevation', 'dem','timezone','lastupdate')
  allcountries <- allcountries %>%
    select(-alternatenames, -population) %>%
    mutate (
      scope = NA
    ) %>%
    filter(featureclass == 'A' | featureclass == 'P' | featureclass =='L') 
 
  # Close temporary file
  unlink(temp)  

  # # Export CSV
  rio::export(allcountries, paste0(dlfolder, "allcountries.csv"))
}

download_hierarchy <- function() {
  url = "https://download.geonames.org/export/dump/hierarchy.zip"  
  temp <- tempfile()

  # Download compressed file
  download.file(url,temp)
  unziped <- unz(temp, "hierarchy.txt")

  # Read uncompressed file
  hierarchy <- read.csv(unziped,sep="\t",comment.char="",header=FALSE, stringsAsFactors = FALSE, encoding = "UTF-8", quote="")
  colnames(hierarchy) <- c('parent', 'child', 'type')

  # Close temporary file
  unlink(temp)  

  # # Export CSV
  rio::export(hierarchy, paste0(dlfolder, "hierarchy.csv"))
}


################################################################################
# Main
################################################################################

# Set option for download.file function
options(timeout = 300)
download_continent()
download_featureclass()
download_featurecode()
download_countryinfo()
download_allcountries()
download_hierarchy()