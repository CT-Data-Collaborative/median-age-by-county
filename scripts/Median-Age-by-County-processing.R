# Setting wd to current directory (Windows)
# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
# source('acsHelpers.R')

library(dplyr)
library(devtools)
library(datapkg)
library(acs)
library(stringr)
library(reshape2)
library(data.table)
library(tidyr)

# Linux
source('./scripts/acsHelpers.R')

##################################################################
#
# Processing Script for Median Age by County
# Created by Jenna Daly
# On 11/27/2017
#
##################################################################

#Get state data
geography=geo.make(state=09)
yearlist=c(2010:2019)
span = 5
col.names="pretty" 
key="ed0e58d2538fb239f51e01643745e83f380582d7"
options(scipen=999)

tables <- c("", "A", "B", "C", "D", "E", "F", "G", "H", "I")
races <- c("All", "White Alone", "Black or African American Alone", "American Indian and Alaska Native Alone", 
           "Asian Alone", "Native Hawaiian and Other Pacific Islander", "Some Other Race Alone", 
           "Two or More Races", "White Alone Not Hispanic or Latino", "Hispanic or Latino")

state_data <- data.table()
for (i in seq_along(yearlist)) {
  endyear = yearlist[i]
  inter_data <- data.table()
  for (j in seq_along(tables)) {
    tbl <- tables[j]
    race <- races[j]
    #needed to grab all columns for all years    
    variable =list()      
    for (k in seq_along(1:3)) {
     number = number=paste0("B01002", tbl, "_", sprintf("%03d",k))
     variable = c(variable, number)
     k=k+1
    }    
    variable <- as.character(variable)    
    data <- acs.fetch(geography=geography, endyear=endyear, span=span, 
                      variable = variable, key=key)
    year <- data@endyear
    print(paste("Processing: ", year, race))
    year <- paste(year-4, year, sep="-")
    geo <- data@geography
    total <- acsSum(data, 1, "Median Age Total")
    total.m <- acsSum(data, 2, "Median Age Male")
    total.f <- acsSum(data, 3, "Median Age Female")
    estimates <- data.table(
            geo, 
            estimate(total),
            estimate(total.m),
            estimate(total.f),
            year,
            race, 
            "Measure Type" = "Number", 
            "Variable" = "Median Age"
        )
    moes <- data.table(
            geo,
            standard.error(total) * 1.645,
            standard.error(total.m) * 1.645,
            standard.error(total.f) * 1.645,
            year,
            race, 
            "Measure Type" = "Number", 
            "Variable" = "Margins of Error"
        )
    numberNames <- c(
            "County", "FIPS",
            "Total",
            "Male",
            "Female",
            "Year",
            "Race/Ethnicity", 
            "Measure Type", 
            "Variable"
         )
    setnames(estimates, numberNames)
    setnames(moes, numberNames)
    data.melt <- melt(
            rbind(estimates, moes),
            id.vars=c("County", "FIPS", "Year", "Measure Type", "Variable", "Race/Ethnicity"),
            variable.name="Gender",
            variable.factor = F,
            value.name="Value",
            value.factor = F
         )
     inter_data <- rbind(inter_data, data.melt)
  }
  state_data <- rbind(state_data, inter_data)
}

#Get state data
geography=geo.make(state=09, county="*")

county_data <- data.table()
for (i in seq_along(yearlist)) {
  endyear = yearlist[i]
  inter_data <- data.table()
  for (j in seq_along(tables)) {
    tbl <- tables[j]
    race <- races[j]
    #needed to grab all columns for all years    
    variable =list()      
    for (k in seq_along(1:3)) {
     number = number=paste0("B01002", tbl, "_", sprintf("%03d",k))
     variable = c(variable, number)
     k=k+1
    }    
    variable <- as.character(variable)    
    data <- acs.fetch(geography=geography, endyear=endyear, span=span, 
                      variable = variable, key=key)
    year <- data@endyear
    print(paste("Processing: ", year, race))
    year <- paste(year-4, year, sep="-")
    geo <- data@geography
    geo$NAME <- gsub(", Connecticut", "", geo$NAME)
    geo$county <- gsub("^", "09", geo$county)
    geo$state <- NULL    
    total <- acsSum(data, 1, "Median Age Total")
    total.m <- acsSum(data, 2, "Median Age Male")
    total.f <- acsSum(data, 3, "Median Age Female")
    estimates <- data.table(
            geo, 
            estimate(total),
            estimate(total.m),
            estimate(total.f),
            year,
            race,
            "Measure Type" = "Number", 
            "Variable" = "Median Age"
            
        )
    moes <- data.table(
            geo,
            standard.error(total) * 1.645,
            standard.error(total.m) * 1.645,
            standard.error(total.f) * 1.645,
            year,
            race, 
            "Measure Type" = "Number", 
            "Variable" = "Margins of Error"
            
        )
    numberNames <- c(
            "County", "FIPS",
            "Total",
            "Male",
            "Female",
            "Year",
            "Race/Ethnicity", 
            "Measure Type", 
            "Variable"            
         )
    setnames(estimates, numberNames)
    setnames(moes, numberNames)
    data.melt <- melt(
            rbind(estimates, moes),
            id.vars=c("County", "FIPS", "Year", "Measure Type", "Variable", "Race/Ethnicity"),
            variable.name="Gender",
            variable.factor = F,
            value.name="Value",
            value.factor = F
         )
     inter_data <- rbind(inter_data, data.melt)
  }
  county_data <- rbind(county_data, inter_data)
}

med_age_data <- rbind(state_data, county_data)

med_age_data <- med_age_data %>% 
  select(County, FIPS, Year, Gender, `Race/Ethnicity`, `Measure Type`, Variable, Value) %>% 
  arrange(County, Year, Gender, `Race/Ethnicity`, Variable)

med_age_data$Value <- replace(med_age_data$Value, med_age_data$Value %in% c(-222222222, -666666666), -6666) 

#Linux
write.table (
  med_age_data,
  file.path(getwd(), "data", "median_age_county_2019.csv"),
  sep = ",",
  row.names = F,
  na = "-9999"
)

#Windows
# write.table (
#   med_age_data,
#   file.path("C:/Users/Jason/Documents/GitHub/median-age-by-county/data/median_age_county_2019.csv"),
#   sep = ",",
#   row.names = F,
#   na = "-9999"
# )