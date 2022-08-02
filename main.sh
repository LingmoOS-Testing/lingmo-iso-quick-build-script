#!/bin/bash
PWD=`pwd`
CD="cd"
export WORK=`pwd`
export CD="$PWD/$CD"
export FORMAT=squashfs
export FS_DIR=casper

echo "Welcome to QuarkOS build script!"
echo "This system is based on Debian and PiscesDE. So please use Debain Host to run this script!"
echo "WARNING! Please use bash to execute this script! e.g. sudo bash main.sh"

echo "Now we are going to create working environment, continue?"

read -r -p "Continue? [Y/n] " input

case $input in
    [yY][eE][sS]|[yY])
        echo "------"
		;;
    *)
		echo "Quitting."
		exit 1
		;;
esac

# Making dirs
sudo mkdir -pv ${CD}/{${FS_DIR},boot/grub} ${WORK}/rootfs

# Install dependencies

echo "The next step will install necessary dependencies for building."
read -r -p "Continue? [Y/n] " input
case $input in
    [yY][eE][sS]|[yY])
        echo "------"
		;;
    *)
		echo "Quitting."
		exit 1
		;;
esac

echo 'Installing dependencies:'
apt install xorriso squashfs-tools -y
echo 'Dependencies installed.'
echo '------'

# Creating base system
echo "We are going to create base system. Press enter to continue or Ctrl+C to exit."
read

debootstrap --arch=amd64 bullseye ${WORK}/rootfs http://repo.huaweicloud.com/debian

# Change sources.

rm -fv ${WORK}/rootfs/etc/apt/sources.list

echo "deb http://repo.huaweicloud.com/debian/ bullseye main non-free contrib" >> ${WORK}/rootfs/etc/apt/sources.list
echo "deb http://repo.huaweicloud.com/debian/ bullseye-updates main non-free contrib" >> ${WORK}/rootfs/etc/apt/sources.list
echo "deb http://repo.huaweicloud.com/debian/ bullseye-backports main non-free contrib" >> ${WORK}/rootfs/etc/apt/sources.list
echo "deb-src http://repo.huaweicloud.com/debian/ bullseye main non-free contrib" >> ${WORK}/rootfs/etc/apt/sources.list
echo "deb-src http://repo.huaweicloud.com/debian/ bullseye-updates main non-free contrib" >> ${WORK}/rootfs/etc/apt/sources.list
echo "deb-src http://repo.huaweicloud.com/debian/ bullseye-backports main non-free contrib" >> ${WORK}/rootfs/etc/apt/sources.list
echo "deb http://repo.huaweicloud.com/debian-security/ bullseye-security main non-free contrib" >> ${WORK}/rootfs/etc/apt/sources.list
echo "deb-src http://repo.huaweicloud.com/debian-security/ bullseye-security main non-free contrib" >> ${WORK}/rootfs/etc/apt/sources.list

# Preparing new os
echo "--------------------"
echo "Now we are going to prepare for chroot."
echo "In this step, some special devices will be mounted. So do not be panic. :)"
echo "Press enter to continue."
read

for i in /etc/resolv.conf /etc/hosts /etc/hostname; do sudo cp -pv $i ${WORK}/rootfs/etc/; done
mount --bind /dev ${WORK}/rootfs/dev
mount -t proc proc ${WORK}/rootfs/proc
mount -t sysfs sysfs ${WORK}/rootfs/sys

# Running apt update in new os
echo 'Now running apt update, press enter to continue.'
read

chroot ${WORK}/rootfs /bin/bash -c "apt update"

# Install some essential packages.
echo "Now install some packages. Wait for 5 seconds."
sleep 5

chroot ${WORK}/rootfs /bin/bash -c "apt install linux-image-5.18.0-0.bpo.1-amd64 linux-headers-5.18.0-0.bpo.1-amd64 xorg sddm kwin-x11"

# Building desktop environment.
echo "Now we will build the desktop!"
echo "But it is not working, skipped. haha. Press enter to continue."
read

# Install Packages Essential for live CD
echo "Install Packages Essential for live CD. Press enter to continue."
read

chroot ${WORK}/rootfs /bin/bash -c "apt install casper"

# Update initramfs in the new os
echo "Update initramfs in the new OS. Press enter to continue."
read

cp -rv ./update-initramfs.sh ${WORK}/rootfs/tmp/update-initramfs.sh

chroot ${WORK}/rootfs /tmp/update-initramfs.sh

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
chroot ${WORK}/rootfs /bin/bash -c "find /var/log -type f | while read file;do cat /dev/null | tee $file ;done"

# Copy the kernel, the updated initrd and memtest prepared in the chroot
echo "--------------------"
echo "Now we are going to make livecd."
echo "Following steps are going to prepare the cd tree. Press enter to continue."
read

export kversion=`cd ${WORK}/rootfs/boot && ls -1 vmlinuz-* | tail -1 | sed 's@vmlinuz-@@'`
sudo cp -vp ${WORK}/rootfs/boot/vmlinuz-${kversion} ${CD}/${FS_DIR}/vmlinuz
sudo cp -vp ${WORK}/rootfs/boot/initrd.img-${kversion} ${CD}/${FS_DIR}/initrd.img
sudo cp -vp ${WORK}/rootfs/boot/memtest86+.bin ${CD}/boot

# Unmount bind mounted dirs
echo "Unmount bind mounted dirs. Wait 2 seconds."
sleep 2

sudo umount ${WORK}/rootfs/proc

sudo umount ${WORK}/rootfs/sys

sudo umount ${WORK}/rootfs/dev

# Convert the directory tree into a squashfs
echo "Convert the directory tree into a squashfs. This will take some time to complete. Press enter to continue."
read

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
read

cp -cv grub.cfg ${CD}/boot/grub/grub.cfg
sleep 2

# Build the CD/DVD
echo "Now Build the CD/DVD. Press enter to continue."
read

mkdir -pv ${WORK}/iso
grub-mkrescue -o ${WORK}/iso/live-cd.iso ${CD}


echo "------------------------------"
echo "Finished! The iso file is: "
echo ${WORK}/iso/live-cd.iso

exit