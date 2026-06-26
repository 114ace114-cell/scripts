-- Anti-Spy Detector (返回控制对象版本)
local AntiSpy = {}

AntiSpy.Enabled = true
AntiSpy.Interval = 2.5
AntiSpy.Detected = false
AntiSpy.OnDetected = nil  -- 你可以在这里设置回调函数

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 蜜罐
local bait = newproxy(true)
local mt = getmetatable(bait)
mt.__tostring = function() return "AntiSpy_Bait" end
mt.__index = function() return nil end
mt.__namecall = function() return nil end

local testRemote = Instance.new("RemoteEvent")
testRemote.Name = "AntiSpyTest_" .. math.random(100000,999999)
testRemote.Parent = ReplicatedStorage

local function detectSpyInStack(err)
    if not err then return false end
    local lower = err:lower()
    local signs = {"simplespy","spy","remotespy","namecallhook","hookmetamethod","__namecall"}
    for _, s in ipairs(signs) do
        if lower:find(s) then return true end
    end
    local _, lines = err:gsub("\n","")
    return lines >= 14
end

task.spawn(function()
    while AntiSpy.Enabled and not AntiSpy.Detected do
        task.wait(AntiSpy.Interval)
        
        pcall(function() testRemote:FireServer(bait) end)
        
        pcall(function()
            local gmt = getrawmetatable(game)
            if gmt and gmt.__namecall then
                local success, err = pcall(gmt.__namecall, bait, "FireServer", testRemote, bait)
                if not success and detectSpyInStack(err) then
                    AntiSpy.Detected = true
                    warn("🚨 [ANTI-SPY] 远程间谍已被检测！")
                    if AntiSpy.OnDetected then
                        AntiSpy.OnDetected()
                    end
                end
            end
        end)
        
        pcall(function()
            if _G.SimpleSpy or getgenv().SimpleSpy then
                AntiSpy.Detected = true
                if AntiSpy.OnDetected then AntiSpy.OnDetected() end
            end
        end)
    end
end)

print("🛡️ Anti-Spy 已加载")
return AntiSpy

-- use case
local AntiSpy = loadstring(game:HttpGet("你的链接"))()   -- 或直接 loadstring([[ ... ]])()

-- -- 设置检测到后的处理方式
-- AntiSpy.OnDetected = function()
--     print("🚨 间谍检测到！正在执行保护措施...")
    
--     -- 这里写你想做的处理：
--     getgenv().SPY_DETECTED = true

-- end