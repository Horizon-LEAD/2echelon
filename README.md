# Echelon Model

Echelon model for the LEAD platform

## Introduction

In the following the basics of the `echelon` model are presented.
That includes descriptions of the input and source files, together with guidelines on using the scripts.

### Source files description
- `main.R`: entrypoint for script
- `echelon.R`: functions for orchestrating the execution
- `zone.R`: functions for reading geographic data
- `calc.R`: functions for calculating the number of vehicles, distance and times

### Input files description
- `config.csv`: contains the configuration for the execution of the Echelon model.
    ```
    k;workshift;branchHandlingTime;UCCHandlingTime;stopTimeFirstEchelon;stopTimeSecondEchelon;distanceType
    ```
- `services.csv`: lists all the deliveries to be serviced
- `facilities.csv`: contains information concerning the facilities
    - First row: characteristics for the first leg.
    - Second row: characteristics for the second leg.
    ```
    Name;Address;Number;City;ZipCode;Latitude;Longitude;HandlingTime (minutes);StartHour;EndHour
    ```
- `vehicles.csv`: contains the details of the available vehicles
    ```
    type;capacityParcels;CapacityKg;CapacityM3;FixedCosts;AverageSpeed(km/h);MaxKilometerDay
    ```
- Area
    - `Madrid_Central.zip`: a zip file with the same name as the `.shp` file inside is expected in the `v1` of the model in order to extract the area details
    - `area.csv`: the area details are provided as a CSV in the `v1-csv` version of the model
        ```
        area(km);lat;long
        ```
### Output files description

- `output.csv`: contains the outputs of the model
    - First row: output for the first leg.
    - Second row: output for the second leg.
        ```
        "Echelon";"zoneName";"zoneAvgSize";"zoneArea";"zoneTotalDeliveries";
        "vehicleName";"vehicleCapacity";"vehicleSpeed";"vehicleStopTime";
        "facilityName";"facilityHandlingTime";
        "totalDistance";"totalTime";"numberOfVehicles"
        ```

## Usage

### Build

To execute the `echelon` model locally some required packages must be installed.
The packages are

```
# building v1 of the model
git checkout v1
docker build -t echelon:v1 .

# building v1-csv of the model
git checkout v1-csv
docker build -t echelon:v1-csv .
```

### Run

The model provides a CLI to facilitate its usage.

```
$ Rscript src/main.R
usage: /app/main.R [-h] [--areacsv]
                   config services facilities vehicles area outdir
/app/main.R: error: the following arguments are required: config, services, facilities, vehicles, area, outdir
```
As an example one could run:
```
Rscript src/main.R \
    ./sample-data/inputs/v1/config.csv \
    ./sample-data/inputs/v1/services.csv \
    ./sample-data/inputs/v1/facilities.csv \
    ./sample-data/inputs/v1/vehicles.csv \
    ./sample-data/inputs/Madrid_Central.zip \
    ./sample-data/outputs

Rscript src/main.R --areacsv \
    ./sample-data/inputs/v1/config.csv \
    ./sample-data/inputs/v1/services.csv \
    ./sample-data/inputs/v1/facilities.csv \
    ./sample-data/inputs/v1/vehicles.csv \
    ./sample-data/inputs/v1/area.csv \
    ./sample-data/outputs
```

Having prepared the containers in the build step, the model can be also run inside the container.
Data can be passed inside the container with volume mounts.
```
docker run --rm \
    -v $PWD/sample-data:/data \
    echelon:v1 \
    /data/inputs/v1/config.csv \
    /data/inputs/v1/services.csv \
    /data/inputs/v1/facilities.csv \
    /data/inputs/v1/vehicles.csv \
    /data/inputs/Madrid_Central.zip \
    /data/outputs

docker run --rm \
    -v $PWD/sample-data:/data \
    echelon:v1-csv \
    /data/inputs/v1/config.csv \
    /data/inputs/v1/services.csv \
    /data/inputs/v1/facilities.csv \
    /data/inputs/v1/vehicles.csv \
    /data/inputs/v1/area.csv \
    /data/outputs
```

## Support

+ [LEAD project](https://www.leadproject.eu/)
+ [Repository](https://github.com/Horizon-LEAD/2echelon)
+ [Issues](https://github.com/Horizon-LEAD/2echelon/issues)

## Roadmap

+ Jan 2022: first demostration
+ Dec 15 2023: delivery to living labs

## License

For open source projects, say how it is licensed.

## Project status

Beta testing
