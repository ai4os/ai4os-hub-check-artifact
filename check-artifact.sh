#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# Copyright (c) 2017 - 2019 Karlsruhe Institute of Technology - Steinbuch Centre for Computing
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
###

### Usage message (params can be re-defined) ###
USAGEMESSAGE="Usage: $0 <docker_image>"

#### Parse input ###
arr=("$@")
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    # print usagemessage
    shopt -s xpg_echo
    echo $USAGEMESSAGE
    exit 1
elif [ $# -eq 1 ]; then
    DOCKER_IMAGE=$1
else
    # Wrong number of arguments is given (!=1)
    echo "[ERROR] Wrong number of arguments provided!"
    shopt -s xpg_echo
    echo $USAGEMESSAGE
    exit 2
fi

# Script full path. The following is taken from
# https://stackoverflow.com/questions/4774054/reliable-way-for-a-bash-script-to-get-the-full-path-to-itself/4774063
SCRIPT_PATH="$( cd $(dirname $0) ; pwd -P )"

# Check metadata
$SCRIPT_PATH/check-metadata.sh $DOCKER_IMAGE
