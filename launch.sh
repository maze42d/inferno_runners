#!/bin/bash

set -e

# sleep if is service
if ! [ -t 1 ]; then
    echo "Not running in a terminal; sleeping for 10 seconds."
    sleep 5
fi

DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
cd "$DIR"

source "_source"

echo "Running inferno_runner in $INFPATH"
cd "$INFPATH"

echo "Starting modules"
"./run_modules.sh"

echo "Killing existing processes"
killall pipewire wireplumber statime inferno || true

sleep 1

tmux new-session -d -s "$SESSION"

tmux send-keys -t "$SESSION":0.0 "./run_ptp.sh" C-m

tmux split-window -h -t "$SESSION":0.0
tmux send-keys -t "$SESSION":0.1 "sleep 10 && ./run_inferno.sh && ./run_pipewire_linker.sh" C-m

tmux split-window -v -t "$SESSION":0.1
tmux send-keys -t "$SESSION":0.2 "sleep 5 && ./run_init_and_pipewire.sh" C-m

tmux select-pane -t "$SESSION":0.0

# Only attach if running in a terminal
if [ -t 1 ]; then
    tmux attach-session -t "$SESSION"
else
    echo "Not running in a terminal; tmux session '$SESSION' started in background."
fi

# TODO: error handling?