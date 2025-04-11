FROM rocker/shiny:latest

# Install any necessary R packages (you might need to add more here)
RUN R -e "install.packages(c('shinydashboard', 'DT', 'dplyr', 'readr', 'haven'), repos='https://cloud.r-project.org/')"

# Copy your Shiny app files into the Docker image
COPY . /srv/shiny-app

# Set the directory Shiny Server will serve
EXPOSE 80
CMD ["/usr/bin/shiny-server"]