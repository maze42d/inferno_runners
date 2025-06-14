# shellcheck disable=SC2148

set -e

doas cp conf.moduleoptions /etc/modprobe.d/inferno.conf

# doas rmmod g_audio || true
doas modprobe dwc2
doas modprobe g_audio
