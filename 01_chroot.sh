#!/bin/bash
set -e 

. lib.sh
. build.conf

for i in dev proc sys;do
    log_info mount $i
    mount --bind /$i build/rootfs/$i
done

log_info change sources.list
rm -fv build/rootfs/etc/apt/sources.list
for i in trixie trixie-updates trixie-backports;do
    echo "deb $MIRROR $i main contrib non-free non-free-firmware" >> build/rootfs/etc/apt/sources.list  
done
echo "deb $MIRROR_SECURITY trixie-security main contrib non-free non-free-firmware" >> build/rootfs/etc/apt/sources.list

log_info chroot apt update
chroot build/rootfs apt update

log_info chroot install essentials
chroot build/rootfs apt install -y live-boot live-config live-config-systemd
chroot build/rootfs apt install -y --no-install-recommends fonts-wqy-zenhei xserver-xorg xinit sddm sudo network-manager cryptsetup e2fsprogs btrfs-progs dosfstools xfsprogs chromium squashfs-tools grub-pc-bin grub-efi-amd64-bin grub-efi-ia32-bin mtools gparted

