FROM r-base:4.1.2

# [1,2] rJava, [3] geojsonio, [4] sf
RUN apt-get update \
    && apt install -y default-jre default-jdk \
                libprotobuf-dev protobuf-compiler \
                libv8-dev libjq-dev libudunits2-0 \
                libudunits2-dev libgdal-dev \
    && R CMD javareconf

# RUN R -e "install.packages(c("sp", "sf", "raster", "dplyr"))"
# RUN R -e "install.packages("spDataLarge", repos="https://nowosad.github.io/drat/", type="source")"
# RUN R -e "install.packages("spData")"
# RUN R -e "install.packages(c("ggmap", "geojsonio", "xlsx", "rJava", "xlsxjars"))"
# RUN R -e "install.packages(c("geosphere"))"

RUN R -e 'install.packages( \
            c("sp", "sf", "raster", "dplyr", "spDataLarge", \
              "spData", "ggmap", "geojsonio", "xlsx", \
              "rJava", "xlsxjars", "geosphere"), \
            repos = c("https://cloud.r-project.org", \
                      "https://nowosad.github.io/drat/"))'

COPY src/* /app/

CMD [ "Rscript", "/app/2echelon.R" ]
