# shellcheck disable=SC2148

set -e

echo "Performance governor"
echo "performance" | doas tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

cd "$INFPATH"
doas cp conf.alsa /etc/alsa/conf.d/80-inferno.conf

# Run install.sh reinstall instead
#cd "$INFPATH/inferno"
#doas cp -v target/release/libasound_module_pcm_inferno.so /usr/lib/aarch64-linux-gnu/alsa-lib

sleep 1

pipewire -c "$INFPATH/conf.pipewire.conf" &
wireplumber &
