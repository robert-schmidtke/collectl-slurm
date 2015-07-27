#!/bin/bash

###############################################################################
# Author: Robert Bärhold
#         Robert Schmidtke
# Date: 27.07.2015
#
# Starting or stopping a distributed collectl tool on slurm.
#
# Call:
# 	./collectl_slurm.sh (start|stop [-savelogs]|cleanup)
#
# Parameter:
# 	$1 [optional] -savelogs
#		> only valid a "stop"
#
###############################################################################

set -e
shopt -s extglob

BASEDIR=$(dirname $0)
SOURCE_FILE=$BASEDIR/env.sh
source $SOURCE_FILE

LOCAL_DIR=""

# Checks generic variables and xtreemfs components and defines basic variables
function initializeEnvironment() {

  outputDebug "Setup: Checking variables and environment"

  if [[ -z $SLURM_JOB_ID ]]; then
    echo "You're not inside an executing SLURM allocation"
    echo "Please alloc SLURM nodes with an active SLURM shell (no '--no-shell' argument)"
    exit 1
  fi

  for var in $CURRENT_JOB_FOLDER_GENERIC $LOCAL_DIR_GENERIC; do
    echo "$var" | grep %JOBID% > /dev/null || {
      echo "%JOBID% parameter was not found in variable: $var"
      exit 1
    }
  done

  for var in $PID_FILENAME_GENERIC; do
    echo "$var" | grep %NAME% > /dev/null || {
      echo "%NAME% parameter was not found in variable: $var"
      exit 1
    }
  done

  LOCAL_DIR=$(substituteJobID "$LOCAL_DIR_GENERIC")

  return 0
}

# calls the start script remotely on each slurm node
function startCollectl() {
  for collectl_hostname in "${COLLECTL_NODES[@]}"; do
    srun -N1-1 --nodelist=$collectl_hostname $BASEDIR/collectl_slurm_rstart.sh "$BASEDIR/env.sh"
  done

  return 0
}

# deletes the local job folder on each slurm node
function cleanUp() {

  echo "Cleanup job folder"

  for slurm_host in "${COLLECTL_NODES[@]}"; do
    outputDebug "Cleaning... $slurm_host of JOB: $JOB_ID"
    srun -N1-1 --nodelist="$slurm_host" rm -r "$LOCAL_DIR"
  done

  return 0
}

# calls the stop script remotely on each slurm node, passing the savelogs flag if activated
function stopCollectlAndSaveLogs() {

  SAVE_LOGS=""
  if [[ ! -z "$1" ]] && [[ "$1" == "-savelogs" ]]; then
    outputDebug "Saving logs is active"
    SAVE_LOGS="-savelogs"
  fi

  for collectl_hostname in "${COLLECTL_NODES[@]}"; do
    srun -N1-1 --nodelist=$collectl_hostname $BASEDIR/collectl_slurm_rstop.sh "$BASEDIR/env.sh" "$SAVE_LOGS"
  done

  return 0
}

function stop() {

  initializeEnvironment

  stopCollectlAndSaveLogs $1
  cleanUp

  return 0
}


# starts the collectl tool setup
function start() {

  initializeEnvironment

  echo "Starting collectl $JOB_ID on slurm..."

  startCollectl

  outputSummary

  return 0
}

function outputSummary() {

  for collectl_hostname in ${COLLECTL_NODES[@]}; do
    echo "collectl-${collectl_hostname} HOST: $collectl_hostname"
  done

  return 0
}

result=0
case "$1" in
  start)
    start
    result=$?
    ;;
   stop)
    stop $2
    result=$?
    ;;
   cleanup)
    initializeEnvironment
    cleanUp
    result=$?
    ;;
   *)
    echo -e "Usage: $0 {start|stop [-savelogs]|cleanup}\n"
    result=1
    ;;
esac

exit $result
