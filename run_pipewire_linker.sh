# shellcheck disable=SC2148

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
