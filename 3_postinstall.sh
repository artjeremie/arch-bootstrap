#!/bin/sh
# https://github.com/hoaxdream
# author: hoaxdream

# Change the value according to your hdd/sdd.
CORE_UUID=$(blkid -s UUID -o value /dev/nvme1n1p1)
DATA_UUID=$(blkid -s UUID -o value /dev/sda1)

xdgconfig() {
    sed -i 's/enabled=True/enabled=False/g' /etc/xdg/user-dirs.conf
}

disablewatchdog() {
    echo blacklist iTCO_wdt > /etc/modprobe.d/watchdog.conf
    echo blacklist iTCO_vendor_support >> /etc/modprobe.d/watchdog.conf
}

nvidiamodule() {
    mkdir -p /etc/pacman.d/hooks
    cat >/etc/pacman.d/hooks/nvidia.hook <<'EOF'
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia
Target=linux

[Action]
Description=Update Nvidia module in initcpio
Depends=mkinitcpio
When=PostTransaction
NeedsTargets
Exec=/bin/sh -c 'while read -r trg; do case $trg in linux) exit 0; esac; done; /usr/bin/mkinitcpio -P'
EOF
}

initramfsmodule() {
    # add nvidia modules
    sed -i 's/MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/g' /etc/mkinitcpio.conf
    # change udev to systemd for silent boot
    sed -i 's/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base systemd autodetect modconf block filesystems keyboard fsck)/g' /etc/mkinitcpio.conf
    # generate mkinitcpio
    mkinitcpio -p linux
}

setdirectory() {
    mkdir /media/
    cd /media
    mkdir core data
}

getuuid() {
echo "# /dev/nvme1n1p1
UUID=$CORE_UUID /media/core ext4 rw,user,exec 0 0

# /dev/sda1
UUID=$DATA_UUID /media/data ext4 rw,user,exec 0 0" | tee -a /etc/fstab >/dev/null
}

fsckedit() {
    echo '\033[0;32mfsck-root.service: Edit with sudo -E systemctl edit --full systemd-fsck-root.service'
    echo '\033[0;32mfsck@.service: Edit with sudo -E systemctl edit --full systemd-fsck@.service'
    echo " "
cat << EOF
Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/lib/systemd/systemd-fsck
StandardOutput=null
StandardError=journal+console
TimeoutSec=0
EOF
    echo '\033[0;32mReboot then manually configure systemd-fsck-root.service and systemd-fsck@.service then reboot'
}

# Disable auto run of xdg to use .config/user-dir.dirs instead.
xdgconfig

# Disable watchdog.
disablewatchdog

# Nvidia early module loading.
nvidiamodule

# Use systemd instead of udev for silentboot.
initramfsmodule

# Make dir for other hdd/sdd.
setdirectory

# Set UUID of other hdd/sdd in fstab.
getuuid

# Reboot the run this manually.
fsckedit

echo '\033[0;32mRun ./4_fmanager.sh and reboot.'
