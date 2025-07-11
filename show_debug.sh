#!/bin/bash
# shellcheck disable=SC1091
source "_source"

./show_status.sh

echo "if inferno is starting properly the checks below should pass anyway. If there's still issues check this:"
echo "[ ] See if your devices and sinks are not muted above ^"
echo "[ ] See if statime is working; you'll be seeing 'LOG: Steered frequency by X' in the output (see \`tmux attach\`, get back out with \`Ctrl+b d\`)"
echo "[ ] See if you can play music with aplay (see \`aplay -l\` or \`arecord -l\` for devices, use /dev/urandom as a test file, it's just noise)"
echo "    wiremix (cargo install wiremix) can show output level so you can see if the sound is actually playing and going somewhere"
echo "[ ] See if you're using the correct link profile (\`active\` symlink in pw-links)"
echo "    write your own if needed (\`pw-link -i\` or \`-o\` will be helpful, \`pw-link -l\` to list all links)"
echo "    remember, think sink of sink as a microphone, and source as a speaker (confused me for a while)"
echo "[ ] If your dac or amp has a knob, make sure it's not turned down or muted (or off entirely) (trust me, it happens)"
echo;
check_passed() {
  # Green
  echo -e "\033[0;32m[PASS]\033[0m: Check $1"
}

check_failed() {
  # Red
  echo -e "\033[0;31m[FAIL]\033[0m: Check $1"
  exit "${2:-1}"
}

check_warn() {
  # Yellow
  echo -e "\033[0;33m[WARN]\033[0m: Check $1"
}

run_checks() {
  # Not running as root
  local check_name="Not running as root"
  if [ "$EUID" -eq 0 ]; then
    check_failed "$check_name" 1
  fi
  check_passed "$check_name"

  # Running as user 'inferno'
  check_name="Running as user 'inferno'"
  if [ "$USER" != "inferno" ]; then
    check_failed "$check_name" 2
  fi
  check_passed "$check_name"

  # User is in 'audio' group
  check_name="User is in 'audio' group"
  if ! id -nG "$USER" | grep -qw "audio"; then
    check_failed "$check_name" 3
  fi
  check_passed "$check_name"

  # systemd-timesyncd is disabled
  check_name="systemd-timesyncd is disabled"
  if systemctl is-enabled systemd-timesyncd 2>/dev/null | grep -qw enabled; then
    check_failed "$check_name" 4
  fi
  check_passed "$check_name"

  # doas is installed
  check_name="doas is installed"
  if ! command -v doas >/dev/null 2>&1; then
    check_failed "$check_name" 5
  fi
  check_passed "$check_name"

  # tmux is installed
  check_name="tmux is installed"
  if ! command -v tmux >/dev/null 2>&1; then
    check_failed "$check_name" 6
  fi
  check_passed "$check_name"

  # doas is configured for no password for user 'inferno'
  check_name="doas is configured for no password for user 'inferno'"
  if ! grep -Eq '^permit nopass inferno' /etc/doas.conf 2>/dev/null; then
    check_failed "$check_name" 7
  fi
  check_passed "$check_name"

  # INFPATH is a valid directory
  check_name="INFPATH is a valid directory"
  if [ ! -d "$INFPATH" ]; then
    check_failed "$check_name" 15
  fi
  check_passed "$check_name"

  # statime is cloned in INFPATH/statime
  check_name="statime is cloned in INFPATH/statime"
  if [ ! -d "$INFPATH/statime/.git" ]; then
    check_failed "$check_name" 8
  fi
  check_passed "$check_name"

  # statime is on 'inferno-dev' branch
  check_name="statime is on 'inferno-dev' branch"
  if ! git -C "$INFPATH/statime" rev-parse --abbrev-ref HEAD | grep -qw "inferno-dev"; then
    check_failed "$check_name" 9
  fi
  check_passed "$check_name"

  # statime is owned by inferno:inferno
  check_name="statime is owned by inferno:inferno"
  if ! [ "$(stat -c '%U:%G' "$INFPATH/statime")" = "inferno:inferno" ]; then
    check_failed "$check_name" 17
  fi
  check_passed "$check_name"

  # inferno is cloned in INFPATH/inferno
  check_name="inferno is cloned in INFPATH/inferno"
  if [ ! -d "$INFPATH/inferno/.git" ]; then
    check_failed "$check_name" 10
  fi
  check_passed "$check_name"

  # inferno is owned by inferno:inferno
  check_name="inferno is owned by inferno:inferno"
  if ! [ "$(stat -c '%U:%G' "$INFPATH/inferno")" = "inferno:inferno" ]; then
    check_failed "$check_name" 16
  fi
  check_passed "$check_name"

  # XDG_RUNTIME_DIR is set and exists
  check_name="XDG_RUNTIME_DIR is set and exists"
  if [ -z "$XDG_RUNTIME_DIR" ] || [ ! -d "$XDG_RUNTIME_DIR" ]; then
    check_failed "$check_name" 11
  fi
  check_passed "$check_name"

  # XDG_RUNTIME_DIR matches current UID
  check_name="XDG_RUNTIME_DIR matches current UID"
  runtime_uid=$(basename "$XDG_RUNTIME_DIR")
  if [ "$runtime_uid" != "$UID" ]; then
    check_failed "$check_name" 13
  fi
  check_passed "$check_name"

  # DBUS_SESSION_BUS_ADDRESS is set
  check_name="DBUS_SESSION_BUS_ADDRESS is set"
  if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    check_failed "$check_name" 12
  fi
  check_passed "$check_name"

# Kernel version is NOT 6.1.*
# this only applies if pipewire suddenly pins a core to 100% and xruns into oblivion
check_name="Kernel version is NOT 6.1"
kernel_version=$(uname -r)

if echo "$kernel_version" | grep -Eq '^6\.1(\.|-)'; then
  check_warn "$check_name"
  echo "!!!! if pipewire suddenly pins a core and xruns, this is your issue"
else
  check_passed "$check_name"
fi


# Exactly one user has systemd linger enabled
check_name="Exactly one user has systemd linger enabled"

linger_dir="/var/lib/systemd/linger"
if [ ! -d "$linger_dir" ]; then
  check_failed "$check_name" 20
fi

linger_count=$(find "$linger_dir" -type f | wc -l)

if [ "$linger_count" -ne 1 ]; then
  check_warn "$check_name"
  echo "you might be running multiple users with inferno:"
  ls "$linger_dir"
  echo "disregard this if you know what you're doing"
fi

check_passed "$check_name"  


}

run_checks

