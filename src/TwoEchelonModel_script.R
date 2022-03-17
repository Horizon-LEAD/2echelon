#Version:               1.0
#Date of creation:      17.05.2021
#Author:                Beatriz Royo
#Last Update:           02.10.2021
#Last modification:     Beatriz Royo

#' ----------------------------------------------------------------------------
#' Description: Script for calculating the number of resources and distance for
#' 2 echelon networks (first leg, second leg) or for just the second leg
#' depending on the input data configuration
#'
#' Input data:
#'    vehicleFirstLeg =  (name, capacity (Porto in boxes), speed (km/h),
#'                        stop time (h))
#'    facilityFirstLeg = (name, handling time, latitude, longitude)
#'    zoneFirstLeg =  (name, delivery size (number of boxes), area (m2),
#'                     latitude, longitude, number of delivery points)
#'    vehicleSecondLeg =  (name, capacity (Porto in boxes), speed (km/h),
#'                         stop time (h))
#'    facilitySecondLeg = (name, handling time, latitude, longitude)
#'    zoneSecondLeg =  (name, delivery size (number of boxes), area (m2),
#'                      latitude, longitude, number of delivery points)
#'    config = (workshift time, k)
#' Output data:
#'    solution= (totalDistanceFirstLeg, totalTimeFirstLeg, mFirstLeg,
#'               totalDistanceSecondLeg, totalTimeSecondLeg, mSecondLeg)
#' ----------------------------------------------------------------------------

library(geosphere)

#' Calculate the number of resources per leg.
#'
#' If first leg not needed the input data for the area and the delivery points
#' must be zero
calculateSolutionTwoLegs <- function(zone1, vehicle1, facility1, zone2,
                                     vehicle2, facility2, config) {

  first_leg <- calculateSolutionLeg(zone1, vehicle1, facility1, config)
  second_leg <- calculateSolutionLeg(zone2, vehicle2, facility2, config)

  solution <- c(first_leg, second_leg)

  return(solution)
}

#' Calculate the number of vehicles and resources to deliver in a specific
#' delivery zone from the hub within the delivery area to the delivery points
calculateSolutionLeg <- function(zone, vehicle, facility, config) {
  # distance if only 1 vehicle
  initial_distance <- calculateTotalDistance(zone, facility, 1, config)

  # number of resources considering capacity constraint
  m1 <- calculateM1(vehicle, zone)
  # number of resources considering time constraint
  m2 <- calculateM2(initial_distance, vehicle, zone, facility, config)
  # browser()

  m <- max(m1, m2) # the number of resources is the max required
  # total distance with the m vehicles
  total_distance <- calculateTotalDistance(zone, facility, m, config)
  total_time <- calculateTotalTime(total_distance, vehicle, zone)

  # solution = list(vehicle, zone, facility, config, totalDistance,
  #                 totalTime, m)

  solution <- c(total_distance, total_time, m)

  return(solution)
}

#' Total direct distance from the branch/ mobile depot to the first point of
#' the delivery area.
#'
#' zone = name, delivery size (number of boxes), area (m2), latitude,
#'                             longitude, number of delivery points
#' facility = name, handling time, latitude, longitude
calculateTotalDistanceDirectShipment <- function(zone, facility, m) {
  # db_dhi = calculateEuclideanDistance(zone[4], zone[5], facility[3],
  #                                     facility[4])
  # db_dhi = calculateGeodesicDistance(zone[4], zone[5], facility[3],
  #                                    facility[4])

    if (distance_type == 1) {
      print("1")
      db_dhi <- calculateEuclideanDistance(zone[4], zone[5], facility[3],
                                          facility[4])
    } else {
      print("2")
      db_dhi <- calculateGeodesicDistance(zone[4], zone[5], facility[3],
                                         facility[4])
    }

  # roundtrip distance
  db_dhi <- db_dhi * 2 * m

  return(db_dhi)
}

#' Calculates the Euclidean distance between tow points.
calculateEuclideanDistance <- function(lat1, lon1, lat2, lon2) {
  euclidian_distance <- sqrt((as.double(lat1) - as.double(lat2)) ^ 2 +
                             (as.double(lon1) - as.double(lon2)) ^ 2)
  # browser()

  return(euclidian_distance)
}

#' Calculates the distance between tow points accoring to the haversine formula
#'
#' by default in metres
calculateGeodesicDistance <- function(lat1, lon1, lat2, lon2) {
  geodesic_distance <- distm(c(as.double(lon1), as.double(lat1)),
                             c(as.double(lon2), as.double(lat2)),
                             fun = distHaversine)
  # browser()

  g <- geodesic_distance[1] / 1000

  return(g)
}

#' Calculated the distance to deliver to the delivery points within the
#' delivery zone according to Daganzo's approach
#'
#' zone = name, delivery size (number of boxes), area (m2), latitude,
#'        longitude, number of delivery points
calculatelDistanceDistributionArea <- function(k, zone) {
  # distance of delivering the nodes concentrated into the delivery zone
  daganzo_distance <- k * sqrt(as.double(zone[3])  * as.double(zone[6]))

  return(daganzo_distance)
}


#' Calculate the total distance to deliver in the area as the sumation from the
#' depot to the centroid of the delivery area and the distance within the
#' delivery area
#'
#' zone = name, delivery size (number of boxes), area (m2), latitude, longitude,
#'        number of delivery points
#' facility = (name, handling time, latitude, longitude)
calculateTotalDistance <- function(zone, facility, m, config) {
  db_dhi <- calculateTotalDistanceDirectShipment(zone, facility, m)
  db_dhi <- db_dhi + calculatelDistanceDistributionArea(config[2], zone)

  return(db_dhi)
}

#' Calculate the total time to deliver in the area as the sumation from the
#' depot to the centroid of the delivery area and the distance within the
#' delivery area
#'
#' vehicle = (name, capacity (Porto in boxes), speed (km/h), stop time (h))
#' zone = name, delivery size (number of boxes), area (m2), latitude, longitude,
#'        number of delivery points
calculateTotalTime <- function(distance, vehicle, zone) {
  db_time <- (distance) / as.double(vehicle[3])
  db_time <- db_time + as.double(vehicle[4]) * as.double(zone[6])
  # browser()

  return(db_time)
}

#' Calculate the number of vehicles required according to the capacity of the
#' vehicle and the distance within the delivery area
#'
#' vehicle =  (name, capacity in parcels, speed (km/h), stop time (h))
#' zone = (name, delivery size in parcels, area (m2), latitude, longitude,
#'         number of delivery points)
calculateM1<- function(vehicle, zone) {
  #(delivery size * number of deliveries)/ capacity of the vehicle
  db_m1 <- as.double(zone[2]) * as.double(zone[6]) / as.double(vehicle[2])

  dec <- db_m1 - as.integer(db_m1)
  if (dec > 0) {
    db_m1 <- as.integer(db_m1) + 1
  } else {
    db_m1 <- as.integer(db_m1)
  }

  return(db_m1)
}

#' Calculate the number of vehicles required according to the capacity of the
#' vehicle and the distance within the delivery area
#'
#' vehicle =  (name, capacity in parcels, speed (km/h), stop time (h))
#' zone = (name, delivery size in parcels, area (m2), latitude, longitude,
#'         number of delivery points)
#' facility = (name, handling time, latitude, longitude)
calculateM2 <- function(first_distance, vehicle, zone, facility, config) {
  db_m2 <- calculateTotalTime(first_distance, vehicle, zone)

  # resources (people) = total time for delivering div by the time available
  # after reducing the time for preparing the vehicle in the facility
  db_m2 <- db_m2 / (as.double(config[1]) - as.double(facility[2]))

  dec <- db_m2 - as.integer(db_m2)
  if (dec > 0) {
    db_m2 <- as.integer(db_m2) + 1
  } else {
    db_m2 <- as.integer(db_m2)
  }

  return(db_m2)
}
