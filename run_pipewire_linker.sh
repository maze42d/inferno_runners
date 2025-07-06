# shellcheck disable=SC2148

target_nodes=("Dummy-Driver" "Freewheel-Driver" "Midi-Bridge" "hdmi")

contains() {
  local e
  for e in "${target_nodes[@]}"; do
    [[ "$e" == "$1" ]] && return 0
  done
  return 1
}

current_id=""
while IFS= read -r line; do
  # Match line with id
  if [[ $line =~ ^[[:space:]]*id[[:space:]]+([0-9]+), ]]; then
    current_id="${BASH_REMATCH[1]}"
  fi
  # Match line with node.name
  if [[ $line =~ node\.name[[:space:]]*=[[:space:]]*\"([^\"]+)\" ]]; then
    node_name="${BASH_REMATCH[1]}"
    if contains "$node_name"; then
      echo "Destroying node id $current_id with name $node_name"
      pw-cli destroy "$current_id"
    fi
  fi
done < <(pw-cli ls Node)



cd pw_links || { echo "Error: Could not find the pw_links directory"; exit 1; }

if [ ! -f active ]; then
    echo "Error: No 'active' file found in pw_links"
    echo "Create a symlink to the desired PipeWire link config in this directory."
    exit 1
fi

echo "Linker: Using $(readlink active)"

sleep 0.3

./active

echo "---"
pw-link -l
