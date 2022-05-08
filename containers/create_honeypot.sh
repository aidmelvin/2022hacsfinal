#!/bin/bash

# Creates and configures honeypots for use in our HTTP expermient. The type of
# container to create is specified by an argument.

if [ $# -ne 1 ]
then
    echo "usage: create_honeypot.sh <container type>"
    exit 1
fi

