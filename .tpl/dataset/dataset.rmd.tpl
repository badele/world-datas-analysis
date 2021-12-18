[comment]: <> (===================================================++++++++++++=)
[comment]: <> (This file is generated from `r gsub(".*\\.tpl/",".tpl/",knitr::current_input(dir=TRUE))`
[comment]: <> (===================================================++++++++++++=)

 - [datasets](#${PROVIDER}-datasets)
 - [variables](#${PROVIDER}-variables)

# ${PROVIDER} datasets

``` {r echo=FALSE, message=FALSE,INCLUDE=TRUE}

source("../../lib/R/file.R")

suppressPackageStartupMessages({
  library(here)
  library(RSQLite)
  library(forcats)
  library(tidyverse) 
  library(kableExtra)
})


dataset <- read_fwf("../../dataset/dataset.txt")

dataset %>%
  filter(provider=='${PROVIDER}') %>%
  kable(format="pipe", escape = FALSE)
```

# ${PROVIDER} variables

``` {r echo=FALSE, message=FALSE,INCLUDE=TRUE}

variable <- read_fwf("../../dataset/variable.txt")

variable %>%
  filter(provider=='${PROVIDER}') %>%
  kable(format="pipe", escape = FALSE)
```
