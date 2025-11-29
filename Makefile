include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-mentohust
PKG_VERSION:=2.0.2
PKG_RELEASE:=1

PKG_LICENSE:=MIT
PKG_MAINTAINER:=Yozlyn

LUCI_TITLE:=LuCI Support for MentoHUST
LUCI_DEPENDS:=+luci-base +mentohust
LUCI_PKGARCH:=all

include $(TOPDIR)/feeds/luci/luci.mk

define Package/luci-app-mentohust/install
	$(call Package/luci-app-mentohust/install/default,$(1))
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./root/etc/init.d/mentohust $(1)/etc/init.d/mentohust
	$(INSTALL_CONF) ./root/etc/mentohust.conf $(1)/etc/mentohust.conf
endef

define Package/luci-app-mentohust/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	chmod 755 /etc/init.d/mentohust
fi
exit 0
endef

define Package/luci-app-mentohust/prerm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	/etc/init.d/mentohust stop 2>/dev/null
	/etc/init.d/mentohust disable 2>/dev/null
	
	uci delete mentohust 2>/dev/null
	uci commit
	uci -q batch <<-EOF >/dev/null
		delete ucitrack.@mentohust[0]
		commit ucitrack
	EOF
	
	rm -f /etc/mentohust.conf 2>/dev/null
	rm -f /etc/uci-defaults/40_luci-mentohust 2>/dev/null
	rm -rf /tmp/luci-modulecache/
fi
exit 0
endef

# call BuildPackage - OpenWrt buildroot signature