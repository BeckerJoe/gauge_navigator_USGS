library(progress)
library(purrr)
library(sf)
# Modified from: https://github.com/r-spatial/sf/issues/801
intersection.progbar <- function(x, y)
{
  intersections <- sf::st_intersects(x, y)
  
  pb <- progress::progress_bar$new(format = "[:bar] :current/:total (:percent)", total = dim(x)[1])
  
  intersectFeatures <- purrr::map_dfr(1:dim(x)[1], function(z){
    pb$tick()
    sf::st_intersection(x[z,], y[intersections[[z]],])
  })
  
  return(intersectFeatures)
}