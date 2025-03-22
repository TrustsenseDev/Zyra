local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local char, root, humanoid = player.Character or player.CharacterAdded:Wait(), player.Character:WaitForChild("HumanoidRootPart", 10), player.Character:WaitForChild("Humanoid", 10)
local backpack = player.Backpack

local GameSettings = {
    ["AutoFarm"] = false,
    ["FarmSpeed"] = 0.1,

    ["AutoDupe"] = false,
    ["AutoDupeSpeed"] = 0.1,
    ["Limit"] = false,
    ["DupeLimit"] = 800,

    ["WalkSpeedHack"] = false,
    ["WalkSpeed"] = 16,

    ["JumpPowerHack"] = false,
    ["JumpPower"] = 50,

    ["HideMuscleGain"] = false,
    ["HideHud"] = false,

    ["InSafeZone"] = false,

    ["DynamicFarmSpeed"] = true,
    ["MinFarmSpeed"] = 0.1,
    ["MaxFarmSpeed"] = 1
}

local statsTracker = {} do
    statsTracker.startTime = nil
    statsTracker.startStrength = player.leaderstats.Strength.Value
    statsTracker.currentStrength = player.leaderstats.Strength.Value
    statsTracker.totalStrength = ReplicatedStorage.Data[player.Name].Strength.Value

    function statsTracker:update()
        self.currentStrength = player.leaderstats.Strength.Value
        self.totalStrength = ReplicatedStorage.Data[player.Name].Strength.Value
        if not self.startTime then
            self.startTime = os.clock()
        end
    end

    function statsTracker:getElapsedTime()
        return self.startTime and (os.clock() - self.startTime) or 0
    end

    function statsTracker:getStrengthGained()
        return math.floor(self.currentStrength - self.startStrength)
    end

    function statsTracker:getSPS()
        local elapsedTime = self:getElapsedTime()
        if elapsedTime < 0.001 then return 0 end
        return math.floor(self:getStrengthGained() / elapsedTime)
    end

    function statsTracker:getSPH()
        return math.floor(self:getSPS() * 3600)
    end

    function statsTracker:getSPD()
        return math.floor(self:getSPH() * 24)
    end

    function statsTracker:getSPW()
        return math.floor(self:getSPD() * 7)
    end
end

local performanceTracker = {} do
    local lastUpdateTime = os.clock()
    local frameCount = 0
    local currentFPS = 0

    function performanceTracker:getCurrentFPS()
        frameCount = frameCount + 1
        local currentTime = os.clock()
        local timeDiff = currentTime - lastUpdateTime

        if timeDiff >= 1 then
            currentFPS = math.floor(frameCount / timeDiff)
            frameCount = 0
            lastUpdateTime = currentTime
        end

        return currentFPS
    end
end

local Kit = {} do
    function Kit:equipAndActivate()
        if humanoid.Health <= 0 then
            return
        end

        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                item.Parent = char
                item:Activate()
            end
        end

        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") then
                item:Activate()
            end
        end
    end

    function Kit:countTools()
        local count = 0

        for _, item in ipairs(backpack:GetChildren()) do
            if not item:IsA("Tool") then continue end
            count += 1
        end

        for _, item in ipairs(char:GetChildren()) do
            if not item:IsA("Tool") then continue end
            count += 1
        end

        return count
    end

    function Kit:Dupe()
        MarketplaceService:SignalPromptGamePassPurchaseFinished(player, 5949054, true)
    end

    function Kit:toggleGain(value)
        player.PlayerGui.HUD.Frame.MuscleGain.Visible = not value
    end

    function Kit:fpsBoost(value)
        if not value then
            settings().Rendering.QualityLevel = 0
            settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level02
            settings().Rendering.EagerBulkExecution = true
            return
        end

        settings().Rendering.QualityLevel = 1
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
        settings().Rendering.EagerBulkExecution = false

        UserSettings():GetService("UserGameSettings").SavedQualityLevel = 1

        local lighting = game:GetService("Lighting")
        lighting.GlobalShadows = false
        lighting.ShadowSoftness = 0
        lighting.Technology = Enum.Technology.Compatibility
        lighting.FogStart = 100000
        lighting.FogEnd = 100000

        for _, v in game:GetDescendants() do
            if v:IsA("BasePart") then
                v.Material = Enum.Material.SmoothPlastic
                v.Color = Color3.new(1, 1, 1)
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Enabled = false
            elseif v:IsA("Explosion") then
                v.Visible = false
            elseif v:IsA("SpecialMesh") and v.Parent.Name ~= "Water" then
                v.MeshType = Enum.MeshType.Brick
                if v:FindFirstChild("TextureId") then
                    v.TextureId = ""
                end
            elseif v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
                v.Enabled = false
            elseif v:IsA("SurfaceAppearance") then
                v:Destroy()
            elseif v:IsA("Clothing") or v:IsA("ShirtGraphic") then
                v:Destroy()
            end
        end

        settings().Network.IncomingReplicationLag = 0

        for _, user in Players:GetPlayers() do
            local character = user.Character
            if not character then continue end
            local animate = character:FindFirstChild("Animate")
            if animate then
                animate.Disabled = true
            end
            for _, part in character:GetDescendants() do
                if part:IsA("BasePart") then
                    part.Material = Enum.Material.SmoothPlastic
                    part.Color = Color3.new(1, 1, 1)
                elseif part:IsA("Decal") or part:IsA("Texture") then
                    part.Transparency = 1
                elseif part:IsA("SpecialMesh") and part.Parent.Name ~= "Water" then
                    if part:FindFirstChild("TextureId") then
                        part.TextureId = ""
                    end
                end
            end
        end
    end

    function Kit:DisableRumble()
        ReplicatedFirst.TourneyQ:Destroy()
    end

    function Kit:ToggleHud(value)
        player.PlayerGui.HUD.Enabled = not value
    end

    function Kit:CreateSafeZone()
        local safeZone = Instance.new("Part")
        safeZone.Name = "SafeZone"
        safeZone.Anchored = true
        safeZone.Size = Vector3.new(1000, 1, 1000)
        safeZone.Position = Vector3.new(10000, 1000, 10000)
        safeZone.Parent = workspace
        return safeZone
    end

    function Kit:TeleportToSafeZone(value)
        local safeZone = workspace:FindFirstChild("SafeZone") or Kit:CreateSafeZone()
        if not root then return end

        root.CFrame = safeZone.CFrame * CFrame.new(0, 100, 0)
        root.Anchored = value
    end

    function Kit:calculateDynamicFarmSpeed()
        local toolCount = Kit:countTools()
        local currentFPS = performanceTracker:getCurrentFPS()
        local playerPing = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()

        local baseSpeed = 0.1
        local speedFactor = math.max(currentFPS / 30, 0.1)
        local weightFactor = math.max(1 - (toolCount / 1000), 0.1)
        local pingFactor = math.min(playerPing / 1000, 1)

        local dynamicSpeed = baseSpeed + (GameSettings["MaxFarmSpeed"] - baseSpeed) * pingFactor * weightFactor * (1 - speedFactor)

        return math.clamp(dynamicSpeed, GameSettings["MinFarmSpeed"], GameSettings["MaxFarmSpeed"])
    end

    function Kit:startAutoFarm()
        local function isHealthy()
            return humanoid and humanoid.Health > humanoid.MaxHealth * 0.75
        end

        local function isLowHealth()
            return humanoid and humanoid.Health <= humanoid.MaxHealth * 0.5
        end

        while task.wait() and GameSettings["AutoFarm"] do
            if not humanoid or humanoid.Health <= 0 then
                char, root, humanoid = player.CharacterAdded:Wait(), nil, nil
                root = char:WaitForChild("HumanoidRootPart")
                humanoid = char:WaitForChild("Humanoid")
                backpack = player.Backpack
            end

            if isLowHealth() then
                repeat
                    task.wait(0.1)
                until isHealthy()
            end

            if GameSettings["DynamicFarmSpeed"] then
                GameSettings["FarmSpeed"] = Kit:calculateDynamicFarmSpeed()
            end

            Kit:equipAndActivate()
            task.wait(GameSettings["FarmSpeed"])
        end
    end
end

-- UI Library Setup
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

-- UI Settings
local Options = Library.Options
local Toggles = Library.Toggles

-- Create Window
local Window = Library:CreateWindow({
    Title = "Box Simulator 2",
    Footer = "v1.0",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

-- Create Tabs
local Tabs = {
    Main = Window:AddTab("Main", "dumbbell"),
    Misc = Window:AddTab("Misc", "settings"),
    Stats = Window:AddTab("Stats", "cloud"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

-- Main Tab
local LiftingGroup = Tabs.Main:AddLeftGroupbox("Lifting")

-- Auto Farm Toggle
LiftingGroup:AddToggle("AutoFarm", {
    Text = "Auto Farm",
    Default = GameSettings["AutoFarm"],
    Tooltip = "Automatically lifts weights for you",
    Callback = function(Value)
        GameSettings["AutoFarm"] = Value
        
        if Value then
            Kit:startAutoFarm()
        end
    end,
})

-- Min Farm Speed Slider
LiftingGroup:AddSlider("MinFarmSpeed", {
    Text = "Min Farm Speed",
    Default = GameSettings["MinFarmSpeed"],
    Min = 0.1,
    Max = 3,
    Rounding = 2,
    Tooltip = "Minimum delay between lifts when using dynamic speed",
    Callback = function(Value)
        GameSettings["MinFarmSpeed"] = Value
    end,
})

-- Max Farm Speed Slider
LiftingGroup:AddSlider("MaxFarmSpeed", {
    Text = "Max Farm Speed",
    Default = GameSettings["MaxFarmSpeed"],
    Min = 0.1,
    Max = 20,
    Rounding = 2,
    Tooltip = "Maximum delay between lifts when using dynamic speed",
    Callback = function(Value)
        GameSettings["MaxFarmSpeed"] = Value
    end,
})

-- Dynamic Farm Speed Toggle
LiftingGroup:AddToggle("DynamicFarmSpeed", {
    Text = "Dynamic Farm Speed",
    Default = GameSettings["DynamicFarmSpeed"],
    Tooltip = "Automatically adjusts farm speed based on performance",
    Callback = function(Value)
        GameSettings["DynamicFarmSpeed"] = Value
    end,
})

-- Farm Speed Label
local FarmSpeedLabel = LiftingGroup:AddLabel("Farm Speed: 0.1")

-- Update Farm Speed Label
task.spawn(function()
    while task.wait(0.5) do
        if GameSettings["DynamicFarmSpeed"] and GameSettings["AutoFarm"] then
            local currentSpeed = string.format("%.2f", GameSettings["FarmSpeed"])
            FarmSpeedLabel:SetText("Farm Speed: " .. currentSpeed)
        end
    end
end)

-- Dupe Group
local DupeGroup = Tabs.Main:AddRightGroupbox("Dupe")

-- Auto Dupe Toggle
DupeGroup:AddToggle("AutoDupe", {
    Text = "Auto Dupe",
    Default = GameSettings["AutoDupe"],
    Tooltip = "Automatically duplicates weights",
    Callback = function(Value)
        GameSettings["AutoDupe"] = Value
        
        task.spawn(function()
            while task.wait(GameSettings["AutoDupeSpeed"]) and GameSettings["AutoDupe"] do
                if GameSettings["Limit"] and Kit:countTools() >= GameSettings["DupeLimit"] then
                    break
                end
                Kit:Dupe()
            end
        end)
    end,
})

-- Dupe Speed Slider
DupeGroup:AddSlider("DupeSpeed", {
    Text = "Dupe Speed",
    Default = GameSettings["AutoDupeSpeed"],
    Min = 0,
    Max = 1,
    Rounding = 1,
    Tooltip = "Delay between duplications",
    Callback = function(Value)
        GameSettings["AutoDupeSpeed"] = Value
    end,
})

-- Limit Dupe Toggle
DupeGroup:AddToggle("LimitDupe", {
    Text = "Limit Dupe",
    Default = GameSettings["Limit"],
    Tooltip = "Stops duping after reaching the limit",
    Callback = function(Value)
        GameSettings["Limit"] = Value
    end,
})

-- Dupe Limit Slider
DupeGroup:AddSlider("DupeLimit", {
    Text = "Dupe Limit",
    Default = GameSettings["DupeLimit"],
    Min = 0,
    Max = 5000,
    Rounding = 0,
    Tooltip = "Maximum number of weights to duplicate",
    Callback = function(Value)
        GameSettings["DupeLimit"] = Value
    end,
})

-- Weights Count Label
local WeightsCountLabel = DupeGroup:AddLabel("Weights: 0")

-- Update Weights Count Label
task.spawn(function()
    while task.wait(0.5) do
        WeightsCountLabel:SetText("Weights: " .. Kit:countTools())
    end
end)

-- Safe Zone Group
local SafeZoneGroup = Tabs.Main:AddLeftGroupbox("Safe Zone")

-- TP Safe Zone Toggle
SafeZoneGroup:AddToggle("SafeZone", {
    Text = "TP Safe Zone",
    Default = GameSettings["InSafeZone"],
    Tooltip = "Teleports you to a safe zone",
    Callback = function(Value)
        GameSettings["InSafeZone"] = Value
        
        task.spawn(function()
            while task.wait() and GameSettings["InSafeZone"] do
                Kit:TeleportToSafeZone(Value)
            end
        end)
    end,
})

-- Walkspeed Hook
local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, index)
    if not checkcaller() and self == humanoid and index == "WalkSpeed" then
        return 16
    end
    return oldIndex(self, index)
end)

-- Misc Tab
local FPSBoostGroup = Tabs.Misc:AddLeftGroupbox("FPS Boost")

-- Hide Muscle Gain Toggle
FPSBoostGroup:AddToggle("HideMuscleGain", {
    Text = "Hide Muscle Gain",
    Default = GameSettings["HideMuscleGain"],
    Tooltip = "Hides the muscle gain UI",
    Callback = function(Value)
        GameSettings["HideMuscleGain"] = Value
        
        task.spawn(function()
            while task.wait() and GameSettings["HideMuscleGain"] do
                Kit:toggleGain(Value)
            end
        end)
    end,
})

-- Hide HUD Toggle
FPSBoostGroup:AddToggle("HideHud", {
    Text = "Hide HUD",
    Default = GameSettings["HideHud"],
    Tooltip = "Hides the game HUD",
    Callback = function(Value)
        GameSettings["HideHud"] = Value
        
        task.spawn(function()
            while task.wait() and GameSettings["HideHud"] do
                Kit:ToggleHud(Value)
            end
        end)
    end,
})

-- FPS Boost Toggle
FPSBoostGroup:AddToggle("FPSBoost", {
    Text = "FPS Boost",
    Default = false,
    Tooltip = "Boosts FPS by reducing graphics",
    Callback = function(Value)
        Kit:fpsBoost(Value)
    end,
})

-- Disable Rumble Button
FPSBoostGroup:AddButton({
    Text = "Disable Rumble",
    Func = function()
        Kit:DisableRumble()
    end,
    Tooltip = "Disables screen shake effects",
})

-- Movement Group
local MovementGroup = Tabs.Misc:AddRightGroupbox("Movement")

-- WalkSpeed Hack Toggle
MovementGroup:AddToggle("WalkSpeedHack", {
    Text = "WalkSpeed Hack",
    Default = GameSettings["WalkSpeedHack"],
    Tooltip = "Modifies your walking speed",
    Callback = function(Value)
        GameSettings["WalkSpeedHack"] = Value
        
        task.spawn(function()
            while task.wait() and GameSettings["WalkSpeedHack"] do
                if humanoid then
                    humanoid.WalkSpeed = GameSettings["WalkSpeed"]
                end
            end
        end)
    end,
})

-- WalkSpeed Slider
MovementGroup:AddSlider("WalkSpeed", {
    Text = "WalkSpeed",
    Default = GameSettings["WalkSpeed"],
    Min = 0,
    Max = 200,
    Rounding = 0,
    Tooltip = "Sets your walking speed",
    Callback = function(Value)
        GameSettings["WalkSpeed"] = Value
    end,
})

-- JumpPower Hack Toggle
MovementGroup:AddToggle("JumpPowerHack", {
    Text = "JumpPower Hack",
    Default = GameSettings["JumpPowerHack"],
    Tooltip = "Modifies your jump height",
    Callback = function(Value)
        GameSettings["JumpPowerHack"] = Value
        
        task.spawn(function()
            while task.wait() and GameSettings["JumpPowerHack"] do
                if humanoid then
                    humanoid.JumpPower = GameSettings["JumpPower"]
                end
            end
        end)
    end,
})

-- JumpPower Slider
MovementGroup:AddSlider("JumpPower", {
    Text = "JumpPower",
    Default = GameSettings["JumpPower"],
    Min = 0,
    Max = 200,
    Rounding = 0,
    Tooltip = "Sets your jump height",
    Callback = function(Value)
        GameSettings["JumpPower"] = Value
    end,
})

-- Stats Tab
local StatsTrackerGroup = Tabs.Stats:AddLeftGroupbox("Tracker")

-- Stat Labels
local StrengthGainedLabel = StatsTrackerGroup:AddLabel("Gained: 0")
local SPSLabel = StatsTrackerGroup:AddLabel("SPS: 0")
local SPHLabel = StatsTrackerGroup:AddLabel("SPH: 0")
local SPDLabel = StatsTrackerGroup:AddLabel("SPD: 0")
local SPWLabel = StatsTrackerGroup:AddLabel("SPW: 0")

-- Format large numbers
local function formatNumber(num)
    local suffixes = {
        {1e12, "T"},
        {1e9, "B"},
        {1e6, "M"},
        {1e3, "K"}
    }

    for _, pair in ipairs(suffixes) do
        local threshold, suffix = table.unpack(pair)
        if num < threshold then continue end
        return string.format("%.2f%s", num / threshold, suffix)
    end

    return tostring(num)
end

-- Update Stats
task.spawn(function()
    while task.wait(1) do
        statsTracker:update()
        
        StrengthGainedLabel:SetText("Gained: " .. formatNumber(statsTracker:getStrengthGained()))
        SPSLabel:SetText("SPS: " .. formatNumber(statsTracker:getSPS()))
        SPHLabel:SetText("SPH: " .. formatNumber(statsTracker:getSPH()))
        SPDLabel:SetText("SPD: " .. formatNumber(statsTracker:getSPD()))
        SPWLabel:SetText("SPW: " .. formatNumber(statsTracker:getSPW()))
    end
end)

-- Performance Group
local PerformanceGroup = Tabs.Stats:AddRightGroupbox("Performance")

-- FPS Label
local FPSLabel = PerformanceGroup:AddLabel("FPS: 0")

-- Update FPS
RunService.RenderStepped:Connect(function()
    FPSLabel:SetText("FPS: " .. performanceTracker:getCurrentFPS())
end)

-- UI Settings Tab
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")

-- Menu Settings
MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = true,
    Text = "Open Keybind Menu",
    Callback = function(Value)
        Library.KeybindFrame.Visible = Value
    end,
})

MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = true,
    Callback = function(Value)
        Library.ShowCustomCursor = Value
    end,
})

MenuGroup:AddDropdown("NotificationSide", {
    Values = { "Left", "Right" },
    Default = "Right",
    Text = "Notification Side",
    Callback = function(Value)
        Library:SetNotifySide(Value)
    end,
})

MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { 
    Default = "RightShift", 
    NoUI = true, 
    Text = "Menu keybind" 
})

MenuGroup:AddButton({
    Text = "Unload",
    Func = function()
        Library:Unload()
    end,
})

Library.ToggleKeybind = Options.MenuKeybind

-- Theme Manager & Save Manager
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("BoxSim2")
SaveManager:SetFolder("BoxSim2/configs")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()

-- Anti-AFK
player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- Character Added Handler
player.CharacterAdded:Connect(function(character)
    char, root, humanoid = character, character:WaitForChild("HumanoidRootPart"), character:WaitForChild("Humanoid")
    backpack = player.Backpack

    if GameSettings["AutoFarm"] then
        Kit:startAutoFarm()
    end
end)
