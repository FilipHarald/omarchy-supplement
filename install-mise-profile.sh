#!/bin/bash

set -euo pipefail

service_name="dev.mise.mise-history.service"
override_dir="$HOME/.config/systemd/user/$service_name.d"
host_name="$(hostname -s)"

if ! systemctl --user cat "$service_name" >/dev/null 2>&1; then
  echo "Mise history watcher is not installed; run mise bootstrap first."
  exit 0
fi

mkdir -p "$override_dir"
printf '[Service]\nEnvironment=MISE_ENV=%s\n' "$host_name" > "$override_dir/profile.conf"

systemctl --user daemon-reload
systemctl --user restart "$service_name"

echo "Mise history watcher profile set to $host_name."
