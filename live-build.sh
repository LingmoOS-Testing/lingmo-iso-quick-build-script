#!/bin/bash
set -e

# Define work directory
WORKDIR=${pwd}/live-build-workspace
LIVE_BUILD_DIR="${WORKDIR}/lingmoos-live"

# Create work directory if it doesn't exist
mkdir -p "${LIVE_BUILD_DIR}"

# Welcome message
echo "Welcome to LingmoOS build script!"

# Start live-build
cd "${LIVE_BUILD_DIR}"

# Initialize live-build and specify the Debian version
lb config --distribution trixie --architectures amd64

# Configure live-build components
# Add your preferred mirror for the Debian repos
echo "Setting up sources.list for live-build."
cat > config/archives/huaweicloud.list.chroot << EOF
deb http://repo.huaweicloud.com/debian/ trixie main non-free contrib
deb http://repo.huaweicloud.com/debian/ trixie-updates main non-free contrib
deb http://repo.huaweicloud.com/debian/ trixie-backports main non-free contrib
deb http://repo.huaweicloud.com/debian-security/ trixie-security main non-free contrib
EOF

# Add hook to install additional packages like 'chromium', etc.
mkdir -p config/hooks/live
cat > config/hooks/live/install_packages.hook.chroot << EOF
#!/bin/sh
apt install -y --no-install-recommends xorg sddm git sudo kmod initramfs-tools adduser network-manager cryptsetup btrfs-progs dosfstools e2fsprogs grub-efi at-spi2-core chromium-common chromium-l10n locales squashfs-tools adwaita-icon-theme
EOF
chmod +x config/hooks/live/install_packages.hook.chroot

# Add your customisations, files and so on
# Example: Create user 'lingmo' using a hook
cat > config/hooks/live/username_setup.hook.chroot << EOF
#!/bin/sh
adduser --disabled-password --gecos "" lingmo
echo 'lingmo:live' | chpasswd
echo 'lingmo ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/lingmo
EOF
chmod +x config/hooks/live/username_setup.hook.chroot

# Add any local deb packages to be installed in your live build
# Example: Copy local packages to config/packages.chroot/
mkdir -p config/packages.chroot/
cp /home/elysia/Projects/ISO/OSSofts/*.deb config/packages.chroot/

# Clean up before starting the build
sudo lb clean

# Build the live system image
echo "Starting live-build process..."
sudo lb build

# Move built ISO to the working directory
mv binary.hybrid.iso "${WORKDIR}/lingmoos-live.iso"

echo "Live-build script completed! The ISO can be found at: ${WORKDIR}/lingmoos-live.iso"
