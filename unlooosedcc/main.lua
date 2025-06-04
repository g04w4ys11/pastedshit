
if not syn or not protectgui then
    getgenv().protectgui = function() end
end

-- Settings
local SilentAimSettings = {
    Enabled = false,
    AutoShoot = true,
    CPS = 15,
    ClassName = "unloosed",
    TeamCheck = false,
    VisibleCheck = false, 
    TargetPart = "Head",
    SilentAimMethod = "Raycast",
    FOVRadius = 70,
    FOVVisible = true,
    ShowSilentAimTarget = false,
    MouseHitPrediction = false,
    MouseHitPredictionAmount = 0.165,
    HitChance = 100
}

local AntiAimSettings = {
    Enabled = false,
    Yaw = 0,
    Pitch = 0,
    Roll = 0,
    Mode = "Static",
    FakeLag = false,
    Desync = false,
    LastUpdate = 0,
    UpdateInterval = 0.1
}

local DashSettings = {
    DashKey = "V",
    DashSpeed = 100.0,
    DashDuration = 0.2,
    DashCooldown = 2.0,
    DashEnabled = true
}

local FlySettings = {
    Enabled = false,
    FlyKey = "T",
    Cooldown = 1
}

local NoclipSettings = {
    Enabled = false
}

local AntiDeathSettings = {
    Enabled = false
}

local JumpStunSettings = {
    Enabled = false
}

local HUDSettings = {
    ShowKeybindsHUD = true
}

local ESPSettings = {
    Enabled = false
}

-- Variables
getgenv().SilentAimSettings = SilentAimSettings
getgenv().AntiAimSettings = AntiAimSettings
getgenv().DashSettings = DashSettings
getgenv().FlySettings = FlySettings
getgenv().NoclipSettings = NoclipSettings
getgenv().AntiDeathSettings = AntiDeathSettings
getgenv().JumpStunSettings = JumpStunSettings
getgenv().HUDSettings = HUDSettings
getgenv().ESPSettings = ESPSettings
local LastDashTime = 0
local IsDashing = false
local LastShotTime = 0
local VisibleCheckCache = {}
local CacheDuration = 0.3
local FlyV2Instance = nil
local ESPInstance = nil
local lastFlyActivation = 0
local NoclipConnection = nil
local Clipon = false

local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local GetChildren = game.GetChildren
local GetPlayers = Players.GetPlayers
local WorldToScreen = Camera.WorldToScreenPoint
local WorldToViewportPoint = Camera.WorldToViewportPoint
local FindFirstChild = game.FindFirstChild
local RenderStepped = RunService.RenderStepped
local GuiInset = GuiService.GetGuiInset
local GetMouseLocation = UserInputService.GetMouseLocation

local resume = coroutine.resume 
local create = coroutine.create

local ValidTargetParts = {"Head"}
local PredictionAmount = 0.165

-- Convert degrees to pixels for FOV
local function degreesToPixels(degrees)
    local cameraFOV = Camera.FieldOfView
    local screenHeight = Camera.ViewportSize.Y
    local radians = math.rad(degrees / 2)
    local cameraFOVRad = math.rad(cameraFOV / 2)
    return math.tan(radians) * (screenHeight / (2 * math.tan(cameraFOVRad)))
end

-- Drawing objects
local mouse_box = Drawing.new("Square")
mouse_box.Visible = false 
mouse_box.ZIndex = 999 
mouse_box.Color = Color3.fromRGB(54, 57, 241)
mouse_box.Thickness = 20 
mouse_box.Size = Vector2.new(20, 20)
mouse_box.Filled = true 

local fov_circle = Drawing.new("Circle")
fov_circle.Thickness = 1
fov_circle.NumSides = 100
fov_circle.Radius = degreesToPixels(SilentAimSettings.FOVRadius)
fov_circle.Filled = false
fov_circle.Visible = false
fov_circle.ZIndex = 999
fov_circle.Transparency = 1
fov_circle.Color = Color3.fromRGB(54, 57, 241)

-- Check Drawing API
if not _G.Drawing then
    warn("Drawing API is not available.")
end

local ExpectedArguments = {
    Raycast = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Vector3", "Vector3", "RaycastParams"
        }
    }
}

-- Tokyo UI Library
local Decimals = 4
local Clock = os.clock()

local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/drillygzzly/Roblox-UI-Libs/main/1%20Tokyo%20Lib%20(FIXED)/Tokyo%20Lib%20Source.lua"))({
    cheatname = "unloosed.cc",
    gamename = "unloosed.cc",
})

library:init()

local Window1 = library.NewWindow({
    title = "unloosed.cc | private",
    size = UDim2.new(0, 510, 0.6, 60)
})

local ExploitsTab = Window1:AddTab("Exploits")
local AimbotTab = Window1:AddTab("Aimbot")
local AntiAimTab = Window1:AddTab("Anti Aim")
local MovementTab = Window1:AddTab("Movement")
local VisualsTab = Window1:AddTab("Visuals")
local SettingsTab = library:CreateSettingsTab(Window1)

-- Exploits Tab: Jump Stun, Anti-Death, FlyV2, and Noclip
local JumpStunSection = ExploitsTab:AddSection("Jump Stun", 1)
local AntiDeathSection = ExploitsTab:AddSection("Anti-Death", 2)
local FlySection = ExploitsTab:AddSection("FlyV2 (Bind only T)", 3)
local NoclipSection = ExploitsTab:AddSection("Noclip", 4)

JumpStunSection:AddToggle({
    text = "Enable Jump Stun",
    state = JumpStunSettings.Enabled,
    risky = true,
    tooltip = "Enable Jump Stun (Bind: B)",
    flag = "JumpStun_Enabled",
    callback = function(v)
        JumpStunSettings.Enabled = v
        if v then
            local success, err = pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/g04w4ys11/pastedshit/refs/heads/main/unlooosedcc/assets/xd"))()
            end)
            if not success then
                warn("Jump Stun: Failed to load - " .. tostring(err))
                JumpStunSettings.Enabled = false
                JumpStunSection:FindFlag("JumpStun_Enabled"):Set(false)
                library:SendNotification("Jump Stun: Failed to load script - " .. tostring(err), 5)
            end
        end
    end
})

 AntiDeathSection:AddToggle({
    text = "Enable Anti-Death",
    state = AntiDeathSettings.Enabled,
    risky = true,
    tooltip = "Prevents death by resetting health",
    flag = "AntiDeath_Enabled",
    callback = function(v)
        AntiDeathSettings.Enabled = v
        if v then
            local success, err = pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/g04w4ys11/pastedshit/refs/heads/main/unlooosedcc/assets/shitp100"))()
            end)
            if not success then
                warn("Anti-Death: Failed to load - " .. tostring(err))
                AntiDeathSettings.Enabled = false
                AntiDeathSection:FindFlag("AntiDeath_Enabled"):Set(false)
                library:SendNotification("Anti-Death: Failed to load script - " .. tostring(err), 5)
            end
        end
    end
})

FlySection:AddToggle({
    text = "Enable FlyV2",
    state = FlySettings.Enabled,
    risky = true,
    tooltip = "Enable FlyV2 (Bind only T)",
    flag = "FlyV2_Enabled",
    callback = function(v)
        FlySettings.Enabled = v
        if v then
            if tick() - lastFlyActivation >= FlySettings.Cooldown then
                lastFlyActivation = tick()
                local success, err = pcall(function()
                    FlyV2Instance = loadstring(game:HttpGet("https://raw.githubusercontent.com/g04w4ys11/pastedshit/refs/heads/main/unlooosedcc/assets/pizdec"))()
                end)
                if not success then
                    warn("FlyV2: Failed to load - " .. tostring(err))
                    FlySettings.Enabled = false
                    FlySection:FindFlag("FlyV2_Enabled"):Set(false)
                    library:SendNotification("FlyV2: Failed to load script - " .. tostring(err), 5)
                end
            else
                FlySettings.Enabled = false
                FlySection:FindFlag("FlyV2_Enabled"):Set(false)
                library:SendNotification("FlyV2: Cooldown active, wait " .. string.format("%.1f", FlySettings.Cooldown - (tick() - lastFlyActivation)) .. "s", 3)
            end
        else
            if FlyV2Instance then
                local success, err = pcall(function()
                    if FlyV2Instance.Destroy then
                        FlyV2Instance:Destroy()
                    end
                    FlyV2Instance = nil
                end)
                if not success then
                    warn("FlyV2: Failed to unload - " .. tostring(err))
                    library:SendNotification("FlyV2: Failed to unload script - " .. tostring(err), 5)
                end
            end
        end
    end
})

NoclipSection:AddToggle({
    text = "Enable Noclip",
    state = NoclipSettings.Enabled,
    risky = true,
    tooltip = "Enable Noclip to pass through walls",
    flag = "Noclip_Enabled",
    callback = function(v)
        NoclipSettings.Enabled = v
        local success, err = pcall(function()
            if v then
                if not Clipon then
                    Clipon = true
                    NoclipConnection = RunService.Stepped:Connect(function()
                        if Clipon and LocalPlayer.Character then
                            for _, part in pairs(LocalPlayer.Character:GetChildren()) do
                                if part:IsA("BasePart") then
                                    part.CanCollide = false
                                end
                            end
                        else
                            if NoclipConnection then
                                NoclipConnection:Disconnect()
                                NoclipConnection = nil
                            end
                        end
                    end)
                end
            else
                Clipon = false
                if NoclipConnection then
                    NoclipConnection:Disconnect()
                    NoclipConnection = nil
                end
                -- Restore collision when Noclip is disabled
                if LocalPlayer.Character then
                    for _, part in pairs(LocalPlayer.Character:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = true
                        end
                    end
                end
            end
        end)
        if not success then
            warn("Noclip: Failed to toggle - " .. tostring(err))
            NoclipSettings.Enabled = false
            NoclipSection:FindFlag("Noclip_Enabled"):Set(false)
            library:SendNotification("Noclip: Failed to toggle - " .. tostring(err), 5)
        end
    end
})

-- Aimbot Tab: Aimbot
local AimbotSection = AimbotTab:AddSection("Aimbot", 1)

AimbotSection:AddToggle({
    text = "Enabled",
    state = false,
    risky = false,
    tooltip = "Enable Silent Aim",
    flag = "aim_Enabled",
    callback = function(v)
        SilentAimSettings.Enabled = v
        mouse_box.Visible = v and SilentAimSettings.ShowSilentAimTarget
    end
})

AimbotSection:AddToggle({
    text = "Auto Shoot",
    state = SilentAimSettings.AutoShoot,
    risky = false,
    tooltip = "Enable Auto Shoot",
    flag = "AutoShoot",
    callback = function(v)
        SilentAimSettings.AutoShoot = v
    end
})

AimbotSection:AddSlider({
    enabled = true,
    text = "Clicks Per Second",
    tooltip = "Set CPS for Auto Shoot",
    flag = "CPS",
    suffix = "",
    dragging = true,
    focused = false,
    min = 1,
    max = 30,
    increment = 1,
    risky = false,
    callback = function(v)
        SilentAimSettings.CPS = math.clamp(v, 1, 30)
    end
})

AimbotSection:AddToggle({
    text = "Team Check",
    state = SilentAimSettings.TeamCheck,
    risky = false,
    tooltip = "Check for team",
    flag = "TeamCheck",
    callback = function(v)
        SilentAimSettings.TeamCheck = v
    end
})

AimbotSection:AddToggle({
    text = "Visible Check",
    state = SilentAimSettings.VisibleCheck,
    risky = false,
    tooltip = "Check for visibility",
    flag = "VisibleCheck",
    callback = function(v)
        SilentAimSettings.VisibleCheck = v
    end
})

AimbotSection:AddList({
    enabled = true,
    text = "Target Part",
    tooltip = "Select target part",
    selected = SilentAimSettings.TargetPart,
    multi = false,
    open = false,
    max = 4,
    values = {"Head"},
    risky = false,
    callback = function(v)
        SilentAimSettings.TargetPart = v
    end
})

AimbotSection:AddList({
    enabled = true,
    text = "Silent Aim Method",
    tooltip = "Select aim method",
    selected = SilentAimSettings.SilentAimMethod,
    multi = false,
    open = false,
    max = 4,
    values = {"Raycast"},
    risky = false,
    callback = function(v)
        SilentAimSettings.SilentAimMethod = v
    end
})

AimbotSection:AddSlider({
    enabled = true,
    text = "Hit Chance",
    tooltip = "Set hit chance percentage",
    flag = "HitChance",
    suffix = "%",
    dragging = true,
    focused = false,
    min = 0,
    max = 100,
    increment = 1,
    risky = false,
    callback = function(v)
        SilentAimSettings.HitChance = v
    end
})

AimbotSection:AddToggle({
    text = "Mouse Hit Prediction",
    state = SilentAimSettings.MouseHitPrediction,
    risky = false,
    tooltip = "Enable mouse hit prediction",
    flag = "Prediction",
    callback = function(v)
        SilentAimSettings.MouseHitPrediction = v
    end
})

AimbotSection:AddSlider({
    enabled = true,
    text = "Prediction Amount",
    tooltip = "Set prediction amount",
    flag = "PredictionAmount",
    suffix = "",
    dragging = true,
    focused = false,
    min = 0.165,
    max = 1,
    increment = 0.001,
    risky = false,
    callback = function(v)
        SilentAimSettings.MouseHitPredictionAmount = v
        PredictionAmount = v
    end
})

-- Visuals Tab: Visuals for Silent Aim and ESP
local VisualsSection = VisualsTab:AddSection("Silent Aim Visuals", 1)
local ESPSection = VisualsTab:AddSection("ESP", 2)

VisualsSection:AddToggle({
    text = "Show FOV Circle",
    state = SilentAimSettings.FOVVisible,
    risky = false,
    tooltip = "Show FOV circle",
    flag = "FOVVisible",
    callback = function(v)
        SilentAimSettings.FOVVisible = v
        fov_circle.Visible = v
    end
}):AddColor({
    text = "FOV Color",
    color = Color3.fromRGB(54, 57, 241),
    flag = "FOVColor",
    callback = function(v)
        fov_circle.Color = v
    end
})

VisualsSection:AddSlider({
    enabled = true,
    text = "FOV Radius (Degrees)",
    tooltip = "Set FOV radius",
    flag = "FOVRadius",
    suffix = "",
    dragging = true,
    focused = false,
    min = 0,
    max = 2000,
    increment = 1,
    risky = false,
    callback = function(v)
        SilentAimSettings.FOVRadius = v
        fov_circle.Radius = degreesToPixels(v)
    end
})

VisualsSection:AddToggle({
    text = "Show Silent Aim Target",
    state = SilentAimSettings.ShowSilentAimTarget,
    risky = false,
    tooltip = "Show aim target",
    flag = "ShowSilentAimTarget",
    callback = function(v)
        SilentAimSettings.ShowSilentAimTarget = v
        mouse_box.Visible = v and SilentAimSettings.Enabled
    end
}):AddColor({
    text = "Target Color",
    color = Color3.fromRGB(54, 57, 241),
    flag = "MouseVisualizeColor",
    callback = function(v)
        mouse_box.Color = v
    end
})

VisualsSection:AddToggle({
    text = "Show Keybinds HUD",
    state = HUDSettings.ShowKeybindsHUD,
    risky = false,
    tooltip = "Show keybinds HUD",
    flag = "ShowKeybindsHUD",
    callback = function(v)
        HUDSettings.ShowKeybindsHUD = v
        UpdateKeybindsHUD()
    end
})

ESPSection:AddToggle({
    text = "Enable ESP",
    state = ESPSettings.Enabled,
    risky = true,
    tooltip = "Enable ESP for highlighting players",
    flag = "ESP_Enabled",
    callback = function(v)
        ESPSettings.Enabled = v
        if v then
            local success, err = pcall(function()
                ESPInstance = loadstring(game:HttpGet("https://raw.githubusercontent.com/g04w4ys11/pastedshit/refs/heads/main/unlooosedcc/assets/lmao"))()
            end)
            if not success then
                warn("ESP: Failed to load - " .. tostring(err))
                ESPSettings.Enabled = false
                ESPSection:FindFlag("ESP_Enabled"):Set(false)
                library:SendNotification("ESP: Failed to load script - " .. tostring(err), 5)
            end
        else
            if ESPInstance then
                local success, err = pcall(function()
                    if ESPInstance.Destroy then
                        ESPInstance:Destroy()
                    end
                    ESPInstance = nil
                end)
                if not success then
                    warn("ESP: Failed to unload - " .. tostring(err))
                    library:SendNotification("ESP: Failed to unload script - " .. tostring(err), 5)
                end
            end
        end
    end
})

-- Anti Aim Tab
local AntiAimSection = AntiAimTab:AddSection("Anti Aim", 1)

AntiAimSection:AddToggle({
    text = "Enable Anti Aim",
    state = AntiAimSettings.Enabled,
    risky = false,
    tooltip = "Enable Anti Aim",
    flag = "AntiAim_Enabled",
    callback = function(v)
        AntiAimSettings.Enabled = v
    end
})

AntiAimSection:AddSlider({
    enabled = true,
    text = "Yaw",
    tooltip = "Set yaw angle",
    flag = "Yaw",
    suffix = "",
    dragging = true,
    focused = false,
    min = -90,
    max = 90,
    increment = 1,
    risky = false,
    callback = function(v)
        AntiAimSettings.Yaw = v
    end
})

AntiAimSection:AddSlider({
    enabled = true,
    text = "Pitch",
    tooltip = "Set pitch angle",
    flag = "Pitch",
    suffix = "",
    dragging = true,
    focused = false,
    min = -90,
    max = 90,
    increment = 1,
    risky = false,
    callback = function(v)
        AntiAimSettings.Pitch = v
    end
})

AntiAimSection:AddSlider({
    enabled = true,
    text = "Roll",
    tooltip = "Set roll angle",
    flag = "Roll",
    suffix = "",
    dragging = true,
    focused = false,
    min = -45,
    max = 45,
    increment = 1,
    risky = false,
    callback = function(v)
        AntiAimSettings.Roll = v
    end
})

AntiAimSection:AddList({
    enabled = true,
    text = "Mode",
    tooltip = "Select Anti Aim mode",
    selected = AntiAimSettings.Mode,
    multi = false,
    open = false,
    max = 4,
    values = {"Static", "Jitter", "Random"},
    risky = false,
    callback = function(v)
        AntiAimSettings.Mode = v
    end
})

AntiAimSection:AddToggle({
    text = "Fake Lag",
    state = AntiAimSettings.FakeLag,
    risky = false,
    tooltip = "Enable fake lag",
    flag = "FakeLag",
    callback = function(v)
        AntiAimSettings.FakeLag = v
    end
})

AntiAimSection:AddToggle({
    text = "Desync",
    state = AntiAimSettings.Desync,
    risky = false,
    tooltip = "Enable desync",
    flag = "Desync",
    callback = function(v)
        AntiAimSettings.Desync = v
    end
})

-- Movement Tab
local MovementSection = MovementTab:AddSection("Movement", 1)

MovementSection:AddToggle({
    text = "Enable Dash",
    state = DashSettings.DashEnabled,
    risky = false,
    tooltip = "Enable dash",
    flag = "Dash_Enabled",
    callback = function(v)
        DashSettings.DashEnabled = v
    end
})

MovementSection:AddList({
    enabled = true,
    text = "Dash Key",
    tooltip = "Select dash key",
    selected = DashSettings.DashKey,
    multi = false,
    open = false,
    max = 4,
    values = {"V", "Q", "E"},
    risky = false,
    callback = function(v)
        DashSettings.DashKey = v
        UpdateKeybindsHUD()
    end
})

MovementSection:AddSlider({
    enabled = true,
    text = "Dash Speed",
    tooltip = "Set dash speed",
    flag = "DashSpeed",
    suffix = "",
    dragging = true,
    focused = false,
    min = 10,
    max = 100,
    increment = 1,
    risky = false,
    callback = function(v)
        DashSettings.DashSpeed = v
    end
})

MovementSection:AddSlider({
    enabled = true,
    text = "Dash Duration",
    tooltip = "Set dash duration",
    flag = "DashDuration",
    suffix = "s",
    dragging = true,
    focused = false,
    min = 0.1,
    max = 1.0,
    increment = 0.1,
    risky = false,
    callback = function(v)
        DashSettings.DashDuration = v
    end
})

MovementSection:AddSlider({
    enabled = true,
    text = "Dash Cooldown",
    tooltip = "Set dash cooldown",
    flag = "DashCooldown",
    suffix = "s",
    dragging = true,
    focused = false,
    min = 0.5,
    max = 5.0,
    increment = 0.1,
    risky = false,
    callback = function(v)
        DashSettings.DashCooldown = v
    end
})

-- Settings Tab
local SettingsSection = SettingsTab:AddSection("Settings", 1)

SettingsSection:AddButton({
    enabled = true,
    text = "Reset Settings",
    tooltip = "Reset all settings to default",
    confirm = true,
    risky = false,
    callback = function()
        if FlyV2Instance then
            if FlyV2Instance.Destroy then
                FlyV2Instance:Destroy()
            end
            FlyV2Instance = nil
        end
        FlySettings.Enabled = false
        if ESPInstance then
            if ESPInstance.Destroy then
                ESPInstance:Destroy()
            end
            ESPInstance = nil
        end
        ESPSettings.Enabled = false
        if NoclipConnection then
            NoclipConnection:Disconnect()
            NoclipConnection = nil
        end
        NoclipSettings.Enabled = false
        Clipon = false
        if LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
})

-- Dash Indicator
local DashGui = Instance.new("ScreenGui")
protectgui(DashGui)
DashGui.Name = "DashIndicatorGui"
DashGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
DashGui.ResetOnSpawn = false

local DashFrame = Instance.new("Frame")
DashFrame.Size = UDim2.new(0, 200, 0, 30)
DashFrame.Position = UDim2.new(0.5, -100, 0, 50)
DashFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
DashFrame.BorderSizePixel = 0
DashFrame.Active = true
DashFrame.Draggable = true
DashFrame.AnchorPoint = Vector2.new(0.5, 0)
DashFrame.Parent = DashGui

local DashFrameCorner = Instance.new("UICorner")
DashFrameCorner.CornerRadius = UDim.new(0, 6)
DashFrameCorner.Parent = DashFrame

local DashFrameStroke = Instance.new("UIStroke")
DashFrameStroke.Color = Color3.fromRGB(147, 112, 219)
DashFrameStroke.Thickness = 2
DashFrameStroke.Parent = DashFrame

local DashBar = Instance.new("Frame")
DashBar.Size = UDim2.new(1, 0, 0.5, 0)
DashBar.Position = UDim2.new(0, 0, 0, 0)
DashBar.BackgroundColor3 = Color3.fromRGB(147, 112, 219)
DashBar.BorderSizePixel = 0
DashBar.Parent = DashFrame

local DashLabel = Instance.new("TextLabel")
DashLabel.Size = UDim2.new(1, 0, 0.5, 0)
DashLabel.Position = UDim2.new(0, 0, 0.5, 0)
DashLabel.BackgroundTransparency = 1
DashLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
DashLabel.Text = "Dash: READY"
DashLabel.TextSize = 14
DashLabel.Font = Enum.Font.SourceSans
DashLabel.TextXAlignment = Enum.TextXAlignment.Center
DashLabel.Parent = DashFrame

-- Keybinds HUD
local KeybindsHUD = Instance.new("ScreenGui")
protectgui(KeybindsHUD)
KeybindsHUD.Name = "KeybindsHUD"
KeybindsHUD.Parent = LocalPlayer:WaitForChild("PlayerGui")
KeybindsHUD.ResetOnSpawn = false

local KeybindsFrame = Instance.new("Frame")
KeybindsFrame.Size = UDim2.new(0, 200, 0, 150)
KeybindsFrame.Position = UDim2.new(1, -220, 0, 20)
KeybindsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
KeybindsFrame.BorderSizePixel = 0
KeybindsFrame.Active = true
KeybindsFrame.Draggable = true
KeybindsFrame.AnchorPoint = Vector2.new(1, 0)
KeybindsFrame.Parent = KeybindsHUD
KeybindsFrame.Visible = HUDSettings.ShowKeybindsHUD

local KeybindsFrameCorner = Instance.new("UICorner")
KeybindsFrameCorner.CornerRadius = UDim.new(0, 6)
KeybindsFrameCorner.Parent = KeybindsFrame

local KeybindsFrameStroke = Instance.new("UIStroke")
KeybindsFrameStroke.Color = Color3.fromRGB(147, 112, 219)
KeybindsFrameStroke.Thickness = 2
KeybindsFrameStroke.Parent = KeybindsFrame

local KeybindsHeader = Instance.new("TextLabel")
KeybindsHeader.Size = UDim2.new(1, 0, 0.2, 0)
KeybindsHeader.Position = UDim2.new(0, 0, 0, 0)
KeybindsHeader.BackgroundTransparency = 1
KeybindsHeader.TextColor3 = Color3.fromRGB(200, 200, 200)
KeybindsHeader.Text = "Keybinds"
KeybindsHeader.TextSize = 16
KeybindsHeader.Font = Enum.Font.SourceSansBold
KeybindsHeader.TextXAlignment = Enum.TextXAlignment.Center
KeybindsHeader.Parent = KeybindsFrame

local JumpStunLabel = Instance.new("TextLabel")
JumpStunLabel.Size = UDim2.new(1, 0, 0.2, 0)
JumpStunLabel.Position = UDim2.new(0, 0, 0.2, 0)
JumpStunLabel.BackgroundTransparency = 1
JumpStunLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
JumpStunLabel.Text = "Jump Stun: B"
JumpStunLabel.TextSize = 14
JumpStunLabel.Font = Enum.Font.SourceSans
JumpStunLabel.TextXAlignment = Enum.TextXAlignment.Center
JumpStunLabel.Parent = KeybindsFrame

local SilentAimLabel = Instance.new("TextLabel")
SilentAimLabel.Size = UDim2.new(1, 0, 0.2, 0)
SilentAimLabel.Position = UDim2.new(0, 0, 0.4, 0)
SilentAimLabel.BackgroundTransparency = 1
SilentAimLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
SilentAimLabel.Text = "Silent Aim: RightAlt"
SilentAimLabel.TextSize = 14
SilentAimLabel.Font = Enum.Font.SourceSans
SilentAimLabel.TextXAlignment = Enum.TextXAlignment.Center
SilentAimLabel.Parent = KeybindsFrame

local DashKeyLabel = Instance.new("TextLabel")
DashKeyLabel.Size = UDim2.new(1, 0, 0.2, 0)
DashKeyLabel.Position = UDim2.new(0, 0, 0.6, 0)
DashKeyLabel.BackgroundTransparency = 1
DashKeyLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
DashKeyLabel.Text = "Dash: " .. DashSettings.DashKey
DashKeyLabel.TextSize = 14
DashKeyLabel.Font = Enum.Font.SourceSans
DashKeyLabel.TextXAlignment = Enum.TextXAlignment.Center
DashKeyLabel.Parent = KeybindsFrame

local FlyKeyLabel = Instance.new("TextLabel")
FlyKeyLabel.Size = UDim2.new(1, 0, 0.2, 0)
FlyKeyLabel.Position = UDim2.new(0, 0, 0.8, 0)
FlyKeyLabel.BackgroundTransparency = 1
FlyKeyLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
FlyKeyLabel.Text = "FlyV2: T"
FlyKeyLabel.TextSize = 14
FlyKeyLabel.Font = Enum.Font.SourceSans
FlyKeyLabel.TextXAlignment = Enum.TextXAlignment.Center
FlyKeyLabel.Parent = KeybindsFrame

-- Functions
local function getPositionOnScreen(Vector)
    local Vec3, OnScreen = WorldToScreen(Camera, Vector)
    return Vector2.new(Vec3.X, Vec3.Y), OnScreen
end

local function ValidateArguments(Args, RayMethod)
    local Matches = 0
    if #Args < RayMethod.ArgCountRequired then
        return false
    end
    for Pos, Argument in next, Args do
        if typeof(Argument) == RayMethod.Args[Pos] then
            Matches = Matches + 1
        end
    end
    return Matches >= RayMethod.ArgCountRequired
end

local function getDirection(Origin, Position)
    return (Position - Origin).Unit * 1000
end

local function getMousePosition()
    return GetMouseLocation(UserInputService)
end

local function visibleCheck(target, part)
    if not SilentAimSettings.VisibleCheck then return true end
    if not target or not target.Character or not part then
        return false
    end

    local currentTime = tick()
    local cacheKey = tostring(target.UserId)

    if VisibleCheckCache[cacheKey] and currentTime - VisibleCheckCache[cacheKey].time < CacheDuration then
        return VisibleCheckCache[cacheKey].visible
    end

    local PlayerCharacter = target.Character
    local LocalPlayerCharacter = LocalPlayer.Character

    if not (PlayerCharacter and LocalPlayerCharacter) then
        VisibleCheckCache[cacheKey] = { visible = false, time = currentTime }
        return false
    end

    local PlayerRoot = FindFirstChild(PlayerCharacter, SilentAimSettings.TargetPart) or FindFirstChild(PlayerCharacter, "HumanoidRootPart")
    local LocalPlayerRoot = FindFirstChild(LocalPlayerCharacter, "HumanoidRootPart")

    if not (PlayerRoot and LocalPlayerRoot) then
        VisibleCheckCache[cacheKey] = { visible = false, time = currentTime }
        return false
    end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayerCharacter, PlayerCharacter}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true
    raycastParams.RespectCanCollide = true

    local pointsToCheck = {
        PlayerRoot.Position,
        PlayerRoot.Position + Vector3.new(0, 2, 0),
        PlayerRoot.Position + Vector3.new(0, -1, 0)
    }

    for _, point in ipairs(pointsToCheck) do
        local direction = (point - LocalPlayerRoot.Position).Unit
        local distance = (point - LocalPlayerRoot.Position).Magnitude
        local raycastResult = workspace:Raycast(LocalPlayerRoot.Position, direction * distance, raycastParams)
        if not raycastResult or (raycastResult.Instance:IsDescendantOf(PlayerCharacter)) then
            VisibleCheckCache[cacheKey] = { visible = true, time = currentTime }
            return true
        end
    end

    VisibleCheckCache[cacheKey] = { visible = false, time = currentTime }
    return false
end

local function getClosestPlayer()
    if not SilentAimSettings.TargetPart then return end
    local Closest
    local DistanceToMouse
    local pixelRadius = degreesToPixels(SilentAimSettings.FOVRadius)
    for _, Player in next, GetPlayers(Players) do
        if Player == LocalPlayer then continue end
        if SilentAimSettings.TeamCheck and Player.Team == LocalPlayer.Team then continue end

        local Character = Player.Character
        if not Character then continue end
        
        local Head = FindFirstChild(Character, "Head")
        local Humanoid = FindFirstChild(Character, "Humanoid")
        if not Head or not Humanoid or Humanoid.Health <= 0 then continue end

        local ScreenPosition, OnScreen = getPositionOnScreen(Head.Position)
        if not OnScreen then continue end

        local Distance = (getMousePosition() - ScreenPosition).Magnitude
        if Distance > pixelRadius then continue end
        
        if SilentAimSettings.VisibleCheck and not visibleCheck(Player, Head) then continue end

        if Distance <= (DistanceToMouse or pixelRadius or 2000) then
            Closest = Head
            DistanceToMouse = Distance
        end
    end
    return Closest
end

local function ApplyAntiAim()
    if not AntiAimSettings.Enabled then return end
    local Character = LocalPlayer.Character
    if not Character then return end
    local RootPart = Character:FindFirstChild("HumanoidRootPart")
    if not RootPart then return end
    local Humanoid = Character:FindFirstChild("Humanoid")
    if not Humanoid or Humanoid.Health <= 0 then return end

    local currentTime = tick()
    if currentTime - AntiAimSettings.LastUpdate < AntiAimSettings.UpdateInterval then return end
    AntiAimSettings.LastUpdate = currentTime

    local yaw = AntiAimSettings.Yaw
    local pitch = AntiAimSettings.Pitch
    local roll = AntiAimSettings.Roll

    if AntiAimSettings.Mode == "Jitter" then
        yaw = yaw + math.random(-45, 45)
        pitch = pitch + math.random(-30, 30)
    elseif AntiAimSettings.Mode == "Random" then
        yaw = math.random(-180, 180)
        pitch = math.random(-90, 90)
        roll = math.random(-90, 90)
    end

    if yaw ~= yaw or pitch ~= pitch or roll ~= roll then return end

    local characterCFrame = CFrame.new(RootPart.Position) * CFrame.Angles(math.rad(pitch), math.rad(yaw + 180), math.rad(roll))
    if characterCFrame.Position.Magnitude > 1000000 then return end
    RootPart.CFrame = characterCFrame

    if BogaAimSettings.FakeLag then
        task.wait(math.random(0.05, 0.15))
    end

    if AntiAimSettings.Desync then
        local desyncCframe = CFrame.Angles(0, math.rad(yaw + 90), 0)
        RootPart.CFrame = CFrame.new(RootPart.Position) * desyncCframe
        task.wait(0.01)
        RootPart.CFrame = characterCFrame
    end
end

local function PerformDash()
    local currentTime = tick()
    if DashSettings.DashEnabled and not IsDashing and currentTime - LastDashTime >= DashSettings.DashCooldown then
        IsDashing = true
        LastDashTime = currentTime
        local Character = LocalPlayer.Character
        if Character and Character:FindFirstChild("HumanoidRootPart") then
            local RootPart = Character.HumanoidRootPart
            local Humanoid = Character:FindFirstChild("Humanoid")
            if Humanoid then
                local MoveDirection = Humanoid.MoveDirection
                if MoveDirection.Magnitude == 0 then
                    MoveDirection = RootPart.CFrame.LookVector
                end
                local StartTime = tick()
                local DashDistance = 0
                local MaxDistance = DashSettings.DashSpeed * DashSettings.DashDuration
                local Connection
                Connection = RunService.Heartbeat:Connect(function(deltaTime)
                    if tick() - StartTime >= DashSettings.DashDuration or not Character or not Humanoid or Humanoid.Health <= 0 then
                        IsDashing = false
                        Connection:Disconnect()
                        return
                    end
                    local StepDistance = DashSettings.DashSpeed * deltaTime
                    DashDistance = DashDistance + StepDistance
                    if DashDistance <= MaxDistance then
                        local DashVector = MoveDirection * StepDistance
                        RootPart.CFrame = RootPart.CFrame + DashVector
                    end
                end)
            end
        end
    end
end

local function UpdateDashCooldown()
    if DashBar and DashLabel then
        local currentTime = tick()
        local cooldownRemaining = math.max(0, LastDashTime + DashSettings.DashCooldown - currentTime)
        DashBar.Size = UDim2.new(1 - (cooldownRemaining / DashSettings.DashCooldown), 0, 0.5, 0)
        DashLabel.Text = "Dash: " .. (cooldownRemaining <= 0 and "READY" or "CD: " .. string.format("%.1f", cooldownRemaining))
    end
end

local function UpdateKeybindsHUD()
    if JumpStunLabel and SilentAimLabel and DashKeyLabel and FlyKeyLabel then
        JumpStunLabel.Text = "Jump Stun: B"
        SilentAimLabel.Text = "Silent Aim: RightAlt"
        DashKeyLabel.Text = "Dash: " .. DashSettings.DashKey
        FlyKeyLabel.Text = "FlyV2: T"
        KeybindsFrame.Visible = HUDSettings.ShowKeybindsHUD
    end
end

local function CalculateChance(Percentage)
    Percentage = math.floor(Percentage)
    local chance = math.floor(Random.new().NextNumber(Random.new(), 0, 1) * 100) / 100
    return chance <= Percentage / 100
end

-- Update visuals, Anti Aim, Dash, Auto Shoot
resume(create(function()
    RenderStepped:Connect(function()
        -- Silent Aim Visuals
        if SilentAimSettings.ShowSilentAimTarget and SilentAimSettings.Enabled then
            local closest = getClosestPlayer()
            if closest then 
                local rootToViewportPoint, isOnScreen = WorldToViewportPoint(Camera, closest.Position)
                mouse_box.Visible = isOnScreen
                mouse_box.Position = Vector2.new(rootToViewportPoint.X, rootToViewportPoint.Y)
            else 
                mouse_box.Visible = false
                mouse_box.Position = Vector2.new(0, 0)
            end
        end
        
        if SilentAimSettings.FOVVisible then 
            fov_circle.Visible = SilentAimSettings.FOVVisible
            fov_circle.Position = getMousePosition()
        end

        -- Auto Shoot
        if SilentAimSettings.Enabled and SilentAimSettings.AutoShoot then
            local currentTime = tick()
            local shootInterval = 1 / math.max(SilentAimSettings.CPS, 1)
            if currentTime - LastShotTime >= shootInterval then
                local target = getClosestPlayer()
                if target and CalculateChance(SilentAimSettings.HitChance) then
                    local success, err = pcall(function()
                        mouse1press()
                        mouse1release()
                    end)
                    if not success then
                        warn("AutoShoot: Failed to fire - " .. tostring(err))
                    end
                    LastShotTime = currentTime
                end
            end
        end

        -- Anti Aim
        pcall(ApplyAntiAim)
        
        -- Dash
        pcall(UpdateDashCooldown)

        -- Keybinds HUD
        pcall(UpdateKeybindsHUD)
    end)
end))

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        if input.KeyCode == Enum.KeyCode[DashSettings.DashKey] then
            PerformDash()
        elseif input.KeyCode == Enum.KeyCode.T then
            if tick() - lastFlyActivation >= FlySettings.Cooldown then
                lastFlyActivation = tick()
                FlySettings.Enabled = not FlySettings.Enabled
                FlySection:FindFlag("FlyV2_Enabled"):Set(FlySettings.Enabled)
            end
        elseif input.KeyCode == Enum.KeyCode.RightAlt then
            SilentAimSettings.Enabled = not SilentAimSettings.Enabled
            mouse_box.Visible = SilentAimSettings.Enabled and SilentAimSettings.ShowSilentAimTarget
        elseif input.KeyCode == Enum.KeyCode.B then
            JumpStunSettings.Enabled = not JumpStunSettings.Enabled
            JumpStunSection:FindFlag("JumpStun_Enabled"):Set(JumpStunSettings.Enabled)
            if JumpStunSettings.Enabled then
                local success, err = pcall(function()
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/g04w4ys11/pastedshit/refs/heads/main/unlooosedcc/assets/pizdec"))()
                end)
                if not success then
                    warn("Jump Stun: Failed to load - " .. tostring(err))
                    JumpStunSettings.Enabled = false
                    JumpStunSection:FindFlag("JumpStun_Enabled"):Set(false)
                    library:SendNotification("Jump Stun: Failed to load script - " .. tostring(err), 5)
                end
            end
        end
    end
end)

-- Hooks
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
    local Method = getnamecallmethod()
    local Arguments = {...}
    local self = Arguments[1]
    local chance = CalculateChance(SilentAimSettings.HitChance)
    if SilentAimSettings.Enabled and self == workspace and not checkcaller() and chance then
        if Method == "Raycast" and SilentAimSettings.SilentAimMethod == "Raycast" then
            if ValidateArguments(Arguments, ExpectedArguments.Raycast) then
                local A_Origin = Arguments[2]
                local HitPart = getClosestPlayer()
                if HitPart then
                    local targetPosition = HitPart.Position
                    if SilentAimSettings.MouseHitPrediction then
                        local humanoid = HitPart.Parent:FindFirstChild("Humanoid")
                        if humanoid and humanoid.MoveDirection.Magnitude > 0 then
                            targetPosition = targetPosition + (humanoid.MoveDirection * SilentAimSettings.MouseHitPredictionAmount)
                        end
                    end
                    Arguments[3] = getDirection(A_Origin, targetPosition)
                    return oldNamecall(unpack(Arguments))
                end
            end
        end
    end
    return oldNamecall(...)
end))

-- Cleanup on death and respawn
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid", 5)
        if humanoid then
            humanoid.Died:Connect(function()
                VisibleCheckCache[tostring(player.UserId)] = nil
            end)
        end
    end)
end)

LocalPlayer.CharacterAdded:Connect(function(newChar)
    task.wait(1)
    if FlyV2Instance then
        if FlyV2Instance.Destroy then
            FlyV2Instance:Destroy()
        end
        FlyV2Instance = nil
        FlySettings.Enabled = false
        FlySection:FindFlag("FlyV2_Enabled"):Set(false)
    end
    if ESPInstance then
        if ESPInstance.Destroy then
            ESPInstance:Destroy()
        end
        ESPInstance = nil
        ESPSettings.Enabled = false
        ESPSection:FindFlag("ESP_Enabled"):Set(false)
    end
    if NoclipConnection then
        NoclipConnection:Disconnect()
        NoclipConnection = nil
        NoclipSettings.Enabled = false
        Clipon = false
        NoclipSection:FindFlag("Noclip_Enabled"):Set(false)
        for _, part in pairs(newChar:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end)

game:BindToClose(function()
    if FlyV2Instance then
        if FlyV2Instance.Destroy then
            FlyV2Instance:Destroy()
        end
        FlyV2Instance = nil
    end
    if ESPInstance then
        if ESPInstance.Destroy then
            ESPInstance:Destroy()
        end
        ESPInstance = nil
    end
    if NoclipConnection then
        NoclipConnection:Disconnect()
        NoclipConnection = nil
    end
end)


    
    task.wait(0.1)  -- Задержка для оптимизации
end
