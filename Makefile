include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-mentohust
PKG_VERSION:=2.0.2
PKG_RELEASE:=2

PKG_LICENSE:=MIT
PKG_MAINTAINER:=Yozlyn

LUCI_TITLE:=LuCI Support for MentoHUST
LUCI_DEPENDS:=+luci-base +libpcap
LUCI_PKGARCH:=aarch64_cortex-a53

include $(TOPDIR)/feeds/luci/luci.mk

define Package/luci-app-mentohust/conffiles
/etc/config/mentohust
/etc/mentohust.conf
endef

define Package/luci-app-mentohust/install
	$(call Package/luci-app-mentohust/install/default,$(1))
endef

define Package/luci-app-mentohust/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	[ ! -e /etc/init.d/mentohust ] || chmod 755 /etc/init.d/mentohust
fi
exit 0
endef

define Package/luci-app-mentohust/prerm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ] && [ "$${1}" = "remove" ]; then
	/etc/init.d/mentohust stop 2>/dev/null
	/etc/init.d/mentohust disable 2>/dev/null
	COUNT=0
	while pgrep -f '/usr/sbin/mentohust' >/dev/null 2>&1 && [ "$${COUNT}" -lt 10 ]; do
		sleep 1
		COUNT=$$(($${COUNT} + 1))
	done
	pkill -9 -f '/usr/sbin/mentohust' >/dev/null 2>&1 || true
fi
exit 0
endef

define Package/luci-app-mentohust/postrm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ] && [ "$${1}" = "remove" ]; then
	uci -q delete mentohust
	uci -q commit mentohust
	uci -q batch <<-'EOF' >/dev/null
		delete ucitrack.@mentohust[0]
		commit ucitrack
	EOF

	rm -f /etc/config/mentohust 2>/dev/null
	rm -f /etc/mentohust.conf 2>/dev/null
	rm -f /etc/uci-defaults/40_luci-mentohust 2>/dev/null
	rm -rf /tmp/luci-modulecache/
fi
exit 0
endef

# call BuildPackage - OpenWrt buildroot signature
