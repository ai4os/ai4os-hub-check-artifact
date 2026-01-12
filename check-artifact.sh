#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# Copyright (c) 2017 - 2024 Karlsruhe Institute of Technology - Scientific Computing Center
# This code is distributed under the MIT License
# Please, see the LICENSE file
#
# @author: vykozlov

### info
# top level script to call various subscripts
#
# input: Docker image to start as DEEPaaS-based application
###

### Main configuration
# Default Docker image, can be re-defiend
DOCKER_IMAGE=deephdc/deep-oc-generic
# Container name: number of seconds since 1970 + a random number
CONTAINER_NAME=$(date +%s)"_"$(($RANDOM))
# Port inside the container.
# It is assumed: 80 = web, 5000 = API, 6006 = Monitor, 8888 = IDE
CONTAINER_PORT=5000
###

### Usage message (params can be re-defined) ###
USAGEMESSAGE="Usage: $0 <docker_image> <container_port>"

# function to remove the Docker container
function remove_container() 
{   echo "[INFO]: Now removing ${CONTAINER_NAME} container"
    docker stop ${CONTAINER_NAME}
    docker rm ${CONTAINER_NAME}
}

#### Parse input ###
arr=("$@")
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    # print usagemessage
    shopt -s xpg_echo
    echo $USAGEMESSAGE
    exit 1
elif [ $# -eq 1 ]; then
    DOCKER_IMAGE=$1
elif [ $# -eq 2 ]; then
    DOCKER_IMAGE=$1
    CONTAINER_PORT=$2
else
    # Wrong number of arguments is given (!=1)
    echo "[ERROR] Wrong number of arguments provided!"
    shopt -s xpg_echo
    echo $USAGEMESSAGE
    exit 2
fi

# Start docker, let system to bind the port
echo "[INFO] Starting Docker image ${DOCKER_IMAGE}"
echo "[INFO] Container name: ${CONTAINER_NAME}"
docker run --name ${CONTAINER_NAME} -p ${CONTAINER_PORT} ${DOCKER_IMAGE} &

sleep_time=10
running_ok=false
HOST_PORT=""
port_ok=false
max_try=5     # max number of tries to get HOST_PORT
itry=1        # initial try number

sleep $sleep_time
# Wait until container is running
while [ "$running_ok" == false ] && [ $itry -le $max_try ];
do
    # Source - https://stackoverflow.com/a
    # Posted by BMitch, modified by community. See post 'Timeline' for change history
    # Retrieved 2026-01-12, License - CC BY-SA 4.0

    if [ "$( docker container inspect -f '{{.State.Status}}' ${CONTAINER_NAME} )" = "running" ]; then
        running_ok=true
        echo "[INFO] Container ${CONTAINER_NAME} marked as running"
    else
        echo "[INFO] Container ${CONTAINER_NAME} is not yet running. Try #"$itry
        sleep $sleep_time
        let itry=itry+1
    fi
done

# If could not run container, delete the container and exit
if [ "$running_ok" == false ]; then
    echo "======="
    echo "[ERROR] Could NOT run the container ${CONTAINER_NAME} (tries = $itry). Exiting..."
    remove_container
    exit 1
fi

# Figure out which host port was binded
while [ "$port_ok" == false ] && [ $itry -le $max_try ];
do
    HOST_PORT=$(docker inspect -f '{{ (index (index .NetworkSettings.Ports "'"$CONTAINER_PORT/tcp"'") 0).HostPort }}'  ${CONTAINER_NAME})
    # Check that HOST_PORT is a number
    # https://stackoverflow.com/questions/806906/how-do-i-test-if-a-variable-is-a-number-in-bash
    if [ ! -z "${HOST_PORT##*[!0-9]*}" ]; then
        port_ok=true
        echo "[INFO] Bind the HOST_PORT=${HOST_PORT}"
    else
        echo "[INFO] Did not get a right HOST_PORT (yet). Try #"$itry
        sleep $sleep_time
        let itry=itry+1
    fi
done

# If could not bind a port, delete the container and exit
if [ "$port_ok" == false ]; then
    echo "======="
    echo "[ERROR] Did not bind a right HOST_PORT (tries = $itry). Exiting..."
    remove_container
    exit 1
fi

# Check that service on CONTAINER_PORT is responding
echo "[INFO] Testing that http://localhost:${HOST_PORT} is accessible"
max_try=5     # max number of tries to access Service
itry=1        # initial try number
status_srv=1  # by default failed status

while [ $status_srv -gt 0 ] && [ $itry -le $max_try ];
do
   sleep $sleep_time
   response=$(curl http://localhost:${HOST_PORT})
   status_srv=$?
   let itry=itry+1
done

if [ $status_srv -eq 0 ]; then
    echo "[OK] Service at http://localhost:${HOST_PORT} is accessible"
else
    echo "[ERROR] Service at http://localhost:${HOST_PORT} is NOT accessible"
fi
status=$status_srv

# Check metadata
# Script full path. The following is taken from
# https://stackoverflow.com/questions/4774054/reliable-way-for-a-bash-script-to-get-the-full-path-to-itself/4774063
SCRIPT_PATH="$( cd $(dirname $0) ; pwd -P )"
if [ $CONTAINER_PORT -eq 5000 ] && [ $status_srv -eq 0 ]; then
    $SCRIPT_PATH/check-metadata.sh $CONTAINER_NAME $HOST_PORT
    status_meta=$?
    let status=status+status_meta
fi

remove_container



if [ $status -eq 0 ]; then
    echo "[SUCCES] Exit checks with code $status"
else
    echo "[FAILED] Exit checks with code $status"
fi
exit $status
