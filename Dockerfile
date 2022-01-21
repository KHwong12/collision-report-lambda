FROM amazon/aws-lambda-provided:latest

ENV R_VERSION=4.1.0

RUN yum -y install wget git tar

RUN yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
  && wget https://cdn.rstudio.com/r/centos-7/pkgs/R-${R_VERSION}-1-1.x86_64.rpm \
  && yum -y install R-${R_VERSION}-1-1.x86_64.rpm \
  && rm R-${R_VERSION}-1-1.x86_64.rpm

ENV PATH="${PATH}:/opt/R/${R_VERSION}/bin/"

# System requirements for R markdown
RUN yum -y install openssl-devel libicu-devel epel-release

# System requirements for kableExtra
RUN yum -y install libcurl-devel libxml2-devel fontconfig-devel freetype-devel libpng-devel ImageMagick ImageMagick-c++-devel

# System requirements for leaflet
RUN yum -y install libpng-devel gdal-devel gdal geos-devel proj-devel proj-epsg

ENV PANDOC_VERSION=2.16.2

RUN wget https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-linux-amd64.tar.gz
RUN tar xvzf pandoc-${PANDOC_VERSION}-linux-amd64.tar.gz --strip-components 1 -C /usr/local
RUN rm -rf pandoc-${PANDOC_VERSION}*

# Package for runtime
RUN Rscript -e "install.packages(c('httr', 'jsonlite', 'logger', 'rmarkdown', 'remotes'), repos = 'https://packagemanager.rstudio.com/all/__linux__/centos7/latest')"
RUN Rscript -e "remotes::install_github('mdneuzerling/lambdr')"

# Package for report
RUN Rscript -e "install.packages(c('dplyr', 'tidyr', 'fst', 'leaflet', 'kableExtra', 'htmltools'), repos = 'https://packagemanager.rstudio.com/all/__linux__/centos7/latest')"

RUN mkdir /lambda
# required or else Pandoc will complain
ENV HOME /lambda
# writeable directory in Lambda
ENV TMPDIR /tmp

COPY runtime.R collision-report.Rmd /lambda/

# Copy files in sub-dir to new dirs in lambda with the same name
COPY data /lambda/data
COPY styles /lambda/styles
COPY templates /lambda/templates

RUN chmod 755 -R /lambda

RUN printf '#!/bin/sh\ncd /lambda\nRscript runtime.R' > /var/runtime/bootstrap \
  && chmod +x /var/runtime/bootstrap

CMD ["report"]
