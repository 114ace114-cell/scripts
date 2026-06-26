-- =============================================
-- ROBLOX ANTI-SPY LIBRARY (Original Logic Preserved)
-- =============================================

local Library = {}

local onDetectCallback = nil

local function flagSpy(reason)
    warn("⚠️ [ANTI-SPY] Remote Spy / Hook Detected: " .. tostring(reason))
    
    if typeof(onDetectCallback) == "function" then
        pcall(onDetectCallback, reason)
    end
end

-- ==================== ORIGINAL DETECTION LOGIC (UNCHANGED) ====================

local function getRawMT()
    return (getrawmetatable or getmetatable)(game)
end

local function detectGCLeak()
    local remote = Instance.new("RemoteEvent")
    remote.Parent = game:GetService("ReplicatedStorage")
    local big = {} for i=1,350 do big = {big} end
    
    for _=1,4 do
        local old = gcinfo()
        pcall(function() remote:FireServer(big) end)
        if gcinfo() - old > 65 then
            flagSpy("GC Leak - Spy detected")
            break
        end
        task.wait(0.07)
    end
    remote:Destroy()
end

local function detectFunctionWrapping()
    local a,b = Instance.new("RemoteEvent"), Instance.new("RemoteEvent")
    if a.FireServer ~= b.FireServer then
        flagSpy("FireServer wrapping detected")
    end
    a:Destroy() b:Destroy()
end

local function detectNamecallInterception()
    local mt = getRawMT()
    local fake = setmetatable({}, {
        __index = function(_,k)
            if type(k)=="string" and (k:find("Fire") or k:find("ClassName")) then
                flagSpy("Spy probed fake remote: "..k)
            end
            return nil
        end
    })
    
    local s, err = pcall(function()
        mt.__namecall(fake, "FireServer", "bait")
    end)
    
    if s or (err and not err:lower():find("instance") and not err:lower():find("table")) then
        flagSpy("Namecall interception detected")
    end
end

local function detectHookOverhead()
    local function bench(n)
        local t = os.clock()
        for i=1,n do pcall(function() game:IsA("DataModel") end) end
        return (os.clock()-t)*1000
    end
    local base = bench(2500)
    local hooked = bench(2500)
    if hooked > base * 2.7 then
        flagSpy("Namecall hook overhead")
    end
end

local function runAll()
    pcall(detectGCLeak)
    pcall(detectFunctionWrapping)
    pcall(detectNamecallInterception)
    pcall(detectHookOverhead)
end

-- ==================== LIBRARY API ====================

function Library:setOnDetect(callback)
    if typeof(callback) == "function" then
        onDetectCallback = callback
    end
end

function Library:run()
    runAll()
end

function Library:runPeriodic(interval)
    interval = interval or 15
    task.spawn(function()
        while true do
            task.wait(interval + math.random(1, 8))
            pcall(runAll)
        end
    end)
end

-- Auto start periodic check
Library:runPeriodic(15)

warn("✅ Anti-Spy Library Loaded")
return Library
