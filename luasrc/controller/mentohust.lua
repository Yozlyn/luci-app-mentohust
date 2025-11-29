module("luci.controller.mentohust", package.seeall)

function index()
    entry({"admin", "services", "mentohust"}, 
          alias("admin", "services", "mentohust", "status"), 
          _("MentoHUST"), 60).dependent = false
    
    entry({"admin", "services", "mentohust", "status"}, 
          template("mentohust/status"), _("运行状态"), 1)

    entry({"admin", "services", "mentohust", "config"}, 
          cbi("mentohust/config"), _("参数设置"), 2)
    
    entry({"admin", "services", "mentohust", "get_log"}, call("action_get_log"))
    entry({"admin", "services", "mentohust", "get_status"}, call("action_get_status"))
    entry({"admin", "services", "mentohust", "service_action"}, call("action_service"))
    entry({"admin", "services", "mentohust", "clear_log"}, call("action_clear_log"))
end

function action_get_log()
    local log = luci.sys.exec("tail -n 100 /tmp/mentohust.log 2>/dev/null || echo '暂无日志'")
    luci.http.prepare_content("text/plain; charset=utf-8")
    luci.http.write(log)
end

function action_get_status()
    local running = luci.sys.call("pgrep mentohust >/dev/null") == 0
    local enabled = luci.sys.init.enabled("mentohust")
    luci.http.prepare_content("application/json")
    luci.http.write_json({running = running, enabled = enabled})
end

function action_service()
    local action = luci.http.formvalue("action")
    local result = false
    
    if action == "stop" or action == "restart" then
        result = luci.sys.call("/etc/init.d/mentohust " .. action) == 0
    end
    
    luci.http.prepare_content("application/json")
    luci.http.write_json({success = result})
end

function action_clear_log()
    local log_file = "/tmp/mentohust.log"
    local result = luci.sys.call("rm -f " .. log_file .. " && touch " .. log_file) == 0
    luci.http.prepare_content("application/json")
    luci.http.write_json({success = result})
end