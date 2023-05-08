###################################
######### 0. Set Up R #############
###################################
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(tidyverse)
library(stringr)
library(ggplot2)
library(tidygeocoder)
library(lubridate)
library(sf)
library(tidycensus)
library(tigris)
library(rosm)
library(tmap)
library(basemaps)
library(tmaptools)
library(OpenStreetMap)

###################################
#### 1. Explore ACS Variables #####
###################################

# Instructions to get API key here: https://www.census.gov/content/dam/Census/library/publications/2020/acs/acs_api_handbook_2020_ch02.pdf
census_api_key("YOUR KEY GOES HERE", install = TRUE)

# Import variables from the American Community Survey for inspection
# This code will give you ACS 5-year estimates. For other options, see 
# https://walker-data.com/tidycensus/reference/load_variables.html
acs5_var <- load_variables(year = 2020, 
                           dataset = "acs5"
                           )

###################################
###### 2. Set Parameters ##########
###################################

# Add the variables you want to a list
var_list <- c("B02001_001", # Total population
              "B25001_001" # Number of housing units 
)

# What year to pull
year = 2020

# Desired geographic level
geography = "block group" # tract

# Which survey to pull
survey = "acs5" # ACS 5-year estimates


###################################
## 3. Pull Estimates for County ###
###################################

acs_geo <- get_acs(
  geography = geography, #"block group", # You can also specify tract, county, etc.
  variables = var_list,
  state = "CO",
  county = "Boulder",
  year = year,
  survey = survey,
  geometry = TRUE,# determines if the dataframe will contain GIS component
  # output = "wide" # changes layout of dataframe to a wide format, default to long
)

###################################
###### 4. Limit Data to City ######
###################################

# Import list of block groups for the City of Boulder and its sub-communities

# Choose either block groups or tracts with parameters above to import
# a list of geographies to subset with.

if (geography == "block group") {
  bg_list <- readRDS("../data/raw_data/boulder_block_groups.rds")
  acs_geo <- acs_geo[acs_geo$NAME %in% bg_list,] # block groups
} else {
  tract_list <- readRDS("../data/raw_data/boulder_tracts.rds")
  acs_geo <- acs_geo[acs_geo$NAME %in% tract_list,] # tracts
}


###################################
### 5. Convert to GeoDataFrame ####
###################################

# Convert to a geodataframe
geo_file <- st_as_sf(acs_geo,
                     sf_column_name = "geometry",
                     crs=4269
)
st_crs(geo_file)

# Transform the CRS 
export_file <- st_transform(geo_file, crs = "EPSG:2876")
st_crs(export_file)


# Interactive map
tmap_mode("view")
# tmap_mode("plot")
tm_basemap("OpenStreetMap.France") +
  tm_shape(export_file) + 
  tm_polygons(col = "GEOID",
              alpha = 0.9,
              palette = "Blues",
              title = "Variable") + 
  tm_layout(title = "\nby Block Group",
            frame = FALSE,
            legend.outside = TRUE)


###################################
########### 6. Export #############
###################################

# Write to a shapefile
st_write(
  export_file,
  "..//data//tidy_data//acs_data.shp",
  driver="ESRI Shapefile"
)

