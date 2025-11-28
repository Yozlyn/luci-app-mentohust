local m, s

m = SimpleForm("mentohust", translate("配置参数"), 
    translate("本插件目前仅提供服务控制。请通过 SSH 修改 /etc/mentohust.conf 或使用下方命令工具。"))

s = m:section(SimpleSection)
s.template = "mentohust/config_manual"

return m
