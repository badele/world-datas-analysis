 - [datasets](#${PROVIDER}-datasets)
 - [variables](#${PROVIDER}-variables)

# ${PROVIDER} datasets

``` {r echo=FALSE, message=FALSE,INCLUDE=TRUE}

source("../lib/R/file.R")

suppressPackageStartupMessages({
  library(here)
  library(RSQLite)
  library(forcats)
  library(tidyverse) 
  library(kableExtra)
})


dataset <- read_fwf("dataset.txt")

dataset %>%
  filter(provider=='${PROVIDER}') %>%
  kable(format="pipe", escape = FALSE)
```

# ${PROVIDER} variables

``` {r echo=FALSE, message=FALSE,INCLUDE=TRUE}

variable <- read_fwf("variable.txt")

variable %>%
  filter(provider=='${PROVIDER}') %>%
  kable(format="pipe", escape = FALSE)
```
