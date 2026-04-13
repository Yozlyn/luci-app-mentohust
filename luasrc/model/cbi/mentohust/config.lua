local m, s, o
local sys = require "luci.sys"
local util = require "luci.util"

m = Map("mentohust", translate("MentoHUST 设置"), 
    translate("配置 802.1x 认证参数。保存配置后服务将自动重启。"))

s = m:section(NamedSection, "default", "mentohust", translate("基本设置"))
s.anonymous = true
s.addremove = false

-- 启用服务选项
o = s:option(Flag, "enabled", translate("启用服务"))
o.rmempty = false

o = s:option(Value, "username", translate("用户名"))
o.rmempty = false

o = s:option(Value, "password", translate("密码"))
o.password = true
o.rmempty = false

o = s:option(Value, "nic", translate("认证网卡"))
for _, dev in ipairs(luci.sys.net.devices()) do
    if dev ~= "lo" then o:value(dev) end
end
o.default = "eth0"
o.rmempty = false

s = m:section(NamedSection, "default", "mentohust", translate("高级设置"))
s.anonymous = true
s.addremove = false

o = s:option(Value, "ip", translate("IP地址"))
o.default = "0.0.0.0"
o.description = translate("DHCP用户请保留 0.0.0.0")

o = s:option(Value, "mask", translate("子网掩码"))
o.default = "0.0.0.0"
o.description = translate("掩码，无关紧要")

o = s:option(Value, "gateway", translate("网关"))
o.default = "0.0.0.0"
o.description = translate("网关，如果指定了就会监视网关ARP信息")

o = s:option(Value, "dns", translate("DNS服务器"))
o.default = "0.0.0.0"
o.description = translate("DNS服务器，无关紧要")

o = s:option(ListValue, "startmode", translate("组播模式"))
o:value("0", translate("标准"))
o:value("1", translate("锐捷"))
o:value("2", translate("赛尔"))
o.default = "0"
o.description = translate("寻找服务器时的组播地址类型 0标准 1锐捷 2将MentoHUST用于赛尔认证")

o = s:option(ListValue, "dhcpmode", translate("DHCP方式"))
o:value("0", translate("不使用"))
o:value("1", translate("二次认证"))
o:value("2", translate("认证后"))
o:value("3", translate("认证前"))
o.default = "1"
o.description = translate("DHCP方式 0(不使用) 1(二次认证) 2(认证后) 3(认证前)")

o = s:option(Value, "pinghost", translate("Ping主机"))
o.default = "0.0.0.0"
o.description = translate("Ping主机，用于掉线检测，0.0.0.0表示关闭该功能")

o = s:option(Value, "timeout", translate("超时时间"))
o.default = "8"
o.description = translate("每次发包超时时间（秒）")

o = s:option(Value, "echointerval", translate("心跳间隔"))
o.default = "30"
o.description = translate("发送Echo包的间隔（秒）")

o = s:option(Value, "restartwait", translate("失败等待"))
o.default = "15"
o.description = translate("认证失败后失败等待（秒）向服务器请求重启认证")

o = s:option(Value, "version", translate("客户端版本"))
o.default = "0.00"
o.description = translate("客户端版本号，如果未开启客户端校验但对版本号有要求，可以在此指定，形如3.30")

o = s:option(ListValue, "daemonmode", translate("后台运行"))
o:value("0", translate("否"))
o:value("1", translate("是，关闭输出"))
o:value("2", translate("是，保留输出"))
o:value("3", translate("是，输出到文件"))
o.default = "3"
o.description = translate("后台运行方式：0 表示前台，1 表示后台并关闭输出，2 表示后台但保留输出，3 表示后台并输出到文件")

o = s:option(Value, "shownotify", translate("通知级别"))
o.default = "0"
o.description = translate("是否显示通知，0 表示关闭，1~20 表示启用不同级别通知")

o = s:option(Value, "datafile", translate("认证数据目录"))
o.default = "/etc/mentohust/"
o.description = translate("认证数据文件目录")
o.rmempty = false

o = s:option(Value, "dhcpscript", translate("DHCP脚本命令"))
o.default = "udhcpc -i eth0 -q"
o.description = translate("指定执行 DHCP 的命令。网卡接口请与上方 '认证网卡' 保持一致。")
o.rmempty = false


m.on_after_commit = function(self)
    local uci = require("luci.model.uci").cursor()
    local username = uci:get("mentohust", "default", "username") or ""
    local password = uci:get("mentohust", "default", "password") or ""
    local enabled = uci:get("mentohust", "default", "enabled")
    local commands = {}

    if username ~= "" and password ~= "" then
        local nic = uci:get("mentohust", "default", "nic") or "eth0"
        local ip = uci:get("mentohust", "default", "ip") or "0.0.0.0"
        local mask = uci:get("mentohust", "default", "mask") or "0.0.0.0"
        local gateway = uci:get("mentohust", "default", "gateway") or "0.0.0.0"
        local dns = uci:get("mentohust", "default", "dns") or "0.0.0.0"
        local pinghost = uci:get("mentohust", "default", "pinghost") or "0.0.0.0"
        local timeout = uci:get("mentohust", "default", "timeout") or "8"
        local echointerval = uci:get("mentohust", "default", "echointerval") or "30"
        local restartwait = uci:get("mentohust", "default", "restartwait") or "15"
        local startmode = uci:get("mentohust", "default", "startmode") or "0"
        local dhcpmode = uci:get("mentohust", "default", "dhcpmode") or "1"
        local daemonmode = uci:get("mentohust", "default", "daemonmode") or "0"
        local version = uci:get("mentohust", "default", "version") or "0.00"
        local dhcpscript = uci:get("mentohust", "default", "dhcpscript") or "udhcpc -i eth0 -q"

        local cmd = table.concat({
            "/usr/sbin/mentohust",
            "-w",
            "-u" .. util.shellquote(username),
            "-p" .. util.shellquote(password),
            "-n" .. util.shellquote(nic),
            "-i" .. util.shellquote(ip),
            "-m" .. util.shellquote(mask),
            "-g" .. util.shellquote(gateway),
            "-s" .. util.shellquote(dns),
            "-o" .. util.shellquote(pinghost),
            "-t" .. util.shellquote(timeout),
            "-e" .. util.shellquote(echointerval),
            "-r" .. util.shellquote(restartwait),
            "-a" .. util.shellquote(startmode),
            "-d" .. util.shellquote(dhcpmode),
            "-b" .. util.shellquote(daemonmode),
            "-v" .. util.shellquote(version),
            "-c" .. util.shellquote(dhcpscript)
        }, " ") .. " >/dev/null 2>&1"

        commands[#commands + 1] = cmd
    end

    if enabled == "1" then
        commands[#commands + 1] = "/etc/init.d/mentohust restart >/dev/null 2>&1"
    else
        commands[#commands + 1] = "/etc/init.d/mentohust stop >/dev/null 2>&1"
    end

    if #commands > 0 then
        sys.call(string.format("/bin/sh -c %s >/dev/null 2>&1 &", util.shellquote(table.concat(commands, " ; "))))
    end
end

return m
