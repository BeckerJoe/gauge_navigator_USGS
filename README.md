# gauge_navigator_USGS

Description:

Simple program for finding USGS gauges upstream of a set of points. Currently working on improving with sfnetworks - current version will not always return correct results if gauge is on the same linestring as a point.


How to use:

1. Clone this repo to your directory, then open the project file.

2. Download state boundary polygons from https://www2.census.gov/geo/tiger/GENZ2015/shp/cb_2015_us_state_500k.zip (you can edit some paths information and use a newer version if needed) and river data for "North and Central America"" at https://www.hydrosheds.org/products/hydrorivers. Make sure that these folders are in the cloned repo's project folder.

3. Make a csv file with the points that you are trying to find upstream gauges for. Include "Name", "lat", and "lon" columns, as these are used by the script.

4. In gauge_navigator.R, adjust variables labeled as "user inputs" to meet the criteria for your query.
  + points.pathfilename - path to your csv file
  + input.state.names - two letter abbreviations for states you wish to study, this should be a vector of strings
  + parameter - parameter code for USGS search (Find list at https://help.waterdata.usgs.gov/parameter_cd?group_cd=%)
  + date1 & date2 - these are the start and end dates for the data you are querying for. Having specified dates here will ensure that the gauges returned by the program have data for the variable in question between these dates
  + time.days - this is the minimum amount of data a gauge should have within the selected daterange to be returned
  
5. Run the gauges_navigator.R script. If configured properly, output will be saved in the project folder. Note that if you are running the script for the first time, it will take a significant amount of time to subset the river linestrings. This subset is saved during the script, and can be reused - keep in mind that you rename it if you are planning on having multiple study area outputs in the same folder.

Notes:

This program may miss upstream gauges that are on the same linestring as the point of interest. Suggestions are welcome, and I plan on fixing this with sfnetworks at some point in the future. This program can be run pretty much out of the box, but tinkering will reward you with more sophisticated queries.