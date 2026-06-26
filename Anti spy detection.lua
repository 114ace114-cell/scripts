-- =============================================
-- ROBLOX ANTI-SPY LIBRARY - DEBUG ENABLED
-- =============================================

local Library = {}
local onDetectCallback = nil

local function flagSpy(reason)
    warn("⚠️ [ANTI-SPY] Remote Spy / Hook Detected: " .. tostring(reason))
    if typeof(onDetectCallback) == "function" then
        pcall(onDetectCallback, reason)
    end
end

local function getRawMT()
    return (getrawmetatable or getmetatable)(game)
end

-- ==================== DETECTIONS ====================

local function detectGCLeak()
    print("[ANTI-SPY] Running GC Leak Check...")
    local remote = Instance.new("RemoteEvent")
    remote.Parent = game:GetService("ReplicatedStorage")
    local big = {} for i=1,300 do big = {big} end
    
    for i=1,4 do
        local old = gcinfo()
        pcall(function() remote:FireServer(big) end)
        local diff = gcinfo() - old
        print("[ANTI-SPY] GC Diff:", diff)
        if diff > 60 then
            flagSpy("GC Leak - Spy detected")
            break
        end
        task.wait(0.1)
    end
    remote:Destroy()
end

local function detectFunctionWrapping()
    print("[ANTI-SPY] Running Function Wrapping Check...")
    local a,b = Instance.new("RemoteEvent"), Instance.new("RemoteEvent")
    print("FireServer A == B?", a.FireServer == b.FireServer)
    if a.FireServer ~= b.FireServer then
        flagSpy("FireServer wrapping detected")
    end
    a:Destroy() b:Destroy()
end

local function detectNamecallInterception()
    print("[ANTI-SPY] Running Namecall Check...")
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
    
    print("[ANTI-SPY] Namecall Result - Success:", s, "| Error:", err)
    if s or (err and not err:lower():find("instance") and not err:lower():find("table")) then
        flagSpy("Namecall interception detected")
    end
end

local function detectHookOverhead()
    print("[ANTI-SPY] Running Overhead Check...")
    local function bench(n)
        local t = os.clock()
        for i=1,n do pcall(function() game:IsA("DataModel") end) end
        return (os.clock()-t)*1000
    end
    local base = bench(2000)
    local hooked = bench(2000)
    print("[ANTI-SPY] Base time:", base, "| Hooked time:", hooked)
    if hooked > base * 2.5 then
        flagSpy("Namecall hook overhead")
    end
end

local function runAll()
    print("🔍 [ANTI-SPY] Starting Full Detection Sweep...")
    pcall(detectGCLeak)
    pcall(detectFunctionWrapping)
    pcall(detectNamecallInterception)
    pcall(detectHookOverhead)
    print("🔍 [ANTI-SPY] Detection Sweep Finished")
end

-- ==================== LIBRARY API ====================

function Library:setOnDetect(callback)
    if typeof(callback) == "function" then
        onDetectCallback = callback
        print("✅ onDetect callback registered")
    end
end

function Library:run()
    runAll()
end

function Library:runPeriodic(interval)
    interval = interval or 15
    task.spawn(function()
        while true do
            task.wait(interval + math.random(3,12))
            pcall(runAll)
        end
    end)
end

Library:runPeriodic(15)
warn("✅ Anti-Spy Library Loaded (Debug Mode)")
return Library
