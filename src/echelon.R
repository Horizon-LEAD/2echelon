library("tools")

source(file.path(script_dirname, "Shapefile_to_Zone.R"))
source(file.path(script_dirname, "TwoEchelonModel_script.R"))

#' Unzip file to given directory
unzip_area <- function(zip_path) {
  unzip(zipfile = zip_path, overwrite = TRUE,
        exdir = dirname(zip_path))
}

echelon <- function(file_config, file_services, file_facilities,
                    file_vehicles, area, out_dir) {
    unzip_area(area)
    file_area <- paste(tools::file_path_sans_ext(area), ".shp", sep = "")

    output_fname <- file.path(out_dir, "output.csv")

    start_time <- Sys.time()
    #-------------------------------------------------------------------------
    # Read config parameters from config file
    fdconfig <- read.csv(file_config, header = T, ";")
    config_ui <- as.matrix(fdconfig, nrow = 2, ncol = 7, byrow = TRUE)

    k <- config_ui[1, 1]
    workshift <- config_ui[1, 2]
    branch_handling_time <- config_ui[1, 3]
    ucc_handling_time <- config_ui[1, 4]
    stop_time_first_echelon <- config_ui[1, 5]
    stop_time_second_echelon <- config_ui[1, 6]
    distance_type <- config_ui[1, 7]

    #-------------------------------------------------------------------------
    # Read data of facilities to serve the consumers.
    #
    # First row of the document (.csv) contains the information for the
    # first leg and the the seconf row for the second leg
    #
    # facility_ui: Information of vehicles from the file
    # facility_ui = (Name, Address, Number, City, ZipCode, Latitude, Longitude,
    #                HandlingTime (minutes), StartHour, EndHour)
    #
    # Model data input:
    # facility = (name, handling time(h), latitude, longitude)'
    # facility first leg in San Fernando = origin of the route
    fd_facilities <- read.csv(file_facilities, header = F, ";")
    facility_ui <- as.matrix(fd_facilities, nrow = 3, ncol = 10, byrow = TRUE)
    facility1 <- c(facility_ui[1, 1],
                as.integer(facility_ui[1, 8]) / 60,
                as.double(facility_ui[1, 6]),
                as.double(facility_ui[1, 7]))

    #-------------------------------------------------------------------------
    # Read data od the vehicles to serve the consumer.
    #
    # First row of the document (.csv) contains the information for the
    # first leg and the the seconf row for the second leg
    #
    # vehicles_ui: Information of vehicles from the file
    # vehicles_ui = (type, capacityParcels, CapacityKg, CapacityM3,
    #                FixedCosts, AverageSpeed(km/h), MaxKilometerDay)
    #
    # vehicle =  (name, capacity (Porto in boxes), speed (km/h),
    #             stop time (h))
    fd_vehicles <- read.csv(file_vehicles, header = F, ";")
    vehicles_ui <- as.matrix(fd_vehicles, nrow = 3, ncol = 7, byrow = TRUE)
    vehicle1 <- c(vehicles_ui[1, 1], vehicles_ui[1, 2], vehicles_ui[1, 6],
                stop_time_second_echelon)


    #-------------------------------------------------------------------------
    # Read the data of the services and geographic data of the delivery area
    # to create the zones.

    # Read the file with the orders for echelon 1 (aggregated orders) and
    # echelon 2 (average size of the orders)
    #
    # zone  <- c(1, zone_avg_order_size, zone_area(km2),
    #            zone_centroid_x(latitude), zone_centroid_y(longitude),
    #            zone_no_orders(#services))
    fd_services <- read.csv(file_services, header = F, ";")
    zone_avg_order_size <- mean(fd_services$V20)
    zone_no_orders <- nrow(fd_services)
    zone_aggregated_orders_size <- sum(fd_services$V20)
    zone_area <- read_area(file_area) / 1000000
    zone_centroid <- read_centroid(file_area)
    zone_centroid_geometry <- st_geometry(zone_centroid)
    zone_coordinates_centroid <- st_coordinates(zone_centroid_geometry)
    zone_centroid_x <- zone_coordinates_centroid[2]
    zone_centroid_y <- zone_coordinates_centroid[1]
    # create the zone for echelon 1:
    # - 1 delivery point (UCC) from the branch with agregated orders
    zone1 <- c(1, zone_avg_order_size, zone_area,
            zone_centroid_x, zone_centroid_y,
            zone_no_orders)

    #-------------------------------------------------------------------------
    #workshift = 8 for the tow legs. We assume independent resources and times
    #K = parameter required for the model
    config <- c(workshift, k)
    #-------------------------------------------------------------------------

    solution <- calculateSolutionLeg(zone1, vehicle1, facility1, config,
                                     distance_type)
    df_solution <- data.frame(
    Echelon = c(1),
    zoneName = c(zone1[1]),
    zoneAvgSize = c(zone1[2]),
    zoneArea =  c(zone1[3]),
    #zoneLatitude = c (zoneFirstLeg[4], zoneSecondLeg[4]),
    #zoneLongitude = c (zoneFirstLeg[5], zoneSecondLeg[5]),
    zoneTotalDeliveries = c(zone1[6]),
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
    numberOfVehicles = c(solution[3])
    )

    # write.csv2(df_solution, "./Madrid_Centro/testOutputASIS.csv", sep =";",
    #            row.names = FALSE, dec = ".")
    write.table(df_solution, output_fname, sep = ";", dec = ".",
                row.names = FALSE)

    print.data.frame(df_solution)
    sprintf("Model execution completed [%.3fs]", Sys.time() - start_time)
}
