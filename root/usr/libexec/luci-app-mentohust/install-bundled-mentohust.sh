#!/bin/sh

BUNDLED_IPK='/usr/share/luci-app-mentohust/mentohust_0.3.1-r1_aarch64_cortex-a53.ipk'
MARKER='/usr/share/luci-app-mentohust/.bundled-mentohust-installed'
LOCK='/var/lock/opkg.lock'

sleep 2

while [ -e "$LOCK" ]; do
	sleep 1
done

if [ ! -f "$BUNDLED_IPK" ]; then
	exit 1
fi

if opkg status mentohust >/dev/null 2>&1; then
	exit 0
fi

opkg install "$BUNDLED_IPK" || exit 1
touch "$MARKER"
