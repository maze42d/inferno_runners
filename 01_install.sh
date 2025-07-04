#!/bin/bash
#set -e # dies on fail


# workdir be the folder where the script is
DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
cd "$DIR"
pwd

source "$DIR/_source"
echo "Cargo available: $(which cargo || echo "no")"

if ! command -v cargo &>/dev/null; then
  echo "cargo not found, installing rustup and Rust toolchain..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
else
  echo "cargo is already installed, skipping rustup installation."
fi


sleep 2

# install inferno service
echo "Installing inferno user service"
# apologies about harcoding xdg paths
mkdir -p "$HOME/.config/systemd/user"
cp $DIR/inferno.service "$HOME/.config/systemd/user/inferno.service"
systemctl --user daemon-reload
systemctl --user enable inferno.service

# deps
doas apt install -y pipewire wireplumber libasound2-dev tmux git pkg-config libasound2-dev libasound2-plugins

# allow clock
mkdir -p ~/.config/systemd/user/pipewire.service.d
echo -e "[Service]\nSystemCallFilter=@clock" > ~/.config/systemd/user/pipewire.service.d/override.conf
systemctl --user daemon-reload

# disable pipewire and wireplumber services
systemctl --user disable pipewire.service wireplumber.service

# clone
git clone --recurse-submodules -b inferno-dev https://github.com/teodly/statime
git clone --recursive https://github.com/teodly/inferno

# build
cd statime
CARGO_NET_GIT_FETCH_WITH_CLI=true cargo build -r -j3

cd "$DIR"

cd inferno
cargo build -r -j3

doas cp -v target/release/libasound_module_pcm_inferno.so /usr/lib/aarch64-linux-gnu/alsa-lib

