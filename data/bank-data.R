library(DBI)
library(odbc)
library(tidyverse)
library(stringr)

# download
download.file(
  url = "https://archive.ics.uci.edu/ml/machine-learning-databases/00222/bank-additional.zip",
  destfile = "data/bank-additional.zip")

# unzip
unzip(zipfile = "data/bank-additional.zip", 
      exdir = "data", 
      files = "bank-additional/bank-additional-full.csv", 
      junkpaths = TRUE)

# Read data
raw_data <- read_delim(file = "demos/bank-additional-full.csv", 
                       delim = ";", 
                       col_types = cols(nr.employed = col_number()),
                       progress = FALSE) 

# Format column names
names(raw_data) <- str_replace_all(names(raw_data), "[.]", "_")

# Rename and remove columns
all_data <- raw_data %>%
  rename(term_deposit = y,
         prior_outcome = poutcome,
         personal_loan = loan,
         housing_loan = housing,
         in_default = default) %>%
  mutate(job = str_replace_all(job, "[.-]", "")) %>%
  # There's something weird with campaign... there is very spotty coverage after 35 (up to 56).
  mutate(campaign = pmin(campaign, 35)) %>%
  mutate(total_contacts = campaign + previous) %>%
  select(-c(nr_employed, emp_var_rate, previous, pdays, campaign, duration)) %>%
  na.omit

# Impute year and date
all_data <- all_data %>%
  mutate(month_idx = ifelse(month != lag(month, default = "may"), 1, 0)) %>%
  mutate(month_idx = cumsum(month_idx)) %>%
  mutate(year = findInterval(month_idx, c(7, 17))) %>%
  mutate(year = case_when(year == 0 ~ "2008",
                          year == 1 ~ "2009",
                          year == 2 ~ "2010")) %>%
  mutate(date = as.Date(paste0("1", month, year), "%d%b%Y"))

# connect
con <- dbConnect(odbc::odbc(), "Teradata")

# Write table
dbRemoveTable(con, "bank")
dbExistsTable(con, "bank")
dbWriteTable(con, "bank", all_data, overwrite = TRUE)

