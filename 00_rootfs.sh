#!/bin/bash
set -e

. lib.sh
. build.conf

log_info build rootfs
debootstrap --include=dbus-broker,systemd-container trixie build/rootfs $MIRROR

