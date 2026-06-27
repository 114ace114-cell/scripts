local HttpService = game:GetService("HttpService")

-- Ensure global hooks exist to prevent overlapping loops if re-executed
_G.HttpListenerCache = _G.HttpListenerCache or {}
_G.ActiveListeners = _G.ActiveListeners or {}

local HttpLib = {}

-- Utility to find the correct HTTP request function across different executors
local function getRequestFunction()
    return syn and syn.request or http and http.request or request
end

-------------------------------------------------------------------------------
-- SENDER
-------------------------------------------------------------------------------
-- @param url: string
-- @param body: table | string | nil (If nil/empty table, defaults to GET, otherwise POST)
-- @param headers: table | nil
-------------------------------------------------------------------------------
function HttpLib.send(url, body, headers)
    local requestFunc = getRequestFunction()
    if not requestFunc then 
        warn("[HttpLib] No valid HTTP request function found in this environment.")
        return false, "Unsupported environment" 
    end

    local method = "GET"
    local encodedBody = nil

    if body and body ~= "" and (type(body) ~= "table" or next(body) ~= nil) then
        method = "POST"
        if type(body) == "table" then
            encodedBody = HttpService:JSONEncode(body)
            headers = headers or {}
            headers["Content-Type"] = "application/json"
        else
            encodedBody = tostring(body)
        end
    end

    local success, response = pcall(requestFunc, {
        Url = url,
        Method = method,
        Headers = headers or {},
        Body = encodedBody
    })

    if not success then
        return false, "HTTP request failed: " .. tostring(response)
    end

    return true, response
end

-------------------------------------------------------------------------------
-- LISTENER
-------------------------------------------------------------------------------
-- @param listenerId: string (A unique key to identify this loop so it can be overwritten/stopped)
-- @param config: table { url, interval, body, headers, callback }
-------------------------------------------------------------------------------
function HttpLib.startListener(listenerId, config)
    local url = config.url
    local interval = config.interval or 3
    local body = config.body
    local headers = config.headers
    local callback = config.callback

    -- Stop any prior running loop with the same listenerId
    if _G.ActiveListeners[listenerId] then
        _G.ActiveListeners[listenerId]()
    end

    local keepLooping = true
    _G.ActiveListeners[listenerId] = function()
        keepLooping = false
        print(string.format("[HttpLib] Listener '%s' stopped.", listenerId))
    end

    -- Clear prior cache for this specific listener
    _G.HttpListenerCache[listenerId] = ""

    task.spawn(function()
        print(string.format("[HttpLib] Listener '%s' started polling every %ds.", listenerId, interval))
        
        while keepLooping do
            local success, response = HttpLib.send(url, body, headers)
            
            if success and response.StatusCode == 200 then
                local rawBody = response.Body
                
                -- Check if the payload actually changed to prevent duplicate executions
                if rawBody and rawBody ~= "" and rawBody ~= _G.HttpListenerCache[listenerId] then
                    _G.HttpListenerCache[listenerId] = rawBody
                    
                    -- Safely parse JSON if applicable, otherwise pass raw body
                    local decodeSuccess, decodedData = pcall(HttpService.JSONDecode, HttpService, rawBody)
                    local finalData = decodeSuccess and decodedData or rawBody
                    
                    -- Trigger custom user logic
                    if callback then
                        task.spawn(pcall, callback, finalData)
                    end
                elseif rawBody == "" then
                    _G.HttpListenerCache[listenerId] = ""
                end
            end
            
            task.wait(interval)
        end
    end)
end

-- Function to manually stop a specific listener from external scripts
function HttpLib.stopListener(listenerId)
    if _G.ActiveListeners[listenerId] then
        _G.ActiveListeners[listenerId]()
        _G.ActiveListeners[listenerId] = nil
    end
end

return HttpLib
