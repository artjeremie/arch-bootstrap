#!/bin/sh
# https://github.com/hoaxdream
# author: hoaxdream
USER=$(whoami)

mpduser() {
    systemctl --user enable mpd
}

transmissionsetuser() {
    sudo sed -i 's/root/'"$USER"'/g' /usr/lib/systemd/system/transmission.service
}

finalize() {
    rm /home/$USER/.bash_logout
    rm /home/$USER/.bash_profile
    rm /home/$USER/.bashrc
    rm /home/$USER/.zshrc
    mkdir -p /home/$USER/.local/share/mail/hoaxdream
    mkdir -p /home/$USER/.config/dl/torrent/completed
    mkdir -p /home/$USER/.config/dl/torrent/incomplete
    mkdir -p /home/$USER/.config/dl/others
    mkdir -p /home/$USER/.config/dl/pics
    mkdir -p /home/$USER/.config/dl/docs
}

# Mpd user daemon
mpduser

# Set transmission user, change User to your username
transmissionsetuser

# Final script, delte and make directories.
finalize

echo '\033[0;32mInstallation completed, please reboot.'
