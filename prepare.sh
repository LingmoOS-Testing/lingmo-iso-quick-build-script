#! /bin/bash
PWD=`pwd`
CD="cd"
export WORK=`pwd`
export CD="$PWD/$CD"
export FORMAT=squashfs
export FS_DIR=casper

for i in /etc/resolv.conf /etc/hosts /etc/hostname; do sudo cp -pv $i ${WORK}/rootfs/etc/; done


sudo mount --bind /dev ${WORK}/rootfs/dev

sudo mount -t proc proc ${WORK}/rootfs/proc

sudo mount -t sysfs sysfs ${WORK}/rootfs/sys

sudo chroot ${WORK}/rootfs /bin/bash