#! /bin/bash
PWD=`pwd`
CD="cd"
export WORK=`pwd`
export CD="$PWD/$CD"
export FORMAT=squashfs
export FS_DIR=casper

sudo umount ${WORK}/rootfs/proc

sudo umount ${WORK}/rootfs/sys

sudo umount ${WORK}/rootfs/dev