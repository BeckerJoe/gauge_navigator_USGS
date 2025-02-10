# Main script for finding upstream USGS gauges
# See README file for additional information
# Written by Becker Gibson
# Updated 02/10/2025
##############################################################

### input variables ###

census.pathfilename <- "cb_2015_us_state_500k/cb_2015_us_state_500k.shp" # full path to US Census shapefiles - cb_2015_us_state_500k.shp
hydrorivs.pathfilename <- "rivers_north_central_america/HydroRIVERS_v10_na_shp/HydroRIVERS_v10_na.shp" # full path to hydrorivers file - rivers_north_central_america/HydroRIVERS_v10_na_shp/HydroRIVERS_v10_na.shp
points.pathfilename <- "" # full path to csv file of points of interest to find upstream gauges from - must have Name, lat, and lon columns

input.state.names <- c("NH", "ME", "MA", "RI", "CT", "VT") # put the two letter abbreviations of the states for study area as strings
parameter <- c("") # parameter code for USGS search

date1 <- "" # beginning date to check against for availability, see readme
date2 <- "" # end date to check against for availability
time.days <- 3650 # minimum amount of time needed in days

### packages ###

library(tidyverse) # dplyr, tidyr, lubridate, & purrr are used
library(dataRetrieval) # retrieves USGS data
library(stars)
library(sf)

### custom functions ###

source("intersection.progbar.R")

find.pts <- function(hy.id, start = TRUE){
  while(TRUE){
    print(paste("NOW: ", hy.id))
    
    # check if hitting another gauge
    if(start == FALSE & hy.id %in% dailyDataAvailable$HYR.ID)
    {
      print("F")
      return(0)
    }
    
    # check if hyriv id contains point of interest
    if (hy.id %in% pts.geom$HYR.ID == TRUE)
    {
      out <- filter(pts.geom, HYR.ID == hy.id)
      print("G")
      return(out$Name)
    } else { # get the next down
      
      new <- filter(rivers, HYRIV_ID == hy.id)
      
      hy.id <- new$NEXT_DOWN
      
      start <- FALSE
      
      print(paste("NEXT: ", hy.id))
      
      if (length(hy.id) == 0){
        return(0)
      } else if (hy.id == 0){
        return(0)
      }
    }
  }
}

enoughTime <- function(startDate1, endDate1, startDate2, endDate2){
  
  if (startDate1 < startDate2 & endDate1 >= startDate2)
  {
    startDate1 <- startDate2
  }
  
  if (endDate1 > endDate2 & startDate1 <= endDate2)
  {
    endDate1 <- endDate2
  }
  
  if (
    startDate1 >= max(startDate1, startDate2) & 
    endDate1 <= min(endDate1, endDate2) &
    difftime(endDate1, startDate1) >= time.days
  ) {
    out <- TRUE
  } else {
    out <- FALSE
  }
  
  return(out)
}

### load data ###

# load state(s) sf shape(s)
USA <- read_sf(census.pathfilename)
states <- st_cast(USA[USA$STUSPS %in% input.state.names,], "POLYGON") %>% 
  st_transform(crs = "EPSG:4326")
study.area <- states %>%   
  st_union()

# rivers
if(file.exists("rivers.RDS") != TRUE) {
  rivers <- read_sf(hydrorivs.pathfilename) %>% 
    intersection.progbar(study.area) %>% 
    select(
      HYRIV_ID, 
      NEXT_DOWN,
      ENDORHEIC,
      geometry
    ) %>% 
    group_by(HYRIV_ID) %>% 
    summarize(
      geometry = st_union(geometry),
      HYRIV_ID = unique(HYRIV_ID),
      ENDORHEIC = unique(ENDORHEIC),
      NEXT_DOWN = unique(NEXT_DOWN)
    )
  
  saveRDS(rivers, "rivers.RDS")
} else {
  rivers <- readRDS("rivers.RDS")
}


# tibble for points of interest
pts.tib <- read.csv(points.pathfilename) %>% 
  dplyr::select(Name, lat, lon) %>%
  st_as_sf(coords = c("lon", "lat")) %>%
  rename(geo_col = geometry) %>%
  as_tibble()
# turn to sf and assign river linestring
pts.geom <- pts.tib %>%
  st_as_sf(sf_column_name = "geo_col", crs = 4326) %>% 
  rowwise() %>% 
  mutate(
    HYR.ID = rivers[st_nearest_feature(geo_col, rivers, ),]$HYRIV_ID
  )

### filter gauge data to available sites ###
dailyDataAvailable <- bind_rows(map(1:length(input.state.names), \(x){
  piece <- whatNWISdata(
    service = "dv",
    stateCd = input.state.names[[x]],
    statCd = "00003"
  ) %>% 
    rowwise() %>% 
    filter(
      parm_cd  == parameter,
      enoughTime(begin_date, end_date, date1, date2) == TRUE
    )
}))

gauge.list <- dailyDataAvailable %>% 
  rowwise() %>% 
  mutate(
    HYR.ID = rivers[st_nearest_feature(geo_col, rivers, ),]$HYRIV_ID
  )

### identify gauge sites upstream of NE ror facilities ###
gauge.list.pts <- gauge.list %>% 
  rowwise() %>% 
  mutate(
    pt = paste(find.pts(HYR.ID), collapse = ",")
  ) %>% 
  filter(
    pt != 0
  )

saveRDS(gauge.list.pts, "upstream_gauges.RDS")