FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Copy the requirement files
COPY requirements.txt requirements.txt
COPY importer/requirements.sh requirements.sh

# Install the required packages
RUN ./requirements.sh

# Remove cached files
RUN rm -rf /var/lib/apt/lists/* && apt-get clean && rm -rf requirements.*
