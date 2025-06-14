# shellcheck_disable=SC2148 or something like that im in vim rn

cd pw_links

echo "Linker: Using $(readlink active)"

./active

echo "---"
pw-link -l
