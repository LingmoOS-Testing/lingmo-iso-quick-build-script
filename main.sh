#!/bin/bash
set -e

script_dir=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
CDname="cd"
export WORK=$script_dir
export CD="$script_dir/$CDname"
export FORMAT=squashfs
export FS_DIR=live
export DEB_TO_PACK_DIR=$script_dir/Deb_to_pack
export DEB_TO_INSTALL_IN_CHROOT=/home/elysia/Projects/ISO/OSSofts
export ISO_CODENAME=polaris
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive

echo "Welcome to QuarkOS build script!"
echo "This system is based on Debian and PiscesDE. So please use Debain Host to run this script!"
echo "WARNING! Please use bash to execute this script! e.g. bash main.sh"

echo "Now we are going to create working environment, continue?"

# Remove Exist files
rm -rf ${CD}
rm -rf ${WORK}/iso
rm -rf ${WORK}/rootfs
rm -rf ${DEB_TO_PACK_DIR}

# Making dirs
mkdir -pv ${CD}/{${FS_DIR},boot/grub} ${WORK}/rootfs
mkdir -pv ${DEB_TO_PACK_DIR}

# Install dependencies

echo "The next step will install necessary dependencies for building."

echo 'Installing dependencies:'
apt install fakeroot xorriso squashfs-tools debootstrap mtools -y
echo 'Dependencies installed.'
echo '------'

# Creating base system
echo "We are going to create base system. Press enter to continue or Ctrl+C to exit."


debootstrap --arch=amd64 trixie ${WORK}/rootfs http://deb.debian.org/debian
 
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

echo "deb https://raw.githubusercontent.com/LingmoOS-Testing/lingmo-rolling-mirror/master/devrepo lingmo-rolling main contrib non-free" >> ${WORK}/rootfs/etc/apt/sources.list.d/lingmo-rolling.list

# Store GPG keys
curl -L https://raw.githubusercontent.com/LingmoOS-Testing/lingmo-rolling-mirror/master/public-file.key
 -o ${WORK}/rootfs/etc/apt/trusted.gpg.d/lingmo-rolling.asc


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

# Install Packages Essential for live CD
echo "Install Packages Essential for live CD. Press enter to continue."

chroot ${WORK}/rootfs /bin/bash -c "apt install -y live-boot live-config live-config-systemd"
# chroot ${WORK}/rootfs /usr/sbin/adduser --disabled-password --gecos "" lingmo
# echo 'lingmo:live' | chroot ${WORK}/rootfs chpasswd
# chroot ${WORK}/rootfs /bin/bash -c 'echo "lingmo ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/lingmo'


# Install some essential packages.
echo "Now install some OS packages. "

chroot ${WORK}/rootfs /bin/bash -c "apt install -y --no-install-recommends fonts-noto fonts-noto-cjk fonts-noto-cjk-extra xorg sddm git sudo kmod initramfs-tools adduser network-manager cryptsetup btrfs-progs dosfstools e2fsprogs grub-efi at-spi2-core chromium-common chromium-l10n locales squashfs-tools adwaita-icon-theme"
chroot ${WORK}/rootfs /bin/bash -c "apt install -y --no-install-recommends \
dirmngr \
linux-image-amd64 \
linux-headers-amd64  \
software-properties-common \
codium \
kwin-x11 \
kwin-dev \
kscreen \
libkf5windowsystem-dev \
libxcb1-dev \
libxcb-shape0-dev \
libkf5networkmanagerqt-dev \
libkf5kio-dev \
sound-theme-freedesktop \
libx11-dev \
vim \
plymouth \
appmotor \
liblingmo \
lingmo \
lingmoui \
lingmo-base-common \
lingmo-core \
lingmo-calculator \
lingmo-cursor-themes
lingmo-daemon \
lingmo-kwin-plugins \
lingmo-dock \
lingmo-gtk-themes \
lingmo-systemicons \
lingmo-launcher \
lingmo-filemanager \
lingmo-settings \
lingmo-terminal \
lingmo-wallpapers \
lingmo-ocr \
lingmo-qt-plugins \
lingmo-gtk-themes \
lingmo-screenlocker \
lingmo-screenshot \
lingmo-sddm-theme \
lingmo-statusbar \
lingmo-texteditor \
firmware-linux \
firmware-linux-free \
firmware-sof-signed \
intel-microcode \
amd64-microcode \
b43-fwcutter \
spice-webdavd \
gnome-disk-utility \
wpasupplicant \
network-manager-gnome
modemmanager \
bluez \
orca \
brltty \
espeak-ng \
at-spi2-core \
mousetweaks \
speech-dispatcher \
speech-dispatcher-espeak-ng \
gparted \
open-vm-tools \
open-vm-tools-desktop \
qemu-guest-agent \
firmware-linux-nonfree \
firmware-atheros \
firmware-bnx2 \
firmware-bnx2x \
firmware-brcm80211 \
firmware-intel-sound \
firmware-cavium \
firmware-ipw2x00 \
firmware-iwlwifi \
firmware-libertas \
firmware-realtek \
firmware-b43-installer \
firmware-misc-nonfree \
firmware-myricom \
firmware-netronome \
firmware-netxen \
firmware-qcom-media \
firmware-qcom-soc \
firmware-qlogic \
firmware-samsung \
firmware-siano \
firmware-ti-connectivity \
firmware-realtek-rtl8723cs-bt \
firmware-zd1211 \
firmware-ast \
broadcom-sta-dkms \
"


# Update initramfs in the new os
echo "Update initramfs in the new OS. Press enter to continue."


cp -rv ./update-initramfs.sh ${WORK}/rootfs/tmp/update-initramfs.sh

chroot ${WORK}/rootfs /bin/bash "/tmp/update-initramfs.sh"

rm -rv ${WORK}/rootfs/tmp/update-initramfs.sh

# Clean apt cache
echo "Clean apt cache. Wait 5 seconds."
sleep 5

chroot ${WORK}/rootfs /bin/bash -c "apt-get clean"

# Clean all the extra log files
# echo "Clean all the extra log files. Wait 5 seconds."
# sleep 5

# chroot ${WORK}/rootfs /bin/bash -c "find /var/log -regex '.*?[0-9].*?' -exec rm -v {} \;"
# chroot ${WORK}/rootfs /bin/bash -c "find /var/log -type f | while  file;do cat /dev/null | tee $file ;done"

# Clean some dirs and files
echo "Clean some dirs and files. Wait 5 seconds."
sleep 5

chroot ${WORK}/rootfs /bin/bash -c "rm -fv /etc/resolv.conf"
chroot ${WORK}/rootfs /bin/bash -c "rm -fv /etc/hostname"


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

# # Downlading grub packages
# echo "Downloading Grub"
# GRUB_DOWNLOAD_DIR=$script_dir/download_grub
# rm -rf ${GRUB_DOWNLOAD_DIR}
# mkdir -p ${GRUB_DOWNLOAD_DIR}
# cd ${GRUB_DOWNLOAD_DIR}

# dpkg --add-architecture i386
# apt update && apt install -y apt-rdepends
# apt-get -y download $(apt-rdepends grub-efi-amd64 grub-efi grub-efi-ia32 grub-pc shim-signed efibootmgr grub-efi-amd64-signed grub-efi-ia32-signed| grep -v "^ " | sed 's/debconf-2.0/debconf/g')

# mv -f ./*.deb ${DEB_TO_PACK_DIR}
# cd $script_dir

# # Making iso repo
# echo "Making ISO Deb repo"
# apt install reprepro -y
# cp -f ${DEB_TO_INSTALL_IN_CHROOT}/*.deb ${DEB_TO_PACK_DIR}/

# cd $script_dir

# ## Prepare structure
# mkdir -p ${CD}/conf
# cat << EOF > ${CD}/conf/distributions
# Codename: ${ISO_CODENAME}
# Architectures: amd64 i386
# Components: main
# Description: LingmoOS ISO Packages
# EOF

# cd ${CD}
# reprepro --delete includedeb ${ISO_CODENAME} ${DEB_TO_PACK_DIR}/*.deb
cd $script_dir

# Convert the directory tree into a squashfs
echo "Convert the directory tree into a squashfs. This will take some time to complete. Press enter to continue."


fakeroot mksquashfs ${WORK}/rootfs ${CD}/${FS_DIR}/filesystem.${FORMAT}

echo "Make filesystem.size"
sleep 1
echo -n $(du -s --block-size=1 ${WORK}/rootfs | tail -1 | awk '{print $1}') | tee ${CD}/${FS_DIR}/filesystem.size

echo "Calculate MD5"
sleep 1

find ${CD} -type f -print0 | xargs -0 md5sum | sed "s@${CD}@.@" | grep -v md5sum.txt | tee -a ${CD}/md5sum.txt

# Make Grub the bootloader of the CD
echo "-------------------------"
echo "Make Grub the bootloader of the CD. This will make this livecd bootable. Press enter to continue."


cp -v $script_dir/grub.cfg ${CD}/boot/grub/grub.cfg
sleep 2

# Build the CD/DVD
echo "Now Build the CD/DVD. Press enter to continue."


mkdir -pv ${WORK}/iso
fakeroot grub-mkrescue  -iso-level 3 -full-iso9660-filenames -o ${WORK}/iso/live-cd.iso ${CD}


echo "------------------------------"
echo "Finished! The iso file is: "
echo ${WORK}/iso/live-cd.iso

exit