#!/bin/bash

if [ $# -ne 2 ]
then
  echo "usage: log_container.sh <container_name> <auth | tcp | tcp_full | downloads | http>"
  exit 1
fi

CONTAINER_NAME=$1
LOG_TYPE=$2

RUNNING=$(sudo lxc-ls --running | grep -c -w "$CONTAINER_NAME")
if [ $RUNNING -ne 1 ]
then
  echo "container '$CONTAINER_NAME' is not running!"
  exit 1
fi

CONTAINER_LOG_DIR="$HOME/LOGS/$CONTAINER_NAME"
CONTAINER_FS="/var/lib/lxc/$CONTAINER_NAME/rootfs"
IPV4=$(sudo lxc-ls -f -F name,IPV4 | grep -w "^$CONTAINER_NAME" | awk '{ print $2 }')

# Create contanier directory (if it doesn't exist)
mkdir $CONTAINER_LOG_DIR > /dev/null 2>&1

if [[ $LOG_TYPE == "auth" ]]
then
  # Watch auth.log
  sudo tail -F "$CONTAINER_FS/var/log/auth.log" | tee -a "$CONTAINER_LOG_DIR/auth.log"
elif [[ $LOG_TYPE == "tcp" ]]
then
  # Don't capture SSH traffic (already handled by MITM)
  sudo tcpdump -n -i any "host $IPV4 and not port 22" -l | tee -a "$CONTAINER_LOG_DIR/tcpdump_basic.log"
elif [[ $LOG_TYPE == "tcp_full" ]]
then
  # Don't capture SSH traffic (already handled by MITM)
  sudo tcpdump -n -i any "host $IPV4 and not port 22" -w "$CONTAINER_LOG_DIR/tcpdump.capture"
elif [[ $LOG_TYPE == "downloads" ]]
then
  mkdir "$CONTAINER_LOG_DIR/downloads"

  # offloads downloaded files and logs it
  sudo watch -n 10 "mv -vf $CONTAINER_FS/var/log/.downloads/D_* $CONTAINER_LOG_DIR/downloads | tee -a $CONTAINER_LOG_DIR/downloads.log"
elif [[ $LOG_TYPE == "http" ]]
then
  # Watch logins.txt
  sudo tail -F "$CONTAINER_FS/var/log/logins.txt" | tee -a "$CONTAINER_LOG_DIR/logins.log"
else
  echo "unknown log type: $LOG_TYPE"
  exit 
fi

