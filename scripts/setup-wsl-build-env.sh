#!/usr/bin/env bash
set -euo pipefail

if ! command -v apt-get >/dev/null 2>&1; then
  echo "This script currently supports Debian/Ubuntu hosts with apt-get only." >&2
  exit 1
fi

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    echo "sudo is required when running as a non-root user." >&2
    exit 1
  fi
fi

packages=(
  build-essential
  ca-certificates
  file
  flex
  bison
  gawk
  gettext
  git
  libncurses5-dev
  libssl-dev
  python3
  rsync
  subversion
  swig
  unzip
  wget
  xsltproc
  zlib1g-dev
)

echo "Updating apt package index..."
$SUDO apt-get update

echo "Installing OpenWrt SDK host dependencies..."
$SUDO apt-get install -y "${packages[@]}"

echo "WSL build dependencies are ready."
