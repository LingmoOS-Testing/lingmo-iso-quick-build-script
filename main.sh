#!/bin/bash
set -e

PWD=`pwd`
CD="cd"
export WORK=`pwd`
export CD="$PWD/$CD"
export FORMAT=squashfs
export FS_DIR=live

echo "Welcome to QuarkOS build script!"
echo "This system is based on Debian and PiscesDE. So please use Debain Host to run this script!"
echo "WARNING! Please use bash to execute this script! e.g. bash main.sh"

echo "Now we are going to create working environment, continue?"

# Remove Exist files
rm -rf ${CD}
rm -rf ${WORK}/iso
rm -rf ${WORK}/rootfs

# Making dirs
mkdir -pv ${CD}/{${FS_DIR},boot/grub} ${WORK}/rootfs

# Install dependencies

echo "The next step will install necessary dependencies for building."

echo 'Installing dependencies:'
apt install xorriso squashfs-tools debootstrap mtools -y
echo 'Dependencies installed.'
echo '------'

# Creating base system
echo "We are going to create base system. Press enter to continue or Ctrl+C to exit."


debootstrap --arch=amd64 trixie ${WORK}/rootfs http://repo.huaweicloud.com/debian

# Change sources.

rm -fv ${WORK}/rootfs/etc/apt/sources.list

echo "deb http://repo.huaweicloud.com/debian/ trixie main non-free contrib" >> ${WORK}/rootfs/etc/apt/sources.list
echo "deb http://repo.huaweicloud.com/debian/ trixie-updates main non-free contrib" >> ${WORK}/rootfs/etc/apt/sources.list
echo "deb http://repo.huaweicloud.com/debian/ trixie-backports main non-free contrib" >> ${WORK}/rootfs/etc/apt/sources.list
echo "# deb-src http://repo.huaweicloud.com/debian/ trixie main non-free contrib" >> ${WORK}/rootfs/etc/apt/sources.list
echo "# deb-src http://repo.huaweicloud.com/debian/ trixie-updates main non-free contrib" >> ${WORK}/rootfs/etc/apt/sources.list
echo "# deb-src http://repo.huaweicloud.com/debian/ trixie-backports main non-free contrib" >> ${WORK}/rootfs/etc/apt/sources.list
echo "deb http://repo.huaweicloud.com/debian-security/ trixie-security main non-free contrib" >> ${WORK}/rootfs/etc/apt/sources.list
echo "# deb-src http://repo.huaweicloud.com/debian-security/ trixie-security main non-free contrib" >> ${WORK}/rootfs/etc/apt/sources.list

# Preparing new os
echo "--------------------"
echo "Now we are going to prepare for chroot."
echo "In this step, some special devices will be mounted. So do not be panic. :)"
echo "Press enter to continue."


for i in /etc/resolv.conf /etc/hosts /etc/hostname; do cp -pv $i ${WORK}/rootfs/etc/; done
mount --bind /dev ${WORK}/rootfs/dev
mount -t proc proc ${WORK}/rootfs/proc
mount -t sysfs sysfs ${WORK}/rootfs/sys

# Running apt update in new os
echo 'Now running apt update, press enter to continue.'


chroot ${WORK}/rootfs /bin/bash -c "apt update"

# Install some essential packages.
echo "Now install some packages. "

cp -r /home/elysia/Projects/ISO/OSSofts ${WORK}/rootfs/tmp/
chroot ${WORK}/rootfs /bin/bash -c "apt install -y /tmp/OSSofts/*.deb --no-install-recommends"
chroot ${WORK}/rootfs /bin/bash -c "apt install -y xorg sddm git sudo kmod initramfs-tools adduser"
rm -rf ${WORK}/rootfs/tmp/OSSofts

# Install Packages Essential for live CD
echo "Install Packages Essential for live CD. Press enter to continue."

chroot ${WORK}/rootfs /bin/bash -c "apt install -y live-boot"
chroot ${WORK}/rootfs /usr/sbin/adduser --disabled-password --gecos "" lingmo
echo 'lingmo:live' | chroot ${WORK}/rootfs chpasswd

# Update initramfs in the new os
echo "Update initramfs in the new OS. Press enter to continue."


cp -rv ./update-initramfs.sh ${WORK}/rootfs/tmp/update-initramfs.sh

chroot ${WORK}/rootfs /bin/bash "/tmp/update-initramfs.sh"

rm -rv ${WORK}/rootfs/tmp/update-initramfs.sh

# Clean apt cache
echo "Clean apt cache. Wait 5 seconds."
sleep 5

chroot ${WORK}/rootfs /bin/bash -c "apt-get clean"

# Clean some dirs and files
echo "Clean some dirs and files. Wait 5 seconds."
sleep 5

chroot ${WORK}/rootfs /bin/bash -c "rm -fv /etc/resolv.conf"
chroot ${WORK}/rootfs /bin/bash -c "rm -fv /etc/hostname"

# Clean all the extra log files
echo "Clean all the extra log files. Wait 5 seconds."
sleep 5

chroot ${WORK}/rootfs /bin/bash -c "find /var/log -regex '.*?[0-9].*?' -exec rm -v {} \;"
chroot ${WORK}/rootfs /bin/bash -c "find /var/log -type f | while  file;do cat /dev/null | tee $file ;done"

# Copy the kernel, the updated initrd and memtest prepared in the chroot
echo "--------------------"
echo "Now we are going to make livecd."
echo "Following steps are going to prepare the cd tree. Press enter to continue."


export kversion=`cd ${WORK}/rootfs/boot && ls -1 vmlinuz-* | tail -1 | sed 's@vmlinuz-@@'`
cp -vp ${WORK}/rootfs/boot/vmlinuz-${kversion} ${CD}/${FS_DIR}/vmlinuz
cp -vp ${WORK}/rootfs/boot/initrd.img-${kversion} ${CD}/${FS_DIR}/initrd.img
# cp -vp ${WORK}/rootfs/boot/memtest86+.bin ${CD}/boot

# Unmount bind mounted dirs
echo "Unmount bind mounted dirs. Wait 2 seconds."
sleep 2

umount ${WORK}/rootfs/proc

umount ${WORK}/rootfs/sys

umount ${WORK}/rootfs/dev

# Convert the directory tree into a squashfs
echo "Convert the directory tree into a squashfs. This will take some time to complete. Press enter to continue."


mksquashfs ${WORK}/rootfs ${CD}/${FS_DIR}/filesystem.${FORMAT} -noappend

echo "Make filesystem.size"
sleep 1
echo -n $(du -s --block-size=1 ${WORK}/rootfs | tail -1 | awk '{print $1}') | tee ${CD}/${FS_DIR}/filesystem.size

echo "Calculate MD5"
sleep 1

find ${CD} -type f -print0 | xargs -0 md5sum | sed "s@${CD}@.@" | grep -v md5sum.txt | tee -a ${CD}/md5sum.txt

# Make Grub the bootloader of the CD
echo "-------------------------"
echo "Make Grub the bootloader of the CD. This will make this livecd bootable. Press enter to continue."


cp -v grub.cfg ${CD}/boot/grub/grub.cfg
sleep 2

# Build the CD/DVD
echo "Now Build the CD/DVD. Press enter to continue."


mkdir -pv ${WORK}/iso
grub-mkrescue -o ${WORK}/iso/live-cd.iso ${CD}


echo "------------------------------"
echo "Finished! The iso file is: "
echo ${WORK}/iso/live-cd.iso

exit