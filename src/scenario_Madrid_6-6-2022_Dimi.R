#Rscript U:/20211027ZLC/scenarioASIS_Madrid.R U:/20211027ZLC/INPUT/config.csv U:/20211027ZLC/INPUT/services.csv U:/20211027ZLC/INPUT/facilitiesASIS.csv U:/20211027ZLC/INPUT/vehiclesASIS.csv U:/20211027ZLC

#Rscript /2ECHELON/scenarioASIS_Madrid.R /home/dimitra/Documents/LEAD/Porto/echelon-copert-demo/Madrid-demo-15-11-2021/2ECHELON/INPUT/config.csv /home/dimitra/Documents/LEAD/Porto/echelon-copert-demo/Madrid-demo-15-11-2021/2ECHELON/INPUT/services.csv /home/dimitra/Documents/LEAD/Porto/echelon-copert-demo/Madrid-demo-15-11-2021/2ECHELON/INPUT/facilitiesASIS.csv /home/dimitra/Documents/LEAD/Porto/echelon-copert-demo/Madrid-demo-15-11-2021/2ECHELON/INPUT/vehiclesASIS.csv /home/dimitra/Documents/LEAD/Porto/echelon-copert-demo/Madrid-demo-15-11-2021/2ECHELON

#Rscript /home/dimitra/Documents/LEAD/Porto/echelon-copert-demo/Madrid-demo-15-11-2021/2ECHELON/scenario_Porto.R /home/dimitra/Documents/LEAD/Porto/echelon-copert-demo/Madrid-demo-15-11-2021/2ECHELON/INPUT/config.csv /home/dimitra/Documents/LEAD/Porto/echelon-copert-demo/Madrid-demo-15-11-2021/2ECHELON/INPUT/services.csv /home/dimitra/Documents/LEAD/Porto/echelon-copert-demo/Madrid-demo-15-11-2021/2ECHELON/INPUT/facilitiesPorto.csv /home/dimitra/Documents/LEAD/Porto/echelon-copert-demo/Madrid-demo-15-11-2021/2ECHELON/INPUT/vehiclesASIS.csv /home/dimitra/Documents/LEAD/Porto/echelon-copert-demo/Madrid-demo-15-11-2021/2ECHELON/INPUT/area.csv /home/dimitra/Documents/LEAD/Porto/echelon-copert-demo/Madrid-demo-15-11-2021/2ECHELON



#--------------------------------------------------------------
#Description: Script for executing Madrid scenarios
#--------------------------------------------------------------Tw
args= commandArgs(trailingOnly = TRUE)
if (length(args)==0) {
  stop("Four arguments need to be supplied", call.=FALSE)
} else if (length(args)==6) {
  # default output file
  file_config = args[1]
  file_services = args[2]
  file_facilities_ASIS=args[3]
  file_vehicles_ASIS =args[4]
  file_area =args[5]
  file_dir=args[6]
}
file_ouptut_ASIS =paste(file_dir,"/OUTPUT/testOutputASIS.txt",sep="")
#source(paste(file_dir,"/Shapefile_to_Zone.R",sep=""))
source(paste(file_dir,"/TwoEchelonModel_script.R",sep=""))


#str_url= "https://datos.madrid.es/egob/catalogo/300229-0-trafico-madrid-central.zip"
#str_file_name=paste(file_dir,"/TEMP/Madrid_Central.shp",sep="")
#-----------------------------------------------------------
#read default paremeters from config
#----------------------------------------------------------
fdconfig = read.csv(file_config,header=T,";")
configUI = as.matrix(fdconfig,nrow=2,ncol=7,byrow=TRUE)


k= configUI[1,1]
workshift = configUI[1,2]
branchHandlingTime = configUI[1,3]
UCCHandlingTime = configUI[1,4]
stopTimeFirstEchelon = configUI[1,5]
stopTimeSecondEchelon = configUI[1,6]
distanceType = configUI[1,7]


#---------------------------------------------------------------
#Read data of facilities to serve the consumers. First row of the
#document (.csv) contains the information for the 
#first leg and the the seconf row for the second leg
#---------------------------------------------------------------
fdFacilities=read.csv(file_facilities_ASIS,header=F,";")
print(file_facilities_ASIS)

#FacilityUI = Information in the file (Name	Address	Number	City	ZipCode	Latitude	Longitude	HandlingTime (minutes) StartHour	EndHour)
facilityUI = as.matrix(fdFacilities,nrow=3,ncol=10,byrow=TRUE)

#Model data input : facility = (name, handling time(h), latitude, longitude)'
#facility first leg in San Fernando = origin of the route
facility1 = c(facilityUI[1,1], as.integer(facilityUI[1,8])/60, as.double(facilityUI[1,6]),as.double(facilityUI[1,7]))


#--------------------------------------------------------------------
#Read data od the vehicles to serve the consumer.  First row of the
#document (.csv) contains the information for the 
#first leg and the the seconf row for the second leg
#--------------------------------------------------------------------
#vehicles'
fdVehicles=read.csv(file_vehicles_ASIS,header=F,";")
#vehiclesUI = (type, capacityParcels, CapacityKg, CapacityM3, FixedCosts, AverageSpeed(km/h), MaxKilometerDay)
vehiclesUI = as.matrix(fdVehicles,nrow=3,ncol=7,byrow=TRUE)

#vehicle =  (name, capacity (Porto in boxes), speed (km/h), stop time (h))
vehicle1 = c(vehiclesUI[1,1], vehiclesUI[1,2], vehiclesUI[1,6], stopTimeSecondEchelon)


#---------------------------------------------------------------------
#read the data of the services and geographic data of the delivery area
#to create the zones.
#----------------------------------------------------------------------

#read the file with the orders for echelon 1 (aggregated orders) and echelon 2 (average size of the orders)'
fd=read.csv(file_services,header=F,";")
zoneAvgOrderSize=mean(fd$V20)
zoneNOrders=nrow(fd)
zoneAggregatedOrdersSize = sum(fd$V20)
#read geographic data od the delivery area'
#print(getwd())
#Read_url_GeographicData(str_url,file_dir)
z=read.csv(file_area,header=F,",")
area = as.matrix(z,nrow=2,ncol=3,byrow=TRUE)
#print(as.numeric(area[2,1])/2)
#print(area[2,2])
#print(area[2,3])


zoneArea = as.numeric(area[2,1])#Read_area(str_file_name)
zoneArea = zoneArea/1000000
#zoneCentroid = Read_centroid(str_file_name)
#zoneCentroidGeometry = st_geometry(zoneCentroid)
#zoneCoordinatesCentroid = st_coordinates(zoneCentroidGeometry)
zoneCentroidX = as.numeric(area[2,2])#zoneCoordinatesCentroid[2]
zoneCentroidY = as.numeric(area[2,3])#zoneCoordinatesCentroid[1]

#----------------------------------------------------------------------------
#Zone 1 
#   ZOne 1: latitude and longitude of the centroid
#   zone 1: area of delivery zone (WARNING in km2)
#   zone 1: number of delivery nodes = number of services
#   zone 1: avgSize is the average size
#---------------------------------------------------------------------------
#create the zone for echelon 1: 1 delivery point (UCC) from the branch with agregated orders
zone1 = c(1,zoneAvgOrderSize,zoneArea, zoneCentroidX, zoneCentroidY,zoneNOrders)


#------------------------------------------------------------------------------'
#workshift = 8 for the tow legs. We assume independent resources and times
#K = parameter required for the model
config =c(workshift,k)
#------------------------------------------------------------------------------'

solution = calculateSolutionLeg(zone1, vehicle1, facility1, config)



dfSolution = data.frame(Echelon= c(1),
                       zoneName = c(zone1[1]),
                       zoneAvgSize = c (zone1[2]),
                       zoneArea =  c (zone1[3]),
                       #zoneLatitude = c (zoneFirstLeg[4], zoneSecondLeg[4]),
                       #zoneLongitude = c (zoneFirstLeg[5], zoneSecondLeg[5]),
                       zoneTotalDeliveries = c (zone1[6]),
                       vehicleName = c(vehicle1[1]),
                       vehicleCapacity = c(vehicle1[2]),
                       vehicleSpeed = c(vehicle1[3]),
                       vehicleStopTime = c(vehicle1[4]),
                       facilityName = c(facility1[1]),
                       facilityHandlingTime = c(facility1[2]),
                       #facilityLatitude = c(facilityFirstLeg[3],facilitySecontLeg[3]),
                       #facilityLongitude = c(facilityFirstLeg[4],facilitySecontLeg[4]),
                       totalDistance = c(solution[1]),
                       totalTime = c(solution[2]),
                       m = c(solution[3])
                                                
)
#write.csv2(dfSolution,"./Madrid_Centro/testOutputASIS.csv",sep =";", row.names = FALSE, dec=".")
write.table(dfSolution,file_ouptut_ASIS,sep =";", dec=".", row.names = FALSE)

                       
print("Terminado AS IS")
