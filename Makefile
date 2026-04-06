include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-mentohust
PKG_VERSION:=2.0.2
PKG_RELEASE:=1
BUNDLED_MENTOHUST_IPK:=mentohust_0.3.1-r1_aarch64_cortex-a53.ipk

PKG_LICENSE:=MIT
PKG_MAINTAINER:=Yozlyn

LUCI_TITLE:=LuCI Support for MentoHUST
LUCI_DEPENDS:=+luci-base
LUCI_PKGARCH:=aarch64_cortex-a53

include $(TOPDIR)/feeds/luci/luci.mk

define Package/luci-app-mentohust/conffiles
/etc/config/mentohust
/etc/mentohust.conf
endef

define Package/luci-app-mentohust/install
	$(call Package/luci-app-mentohust/install/default,$(1))
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/usr/libexec/luci-app-mentohust
	$(INSTALL_DIR) $(1)/usr/share/luci-app-mentohust
	$(INSTALL_BIN) ./root/etc/init.d/mentohust $(1)/etc/init.d/mentohust
	$(INSTALL_BIN) ./root/usr/libexec/luci-app-mentohust/install-bundled-mentohust.sh $(1)/usr/libexec/luci-app-mentohust/install-bundled-mentohust.sh
	$(INSTALL_CONF) ./root/etc/mentohust.conf $(1)/etc/mentohust.conf
	$(INSTALL_DATA) ./$(BUNDLED_MENTOHUST_IPK) $(1)/usr/share/luci-app-mentohust/$(BUNDLED_MENTOHUST_IPK)
endef

define Package/luci-app-mentohust/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	chmod 755 /etc/init.d/mentohust

	if ! opkg status mentohust >/dev/null 2>&1; then
		/usr/libexec/luci-app-mentohust/install-bundled-mentohust.sh >/tmp/luci-app-mentohust-install.log 2>&1 &
	fi
fi
exit 0
endef

define Package/luci-app-mentohust/prerm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ] && [ "$${1}" = "remove" ]; then
	/etc/init.d/mentohust stop 2>/dev/null
	/etc/init.d/mentohust disable 2>/dev/null
fi
exit 0
endef

define Package/luci-app-mentohust/postrm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ] && [ "$${1}" = "remove" ]; then
	MARKER="/usr/share/luci-app-mentohust/.bundled-mentohust-installed"

	if [ -f "$${MARKER}" ]; then
		opkg remove mentohust 2>/dev/null
	fi

	uci -q delete mentohust
	uci -q commit mentohust
	uci -q batch <<-'EOF' >/dev/null
		delete ucitrack.@mentohust[0]
		commit ucitrack
	EOF

	rm -f /etc/config/mentohust 2>/dev/null
	rm -f /etc/mentohust.conf 2>/dev/null
	rm -f /etc/uci-defaults/40_luci-mentohust 2>/dev/null
	rm -rf /usr/share/luci-app-mentohust 2>/dev/null
	rm -rf /tmp/luci-modulecache/
fi
exit 0
endef

# call BuildPackage - OpenWrt buildroot signature
