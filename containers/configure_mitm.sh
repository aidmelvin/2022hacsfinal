#!/bin/bash

# configure_mitm.sh: Configures a MITM SSH server for a given running container.

if [ $# -ne 2 ]
then
  echo "configure_container.sh <container name> <mitm port>"
  exit 1
fi

CONTAINER_NAME=$1
MITM_PORT=$2

RUNNING=$(sudo lxc-ls --running | grep -c -w "$CONTAINER_NAME")
if [ $RUNNING -ne 1 ]
then
  echo "container '$CONTAINER_NAME' is not running!"
  exit 1
fi

# Run MITM
MITM_JS_PATH="$HOME/MITM/mitm.js"
MITM_LOG_FILE="$HOME/MITM_LOGS/$CONTAINER_NAME.log"

# Check for existing log
if [ -e $MITM_LOG_FILE ]
then
  echo "There is already an existing log file at '$MITM_LOG_FILE', please remove/move it before continuing."
  exit 1
fi

AUTO_ACCESS_ATTMEPTS=2
IPV4=$(sudo lxc-ls -f -F name,IPV4 | grep -w "^$CONTAINER_NAME" | awk '{ print $2 }')
sudo forever -l $MITM_LOG_FILE start $MITM_JS_PATH -n $CONTAINER_NAME -i $IPV4 -p $MITM_PORT --auto-access --auto-access-fixed $AUTO_ACCESS_ATTMEPTS
