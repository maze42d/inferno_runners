#!/bin/bash
# shellcheck disable=SC1091
source "_source"

./check_status.sh

echo "if inferno is starting properly the checks below should pass anyway. If there's still issues check this:"
echo "[ ] See if your devices and sinks are not muted above ^"
echo "[ ] See if statime is working; you'll be seeing 'LOG: Steered frequency by X' in the output (see \`tmux attach\`, get back out with \`Ctrl+b d\`)"
echo "[ ] See if you can play music with aplay (see \`aplay -l\` or \`arecord -l\` for devices, use /dev/urandom as a test file, it's just noise)"
echo "    wiremix (cargo install wiremix) can show output level so you can see if the sound is actually playing and going somewhere"
echo "[ ] See if you're using the correct link profile (\`active\` symlink in pw-links)"
echo "    write your own if needed (\`pw-link -i\` or \`-o\` will be helpful, \`pw-link -l\` to list all links)"
echo "    remember, think sink of sink as a microphone, and source as a speaker (confused me for a while)"
echo "[ ] If your dac or amp has a knob, make sure it's not turned down or muted"

check_passed() {
  # Green
  echo -e "Check $1: \033[0;32mpass\033[0m"
}

check_failed() {
  # Red
  echo -e "Check $1: \033[0;31mfail\033[0m"
  exit "${2:-1}"
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

  # inferno is cloned in INFPATH/inferno
  check_name="inferno is cloned in INFPATH/inferno"
  if [ ! -d "$INFPATH/inferno/.git" ]; then
    check_failed "$check_name" 10
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

  # DBUS_SESSION_BUS_ADDRESS UID matches current UID
  check_name="DBUS_SESSION_BUS_ADDRESS UID matches current UID"
  if echo "$DBUS_SESSION_BUS_ADDRESS" | grep -q 'uid='; then
    dbus_uid=$(echo "$DBUS_SESSION_BUS_ADDRESS" | sed -n 's/.*uid=\([0-9]*\).*/\1/p')
    if [ -n "$dbus_uid" ] && [ "$dbus_uid" != "$UID" ]; then
      check_failed "$check_name" 14
    fi
  fi
  check_passed "$check_name"
}

run_checks

