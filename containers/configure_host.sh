#!/bin/bash

# configure_host.sh: Prepares the host for hosting honeypot containers for our experiment by
# installing the MITM server.

MITM_PATH="$HOME/MITM"
MITM_LOGS="$HOME/MITM_LOGS"
CONTAINER_LOGS="$HOME/LOGS"

sudo npm install -g forever

# Get MITM repo
git clone https://github.com/UMD-ACES/MITM $MITM_PATH

# Install
$HOME/MITM/install.sh

# Make Log Dirs
mkdir $MITM_LOGS
mkdir $CONTAINER_LOGS

