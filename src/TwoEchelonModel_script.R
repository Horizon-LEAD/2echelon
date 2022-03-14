#Version:               1.0
#Date of creation:      17.05.2021
#Author:                Beatriz Royo
#Last Update:           02.10.2021
#Last modification:     Beatriz Royo

#------------------------------------------------------------------------------
#Description: Script for calculating the number of resources and distance for 2 echelon networks (first leg, second leg)
#             or for just the second leg depending on the input data configuration
#input data: 
#           vehicleFirstLeg =  (name, capacity (Porto in boxes), speed (km/h), stop time (h))
#           facilityFirstLeg = (name, handling time, latitude, longitude)
#           zoneFirstLeg =  (name, delivery size (number of boxes), area (m2), latitude, longitude, number of delivery points)
#           vehicleSecondLeg =  (name, capacity (Porto in boxes), speed (km/h), stop time (h))
#           facilitySecondLeg = (name, handling time, latitude, longitude)
#           zoneSecondLeg =  (name, delivery size (number of boxes), area (m2), latitude, longitude, number of delivery points)
#           config = (workshift time, k)
#output data:
#           solution= (totalDistanceFirstLeg, totalTimeFirstLeg, mFirstLeg,totalDistanceSecondLeg, totalTimeSecondLeg, mSecondLeg)
#----------------------------------------------------------------------------------------------------------------------

#------------------------------------------------------------------------------------------
# execution: README File 
#----------------------------------------------------------------------------------------


calculateSolutionTwoLegs <- function(zone1, vehicle1, facility1, zone2, vehicle2, facility2, config){
  #calculate the number of resources per leg. If first leg not needed the input data for the area and the delivery 
  #points must be zero
 
  solutionFirstLeg = calculateSolutionLeg(zone1,vehicle1, facility1, config)
  solutionSecondLeg = calculateSolutionLeg(zone2, vehicle2, facility2, config)

  solution=c(solutionFirstLeg, solutionSecondLeg)

  return (solution)
}


calculateSolutionLeg<- function(zone, vehicle, facility, config) {
  #calculate the number of vehicles and resources to deliver in a specific delivery zone from the hub within the delivery area
  #to the delivery points
  initialDistance = calculateTotalDistance(zone, facility,1,config) #distance if only 1 vehicle
 
  m1 =calculateM1(vehicle,zone) #number of resources considering capacity constraint
  m2 = calculateM2(initialDistance, vehicle, zone, facility) #number of resources considering time constraint
  #browser()
  
  m =max(m1,m2) #the number of resources is the max required
  totalDistance = calculateTotalDistance(zone, facility,m,config) #total distance with the m vehicles
  totalTime = calculateTotalTime(totalDistance, vehicle, zone)
  
  'solution = list(vehicle, zone, facility, config, totalDistance, totalTime, m)'
  
  solution = c(totalDistance, totalTime, m)
  
  return (solution)
}


calculateTotalDistanceDirectShipment <- function(zone, facility, m) {
#total direct distance from the branch/ mobile depot to the first point of the delivery area
#zone = name, delivery size (number of boxes), area (m2), latitude, longitude, number of delivery points
#facility = name, handling time, latitude, longitude
  #db_dhi = calculateEuclideanDistance(zone[4], zone[5], facility[3], facility[4])
  # db_dhi = calculateGeodesicDistance(zone[4], zone[5], facility[3], facility[4])
  
    if(distanceType==1){
      print("1")
      db_dhi = calculateEuclideanDistance(zone[4], zone[5], facility[3], facility[4])
    }else{
      print("2")
      db_dhi = calculateGeodesicDistance(zone[4], zone[5], facility[3], facility[4])
    } 

  db_dhi = db_dhi * 2 * m #roundtrip distance

  return (db_dhi)
}

calculateEuclideanDistance <- function(lat1, lon1, lat2,lon2) {
#calculates the distance between tow points. 
#Euclidean distance

  EuclidianDistance = sqrt((as.double(lat1) - as.double(lat2)) ^ 2 + (as.double(lon1) - as.double(lon2)) ^ 2)
  #browser()
  
  return (EuclidianDistance)
}


calculateGeodesicDistance <- function(lat1, lon1, lat2,lon2) {
  #calculates the distance between tow points accoring to the haversine formula
  #by default in metres
  
  library(geosphere)
  GeodesicDistance= distm (c(as.double(lon1), as.double(lat1)), c(as.double(lon2), as.double(lat2)), fun = distHaversine) 
  ##browser()
  
  g=GeodesicDistance[1]/1000

  return (g)
}

calculatelDistanceDistributionArea <- function(k, zone) {
#calculated the distance to deliver to the delivery points within the delivery zone according to Daganzo's approach
#zone = name, delivery size (number of boxes), area (m2), latitude, longitude, number of delivery points

  DaganzoDistance = k * sqrt(as.double(zone[3])  * as.double(zone[6])) #distance of delivering the nodes concentrated into the delivery zone

  return (DaganzoDistance)
}


calculateTotalDistance <- function(zone, facility,m, config) {
  #calculated the total distance to deliver in the area as the sumation from the depot to the centroid of the delivery area
  #and the distance within the delivery area
  #zone = name, delivery size (number of boxes), area (m2), latitude, longitude, number of delivery points
  #facility = (name, handling time, latitude, longitude)
  
  db_dhi = calculateTotalDistanceDirectShipment(zone, facility, m)
  db_dhi = db_dhi + calculatelDistanceDistributionArea(config[2], zone)

  return (db_dhi)
}


calculateTotalTime <- function(distance, vehicle, zone) {
  #calculated the total distance to deliver in the area as the sumation from the depot to the centroid of the delivery area
  #and the distance within the delivery area
  #vehicle =  (name, capacity (Porto in boxes), speed (km/h), stop time (h))
  #zone = name, delivery size (number of boxes), area (m2), latitude, longitude, number of delivery points

  db_time = (distance) / as.double(vehicle[3])
  db_time = db_time + as.double(vehicle[4]) * as.double(zone[6])
  #browser()

  return (db_time)
}

calculateM1<- function(vehicle, zone) {
  #calculate the number of vehicles required according to the capacity of the vehicle
  #and the distance within the delivery area
  #vehicle =  (name, capacity in parcels, speed (km/h), stop time (h))
  #zone = (name, delivery size in parcels, area (m2), latitude, longitude, number of delivery points)

  #(delivery size * number of deliveries)/ capacity of the vehicle
  db_m1 = as.double(zone[2])*as.double(zone[6]) / as.double(vehicle[2])
  
  dec = db_m1 - as.integer(db_m1)
  if(dec > 0){
    db_m1 = as.integer(db_m1)+1
    
  }
  else {
    db_m1 = as.integer(db_m1)
  }

  return (db_m1)
}

calculateM2<- function(firstDistance, vehicle, zone, facility) {
  #calculate the number of vehicles required according to the capacity of the vehicle
  #and the distance within the delivery area
  #vehicle =  (name, capacity in parcels, speed (km/h), stop time (h))
  #zone = (name, delivery size in parcels, area (m2), latitude, longitude, number of delivery points)
  #facility = (name, handling time, latitude, longitude)
  
  db_m2 = calculateTotalTime(firstDistance,vehicle,zone)
  
  #resources (people) = total time for delivering div by the time available after reducing the time for preparing the vehicle in the facility
  db_m2 = db_m2 / (as.double(config[1]) - as.double(facility[2]))
  
  dec = db_m2 - as.integer(db_m2)
  if(dec>0){
    db_m2 = as.integer(db_m2)+1
    
  }
  else {
    db_m2 = as.integer(db_m2) 
  }

  return (db_m2)
}
