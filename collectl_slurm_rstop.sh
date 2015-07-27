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
  COLLECTL_LOG=`ls $CURRENT_LOCAL_FOLDER/$(hostname)-*.gz`

  # if server log exists, create backup folder (if not exists) and copy log
  if [[ -f "$COLLECTL_LOG" ]]; then
    mkdir -p "$CURRENT_JOB_FOLDER/savedLogs"
    cp "$COLLECTL_LOG" "$CURRENT_JOB_FOLDER/savedLogs/"
  else
    echo "Couldn't save log file ($COLLECTL_LOG), because it doesn't exist!"
    return 1
  fi
  
  return 0
}

# Killing the process of the collectl too using the saved process id (pid)
function stopCollectl() {

  COLLECTL_PID=$(substituteName "$PID_FILENAME_GENERIC" "$COLLECTL_NAME") 

  if [[ -f "$CURRENT_LOCAL_FOLDER/$COLLECTL_PID" ]]; then
    outputDebug -n "Stopping collectl Process: ${COLLECTL_PID%.*} ..."
    
    
    result=0
    if [[ -e "/proc/$(<"$CURRENT_LOCAL_FOLDER/$COLLECTL_PID")" ]]; then
      kill $(<"$CURRENT_LOCAL_FOLDER/$COLLECTL_PID")
      result=$?
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