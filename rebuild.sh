#!/usr/bin/env bash
# Reapply this repository using its locked nix-darwin tool.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
if [ "$(id -un)" != konrad ] || [ "$HOME" != /Users/konrad ]; then
  echo "Run as konrad (without sudo), with home directory /Users/konrad."
  exit 1
fi
CONFIG_LINK=/Users/konrad/.dotfiles
if [ "$DIR" != "$CONFIG_LINK" ]; then
  if [ -e "$CONFIG_LINK" ] && [ ! -L "$CONFIG_LINK" ]; then
    echo "Run ./bootstrap.sh first to back up the existing $CONFIG_LINK directory."
    exit 1
  fi
  ln -sfn "$DIR" "$CONFIG_LINK"
fi
if ! command -v nix >/dev/null 2>&1 && [ -x /nix/var/nix/profiles/default/bin/nix ]; then
  export PATH="/nix/var/nix/profiles/default/bin:$PATH"
fi
if ! command -v nix >/dev/null 2>&1; then
  echo "Nix is missing. Run ./bootstrap.sh first."
  exit 1
fi
NIX_BIN="$(command -v nix)"
exec sudo -H "$NIX_BIN" --extra-experimental-features "nix-command flakes" \
  run "$DIR#darwin-rebuild" -- switch --flake "$DIR#mac"
