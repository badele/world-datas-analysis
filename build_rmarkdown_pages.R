suppressPackageStartupMessages({
  library(here)
  library(knitr)
  library(RSQLite)
  library(forcats)
  library(tidyverse) 
  library(kableExtra)
})

source("lib/R/file.R")


# Generate providers template
dfprovider <- read_fwf("dataset/provider.txt")

for (idx in 1:nrow(dfprovider)) {
    providername <- dfprovider[idx,1] 
    system(paste0("PROVIDER=",providername," envsubst < dataset/dataset.rmd.tpl > dataset/",providername,".rmd"))
}

files <- list.files(pattern="\\.rmd$",recursive=TRUE)
for (filename in files) {
    fmarkdown <- gsub("\\.rmd$",".md",filename)

    cat(paste0("Build ",filename),sep="\n")

    # Build markdown
    knit(filename, output=fmarkdown, quiet=TRUE)
}