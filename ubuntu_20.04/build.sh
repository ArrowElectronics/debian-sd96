#!/bin/bash

# Run with sudo

ROOTFS=$(pwd)/rootfs

mkdir -p $ROOTFS
# install basic system
multistrap -a armhf -f focal-ports.conf -d $ROOTFS

