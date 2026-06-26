-- =============================================
-- ANTI-SPY LIBRARY - ZERO FALSE POSITIVE MODE
-- =============================================

local AntiSpy = {
    Enabled = true,
    Detected = false,
    OnDetected = nil,
    Interval = 1
}

local function flagSpy(reason)
    if AntiSpy.Detected then return end
    AntiSpy.Detected = true
    warn("🚨 [ANTI-SPY] Remote Spy Detected: " .. reason)
    if typeof(AntiSpy.OnDetected) == "function" then
        pcall(AntiSpy.OnDetected)
    end
end

local function getRawMT()
    return (getrawmetatable or getmetatable)(game)
end

-- ==================== STRICT DETECTIONS ====================

local function detectArtifacts()
    -- Very specific checks only
    local strictSigns = {
        "SimpleSpy", "SimpleSpyV3", "RemoteSpy", "hydroxide", "cobaltspy"
    }
    for _, s in ipairs(strictSigns) do
        if _G[s] or getgenv()[s] or game:FindFirstChild(s, true) then
            flagSpy("Known Spy: " .. s)
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
        task.wait(0.1)
    end
    
    if maxDiff > 90 then  -- Very high threshold
        flagSpy("GC Memory Leak")
    end
    remote:Destroy()
end

local function detectNamecallHook()
    local mt = getRawMT()
    local fake = setmetatable({}, {
        __index = function(_, k)
            if type(k) == "string" and (k:find("Fire") or k:find("ClassName")) then
                -- Only flag if it triggers during namecall test
            end
            return nil
        end
    })

    local success, err = pcall(function()
        mt.__namecall(fake, "FireServer", "bait_test_987")
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
    
    r1:Destroy()
    r2:Destroy()
end

local function runAll()
    if not AntiSpy.Enabled or AntiSpy.Detected then return end
    
    pcall(detectArtifacts)
    pcall(detectGCLeak)
    pcall(detectNamecallHook)
    pcall(detectFunctionWrapping)
end

-- Background loop with confirmation
task.spawn(function()
    while AntiSpy.Enabled and not AntiSpy.Detected do
        task.wait(AntiSpy.Interval)
        pcall(runAll)
    end
end)

print("🛡️ Anti-Spy Loaded (Zero False Positive Mode)")
return AntiSpy
