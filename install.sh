#!/bin/bash

set -e # dies on fail

# workdir be the folder where the script is
DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
cd "$DIR"
pwd
echo "Cargo installed: $(which cargo || echo "no, please quit and install rustup")"
sleep 2

# ./install.sh reinstall
if [[ "$1" == "reinstall" ]]; then
    echo "Rebuilding and reinstalling inferno and statime"
    cd statime
    CARGO_NET_GIT_FETCH_WITH_CLI=true cargo build -r

    cd "$DIR"

    cd inferno
    cargo build -r

    doas cp -v target/release/libasound_module_pcm_inferno.so /usr/lib/aarch64-linux-gnu/alsa-lib
    exit 0
fi

# deps
doas apt install -y pipewire wireplumber libasound2-dev tmux git pkg-config libasound2-dev libasound2-plugins rtkit

# allow clock
mkdir -p ~/.config/systemd/user/pipewire.service.d
echo -e "[Service]\nSystemCallFilter=@clock" > ~/.config/systemd/user/pipewire.service.d/override.conf
systemctl --user daemon-reload

# enable rtkit

doas systemctl enable --now rtkit-daemon.service

# install polkit rule

doas mkdir -p /etc/polkit-1/rules.d
doas cp -v "$DIR/config/polkit-rtkit-audio.rules" /etc/polkit-1/rules.d/90-inferno-pipewire-rtkit.rules

# clone
git clone --recurse-submodules -b inferno-dev https://github.com/teodly/statime
git clone --recursive https://github.com/teodly/inferno

# build
cd statime
CARGO_NET_GIT_FETCH_WITH_CLI=true cargo build -r

cd "$DIR"

cd inferno
cargo build -r

# Determine architecture for library path
ARCH=$(dpkg --print-architecture)
LIBDIR="/usr/lib/$ARCH/alsa-lib"

doas cp -v target/release/libasound_module_pcm_inferno.so "$LIBDIR"

# Install and enable inferno user service
mkdir -p "$HOME/.config/systemd/user"
cp $DIR/inferno.service "$HOME/.config/systemd/user/inferno.service"
systemctl --user daemon-reload
systemctl --user enable --now inferno.service
echo "Enabled inferno user service for user $(whoami)"

echo "Done. Remeber to set the interface in statime/inferno-ptpv1.toml"
echo "Currently set to:"
grep "interface" "$DIR/statime/inferno-ptpv1.toml"
echo "Currently online interfaces:"
ip a | grep "state UP"
