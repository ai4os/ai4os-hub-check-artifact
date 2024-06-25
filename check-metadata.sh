#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# Copyright (c) 2017 - 2019 Karlsruhe Institute of Technology - Steinbuch Centre for Computing
# This code is distributed under the MIT License
# Please, see the LICENSE file
#
# @author: vykozlov

### info
# the bash script starts a DEEP-OC container
# and checks that the default execution is ok 
# (defined in the CMD field of the Dockerfile)
# by requesting get_metadata method.
# Also checks if various fields are present in the response.
###

### Main configuration
#META_DATA_FIELDS=("name\":" "author\":" "author-email\":" "license\":")
META_DATA_FIELDS=("name*..:" "author*..:" "license*..:")
FAKE_MODEL="deepaas-test"
###

### Usage message (params can be re-defined) ###
USAGEMESSAGE="Usage: $0 <docker_image> <host_port>"

#### Parse input ###
arr=("$@")
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    # print usagemessage
    shopt -s xpg_echo
    echo $USAGEMESSAGE
    exit 1
elif [ $# -eq 2 ]; then
    DOCKER_IMAGE=$1
    HOST_PORT=$2
else
    # Wrong number of arguments is given (!=1)
    echo "[ERROR] Wrong number of arguments provided!"
    shopt -s xpg_echo
    echo $USAGEMESSAGE
    exit 1
fi




# Trying to access the deployment
c_url=""
api_ver=""
c_url_v1="http://localhost:${HOST_PORT}/models/"
c_url_v2="http://localhost:${HOST_PORT}/v2/models/"
c_args_h="Accept: application/json"

max_try=10     # max number of tries to access DEEPaaS API
itry=1         # initial try number
running=false

while [ "$running" == false ] && [ $itry -lt $max_try ];
do
   sleep 10
   # try as DEEP API V1
   curl_call=$(curl -s -X GET $c_url_v1 -H "$c_args_h")
   if (echo $curl_call | grep -q 'id\":') then
       echo "[INFO] Service is responding as API V1 (tries = $itry)"
       running=true
       c_url=$c_url_v1
       api_ver="V1"
   else
       echo "[INFO] Service is NOT responding as API V1. Try #"$itry
   fi

   # try as DEEP API V2
   curl_call=$(curl -s -X GET $c_url_v2 -H "$c_args_h")
   #echo "[DEBUG] curl call (V2): $curl_call"
   if (echo $curl_call | grep -q 'id\":') then
       echo "[INFO] Service is responding as API V2 (tries = $itry)"
       running=true
       c_url=$c_url_v2
       api_ver="V2"
   else
       echo "[INFO] Service is NOT responding as API V2. Try #"$itry
   fi
   let itry=itry+1
done

# If could not access the deployment, delete the container and exit
if [[ $itry -ge $max_try ]]; then
    echo "======="
    echo "[ERROR] DEEPaaS API does not respond (tries = $itry). Exiting..."
    exit 1
fi

# Access the running DEEPaaS API. Check that various fields are present
curl_call=$(curl -s -X GET $c_url -H "$c_args_h")
fields_ok=true
fields_missing=()

for field in ${META_DATA_FIELDS[*]}
do
   if (echo $curl_call | grep -iq $field) then
       echo "[INFO] $field is present in the get_metadata() response."
   else
       echo "[ERROR] $field is NOT present in the get_metadata() response."
       fields_ok=false
       fields_missing+=($field)
   fi
done

# If some fields are missing, print them, delete the container and exit
if [ "$fields_ok" == false ]; then
   echo "======="
   echo "[ERROR] The following fields are missing: (${fields_missing[*]}). Exiting..."
   exit 1
fi

# If FAKE_MODEL (deepaas-test) is loaded, delete the container and exit with error
name_field=$(echo $curl_call | sed 's/,/\n/g' | grep -i "${META_DATA_FIELDS[0]}" | head -n1 | tr -d ' ')
if (echo $name_field | grep -iq $FAKE_MODEL) then
   echo "======="
   echo "[ERROR] The test model (\"$FAKE_MODEL\") is detected, i.e. the true one failed to load :-( Exiting..."
   exit 1
else
  echo "[INFO] loaded model $name_field, i.e. not \"$FAKE_MODEL\""
fi

# if got here, all worked fine
echo "======="
echo "[OK]: DEEPaaS API starts, ver: ${api_ver}"
echo "[OK]: Successfully checked for:"
echo "+ (${META_DATA_FIELDS[*]}) are present"
echo "+ test model \"$FAKE_MODEL\" is *not* loaded but true one"
echo "[OK] Metadata check finished. Exit with the code 0 (success)"
echo "======="
exit 0

