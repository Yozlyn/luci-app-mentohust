#!/usr/bin/env bash
set -euo pipefail

PACKAGE_NAME="luci-app-mentohust"
SDK_NAME="openwrt-sdk-23.05.5-mediatek-filogic_gcc-12.3.0_musl.Linux-x86_64"
SDK_URL="https://downloads.openwrt.org/releases/23.05.5/targets/mediatek/filogic/openwrt-sdk-23.05.5-mediatek-filogic_gcc-12.3.0_musl.Linux-x86_64.tar.xz"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CACHE_DIR="${CACHE_DIR:-$REPO_ROOT/.cache}"
SDK_ARCHIVE="$CACHE_DIR/$SDK_NAME.tar.xz"
SDK_DIR="${SDK_DIR:-$REPO_ROOT/sdk}"
DL_CACHE_DIR="$CACHE_DIR/dl"
DIST_DIR="$REPO_ROOT/dist"
BUILD_LOG_DIR="$REPO_ROOT/build-logs"
LOG_FILE="$BUILD_LOG_DIR/local-build.log"

REFRESH_SDK=0
SKIP_FEEDS=0
USER_JOBS="${JOBS:-}"
BUILD_VERBOSE="${BUILD_VERBOSE:-s}"

usage() {
  cat <<'EOF'
Usage: bash scripts/build-local.sh [options]

Options:
  -j, --jobs N       Override auto-detected parallel jobs
      --refresh-sdk  Remove and re-extract the SDK before building
      --skip-feeds   Reuse existing feeds state without update/install
  -h, --help         Show this help

Environment:
  CACHE_DIR          Override SDK/download cache directory
  SDK_DIR            Override extracted SDK directory
  JOBS               Override auto-detected parallel jobs
  BUILD_VERBOSE      OpenWrt make verbosity, default: s
EOF
}

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
}

validate_jobs() {
  local value="$1"
  case "$value" in
    ''|*[!0-9]*)
      echo "Invalid jobs value: $value" >&2
      exit 1
      ;;
    0)
      echo "Jobs must be greater than 0." >&2
      exit 1
      ;;
  esac
}

min_int() {
  local a="$1"
  local b="$2"
  if [ "$a" -le "$b" ]; then
    echo "$a"
  else
    echo "$b"
  fi
}

detect_mem_mib() {
  awk '/MemTotal:/ {print int($2 / 1024)}' /proc/meminfo
}

detect_default_jobs() {
  local cpu_count mem_mib jobs_by_mem jobs
  cpu_count="$(nproc)"
  mem_mib="$(detect_mem_mib)"

  if [ "$mem_mib" -le 4096 ]; then
    jobs_by_mem=1
  else
    jobs_by_mem=$(( (mem_mib - 3072) / 1536 ))
    if [ "$jobs_by_mem" -lt 1 ]; then
      jobs_by_mem=1
    fi
  fi

  jobs="$(min_int "$cpu_count" "$jobs_by_mem")"
  jobs="$(min_int "$jobs" 16)"

  if [ "$jobs" -lt 1 ]; then
    jobs=1
  fi

  echo "$jobs"
}

prepare_dirs() {
  mkdir -p "$CACHE_DIR" "$DL_CACHE_DIR" "$DIST_DIR" "$BUILD_LOG_DIR"
}

download_sdk() {
  if [ ! -f "$SDK_ARCHIVE" ]; then
    echo "Downloading OpenWrt SDK archive..."
    wget -O "$SDK_ARCHIVE" "$SDK_URL"
  else
    echo "Using cached SDK archive: $SDK_ARCHIVE"
  fi
}

extract_sdk() {
  if [ "$REFRESH_SDK" -eq 1 ] && [ -d "$SDK_DIR" ]; then
    echo "Refreshing SDK directory..."
    rm -rf "$SDK_DIR"
  fi

  if [ ! -d "$SDK_DIR/scripts" ]; then
    echo "Extracting SDK into: $SDK_DIR"
    rm -rf "$SDK_DIR"
    mkdir -p "$SDK_DIR"
    tar -xf "$SDK_ARCHIVE" -C "$SDK_DIR" --strip-components=1
  else
    echo "Using existing SDK directory: $SDK_DIR"
  fi

  rm -rf "$SDK_DIR/dl"
  ln -s "$DL_CACHE_DIR" "$SDK_DIR/dl"
}

sync_package() {
  local package_dir="$SDK_DIR/package/$PACKAGE_NAME"

  echo "Syncing package sources into SDK..."
  rm -rf "$package_dir"
  mkdir -p "$package_dir"
  cp -r "$REPO_ROOT/Makefile" "$REPO_ROOT/luasrc" "$REPO_ROOT/root" "$package_dir/"
}

prepare_feeds() {
  if [ "$SKIP_FEEDS" -eq 1 ]; then
    echo "Skipping feeds update/install as requested."
    return
  fi

  echo "Updating and installing OpenWrt feeds..."
  (
    cd "$SDK_DIR"
    ./scripts/feeds update -a
    ./scripts/feeds install -a
  )
}

build_package() {
  local jobs="$1"
  local output_ipk

  echo "Generating default SDK config..."
  (
    cd "$SDK_DIR"
    make defconfig
  )

  echo "Building $PACKAGE_NAME with -j$jobs ..."
  (
    cd "$SDK_DIR"
    set -o pipefail
    make "package/$PACKAGE_NAME/compile" "V=$BUILD_VERBOSE" -j"$jobs" 2>&1 | tee "$LOG_FILE"
  )

  output_ipk="$(find "$SDK_DIR/bin/packages" -type f -name "$PACKAGE_NAME*.ipk" | sort | head -n 1)"
  if [ -z "$output_ipk" ]; then
    echo "Build finished but no IPK was found under $SDK_DIR/bin/packages/." >&2
    exit 1
  fi

  cp "$output_ipk" "$DIST_DIR/"
  echo "Build completed successfully."
  echo "IPK: $output_ipk"
  echo "Copied to: $DIST_DIR/$(basename "$output_ipk")"
  echo "Log: $LOG_FILE"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -j|--jobs)
      shift
      if [ "$#" -eq 0 ]; then
        echo "Missing value for --jobs" >&2
        exit 1
      fi
      USER_JOBS="$1"
      ;;
    --refresh-sdk)
      REFRESH_SDK=1
      ;;
    --skip-feeds)
      SKIP_FEEDS=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

require_command awk
require_command find
require_command make
require_command nproc
require_command rsync
require_command tar
require_command tee
require_command wget

prepare_dirs
download_sdk
extract_sdk
prepare_feeds
sync_package

JOBS="${USER_JOBS:-$(detect_default_jobs)}"
validate_jobs "$JOBS"
echo "Detected memory: $(detect_mem_mib) MiB"
echo "Detected CPU threads: $(nproc)"
echo "Using build jobs: $JOBS"

build_package "$JOBS"
