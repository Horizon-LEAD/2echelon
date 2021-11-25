'--------------------------------------------------------------'
'Description: Script for executing Madrid scenarios'
'--------------------------------------------------------------'

'---------------------------------------------------------------'
#Read data of facilities to serve the consumers. First row of the
#document (.csv) contains the information for the 
#first leg and the the seconf row for the second leg
'---------------------------------------------------------------'
fdFacilities=read.csv(file_facilities_TOBE,header=F,";")

#FacilityUI = Information in the file (Name	Address	Number	City	ZipCode	Latitude	Longitude	HandlingTime (minutes) StartHour	EndHour)
facilityUI = as.matrix(fdFacilities,nrow=3,ncol=10,byrow=TRUE)

#Model data input : facility = (name, handling time(h), latitude, longitude)'
#facility first leg in San Fernando = origin of the route
facility1 = c(facilityUI[1,1], as.integer(facilityUI[1,8])/60, as.double(facilityUI[1,6]),as.double(facilityUI[1,7]))

#facility second leg in UCC = origin on the route
facility2 = c(facilityUI[2,1],  as.integer(facilityUI[2,8])/60, as.double(facilityUI[2,6]),as.double(facilityUI[2,7]))
'--------------------------------------------------------------------'

'--------------------------------------------------------------------'
#Read data od the vehicles to serve the consumer.  First row of the
#document (.csv) contains the information for the 
#first leg and the the seconf row for the second leg
'--------------------------------------------------------------------'
'vehicles'
fdVehicles=read.csv(file_vehicles_TOBE,header=F,";")
#vehiclesUI = (type, capacityParcels, CapacityKg, CapacityM3, FixedCosts, AverageSpeed(km/h), MaxKilometerDay)
vehiclesUI = as.matrix(fdVehicles,nrow=3,ncol=7,byrow=TRUE)

#vehicle =  (name, capacity (Porto in boxes), speed (km/h), stop time (h))
vehicle1 = c(vehiclesUI[1,1], vehiclesUI[1,2], vehiclesUI[1,6], stopTimeFirstEchelon)
vehicle2 = c(vehiclesUI[2,1], vehiclesUI[2,2], vehiclesUI[1,6], stopTimeSecondEchelon)
'---------------------------------------------------------------------'

'---------------------------------------------------------------------'
#read the data of the services and geographic data of the delivery area
#to create the zones.
'----------------------------------------------------------------------'

'read the file with the orders for echelon 1 (aggregated orders) and echelon 2 (average size of the orders)'
fd=read.csv(file_services,header=F,";")
zoneAvgOrderSize=mean(fd$V20)
zoneNOrders=nrow(fd)
zoneAggregatedOrdersSize = sum(fd$V20)
'read geographic data od the delivery area'
Read_url_GeographicData(str_url)
zoneArea = Read_area(str_file_name)
zoneArea = zoneArea/1000000
zoneCentroid = Read_centroid(str_file_name)
zoneCentroidGeometry = st_geometry(zoneCentroid)
zoneCoordinatesCentroid = st_coordinates(zoneCentroidGeometry)
zoneCentroidX = zoneCoordinatesCentroid[2]
zoneCentroidY = zoneCoordinatesCentroid[1]

'----------------------------------------------------------------------------'
#Zone 1 
#   Will have just one delivery node that is the location of the UCC.
#   ZOne 1: latitude and longitude = facility 2 latitude and longitude
#   zone 1: number of delivery nodes = 0
#   zonse 1: avgSize is the sumation of all the parcels to be deliver in the zone
'---------------------------------------------------------------------------'
'create the zone for echelon 1: 1 delivery point (UCC) from the branch with agregated orders'
zone1 = c(1,zoneAggregatedOrdersSize,0, facility2[3], facility2[4],stopTimeFirstEchelon)

'----------------------------------------------------------------------------'
#Zone 2 
#   Will have just n delivery nodes.
#   zone 2: WARNING, check the distance is in km2
#   ZOne 2: latitude and longitude = centroide of the area
#   zone 2: number of delivery nodes = number of services
#   zone 2: avgSize is the average of all the parcels to be deliver in the zone
'---------------------------------------------------------------------------'
'create the zone for echelon 2: n delivery points from the (UCC) with avg size of the orders'
zone2 = c(2,zoneAvgOrderSize,zoneArea,zoneCentroidX,zoneCentroidY, zoneNOrders)

'------------------------------------------------------------------------------'
#workshift = 8 for the tow legs. We assume independent resources and times
#K = parameter required for the model
config =c(workshift,k)
'------------------------------------------------------------------------------'

solution = calculateSolutionTwoLegs(zone1, vehicle1, facility1,zone2, vehicle2, facility2, config)



dfSolution = data.frame(Echelon= c(1,2),
                       zoneName = c(zone1[1], zone2[1]),
                       zoneAvgSize = c (zone1[2], zone2[2]),
                       zoneArea =  c (zone1[3], zone2[3]),
                       #zoneLatitude = c (zoneFirstLeg[4], zoneSecondLeg[4]),
                       #zoneLongitude = c (zoneFirstLeg[5], zoneSecondLeg[5]),
                       zoneTotalDeliveries = c (zone1[6], zone2[6]),
                       vehicleName = c(vehicle1[1],vehicle2[1]),
                       vehicleCapacity = c(vehicle1[2],vehicle2[2]),
                       vehicleSpeed = c(vehicle1[3],vehicle2[3]),
                       vehicleStopTime = c(vehicle1[4],vehicle2[4]),
                       facilityName = c(facility1[1],facility2[1]),
                       facilityHandlingTime = c(facility1[2],facility2[2]),
                       #facilityLatitude = c(facilityFirstLeg[3],facilitySecontLeg[3]),
                       #facilityLongitude = c(facilityFirstLeg[4],facilitySecontLeg[4]),
                       totalDistance = c(solution[1], solution[4]),
                       totalTime = c(solution[2], solution[5]),
                       m = c(solution[3], solution[6])
                                                
)
#write.csv2(dfSolution,"./Madrid_Centro/testOutputTOBE.csv",sep =";", row.names = FALSE, dec=".")
write.table(dfSolution,file_ouptut_TOBE,sep =";", dec=".", row.names = FALSE)

                       
print("Terminado TO BE")
