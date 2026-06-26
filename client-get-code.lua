local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CodeRunner = { isLooping = false }

local SERVER_URL = "https://backend-server.114ace114.workers.dev/get-code"
local username = Players.LocalPlayer and Players.LocalPlayer.Name or "Unknown"
local currentUniverseId = tostring(game.GameId)

local cacheString, cacheFunc = "", nil

-- Global tracking variable for the active script instance
_G.CurrentScriptToken = _G.CurrentScriptToken or 0

function CodeRunner.fetchAndRun()
    local success, response = pcall(request, {
        Url = SERVER_URL,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode({ 
            username = username,
            gameId = currentUniverseId
        })
    })
    
    if not success then return false end
    
    local decodeSuccess, json = pcall(HttpService.JSONDecode, HttpService, response.Body)
    if not decodeSuccess or not json or json.status ~= "success" then return false end

    -- Compile if new, execute from upvalue cache if old
    if json.scriptCode ~= cacheString then
        cacheString = json.scriptCode
        print("New script detected! Updating token...")
        
        -- Increment the token to invalidate any previous running cacheFunc loops
        _G.CurrentScriptToken = _G.CurrentScriptToken + 1
        
        cacheFunc = loadstring(json.scriptCode)
    end

    if cacheFunc then 
        -- Pass the token into the function so the script knows its own identity
        pcall(cacheFunc, _G.CurrentScriptToken) 
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
