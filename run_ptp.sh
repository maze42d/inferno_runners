# shellcheck disable=SC2148,SC2164

doas systemctl stop systemd-timesyncd
sleep 1
cd statime
doas taskset -c "$CORES_STATIME" target/release/statime -c inferno-ptpv2.toml
