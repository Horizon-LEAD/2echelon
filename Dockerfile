FROM r-base:4.1.2

RUN apt update
# rJava
RUN apt install -y default-jre default-jdk
RUN R CMD javareconf
# geojsonio
RUN apt install -y libprotobuf-dev protobuf-compiler libv8-dev libjq-dev
# sf
RUN apt install -y libudunits2-0 libudunits2-dev libgdal-dev

RUN R -e "install.packages(c('sp', 'sf', 'raster', 'dplyr'))"
RUN R -e "install.packages('spDataLarge', repos='https://nowosad.github.io/drat/', type='source')"
RUN R -e "install.packages('spData')"
RUN R -e "install.packages(c('ggmap', 'geojsonio', 'xlsx', 'rJava', 'xlsxjars'))"
RUN R -e "install.packages(c('geosphere'))"

COPY src/* /app/

CMD [ "Rscript", "/app/2echelon.R" ]
