local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local SERVER_URL = "https://backend-server.114ace114.workers.dev/get-code"
local username = Players.LocalPlayer and Players.LocalPlayer.Name or "Unknown"
local currentUniverseId = tostring(game.GameId)

-- 使用全局变量 _G 确保多次点击 "Execute" 时不会叠加循环
_G.CodeRunnerCacheString = _G.CodeRunnerCacheString or ""
_G.CurrentScriptToken = _G.CurrentScriptToken or 0

-- 如果已经有循环在跑了，直接关闭旧循环，防止多开
if _G.StopPriorCodeRunnerLoop then
    _G.StopPriorCodeRunnerLoop()
end

local CodeRunner = {}
local keepLooping = true

-- 提供一个关闭当前循环的全局钩子
_G.StopPriorCodeRunnerLoop = function()
    keepLooping = false
    print("[Loader] 旧的监听循环已成功关闭。")
end

function CodeRunner.fetchAndRun()
    local httpFunction = syn and syn.request or http and http.request or request
    if not httpFunction then return false end

    local success, response = pcall(httpFunction, {
        Url = SERVER_URL,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode({ 
            username = username,
            gameId = currentUniverseId
        })
    })
    
    if not success or response.StatusCode ~= 200 then return false end
    
    local decodeSuccess, json = pcall(HttpService.JSONDecode, HttpService, response.Body)
    if not decodeSuccess or not json or json.status ~= "success" then return false end

    -- 【修复核心 1】: 只有当指令/代码发生改变，或者是空命令变有命令时才触发执行
    if json.scriptCode and json.scriptCode ~= "" and json.scriptCode ~= _G.CodeRunnerCacheString then
        _G.CodeRunnerCacheString = json.scriptCode
        print("New script detected! Updating token...")
        
        _G.CurrentScriptToken = _G.CurrentScriptToken + 1
        
        local cacheFunc = loadstring(json.scriptCode)
        if cacheFunc then 
            pcall(cacheFunc, _G.CurrentScriptToken) 
            return true
        end
    elseif json.scriptCode == "" then
        -- 如果服务器返回空，说明命令已被消费清空，重置本地缓存
        _G.CodeRunnerCacheString = ""
    end
    
    return false
end

function CodeRunner.startLoop(interval)
    print("load game", game.GameId)
    
    task.spawn(function()
        while keepLooping do
            CodeRunner.fetchAndRun()
            task.wait(interval or 3)
        end
    end)
end

-- 启动轮询，间隔 3 秒
CodeRunner.startLoop(3)

return CodeRunner
