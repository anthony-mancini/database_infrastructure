#!/usr/bin/env bash

#
# This file contains a post install script to be used with terraform deployment
# of a MongoDB database on an Ubuntu20 machine. The script will install Docker 
# and all its dependencies, pull the Docker container for MongoDB from Docker 
# Hub, and run the pulled Docker image. For additional information on the
# underlying infrastructure, see the .tf terraform files in this repository.
#
# @author Anthony Mancini
# @version 1.0.0
# @license GNU GPLv3 or later
#

# Updating the package repo on the newly installed machine
sudo apt update -y

# Upgrading existing programs to the latest versions
sudo apt upgrade -y

# Installing all of the dependencies needed to download and run the code for
# parsing out the patent and label data, processing it, and storing it into
# a MongoDB database
sudo apt-get install -y python3
sudo apt-get install -y python3-pip
sudo apt-get install -y git
sudo apt-get install -y nodejs
sudo apt-get install -y npm

# TODO: when completed, add code clone the repository and run the code for the
# ETL pipeline

# Uninstalling old versions of Docker and dependencies if installed
sudo apt-get remove -y docker
sudo apt-get remove -y docker-engine
sudo apt-get remove -y docker.io
sudo apt-get remove -y containerd
sudo apt-get remove -y runc
sudo apt autoremove -y

# Installing docker dependencies
sudo apt-get install -y apt-transport-https
sudo apt-get install -y ca-certificates
sudo apt-get install -y curl
sudo apt-get install -y gnupg

# Fetching Docker's GPG key and adding it to the GPG keyring
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Setting up the Docker repository and adding it to the sources list
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Updating the repository and installing Docker and all dependencies
sudo apt-get update
sudo apt-get install -y docker-ce
sudo apt-get install -y docker-ce-cli
sudo apt-get install -y containerd.io

# Pulling the MongoDB container from Docker Hub
sudo docker pull mongo

# Running MongoDB 4.4 on ports 27017-27019
sudo docker run \
    -p 27017-27019:27017-27019 \
    --name mongodb \
    -d mongo:4.4
