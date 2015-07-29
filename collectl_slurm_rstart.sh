#!/bin/bash

###############################################################################
# Author: Robert Bärhold
#         Robert Schmidtke
# Date: 27.07.2015
#
# Start script for the collectl tool.
# "rstart", cause it's called remote on a specific slurm node.
# 
# Call: 
# 	./collectl_slurm_rstart.sh /path/to/env.sh
#
# Parameter:
# 	$1 path to source file (env.sh)
#
###############################################################################

if [[ "$#" -ne 1 ]]; then
  echo "Wrong parameter count!"
  echo "Expecting 1 argument; found: $#"
  exit 1
fi

SOURCE_FILE="$1"
COLLECTL_NAME="collectl-$(hostname)"

if [[ ! -f $SOURCE_FILE ]]; then
  echo "SOURCE_FILE $SOURCE_FILE not found!"
  exit 1;
fi
source $SOURCE_FILE

# Start collectl tool and save process id into pid file
function startCollectl() {
  
  COLLECTL_PID=$(substituteName "$PID_FILENAME_GENERIC" "$COLLECTL_NAME") 
  
  CURRENT_JOB_FOLDER=$(substituteJobID "$CURRENT_JOB_FOLDER_GENERIC")
  CURRENT_LOCAL_FOLDER=$(substituteJobID "$LOCAL_DIR_GENERIC")
  mkdir -p $CURRENT_LOCAL_FOLDER
  
  outputDebug -n "Starting collectl $COLLECTL_NAME on $(hostname) ... "
  # Collect summary and detail data for (C)PU, (D)isk, (M)emory (N)etwork;
  # plotting friendly output; flush buffers every 5 seconds; save to local folder;
  # don't die when this script exits.
  collectl --subsys cCdDmMnN --plot --flush 5 --filename $CURRENT_LOCAL_FOLDER/ --nohup > /dev/null 2&>1 &
  PROCPID="$!"
  echo "$PROCPID" > "$CURRENT_LOCAL_FOLDER/$COLLECTL_PID"
  sleep 1s
  
  if [[ -e "/proc/$PROCPID" ]]; then
   outputDebug "success ($PROCPID)"
  else
   outputDebug "failed"
   return 1
  fi

  return 0
}

startCollectl

exit $?
