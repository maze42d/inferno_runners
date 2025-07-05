#!/bin/bash

# run as root via curl https://raw.githubusercontent.com/maze42d/inferno_runners/refs/heads/master/00_initial_setup.sh | sh

set -e

echo "Running inferno initial setup script"
echo "Press CTRL+C to cancel"
sleep 5


IUSER=inferno
IUID=6666
IPASS="1nfern0" # preset password is not good, change it (passwd $IUSER)

REPO_URL="https://github.com/maze42d/inferno_runners"


echo "Installing dependencies"
apt install git doas udev dbus alsa-utils rtkit pipewire wireplumber libasound2-dev tmux git pkg-config libasound2-dev libasound2-plugins

# check for user inferno
if ! id -u "$IUSER" >/dev/null 2>&1; then
  echo "User $IUSER does not exist, creating..."
  useradd -m -u "$IUID" -G audio,video,render,plugdev,input,netdev,systemd-journal "$IUSER"
  echo "$IUSER:$IPASS" | chpasswd
  echo "User $IUSER created with password $IPASS (CHANGE IT  > passwd $IUSER <)"
  else
    echo "User $IUSER already exists"
    echo "Use --skip-user to skip user creation"
    if [[ "$1" == "--skip-user" ]]; then
      echo "Skipping user creation"
      usermod -aG audio,video,render,plugdev,input,netdev,systemd-journal "$IUSER"
      echo "User $IUSER added to groups audio,video,render,plugdev,input,netdev,systemd-journal"
    fi
    exit 1
fi

echo "Enabling linger"
loginctl enable-linger "$IUSER"

echo "Setting up doas for no password (!!!)"
echo "permit nopasswd $IUSER" | tee -a /etc/doas.conf

echo "Running the second install script as $IUSER"
echo "Press CTRL+C to cancel"
sleep 5

doas -u "$IUSER" bash -c "git clone $REPO_URL && cd inferno_runners && ./01_install.sh"

