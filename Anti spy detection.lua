-- =============================================
-- ANTI-SPY LIBRARY - CONTINUOUS CHECKING
-- =============================================

local AntiSpy = {
    Enabled = true,
    Detected = false,
    OnDetected = nil,
    Interval = 4
}

local function flagSpy(reason)
    warn("🚨 [ANTI-SPY] Remote Spy Detected: " .. reason)
    
    if not AntiSpy.Detected and typeof(AntiSpy.OnDetected) == "function" then
        AntiSpy.Detected = true
        pcall(AntiSpy.OnDetected)
    end
end

local function getRawMT()
    return (getrawmetatable or getmetatable)(game)
end

-- ==================== DETECTIONS ====================

local function detectArtifacts()
    local strictSigns = {"SimpleSpy", "SimpleSpyV3", "RemoteSpy", "hydroxide", "cobaltspy"}
    for _, s in ipairs(strictSigns) do
        if _G[s] or getgenv()[s] or game:FindFirstChild(s, true) then
            flagSpy("Known Spy Artifact: " .. s)
            return
        end
    end
end

local function detectGCLeak()
    local remote = Instance.new("RemoteEvent")
    remote.Parent = game:GetService("ReplicatedStorage")
    
    local big = {} 
    for i = 1, 400 do big = {big} end

    local maxDiff = 0
    for _ = 1, 4 do
        local old = gcinfo()
        pcall(function() remote:FireServer(big) end)
        local diff = gcinfo() - old
        maxDiff = math.max(maxDiff, diff)
        task.wait(0.08)
    end
    
    if maxDiff > 85 then
        flagSpy("GC Memory Leak - Spy detected")
    end
    remote:Destroy()
end

local function detectNamecallHook()
    local mt = getRawMT()
    local fake = setmetatable({}, {
        __index = function(_, k)
            if type(k) == "string" and (k:find("Fire") or k:find("ClassName")) then
                -- silent
            end
            return nil
        end
    })

    local success, err = pcall(function()
        mt.__namecall(fake, "FireServer", "bait_test")
    end)

    if success or (err and not err:lower():find("instance") and not err:lower():find("table")) then
        flagSpy("Namecall Hook Detected")
    end
end

local function detectFunctionWrapping()
    local r1 = Instance.new("RemoteEvent")
    local r2 = Instance.new("RemoteEvent")
    if r1.FireServer ~= r2.FireServer then
        flagSpy("FireServer Wrapping Detected")
    end
    r1:Destroy() r2:Destroy()
end

local function runAll()
    if not AntiSpy.Enabled then return end
    pcall(detectArtifacts)
    pcall(detectGCLeak)
    pcall(detectNamecallHook)
    pcall(detectFunctionWrapping)
end

-- Continuous Background Checking (Never stops)
task.spawn(function()
    while AntiSpy.Enabled do
        task.wait(AntiSpy.Interval)
        pcall(runAll)
    end
end)

print("🛡️ Anti-Spy Loaded - Continuous Mode")
return AntiSpy
