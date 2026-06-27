local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local SERVER_URL = "https://backend-server.114ace114.workers.dev"
local customRequest = (fluxus and fluxus.request) or (syn and syn.request) or (http and http.request) or request

-- Unique PC Hardware Identifier (Unique per machine, bound to Windows/Registry)
local function getClientHwid()
    local success, trueHwid = pcall(function()
        return RbxAnalyticsService:GetClientId()
    end)
    
    if success and trueHwid then
        return tostring(trueHwid)
    end
    
    -- Fallback to executor-specific HWID methods if analytics service fails
    local envHwid = gethwid or (fluxus and fluxus.gethwid) or (syn and syn.gethwid)
    if typeof(envHwid) == "function" then
        local successFallback, id = pcall(envHwid)
        if successFallback then return tostring(id) end
    end
    
    return "unknown_hardware_id"
end

local function fetchGameScript(scriptName, gameId)
    if not customRequest then 
        return false, "Executor missing HTTP Request function" 
    end

    local payload = HttpService:JSONEncode({
        scriptName = scriptName,
        gameId = tostring(gameId),
        username = LocalPlayer.Name
    })

    -- Perform the POST request sending ONLY the hardware ID in the headers
    local success, response = pcall(customRequest, {
        Url = SERVER_URL .. "/gamescript",
        Method = "POST",
        Headers = { 
            ["Content-Type"] = "application/json",
            ["hwid"] = getClientHwid() -- Device tracking removed
        },
        Body = payload
    })

    if not success then
        return false, "Network error: Unable to connect to server."
    end

    if response.StatusCode == 200 then
        local responseData = HttpService:JSONDecode(response.Body)
        if responseData and responseData.success and responseData.scriptContents then
            
            -- Compiling string to closure directly inside the fetch function
            local compiledScript, err = loadstring(responseData.scriptContents)
            if compiledScript then
                return true, compiledScript
            else
                return false, "Compilation error: " .. tostring(err)
            end
            
        else
            return false, responseData.message or "Script could not be retrieved."
        end
    else
        return false, "Server Error: Status Code " .. tostring(response.StatusCode)
    end
end
