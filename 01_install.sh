#!/bin/bash
#set -e # dies on fail


# workdir be the folder where the script is
DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
cd "$DIR"
pwd
echo "Cargo installed: $(which cargo || echo "no, please quit and install rustup")"
sleep 2

# deps
doas apt install -y pipewire wireplumber libasound2-dev tmux git pkg-config libasound2-dev libasound2-plugins

# allow clock
mkdir -p ~/.config/systemd/user/pipewire.service.d
echo -e "[Service]\nSystemCallFilter=@clock" > ~/.config/systemd/user/pipewire.service.d/override.conf
systemctl --user daemon-reload

# clone
git clone --recurse-submodules -b inferno-dev https://github.com/teodly/statime
git clone --recursive https://github.com/teodly/inferno

# build
cd statime
CARGO_NET_GIT_FETCH_WITH_CLI=true cargo build -r

cd "$DIR"

cd inferno
cargo build -r

doas cp -v target/release/libasound_module_pcm_inferno.so /usr/lib/aarch64-linux-gnu/alsa-lib

