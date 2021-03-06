#!/bin/bash

###############################################################################
# Author: Robert Bärhold
#         Robert Schmidtke
# Date: 27.07.2015
#
# Stop script for the collectl tool.
# "rstop", cause it's called remote on a specific slurm node.
# 
# Call: 
# 	./collectl_slurm_rstop.sh /path/to/env.sh [-savelogs]
#
# Parameter:
# 	$1 path to source file (env.sh)
# 	$2 [optional] "-savelogs"
#
###############################################################################

if [[ ! "$#" -ge 1 ]]; then
  echo "Wrong parameter count!"
  echo "Expecting at least 1 argument; found: $#"
  exit 1
fi

SOURCE_FILE="$1"
SAVE_LOG="$2"
COLLECTL_NAME="collectl-$(hostname)"

if [[ ! -f $SOURCE_FILE ]]; then
  echo "SOURCE_FILE $SOURCE_FILE not found!"
  exit 1;
fi
source $SOURCE_FILE

CURRENT_LOCAL_FOLDER=$(substituteJobID "$LOCAL_DIR_GENERIC")

# Save logs to current job folder
function saveLogs() {

  CURRENT_JOB_FOLDER=$(substituteJobID "$CURRENT_JOB_FOLDER_GENERIC")
  COLLECTL_LOG=$(substituteName "$LOG_FILENAME_GENERIC" "$COLLECTL_NAME")
  COLLECTL_LOG_NAMES=`ls $CURRENT_LOCAL_FOLDER/$(hostname)-*.gz`
  COLLECTL_LOGS=($COLLECTL_LOG_NAMES $CURRENT_LOCAL_FOLDER/$COLLECTL_LOG)

  # if server log exists, create backup folder (if not exists) and copy log
  for collectl_log in "${COLLECTL_LOGS[@]}"; do
    if [[ -f "$collectl_log" ]]; then
      mkdir -p "$CURRENT_JOB_FOLDER/savedLogs"
      cp "$collectl_log" "$CURRENT_JOB_FOLDER/savedLogs/"
    else
      echo "Couldn't save log file ($collectl_log), because it doesn't exist!"
      return 1
    fi
  done
  
  return 0
}

# Killing the process of the collectl too using the saved process id (pid)
function stopCollectl() {

  COLLECTL_PID=$(substituteName "$PID_FILENAME_GENERIC" "$COLLECTL_NAME") 

  if [[ -f "$CURRENT_LOCAL_FOLDER/$COLLECTL_PID" ]]; then
    outputDebug -n "Stopping collectl Process: ${COLLECTL_PID%.*} ... "
    
    result=0
    if [[ -e "/proc/$(<"$CURRENT_LOCAL_FOLDER/$COLLECTL_PID")" ]]; then
      kill -2 $(<"$CURRENT_LOCAL_FOLDER/$COLLECTL_PID")
      result=$?
    else
      outputDebug -n "$(<"$CURRENT_LOCAL_FOLDER/$COLLECTL_PID") not running ... "
    fi
    
    if [[ "$result" -eq 0 ]]; then
      outputDebug "success"
    else
      outputDebug "failed"
    fi
  else
    echo "PID file ($CURRENT_LOCAL_FOLDER/$COLLECTL_PID) not found!"
    return 1
  fi
  
  return 0
}

stopCollectl
RESULT=$?

if [[ ! -z "$SAVE_LOG" ]] && [[ "$SAVE_LOG" == "-savelogs" ]]; then
  saveLogs
fi

exit $RESULT
