# shellcheck disable=SC2154,SC1091,SC2148
source _source

wpctl status | \
	awk '/^Audio$/ {inblock=1; next} /^Video$/ {inblock=0} inblock' | \
	sed $'s/.* ├─.*/\x1b[33m&\x1b[0m/' | \
	env LC_ALL=C sed -E $'s/(\\[vol: 0\\.[0-9]+\\])/\x1b[33m\\1\x1b[0m/g' | \
	env LC_ALL=C sed -E $'s/(\\[vol: 1\\.[0-9]+\\])/\x1b[32m\\1\x1b[0m/g'

# awk ^Audio to ^Video non-inclusive
# sed Color headlines yellow
# sed 0.* volume yellow
# sed 1.* volume green
