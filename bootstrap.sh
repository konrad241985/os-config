#!/usr/bin/env bash
# Set up Konrad's Apple Silicon Mac from a fresh clone of os-config.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
if [ "$(uname -s)" != Darwin ] || [ "$(uname -m)" != arm64 ]; then
  echo "This configuration requires an Apple Silicon Mac."
  exit 1
fi
if [ "$(id -un)" != konrad ] || [ "$HOME" != /Users/konrad ]; then
  echo "Run as konrad (without sudo), with home directory /Users/konrad."
  exit 1
fi

# The stable link is fixed; its target follows the clone's actual location.
CONFIG_LINK=/Users/konrad/.dotfiles
BACKUP_SUFFIX="before-os-config-$(date +%Y%m%d-%H%M%S)-$$"

if ! command -v nix >/dev/null 2>&1 && [ -x /nix/var/nix/profiles/default/bin/nix ]; then
  export PATH="/nix/var/nix/profiles/default/bin:$PATH"
fi
if command -v nix >/dev/null 2>&1; then
  echo "==> Nix already installed"
else
  echo "==> Installing Determinate Nix"
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi
NIX_BIN="$(command -v nix)"

# Save an old real directory rather than silently nesting a symlink inside it.
if [ "$DIR" != "$CONFIG_LINK" ]; then
  if [ -e "$CONFIG_LINK" ] && [ ! -L "$CONFIG_LINK" ]; then
    mv "$CONFIG_LINK" "$CONFIG_LINK.$BACKUP_SUFFIX"
    echo "==> Preserved $CONFIG_LINK.$BACKUP_SUFFIX"
  fi
  ln -sfn "$DIR" "$CONFIG_LINK"
fi

echo "==> Preparing existing system shell files"
sudo -v
# nix-darwin owns these as symlinks after activation. Preserve regular files
# supplied by macOS/Nix on the first install; never move managed symlinks.
for file in /etc/bashrc /etc/zshrc; do
  if [ -e "$file" ] && [ ! -L "$file" ]; then
    sudo mv "$file" "$file.$BACKUP_SUFFIX"
    echo "==> Preserved $file.$BACKUP_SUFFIX"
  fi
done

echo "==> Applying os-config for konrad (flake.lock pins the rebuild tool too)"
sudo -H "$NIX_BIN" --extra-experimental-features "nix-command flakes" \
  run "$DIR#darwin-rebuild" -- switch --flake "$DIR#mac"

echo "==> Done. Open a new terminal; use ./rebuild.sh for future changes."
