# ADMINISTRATIVE
#------------------------------------------------------------------------------------
# rm(list = ls())
# Optional - don't treat strings as factors, no scientific notation for large #'s
options(stringsAsFactors = F, scipen = 99)

# Required Packages - install if necessary - UPDATE TO INSTALL IF DON'T EXISt
pks <- c("ggplot2", "stringr", "tidyverse", "xlsx", "readxl", "lubridate", "fs", 
         "reshape2", "purrr", "tidyquant", "scales", "tidyr")

lapply(pks, require, character.only = T)
#########################################
# INPUT REQUIRED
# CHANGE AND UNCOMMMENT SECTIONS BELOW
#########################################

# # Set working directory/subdirectory where plots will be saved locally
# # ADJUST AS APPROPRIATE AND UNCOMMENT PRIOR TO RUN

# sub_dir <- "/R/2018/HVS-Homeownership/"
# setwd(paste0(Sys.getenv("HOME"), sub_dir))

# # Link of online data file (single sheet). See Citations below for details
# # CHECK FOR THE MOST RECENT FILE HERE https://www.census.gov/housing/hvs/data/histtabs.html
# # & COPY AND PASTE LINK BELOW FOR MOST RECENT DATA

hvs_url <- "https://www.census.gov/housing/hvs/data/histtab19.xlsx"

# BUILD FUNCTION TO GET AND CLEAN DATA
#------------------------------------------------------------------------------------

get_hvs_data <- function(hvs_url) suppressWarnings({
  
  # Reference data for joining month with the associated quarter
  .ref_data <- data.frame(clean_col_nms = c("Q1", "Q2", "Q3", "Q4"), 
                          dt_mo = c(1,4,7,10))
  
  
  # Create temp file to download data from url to local direcotry
  tf <- tempfile()
  # Download File - takes the only function paramaeter (URL)
  download.file(hvs_url, tf, mode = "wb")
  # Read in data (it's messy)
  d1 <- read_excel(tf, sheet = 1, skip = 3)
  # Unlink data (i.e. delete temp file)
  unlink(tf)
  
  
  # Create a vector of names for renaming the columns in the loaded data
  d1_col_nms <- c("period", "national",
                  str_to_lower(str_replace_all(colnames(d1[3:ncol(d1)]),
                                               pattern = " ", "_")))
  # Rename the columns and drop rows that are NA or contain unecessary comments
  d2 <- d1%>%
    setNames(., d1_col_nms)%>%
    filter(!is.na(national))
  
  
  # File only contains the quarter, create a vector for reproted year
  # Start YEAR of Reporting Period
  start_yr <- 1994
  # End YEAR of reported data
  max_yr <- start_yr + nrow(d2)%/%4
  # Get the most recent Quarter associated with the data
  qtr_per <- ifelse(nrow(d2)%%4 == 0, 4, nrow(d2)%%4)
  
  # IF there are 4 quarters (full year), easy repeated sequence, ELSE concatenated sequence
  # through reported quarter (e.g. 1, 2, 3)
  if(qtr_per == 4){
    dt_yr = c(rep(seq(start_yr, max_yr, 1), each = 4))
  }else{
    dt_yr = c(rep(seq(start_yr, max_yr-1, 1), each = 4), rep(max_yr, qtr_per))
  }
  
  # Clean data, engineer desired dates, create calculations
  # Create Clean Quarter rows and join standard month to quarter for making a full date
  # Melt data = make long. Where variable = Age Cohort and value = Home Ownership Percent
  # Create Y.o.Y percent change in Homeownership; Q.o.Q Percent Change
  # Annual moving average (4-qtr)
  
  d3 <- d2%>%
    mutate(period = paste0("Q",str_replace_all(period, pattern = "[^0-9]", "")), 
           dt_yr = dt_yr)%>%
    left_join(., .ref_data, by = c("period"="clean_col_nms"))%>%
    mutate(full_dt = as.Date(paste(dt_yr, dt_mo, "01", sep = "-"), format = "%Y-%m-%d"))%>%
    select(-dt_mo)%>%
    melt(id.vars = c("full_dt", "period", "dt_yr"))%>%
    arrange(variable, full_dt)%>%
    group_by(variable)%>%
    mutate(yoy_ho = (value/lag(value,4)-1)*100, 
           qoq_ho = (value/lag(value,1)-1)*100, 
           ma_ann_right = rollmean(value, 4, align = "right", fill = NA, na = T))%>%
    ungroup()
  
  # Return final data to assigned environment object
  return(d3)
})


# LOAD DATA WITH FUNCTION
#------------------------------------------------------------------------------------

d <- get_hvs_data(hvs_url)


# WRITE CSV TO WORKING DIRECTORY (UNCOMMENT REQUIRED)
#------------------------------------------------------------------------------------

# # Writes the csv file (OPTIONAL)
# # SETWD, DESIRED OUTPUT FILENAME AND WRITE CSV LOCALLY

# write_csv(x = d, file = paste0(Sys.Date(), "-HVS-Homeownership-Q32018.csv"))

