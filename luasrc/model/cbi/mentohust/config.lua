local m, s, o

-- 定义映射到 /etc/config/mentohust 的配置 Map
m = Map("mentohust", translate("MentoHUST 设置"), 
    translate("配置 802.1x 认证参数。保存配置后服务将自动重启。"))

-- [基本设置] 部分
s = m:section(NamedSection, "default", "mentohust", translate("基本设置"))
s.anonymous = true
s.addremove = false

-- 启用开关
o = s:option(Flag, "enabled", translate("启用自动运行"))
o.rmempty = false

-- 用户名输入框
o = s:option(Value, "username", translate("用户名"))
o.rmempty = false

-- 密码输入框
o = s:option(Value, "password", translate("密码"))
o.password = true
o.rmempty = false

-- 网卡选择下拉框 (自动读取系统网卡)
o = s:option(Value, "nic", translate("认证网卡"))
for _, dev in ipairs(luci.sys.net.devices()) do
    if dev ~= "lo" then
        o:value(dev)
    end
end
o.default = "eth0"
o.rmempty = false

-- [高级设置] 部分
s = m:section(NamedSection, "default", "mentohust", translate("高级设置"))
s.anonymous = true
s.addremove = false

-- 组播模式选择
o = s:option(ListValue, "startmode", translate("组播模式"))
o:value("0", translate("0 - 标准"))
o:value("1", translate("1 - 锐捷"))
o:value("2", translate("2 - 赛尔"))
o.default = "0"

-- DHCP 方式选择
o = s:option(ListValue, "dhcpmode", translate("DHCP方式"))
o:value("0", translate("0 - 不使用"))
o:value("1", translate("1 - 二次认证"))
o:value("2", translate("2 - 认证后"))
o:value("3", translate("3 - 认证前"))
o.default = "0"

-- IP参数
o = s:option(Value, "ip", translate("IP地址"))
o.default = "0.0.0.0"
o.description = translate("DHCP用户请保留 0.0.0.0")

o = s:option(Value, "mask", translate("子网掩码"))
o.default = "255.255.0.0"

o = s:option(Value, "gateway", translate("网关"))
o.default = "0.0.0.0"

o = s:option(Value, "dns", translate("DNS服务器"))
o.default = "0.0.0.0"

o = s:option(Value, "pinghost", translate("Ping主机"))
o.default = "0.0.0.0"
o.description = translate("用于掉线检测，0.0.0.0 表示关闭")

o = s:option(Value, "timeout", translate("超时时间(秒)"))
o.default = "8"

o = s:option(Value, "echointerval", translate("心跳间隔(秒)"))
o.default = "30"

o = s:option(Value, "restartwait", translate("失败等待(秒)"))
o.default = "15"

o = s:option(Value, "version", translate("客户端版本"))
o.default = "0.00"
o.description = translate("例如 4.85，0.00 表示兼容模式")

return m