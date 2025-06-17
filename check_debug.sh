#!/bin/bash
source "_source"

if [ "$EUID" -eq 0 ]; then
  echo "Error: Script must not be run as root."
  exit 1
fi

if [ "$USER" != "inferno" ]; then
  echo "Error: Script must be run as user 'inferno'."
  exit 2
fi

echo "User check passed: not root and is 'inferno'."

# Check if user 'inferno' is in 'audio' group
if ! id -nG "$USER" | grep -qw "audio"; then
  echo "Error: User '$USER' is not in the 'audio' group."
  exit 3
fi

# Check if systemd-timesyncd is disabled
if systemctl is-enabled systemd-timesyncd 2>/dev/null | grep -qw enabled; then
  echo "Error: systemd-timesyncd is enabled."
  exit 4
fi

# Check if doas is installed
if ! command -v doas >/dev/null 2>&1; then
  echo "Error: doas is not installed."
  exit 5
fi

# Check if tmux is installed
if ! command -v tmux >/dev/null 2>&1; then
  echo "Error: tmux is not installed."
  exit 6
fi

# Check if doas is configured for no password for user 'inferno'
if ! grep -Eq '^permit nopass inferno' /etc/doas.conf 2>/dev/null; then
  echo "Error: doas is not configured for no password for user 'inferno'."
  exit 7
fi

# Check if INFPATH is a valid directory
if [ ! -d "$INFPATH" ]; then
  echo "Error: INFPATH ($INFPATH) is not a valid directory."
  exit 15
fi

# Check if statime is cloned and on inferno-dev branch
if [ ! -d "$INFPATH/statime/.git" ]; then
  echo "Error: statime is not cloned in \$INFPATH/statime."
  exit 8
fi
if ! git -C "$INFPATH/statime" rev-parse --abbrev-ref HEAD | grep -qw "inferno-dev"; then
  echo "Error: statime is not on 'inferno-dev' branch."
  exit 9
fi

# Check if inferno is cloned
if [ ! -d "$INFPATH/inferno/.git" ]; then
  echo "Error: inferno is not cloned in \$INFPATH/inferno."
  exit 10
fi

# Check XDG_RUNTIME_DIR is set and exists
if [ -z "$XDG_RUNTIME_DIR" ] || [ ! -d "$XDG_RUNTIME_DIR" ]; then
  echo "Error: XDG_RUNTIME_DIR is not set correctly or does not exist."
  exit 11
fi

# Check XDG_RUNTIME_DIR contains correct UID
runtime_uid=$(basename "$XDG_RUNTIME_DIR")
if [ "$runtime_uid" != "$UID" ]; then
  echo "Error: XDG_RUNTIME_DIR does not match current UID ($UID)."
  exit 13
fi

# Check DBUS_SESSION_BUS_ADDRESS is set and non-empty
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
  echo "Error: DBUS_SESSION_BUS_ADDRESS is not set."
  exit 12
fi

# Check DBUS_SESSION_BUS_ADDRESS contains correct UID if possible
if echo "$DBUS_SESSION_BUS_ADDRESS" | grep -q 'uid='; then
  dbus_uid=$(echo "$DBUS_SESSION_BUS_ADDRESS" | sed -n 's/.*uid=\([0-9]*\).*/\1/p')
  if [ -n "$dbus_uid" ] && [ "$dbus_uid" != "$UID" ]; then
    echo "Error: DBUS_SESSION_BUS_ADDRESS UID ($dbus_uid) does not match current UID ($UID)."
    exit 14
  fi
fi

