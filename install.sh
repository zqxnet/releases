#!/usr/bin/env bash
# Installs the latest ZQX release on a Linux x86-64 machine, runs zqxd as a
# systemd service, and joins the xnet with an auth key that it asks for.
#
# Run on the machine (as root, or as a user with sudo):
#   curl -fsSL https://raw.githubusercontent.com/zqxnet/releases/main/install.sh | bash
#
# - The download is checked against the release's SHA-256 digest.
# - The key is read without echo, passed to `zqx up` in the environment (not
#   on the command line), and never written to disk or shell history.
# - The service uses the `zqx` operator group; the user who runs this is
#   added to it (sign in again to use `zqx up` and `zqx down` without sudo).

set -euo pipefail

REPO=zqxnet/releases
ASSET=zqx-linux-amd64.tar.gz
DEFAULT_SERVER=console.zqxnet.com

[ "$(uname -s)" = Linux ] || { echo "This script is for Linux."; exit 1; }
[ "$(uname -m)" = x86_64 ] || { echo "Only x86-64 Linux has a release build ($(uname -m) found)."; exit 1; }
for tool in curl tar sha256sum python3 systemctl; do
  command -v "$tool" >/dev/null || { echo "Missing: $tool"; exit 1; }
done
SUDO=""; [ "$(id -u)" -eq 0 ] || SUDO=sudo
TARGET_USER=${SUDO_USER:-$(id -un)}

WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
cd "$WORK"

echo "== Finding the latest release"
curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" -o release.json
read -r TAG DIGEST < <(python3 -I -c '
import json, sys
r = json.load(open("release.json"))
a = [x for x in r["assets"] if x["name"] == sys.argv[1]]
print(r["tag_name"], (a[0].get("digest") or "").removeprefix("sha256:") if a else "")
' "$ASSET")
[ -n "$DIGEST" ] || { echo "No SHA-256 digest published for $ASSET in $TAG."; exit 1; }
echo "   $TAG"

echo "== Downloading and checking $ASSET"
curl -fsSL "https://github.com/$REPO/releases/download/$TAG/$ASSET" -o "$ASSET"
echo "$DIGEST  $ASSET" | sha256sum -c --quiet - || { echo "Checksum mismatch: not installing."; exit 1; }
mkdir pkg && tar -xzf "$ASSET" -C pkg
BIN_DIR=$(dirname "$(find pkg -type f -name zqxd | head -1)")
[ -x "$BIN_DIR/zqxd" ] && [ -x "$BIN_DIR/zqx" ] || { echo "The archive has no zqx/zqxd."; exit 1; }

echo "== Installing to /usr/local/bin"
for b in zqx zqxd zqx-stir; do
  [ -f "$BIN_DIR/$b" ] && $SUDO install -m 0755 "$BIN_DIR/$b" /usr/local/bin/$b
done
NOTICES=$(find pkg -type f -name THIRD-PARTY-NOTICES.txt | head -1)
if [ -n "$NOTICES" ]; then
  $SUDO install -d /usr/local/share/doc/zqx
  $SUDO install -m 0644 "$NOTICES" /usr/local/share/doc/zqx/THIRD-PARTY-NOTICES.txt
fi

echo "== Operator group zqx"
getent group zqx >/dev/null || $SUDO groupadd --system zqx
[ "$TARGET_USER" = root ] || $SUDO usermod -aG zqx "$TARGET_USER"

echo "== systemd service zqxd"
$SUDO tee /etc/systemd/system/zqxd.service >/dev/null <<'UNIT'
[Unit]
Description=ZQX Zero-Trust Fabric Network Daemon
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/zqxd --state auto --operator-group zqx
Restart=always
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
UNIT
$SUDO systemctl daemon-reload
$SUDO systemctl enable --now zqxd >/dev/null
$SUDO systemctl restart zqxd
for _ in $(seq 1 20); do [ -S /var/run/zqx/zqxd.sock ] && break; sleep 0.5; done
[ -S /var/run/zqx/zqxd.sock ] || { echo "zqxd did not start: run 'sudo journalctl -u zqxd'."; exit 1; }
echo "   $(/usr/local/bin/zqxd --version), active"

echo "== Join your xnet"
echo "   In the console: Add device. Copy the key from the command"
echo "   (the part after --auth-key, including any .suffix)."
read -r -p "   Controller [$DEFAULT_SERVER]: " SERVER < /dev/tty
SERVER=${SERVER:-$DEFAULT_SERVER}
read -r -s -p "   Auth key (hidden): " KEY < /dev/tty; echo
[ -n "$KEY" ] || { echo "No key given. Join later with: sudo zqx up --server $SERVER --auth-key <key>"; exit 1; }
read -r -p "   Device name [$(hostname)]: " NAME < /dev/tty
NAME=${NAME:-$(hostname)}

# The key reaches `zqx up` on standard input, then in its environment: never
# on a command line (visible to other users in `ps`).
JOIN='IFS= read -r ZQX_AUTH_TOKEN; export ZQX_AUTH_TOKEN; exec /usr/local/bin/zqx up --server "$1" --hostname "$2"'
if $SUDO bash -c "$JOIN" join "$SERVER" "$NAME" <<< "$KEY"; then
  unset KEY
  echo "== Done"
  /usr/local/bin/zqx status | sed -n 2,8p
  [ "$TARGET_USER" = root ] || echo "   Sign in again as $TARGET_USER to use zqx up / zqx down without sudo."
else
  unset KEY
  echo "Joining failed. The key works once and expires in 24 hours: make a new one in the console and run:"
  echo "   sudo zqx up --server $SERVER --auth-key <key>"
  exit 1
fi
