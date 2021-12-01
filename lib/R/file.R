suppressPackageStartupMessages({
    library(gdata)
    library(stringr)
})

#' Generate automatically .fwf file (fixed width file) in R
#' @description This function creates automatically fixed width file
#' It align columns headers with datas
#' @param df dataframe   
#' @param filename filename   
#' @param nbspaces nb spaces for columns separator   
#' @param replace_na Empty/NA chain replacement   
#' @param rowname If it's defined, it convert rownames column to named column   
#' @examples write_fwf(mtcars, "carname", "/tmp/mtcars.fwf")
#'
#' # colnames: carname,mpg,cyl,disp,hp,drat,wt,qsec,vs,am,gear,carb
#' # cols: 22,7,6,8,6,7,8,8,5,5,7,7
#' carname                mpg   cyl    disp    hp   drat      wt    qsec   vs   am   gear   carb
#' Mazda RX4             21.0     6   160.0   110   3.90   2.620   16.46    0    1      4      4
#' Mazda RX4 Wag         21.0     6   160.0   110   3.90   2.875   17.02    0    1      4      4
#' Datsun 710            22.8     4   108.0    93   3.85   2.320   18.61    1    1      4      1
#' Hornet 4 Drive        21.4     6   258.0   110   3.08   3.215   19.44    1    0      3      1
write_fwf <- function(df, filename,rowname = FALSE,nbspaces = 3, replace_na = "NA") {
  # Convert rownames to column
  if (rowname) {
    df <- tibble::rownames_to_column(df, rowname)
  }

  # Replace NA
  df[is.na(df)] <- replace_na

  # Compute column size
  maxwidthname <- nchar(colnames(df))
  maxwidthvalue <- sapply(df, function(x) max(nchar(x)))
  maxcols <- pmax(maxwidthname,maxwidthvalue)
  delta <- maxwidthvalue - maxwidthname 

  # Compute header
  header <- c()
  for (idx in seq(ncol(df))) {
    # Check if column is a date
    if (is.POSIXt(df[,idx])) {
      stop("PLease convert date column to string")
    }

    if (is.character(df[,idx])) {
      header <- append(header,paste0(colnames(df)[idx],strrep(" ",max(delta[idx],0))))
    } else {
      header <- append(header,paste0(strrep(" ",max(delta[idx],0)), colnames(df)[idx]))
    }
  }

  # Open file
  file <- file(filename, "w")
  
  # Write header
  writeLines(paste("# colnames:", paste(colnames(df), collapse=',')),file)
  writeLines(paste("# cols:", paste(unlist(maxcols+nbspaces), collapse=',')),file)
  writeLines(header,file, sep=strrep(" ",nbspaces))
  writeLines("", file, sep="\n")
  close(file)
  
  # Export data
  write.fwf(df,file=filename,append=TRUE, width=maxcols,colnames=FALSE,na=replace_na, sep=strrep(" ",nbspaces))
}

#' Read automatically .fwf file (fixed width file) in R
#' @description This function read and detect automatically fixed width file
#' @param maxsearchlines nb lines for the searching the columns metadata description   
#' @examples read_fwf("/tmp/mtcars.fwf")
read_fwf <- function(filename,maxsearchlines=100) {
  # Search columns informations
  file <- file(filename, "r")
  on.exit(close(file))

  lines <- readLines(file,n=maxsearchlines)

  idxname <- str_which(lines,"# colnames: ")
  colnames <- str_replace(lines[idxname], "# colnames: ", "")
  colnames <- unlist(str_split(colnames, ","))

  idxcols <- str_which(lines,"# cols: ")
  colwidths <- str_replace(lines[idxcols], "# cols: ", "")
  colwidths <- str_split(colwidths, ",")
  colwidths <- strtoi(unlist(colwidths))

  return(read.fwf(file=filename, skip=idxcols+2, col.names = colnames, widths=colwidths,strip.white=TRUE))
}