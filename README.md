# Echelon Model

Echelon model for the LEAD platform

## Introduction

In the following the basics of the `2echelon` model are presented.
That includes descriptions of the input and source files, together with guidelines on using the scripts.

## Environment preparation

```
conda create -n r-echelon r-base=4.2.0 r-essentials
conda activate r-echelon
conda install -c conda-forge r-sp r-sf
conda install -c conda-forge r-raster r-dplyr r-spData r-ggmap r-geojsonio r-geosphere
conda install -c conda-forge r-xlsx r-xlsxjars r-rJava
$ R
> install.packages(c("spDataLarge"), repos = c("https://cloud.r-project.org", "https://nowosad.github.io/drat/"))
```

<!--
--------------------------------------------------------------------------------------------------
ROOT FOLDER
-------------------------------------------------------------------------------------------------
--Shapefile_to_Zone.r: functions for reading geographic data.
--TwoEchelonModel_script.r: functions for calculating the number of vehicles, distance and times
for delivering for one leg (ASIS) and two legs (TOBE) scenarios.
--scenarioASIS_Madrid.r: script for executing the scenario asis and writing the results in a specific document.
The information required is in the INPUT folder and the output will be saved in the OUTPUT folder.
--scenarioTOBE_Madrid:script for executing the scenario asis and writing the results in a specific document.
The information required is in the INPUT folder and the output will be saved in the OUTPUT folder. (NOT WORKING)

--------------------------------------------------------------------------------------------------
INPUT FOLDER
-------------------------------------------------------------------------------------------------
This folder contains the csv with the information provided by the LSP differentiated by scenario.
facilitesASIS.csv: It contains the information of the facility for the asis scenario
facilitiesTOBE.csv: It contains the information of the facilities for the tobe scenario
- First row: characteristics for the first leg.
- Second row: characteristics for the second leg.
facilitesASIS.csv: It contains the information of the vechicle for the asis scenario
facilitiesTOBE.csv: It contains the information of the vechicles for the tobe scenario
- First row: characteristics for the first leg.
- Second row: characteristics for the second leg.
services.csv: It contains the services. It is the same for the TOBE and ASIS scenarios.
--------------------------------------------------------------------------------------------------
OUTPUT FOLDER
--------------------------------------------------------------------------------------------------
This folder will contain the result of executing both scenarios.
testOutputASIS.txt: It will contain a row with the number of vehicles, kms and delivery time for the ASIS scenario.
testOutputTOBE.txt: It will contain two rows:
- First row: number of vehicles, kms and delivery time for the first leg.
- Second row: number of vehicles, kms and delivery time for the second leg.
---------------------------------------------------------------------------------------------------
TEMP FOLDER
---------------------------------------------------------------------------------------------------
Folder for unziping the geographic data of the delivery area in the case of Madrid.
---------------------------------------------------------------------------------------------------- -->


## Installation

The model is deployed as a container and the necessary file should be provided as a volume mount under `/data`.

## Usage

Under a specific directory a few files must be defined.
+ A `config.csv` file contains the configuration for the execution of the Echelon model.
+ A `facilities.csv` file contains the details of the facilities.
+ A `vehicles.csv` file contains the details of the available vehicles.
+ A `services.csv` file lists all the deliveries to be serviced.

Mounting this directory to a location in the container while setting accordingly the `DATA_BASE_DIR` environment variable sets the inputs of the model.
The output of the model will be written in the same directory.

```
docker run -v /your/data/path:/data -e DATA_BASE_DIR=/data echelon-model
```

+ Inputs
    + args[1] = csv with the config parameteres "U:/2ECHELON/INPUT/config.csv"; the file in the INPUT FOLDER
    + args[2] = csv with the daily services from the operator "U:/2ECHELON/INPUT/services.csv"; see file in the INPUT FOLDER
    + args[3] = csv with the daily facilities "U:/2ECHELON/INPUT/facilitiesASIS.csv"; see file in the INPUT FOLDER
    + args[4] = csv with the daily vehicles "U:/2ECHELON/INPUT/vehiclesASIS.csv"; see file in the INPUT FOLDER
    + args[5] = working directory  "U:/2ECHELON"; to crate the TMP folder and the OUTPUT of the model

### For windows users

1. Navigate to the \bin subdirectory on your R version directory (C:\Program Files\R\your_R_version_directory \bin)
2. Search & Replace del string U:/20211027ZLC with the name of your directory and run the line below after updating the corresponding directory.
3. Rscript U:/2ECHELON/scenarioASIS_Madrid.R U:/2ECHELON/INPUT/config.csv U:/2ECHELON/INPUT/services.csv U:/2ECHELON/INPUT/facilitiesASIS.csv U:/2ECHELON/INPUT/vehiclesASIS.csv U:/2ECHELON

### Tested platforms

```
platform       x86_64-w64-mingw32
arch           x86_64
os             mingw32
system         x86_64, mingw32
status
major          4
minor          0.5
year           2021
month          03
day            31
svn rev        80133
language       R
version.string R version 4.0.5 (2021-03-31)
nickname       Shake and Throw
```

## Support

+ [LEAD project](https://www.leadproject.eu/)
+ [Echelon Model](https://www.google.com/)

## Roadmap

+ Jan 2022: first demostration

## License

For open source projects, say how it is licensed.

## Project status

Under development
