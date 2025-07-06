#!/bin/bash

# run as root via curl https://raw.githubusercontent.com/maze42d/inferno_runners/refs/heads/master/00_initial_setup.sh | bash
# use bash not sh

set -e

echo "Running inferno initial setup script"
echo "Press CTRL+C to cancel"
sleep 5

IUSER=inferno
IUID=6666
IPASS="1nfern0" # preset password is not good, change it (passwd $IUSER)

REPO_URL="https://github.com/maze42d/inferno_runners"

echo "Installing dependencies"
# install -y just doesnt work?
yes | apt install git doas udev dbus alsa-utils rtkit tmux pkg-config libasound2-dev libasound2-plugins pipewire pipewire-bin wireplumber

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

  else
    exit 1
  fi
fi

echo "Enabling linger"
loginctl enable-linger "$IUSER"

echo "Setting up multi-user target (this will disable you desktop environment if you have one)"
systemctl set-default multi-user.target

echo "Setting up doas for no password (!!!)"
echo "permit nopass $IUSER" | tee -a /etc/doas.conf
echo "permit nopass root as $IUSER" | tee -a /etc/doas.conf

echo "Running the second install script as $IUSER"
echo "Press CTRL+C to cancel"
sleep 5

# dont mind this thx

# cd ~$IUSER
cd /home/"$IUSER" # apparently cant do ~$IUSER
doas -u "$IUSER" git clone "$REPO_URL"
cd inferno_runners
doas -u "$IUSER" bash "01_install.sh"