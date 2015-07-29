#!/bin/bash

###############################################################################
# Author: Robert Bärhold
#         Robert Schmidtke
# Date: 27.07.2015
#
# Settings file for the collectl tool script on slurm.
# This file serves as source file for the different scripts.
# It contains user specific and general variables and shared functions.
# Boolean variables should be use with "true" and "false"
#
###############################################################################

####
 ##  System settings
####

# Used for enabling/disabling debug output (see function below)
__DEBUG=true

# Path that is local to each slurm node;
# will be created, so it needs to be accessible
# by the user running this script
LOCAL_PATH="/local/$USER/collectl"

# Leave empty if the system default is to be used
COLLECTL_HOME="~/collectl-4.0.2"

JOB_ID=$SLURM_JOB_ID # default the current ID
COLLECTL_NODE_NAMES=`scontrol show hostnames` # flat list of node names seperated with space

####
 ##  Generic name and path settings
####

# Path where the results will be saved to,
# typically a shared network drive/folder;
# will be created, so it needs to be accessible
# by the user running this script
CURRENT_JOB_FOLDER_GENERIC="$(pwd)/slurm-%JOBID%"

LOCAL_DIR_GENERIC="$LOCAL_PATH/%JOBID%"

LOG_FILENAME_GENERIC="%NAME%.log"
PID_FILENAME_GENERIC="%NAME%.pid"

####
 ## Internal
####

COLLECTL_NODES=($COLLECTL_NODE_NAMES) # put into an array, easier access

####
 ##  Substitute functions for generic variables
####

# Substitutes %JOBID% inside argument $1 with the slurm environment job id
function substituteJobID() {
  echo "$1" | sed -e "s/%JOBID%/$JOB_ID/g"
}

# Substitutes %name% in argument $1 with argument $2
function substituteName() {
  echo "$1" | sed -e "s/%NAME%/$2/g"
}

# Searches for the line containing $2 inside file $1 and replaces the line with $3,
# saving the new content back to file $1
function substituteProperty() {
  LINE_NUMBER=`grep -nr "$2" "$1" | cut -d : -f 1`
  printf '%s\n' "${LINE_NUMBER}s#.*#$3#" w  | ed -s $1
}

####
 ##  Shared functions
####

function outputDebug() {
  if [[ "$__DEBUG" == "true" ]]; then
    echo $@
  fi
}
