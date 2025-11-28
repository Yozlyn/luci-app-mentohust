include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-mentohust
PKG_VERSION:=1.0.9
PKG_RELEASE:=1

PKG_LICENSE:=MIT
PKG_MAINTAINER:=Your Name <your@email.com>

LUCI_TITLE:=LuCI Support for MentoHUST
LUCI_DEPENDS:=+luci-base +mentohust
LUCI_PKGARCH:=all

include $(TOPDIR)/feeds/luci/luci.mk
define Package/luci-app-mentohust/install
	$(call Package/luci-app-mentohust/install/default,$(1))
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./root/etc/init.d/mentohust $(1)/etc/init.d/mentohust
endef

# call BuildPackage - OpenWrt buildroot signature