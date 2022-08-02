#!/bin/bash

export kversion=`cd /boot && ls -1 vmlinuz-* | tail -1 | sed 's@vmlinuz-@@'`
depmod -a $kversion
update-initramfs -u -k $kversion
exit