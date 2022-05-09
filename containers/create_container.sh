#!/bin/bash

# Creates and configures honeypots for use in our HTTP expermient. The type of
# container to create is specified by an argument.

if [ $# -ne 4 ]
then
    echo "usage: create_honeypot.sh <name> <interface> <public ip> <mitm port>"
    exit 1
fi

CONTAINER_NAME=$1
CONTAINER_INTERFACE=$2
CONTAINER_IP=$3
MITM_PORT=$4

# First check to see if a container already exists
EXISTS=$(sudo lxc-ls | grep -w -c "$CONTAINER_NAME")
if [ $EXISTS -ne 0 ]
then
  echo "A container with the name $CONTAINER_NAME already exists!"
  exit 1
fi

# Create and start the contaienr
sudo lxc-create -n "$CONTAINER_NAME" -t download -- -d ubuntu -r focal -a amd64
sudo lxc-start  -n "$CONTAINER_NAME"

# Wait for container IP address
IPV4="-"
while [[ $IPV4 == "-" ]]
do
  IPV4=$(sudo lxc-ls -f -F name,IPV4 | grep -w "^$CONTAINER_NAME" | cut -d' ' -f2)
  sleep 1
done

# Configure container NAT rules
sudo iptables --insert PREROUTING --table nat --source 0.0.0.0/0 --destination $CONTAINER_IP --jump DNAT --to-destination $IPV4
sudo iptables --insert POSTROUTING --table nat --source $IPV4 --destination 0.0.0.0/0 --jump SNAT --to-source $CONTAINER_IP

# MITM
sudo sysctl -w net.ipv4.conf.all.route_localnet=1
sudo iptables --insert PREROUTING --table nat --source 0.0.0.0/0 --destination $CONTAINER_IP --protocol tcp --dport 22 --jump DNAT --to-destination "127.0.0.1:$MITM_PORT"

# Container interface
sudo ip addr add "$CONTAINER_IP/16" brd + dev $CONTAINER_INTERFACE

# Make log dir
mkdir "$HOME/LOGS/$CONTAINER_NAME"
