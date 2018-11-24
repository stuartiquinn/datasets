#ADMIN
#-----------------------------------------------------------------------------
# rm(list = ls())
# Set options: StringsAsFactors and Non-Scientific Notation
options(stringsAsFactors = F, scipen = 99)

# List packages used
pks <- c("rvest", "ggplot2", "purrr", "tidyverse", "tidycensus",
         "stringr", "lubridate", "fs", "xlsx", "readxl", "scales")

# Load packages used
lapply(pks, require, character.only = T)

# Set working directory

###########################
# Requires user INPUT    #
###########################

setwd(paste0(path_home_r(), "/R/2018/FHA-Orig/"))

# Check to see if data folder exists in working directory, if no, create
if(is_dir(paste0(getwd(), "/data/"))==F){
  dir_create(paste0(getwd(), "/data/"))
  print("Directory 'data' created in working directory")
}else{
  f_cnt <- length(dir_ls(paste0(getwd(), "/data/")))
  print(paste0("Directory already exists and contains", f_cnt, "files"))
}

# Get data direcotry
data_dir <- paste0(getwd(), "/data/")

# Check to see if files already exist
fn_exists_already <- dir_ls(data_dir)

###########################
# Requires reference file #
# saved location input if #
# not in working directory#
###########################

# Get path to reference file which contains column headers and definitions
ref_file_path <- dir_ls(getwd(), regexp = "ref_var_def")

# FUNCTIONS
#-------------------------------------------------------------------------------

# Function to read in all FHA data that is downloaded, where sheet 3 = Purchase Loans
# Sheet 4 = Refinance transactions

read_in_fha_orig <- function(vec_file_nms){
  d_purchase <- map_df(vec_file_nms, ~read_excel(path = ., sheet = 3, col_names = F, skip = 1))
  d_refi <- map_df(vec_file_nms, ~read_excel(path = ., sheet = 4, col_names = F, skip = 1))
  d_full <- bind_rows(d_purchase, d_refi)
  return(d_full)
}

# GET URLS FOR ONLINE FILES
#----------------------------------------------------------------------------------------------

# Site address hosting files
hud_link_url <- "https://www.hud.gov/program_offices/housing/rmra/oe/rpts/sfsnap/sfsnap"
# Base url where files are actually stored
hud_base_url <- "https://www.hud.gov"

# Using rvest, scrape table for links and link names
# Filter only .xls files (some are zip)

hud_links <- read_html(hud_link_url)%>%
  html_nodes('a')%>%
  html_attr('href')%>%
  data.frame(url = ., stringsAsFactors = F)%>%
  filter(grepl('.xls', url))%>%
  mutate(fname = basename(url),
         full_dl_link = paste0(hud_base_url, url),
         dl_dir = data_dir)

# Filter out those for 2018 (many more years of archived data as needed)
dl_links <- filter(hud_links, grepl(url, pattern = "2018", ignore.case = T))

# Check to see if the file has been downloaded already based on wd/data
# If yes, filter out from dl list so you only receive net new files
if(length(fn_exists_already) > 0){
  dl_links <- filter(dl_links, fname %in% fn_exists_already)
}else{
  dl_links <- dl_links
}


# GET DATA (DL, SAVE, LOAD)
#----------------------------------------------------------------------------------------------

# This is our reference file that has col headers and definitions

fha_ref_url <- "https://raw.githubusercontent.com/stuartiquinn/datasets/master/fha_originations/ref_file/1_ref_var_definitions.csv"
d_ref_col_nms <- read_csv(fha_ref_url)

# This iterates through each link and downloads the workbook 
if(nrow(dl_links) == 0){
  print("You already have all of the files available")
}else{
  map2(dl_links$full_dl_link, dl_links$fname,
       ~download.file(url = .x, destfile = paste0(data_dir, .y), mode = "wb"))
}
# This takes all of the files in our working directory for purposes of reading
# in each excel sheet and names it by file name
fnames <- dir_ls(data_dir)

# Calls our function above that reads in each file: purchase sheet, then refi sheet
# then binds the files together for all originations

#****NOTE*** Takesa while as it is reading in a lot of data
d_full <- read_in_fha_orig(fnames)

# Set colnames with the reference file
colnames(d_full) <- d_ref_col_nms$var_name

d_full <- d_full%>%
  arrange(dt_yr_endorse, dt_mo_endorse)

# WRITE FULL FILE TO WORKING DIRECTORY
#-------------------------------------------------------------------------------------

# System Date (i.e. date of dl) for data through max month and year
fname_out <- paste0(Sys.Date(), "-FHA-Orig-2018-Through-",
                    month.abb[max(d_full$dt_mo_endorse)],"-", max(d_full$dt_yr_endorse), 
                    ".csv")

# Our function to write_to_excel only accepts lists so create a named list

write_excel_csv(d_full, path = fname_out)

