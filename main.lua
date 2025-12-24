-- ============================================
-- FISCH EXPLOIT HUB - COMPLETE VERSION
-- ============================================
-- Features:
-- - Santa Rod Request (Auto Wish)
-- - Auto Farm
-- - Auto Sell
-- - Teleports
-- - Player Stats
-- - ESP & Visuals
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- ============================================
-- CONFIGURATION
-- ============================================
local Config = {
    -- Santa Rod
    SantaRodName = "Santa's Miracle Rod",
    
    -- Auto Farm
    AutoFarm = false,
    AutoSell = false,
    AutoCast = false,
    AutoReel = false,
    
    -- Teleport
    FastTeleport = true,
    
    -- ESP
    FishESP = false,
    PlayerESP = false,
    
    -- Misc
    WalkSpeed = 16,
    JumpPower = 50,
    NoClip = false,
    InfiniteJump = false,
    
    -- Anti-Kick
    AntiAFK = true,
    AntiKick = true,
}

-- ============================================
-- AVAILABLE RODS
-- ============================================
local AVAILABLE_RODS = {
    "Smurf Rod", "Plastic Rod", "Test Rod",
    "Peppermint Rod", "Gingerbread Rod",
    "Santa's Miracle Rod", "Jinglestar Rod",
    "Christmas Tree Rod", "The Boom Ball",
    "Carrot Rod", "Brick Built Rod"
}

-- ============================================
-- TELEPORT LOCATIONS
-- ============================================
local TeleportLocations = {
    ["Moosewood"] = CFrame.new(387, 135, 236),
    ["Roslit Bay"] = CFrame.new(-1472, 135, 687),
    ["Snowcap Island"] = CFrame.new(2648, 140, 2522),
    ["Mushgrove Swamp"] = CFrame.new(2501, 132, -721),
    ["The Depths"] = CFrame.new(979, -710, 1240),
    ["Vertigo"] = CFrame.new(-112, -492, 1040),
    ["Statue Of Sovereignty"] = CFrame.new(46, 143, -1003),
    ["Sunstone Island"] = CFrame.new(-933, 132, -1123),
    ["Forsaken Shores"] = CFrame.new(-2708, 132, 1839),
    ["Ancient Isle"] = CFrame.new(5961, 132, 545),
}

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================
local function log(msg, color)
    color = color or Color3.fromRGB(255, 255, 255)
    print("[Fisch Hub] " .. msg)
end

local function notify(title, text, duration)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration or 3,
    })
end

local function safeCall(func)
    local success, err = pcall(func)
    if not success then
        warn("[Fisch Hub Error] " .. tostring(err))
    end
    return success
end

-- ============================================
-- SANTA ROD REQUEST
-- ============================================
local SantaModule = {}

function SantaModule.setupHooks()
    safeCall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        
        local old = mt.__namecall
        
        mt.__namecall = function(self, ...)
            local method = getnamecallmethod()
            
            if method == "InvokeServer" and tostring(self):find("santa") then
                if tostring(self) == "santa_IsRodOwned" then
                    return false
                end
            end
            
            return old(self, ...)
        end
        
        setreadonly(mt, true)
        log("Santa hooks applied")
    end)
end

function SantaModule.naturalClick(button, times)
    times = times or 1
    
    for i = 1, times do
        wait(0.5 + math.random() * 0.3)
        
        safeCall(function()
            for _, conn in pairs(getconnections(button.Activated)) do
                conn:Fire()
            end
        end)
        
        wait(0.2)
    end
end

function SantaModule.requestRod(rodName)
    log("Requesting Santa Rod: " .. rodName)
    
    local PlayerGui = LocalPlayer.PlayerGui
    local christmas = PlayerGui:FindFirstChild("christmas")
    
    if not christmas then
        notify("Error", "Christmas UI not found", 3)
        return false
    end
    
    -- Open letter
    local right = christmas:FindFirstChild("right")
    if right then
        local santasLetter = right:FindFirstChild("SantasLetter")
        if santasLetter then
            SantaModule.naturalClick(santasLetter)
            wait(1.5)
        end
    end
    
    -- Main UI
    local christmasLetter = christmas:FindFirstChild("ChristmasLetter")
    if not christmasLetter then
        notify("Error", "ChristmasLetter not found", 3)
        return false
    end
    
    christmasLetter.Visible = true
    
    local safezone = christmasLetter:FindFirstChild("Safezone")
    if not safezone then
        return false
    end
    
    -- UI adjustments
    local dateLabel = safezone:FindFirstChild("Date")
    if dateLabel then dateLabel.Visible = false end
    
    local signHere = safezone:FindFirstChild("SignHere")
    if signHere then signHere.Visible = true end
    
    -- Text input
    local textBox = safezone:FindFirstChild("TextBox")
    if not textBox then
        return false
    end
    
    wait(0.5)
    textBox.Text = rodName
    wait(0.5)
    
    safeCall(function()
        for _, conn in pairs(getconnections(textBox.FocusLost)) do
            conn:Fire()
        end
    end)
    
    wait(1)
    
    -- Confirm button
    if signHere then
        SantaModule.naturalClick(signHere, 6)
        notify("Success", "Rod requested: " .. rodName, 3)
        
        -- Reset camera
        wait(1)
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        
        return true
    end
    
    return false
end

function SantaModule.directRequest(rodName)
    log("Direct request: " .. rodName)
    
    local events = ReplicatedStorage:FindFirstChild("events")
    if not events then return false end
    
    local santaRequestRod = events:FindFirstChild("santa_RequestRod")
    if not santaRequestRod then return false end
    
    local success, result = pcall(function()
        return santaRequestRod:InvokeServer(rodName)
    end)
    
    if success then
        notify("Success", "Rod requested successfully!", 3)
        return true
    else
        notify("Failed", "Request failed: " .. tostring(result), 3)
        return false
    end
end

-- ============================================
-- AUTO FARM
-- ============================================
local FarmModule = {}

function FarmModule.getCastFunction()
    local success, result = pcall(function()
        local controller = require(ReplicatedStorage.client.legacyControllers)
        return controller.fishing
    end)
    
    if success then
        return result
    end
    return nil
end

function FarmModule.autoCast()
    local fishing = FarmModule.getCastFunction()
    if fishing and fishing.cast then
        safeCall(function()
            fishing:cast()
        end)
    end
end

function FarmModule.autoReel()
    local fishing = FarmModule.getCastFunction()
    if fishing and fishing.reel then
        safeCall(function()
            fishing:reel()
        end)
    end
end

function FarmModule.autoSell()
    -- Find nearest merchant
    local merchants = workspace:FindFirstChild("world")
    if merchants then
        merchants = merchants:FindFirstChild("npcs")
        if merchants then
            for _, npc in pairs(merchants:GetChildren()) do
                if npc.Name:find("Merchant") then
                    -- Teleport to merchant
                    HumanoidRootPart.CFrame = npc.PrimaryPart.CFrame
                    wait(0.5)
                    
                    -- Interact
                    local clickDetector = npc:FindFirstChildOfClass("ClickDetector", true)
                    if clickDetector then
                        fireclickdetector(clickDetector)
                    end
                    
                    break
                end
            end
        end
    end
end

-- ============================================
-- TELEPORT
-- ============================================
local TeleportModule = {}

function TeleportModule.teleport(location)
    if not TeleportLocations[location] then
        notify("Error", "Location not found", 3)
        return
    end
    
    local targetCFrame = TeleportLocations[location]
    
    if Config.FastTeleport then
        HumanoidRootPart.CFrame = targetCFrame
        notify("Teleported", location, 2)
    else
        local tween = TweenService:Create(
            HumanoidRootPart,
            TweenInfo.new(2, Enum.EasingStyle.Linear),
            {CFrame = targetCFrame}
        )
        tween:Play()
        notify("Teleporting", location, 2)
    end
end

-- ============================================
-- ESP
-- ============================================
local ESPModule = {}
local ESPObjects = {}

function ESPModule.createESP(obj, color, text)
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "ESP"
    billboardGui.AlwaysOnTop = true
    billboardGui.Size = UDim2.new(0, 100, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.Parent = obj
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 0.5
    frame.BackgroundColor3 = color
    frame.Parent = billboardGui
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Parent = frame
    
    table.insert(ESPObjects, billboardGui)
end

function ESPModule.clearESP()
    for _, esp in pairs(ESPObjects) do
        if esp then esp:Destroy() end
    end
    ESPObjects = {}
end

function ESPModule.updateFishESP()
    ESPModule.clearESP()
    
    if not Config.FishESP then return end
    
    local world = workspace:FindFirstChild("world")
    if world then
        local fish = world:FindFirstChild("fish")
        if fish then
            for _, fishObj in pairs(fish:GetChildren()) do
                ESPModule.createESP(fishObj, Color3.fromRGB(0, 255, 255), fishObj.Name)
            end
        end
    end
end

function ESPModule.updatePlayerESP()
    if not Config.PlayerESP then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp and not hrp:FindFirstChild("ESP") then
                ESPModule.createESP(hrp, Color3.fromRGB(255, 0, 0), player.Name)
            end
        end
    end
end

-- ============================================
-- PLAYER MODIFICATIONS
-- ============================================
local PlayerModule = {}

function PlayerModule.setWalkSpeed(speed)
    local humanoid = Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = speed
    end
end

function PlayerModule.setJumpPower(power)
    local humanoid = Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.JumpPower = power
    end
end

function PlayerModule.toggleNoClip(enabled)
    Config.NoClip = enabled
end

function PlayerModule.toggleInfiniteJump(enabled)
    Config.InfiniteJump = enabled
end

-- ============================================
-- ANTI-AFK & ANTI-KICK
-- ============================================
local AntiModule = {}

function AntiModule.antiAFK()
    local VirtualUser = game:GetService("VirtualUser")
    
    game:GetService("Players").LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
        log("Anti-AFK triggered")
    end)
end

function AntiModule.antiKick()
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    
    setreadonly(mt, false)
    
    mt.__namecall = function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if method == "Kick" or method == "kick" then
            log("Kick attempt blocked")
            return
        end
        
        return oldNamecall(self, ...)
    end
    
    setreadonly(mt, true)
end

-- ============================================
-- MAIN LOOP
-- ============================================
local function mainLoop()
    RunService.Heartbeat:Connect(function()
        -- Auto Farm
        if Config.AutoCast then
            FarmModule.autoCast()
            wait(5)
        end
        
        if Config.AutoReel then
            FarmModule.autoReel()
        end
        
        if Config.AutoSell then
            FarmModule.autoSell()
            wait(10)
        end
        
        -- No Clip
        if Config.NoClip then
            for _, part in pairs(Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
        
        -- Player modifications
        if Config.WalkSpeed ~= 16 then
            PlayerModule.setWalkSpeed(Config.WalkSpeed)
        end
        
        if Config.JumpPower ~= 50 then
            PlayerModule.setJumpPower(Config.JumpPower)
        end
    end)
end

-- ============================================
-- GUI CREATION
-- ============================================
local function createGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "FischHub"
    ScreenGui.ResetOnSpawn = false
    
    pcall(function()
        ScreenGui.Parent = game.CoreGui
    end)
    
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer.PlayerGui
    end
    
    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 450, 0, 500)
    MainFrame.Position = UDim2.new(0.5, -225, 0.5, -250)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    MainFrame.BorderSizePixel = 2
    MainFrame.BorderColor3 = Color3.fromRGB(0, 150, 255)
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    Title.BorderSizePixel = 0
    Title.Text = "FISCH EXPLOIT HUB"
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 20
    Title.Parent = MainFrame
    
    -- Tabs Container
    local TabsFrame = Instance.new("Frame")
    TabsFrame.Size = UDim2.new(1, 0, 0, 35)
    TabsFrame.Position = UDim2.new(0, 0, 0, 40)
    TabsFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    TabsFrame.BorderSizePixel = 0
    TabsFrame.Parent = MainFrame
    
    -- Content Frame
    local ContentFrame = Instance.new("ScrollingFrame")
    ContentFrame.Size = UDim2.new(1, -10, 1, -85)
    ContentFrame.Position = UDim2.new(0, 5, 0, 80)
    ContentFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    ContentFrame.BorderSizePixel = 0
    ContentFrame.ScrollBarThickness = 6
    ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ContentFrame.Parent = MainFrame
    
    -- Tab system
    local currentTab = nil
    local tabs = {}
    
    local function createTab(name)
        local TabButton = Instance.new("TextButton")
        TabButton.Size = UDim2.new(0, 100, 1, 0)
        TabButton.Position = UDim2.new(0, #tabs * 100, 0, 0)
        TabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        TabButton.BorderSizePixel = 0
        TabButton.Text = name
        TabButton.TextColor3 = Color3.new(1, 1, 1)
        TabButton.Font = Enum.Font.SourceSansBold
        TabButton.TextSize = 14
        TabButton.Parent = TabsFrame
        
        local TabContent = Instance.new("Frame")
        TabContent.Size = UDim2.new(1, 0, 1, 0)
        TabContent.BackgroundTransparency = 1
        TabContent.Visible = false
        TabContent.Parent = ContentFrame
        
        TabButton.MouseButton1Click:Connect(function()
            for _, tab in pairs(tabs) do
                tab.button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
                tab.content.Visible = false
            end
            
            TabButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
            TabContent.Visible = true
            currentTab = TabContent
        end)
        
        table.insert(tabs, {button = TabButton, content = TabContent})
        
        return TabContent
    end
    
    -- Helper functions for UI elements
    local yOffset = 0
    
    local function createButton(parent, text, callback)
        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(0.95, 0, 0, 35)
        Button.Position = UDim2.new(0.025, 0, 0, yOffset)
        Button.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        Button.BorderSizePixel = 0
        Button.Text = text
        Button.TextColor3 = Color3.new(1, 1, 1)
        Button.Font = Enum.Font.SourceSansBold
        Button.TextSize = 14
        Button.Parent = parent
        
        Button.MouseButton1Click:Connect(callback)
        
        yOffset = yOffset + 40
        return Button
    end
    
    local function createToggle(parent, text, callback)
        local Toggle = Instance.new("TextButton")
        Toggle.Size = UDim2.new(0.95, 0, 0, 35)
        Toggle.Position = UDim2.new(0.025, 0, 0, yOffset)
        Toggle.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
        Toggle.BorderSizePixel = 0
        Toggle.Text = text .. ": OFF"
        Toggle.TextColor3 = Color3.new(1, 1, 1)
        Toggle.Font = Enum.Font.SourceSansBold
        Toggle.TextSize = 14
        Toggle.Parent = parent
        
        local enabled = false
        
        Toggle.MouseButton1Click:Connect(function()
            enabled = not enabled
            
            if enabled then
                Toggle.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
                Toggle.Text = text .. ": ON"
            else
                Toggle.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
                Toggle.Text = text .. ": OFF"
            end
            
            callback(enabled)
        end)
        
        yOffset = yOffset + 40
        return Toggle
    end
    
    local function createTextBox(parent, placeholderText, defaultText)
        local TextBox = Instance.new("TextBox")
        TextBox.Size = UDim2.new(0.95, 0, 0, 35)
        TextBox.Position = UDim2.new(0.025, 0, 0, yOffset)
        TextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        TextBox.BorderSizePixel = 1
        TextBox.BorderColor3 = Color3.fromRGB(100, 100, 100)
        TextBox.PlaceholderText = placeholderText
        TextBox.Text = defaultText or ""
        TextBox.TextColor3 = Color3.new(1, 1, 1)
        TextBox.Font = Enum.Font.SourceSans
        TextBox.TextSize = 14
        TextBox.ClearTextOnFocus = false
        TextBox.Parent = parent
        
        yOffset = yOffset + 40
        return TextBox
    end
    
    local function createSlider(parent, text, min, max, default, callback)
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(0.95, 0, 0, 50)
        Container.Position = UDim2.new(0.025, 0, 0, yOffset)
        Container.BackgroundTransparency = 1
        Container.Parent = parent
        
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, 0, 0, 20)
        Label.BackgroundTransparency = 1
        Label.Text = text .. ": " .. default
        Label.TextColor3 = Color3.new(1, 1, 1)
        Label.Font = Enum.Font.SourceSans
        Label.TextSize = 14
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Container
        
        local SliderFrame = Instance.new("Frame")
        SliderFrame.Size = UDim2.new(1, 0, 0, 20)
        SliderFrame.Position = UDim2.new(0, 0, 0, 25)
        SliderFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        SliderFrame.BorderSizePixel = 0
        SliderFrame.Parent = Container
        
        local SliderButton = Instance.new("Frame")
        SliderButton.Size = UDim2.new(0, 10, 1, 0)
        SliderButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        SliderButton.BorderSizePixel = 0
        SliderButton.Parent = SliderFrame
        
        local dragging = false
        
        SliderButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
            end
        end)
        
        SliderButton.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        game:GetService("UserInputService").InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local mousePos = input.Position.X
                local framePos = SliderFrame.AbsolutePosition.X
                local frameSize = SliderFrame.AbsoluteSize.X
                
                local relative = math.clamp((mousePos - framePos) / frameSize, 0, 1)
                local value = math.floor(min + (max - min) * relative)
                
                SliderButton.Position = UDim2.new(relative, 0, 0, 0)
                Label.Text = text .. ": " .. value
                
                callback(value)
            end
        end)
        
        yOffset = yOffset + 55
        return Container
    end
    
    local function resetYOffset()
        yOffset = 0
    end
    
    -- ============================================
    -- SANTA TAB
    -- ============================================
    local SantaTab = createTab("Santa")
    resetYOffset()
    
    local RodTextBox = createTextBox(SantaTab, "Enter rod name...", Config.SantaRodName)
    
    createButton(SantaTab, "Request Rod (UI Method)", function()
        Config.SantaRodName = RodTextBox.Text
        SantaModule.setupHooks()
        wait(0.5)
        SantaModule.requestRod(Config.SantaRodName)
    end)
    
    createButton(SantaTab, "Request Rod (Direct)", function()
        Config.SantaRodName = RodTextBox.Text
        SantaModule.directRequest(Config.SantaRodName)
    end)
    
    -- Rod list
    local RodListLabel = Instance.new("TextLabel")
    RodListLabel.Size = UDim2.new(0.95, 0, 0, 25)
    RodListLabel.Position = UDim2.new(0.025, 0, 0, yOffset)
    RodListLabel.BackgroundTransparency = 1
    RodListLabel.Text = "Available Rods:"
    RodListLabel.TextColor3 = Color3.fromRGB(0, 150, 255)
    RodListLabel.Font = Enum.Font.SourceSansBold
    RodListLabel.TextSize = 16
    RodListLabel.TextXAlignment = Enum.TextXAlignment.Left
    RodListLabel.Parent = SantaTab
    yOffset = yOffset + 30
    
    for _, rod in ipairs(AVAILABLE_RODS) do
        createButton(SantaTab, rod, function()
            RodTextBox.Text = rod
            Config.SantaRodName = rod
        end)
    end
    
    -- Update canvas size
    SantaTab.Parent.CanvasSize = UDim2.new(0, 0, 0, yOffset)
    
    -- ============================================
    -- FARM TAB
    -- ============================================
    local FarmTab = createTab("Farm")
    resetYOffset()
    
    createToggle(FarmTab, "Auto Cast", function(enabled)
        Config.AutoCast = enabled
        if enabled then
            notify("Auto Cast", "Enabled", 2)
        end
    end)
    
    createToggle(FarmTab, "Auto Reel", function(enabled)
        Config.AutoReel = enabled
        if enabled then
            notify("Auto Reel", "Enabled", 2)
        end
    end)
    
    createToggle(FarmTab, "Auto Sell", function(enabled)
        Config.AutoSell = enabled
        if enabled then
            notify("Auto Sell", "Enabled", 2)
        end
    end)
    
    createButton(FarmTab, "Manual Cast", function()
        FarmModule.autoCast()
    end)
    
    createButton(FarmTab, "Manual Sell", function()
        FarmModule.autoSell()
    end)
    
    FarmTab.Parent.CanvasSize = UDim2.new(0, 0, 0, yOffset)
    
    -- ============================================
    -- TELEPORT TAB
    -- ============================================
    local TeleportTab = createTab("Teleport")
    resetYOffset()
    
    createToggle(TeleportTab, "Fast Teleport", function(enabled)
        Config.FastTeleport = enabled
    end)
    
    for location, _ in pairs(TeleportLocations) do
        createButton(TeleportTab, location, function()
            TeleportModule.teleport(location)
        end)
    end
    
    TeleportTab.Parent.CanvasSize = UDim2.new(0, 0, 0, yOffset)
    
    -- ============================================
    -- PLAYER TAB
    -- ============================================
    local PlayerTab = createTab("Player")
    resetYOffset()
    
    createSlider(PlayerTab, "Walk Speed", 16, 200, 16, function(value)
        Config.WalkSpeed = value
        PlayerModule.setWalkSpeed(value)
    end)
    
    createSlider(PlayerTab, "Jump Power", 50, 200, 50, function(value)
        Config.JumpPower = value
        PlayerModule.setJumpPower(value)
    end)
    
    createToggle(PlayerTab, "No Clip", function(enabled)
        PlayerModule.toggleNoClip(enabled)
    end)
    
    createToggle(PlayerTab, "Infinite Jump", function(enabled)
        PlayerModule.toggleInfiniteJump(enabled)
        
        if enabled then
            game:GetService("UserInputService").JumpRequest:Connect(function()
                if Config.InfiniteJump then
                    local humanoid = Character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end)
        end
    end)

    createButton(PlayerTab, "Reset Character", function()
        LocalPlayer.Character:BreakJoints()
        notify("Reset", "Character reset", 2)
    end)

    createButton(PlayerTab, "Remove Tool", function()
        if LocalPlayer.Character then
            for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
                if tool:IsA("Tool") then
                    tool:Destroy()
                end
            end
            notify("Tools", "Removed all tools", 2)
        end
    end)

    PlayerTab.Parent.CanvasSize = UDim2.new(0, 0, 0, yOffset)

    -- ============================================
    -- ESP TAB
    -- ============================================
    local ESPTab = createTab("ESP")
    resetYOffset()

    createToggle(ESPTab, "Fish ESP", function(enabled)
        Config.FishESP = enabled
        if enabled then
            ESPModule.updateFishESP()
            notify("Fish ESP", "Enabled", 2)
        else
            ESPModule.clearESP()
        end
    end)

    createToggle(ESPTab, "Player ESP", function(enabled)
        Config.PlayerESP = enabled
        if enabled then
            ESPModule.updatePlayerESP()
            notify("Player ESP", "Enabled", 2)
        else
            ESPModule.clearESP()
        end
    end)

    createButton(ESPTab, "Refresh ESP", function()
        ESPModule.clearESP()
        if Config.FishESP then
            ESPModule.updateFishESP()
        end
        if Config.PlayerESP then
            ESPModule.updatePlayerESP()
        end
        notify("ESP", "Refreshed", 2)
    end)

    createButton(ESPTab, "Clear All ESP", function()
        Config.FishESP = false
        Config.PlayerESP = false
        ESPModule.clearESP()
        notify("ESP", "Cleared all ESP", 2)
    end)

    ESPTab.Parent.CanvasSize = UDim2.new(0, 0, 0, yOffset)

    -- ============================================
    -- MISC TAB
    -- ============================================
    local MiscTab = createTab("Misc")
    resetYOffset()

    createToggle(MiscTab, "Anti-AFK", function(enabled)
        Config.AntiAFK = enabled
        if enabled then
            AntiModule.antiAFK()
            notify("Anti-AFK", "Enabled", 2)
        end
    end)

    createToggle(MiscTab, "Anti-Kick", function(enabled)
        Config.AntiKick = enabled
        if enabled then
            AntiModule.antiKick()
            notify("Anti-Kick", "Enabled", 2)
        end
    end)

    createButton(MiscTab, "Fullbright", function()
        local Lighting = game:GetService("Lighting")
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.Brightness = 2
        Lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
        Lighting.ColorShift_Top = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        notify("Fullbright", "Enabled", 2)
    end)

    createButton(MiscTab, "Remove Fog", function()
        local Lighting = game:GetService("Lighting")
        Lighting.FogEnd = 100000
        for _, v in pairs(Lighting:GetDescendants()) do
            if v:IsA("Atmosphere") then
                v:Destroy()
            end
        end
        notify("Fog", "Removed", 2)
    end)

    createButton(MiscTab, "Rejoin Server", function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(
            game.PlaceId,
            game.JobId,
            LocalPlayer
        )
    end)

    createButton(MiscTab, "Server Hop", function()
        local servers = {}
        local req = syn and syn.request or http and http.request or http_request or request
        if req then
            local response = req({
                Url = string.format(
                    "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100",
                    game.PlaceId
                )
            })
            local body = game:GetService("HttpService"):JSONDecode(response.Body)
            if body and body.data then
                for _, v in pairs(body.data) do
                    if v.playing < v.maxPlayers and v.id ~= game.JobId then
                        table.insert(servers, v.id)
                    end
                end
            end
        end
        
        if #servers > 0 then
            game:GetService("TeleportService"):TeleportToPlaceInstance(
                game.PlaceId,
                servers[math.random(1, #servers)],
                LocalPlayer
            )
        else
            notify("Server Hop", "No servers available", 3)
        end
    end)

    createButton(MiscTab, "Copy JobId", function()
        setclipboard(game.JobId)
        notify("JobId", "Copied to clipboard", 2)
    end)

    createButton(MiscTab, "Show Stats", function()
        local stats = LocalPlayer:FindFirstChild("leaderstats")
        if stats then
            local message = "Player Stats:\n"
            for _, stat in pairs(stats:GetChildren()) do
                message = message .. stat.Name .. ": " .. tostring(stat.Value) .. "\n"
            end
            notify("Stats", message, 5)
        else
            notify("Stats", "No stats found", 2)
        end
    end)

    MiscTab.Parent.CanvasSize = UDim2.new(0, 0, 0, yOffset)

    -- ============================================
    -- CREDITS TAB
    -- ============================================
    local CreditsTab = createTab("Credits")
    resetYOffset()

    local CreditsLabel = Instance.new("TextLabel")
    CreditsLabel.Size = UDim2.new(0.95, 0, 0, 400)
    CreditsLabel.Position = UDim2.new(0.025, 0, 0, yOffset)
    CreditsLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    CreditsLabel.BorderSizePixel = 0
    CreditsLabel.Text = [[
FISCH EXPLOIT HUB
Version 2.0
━━━━━━━━━━━━━━━━━━━━━━

Features:
- Santa Rod Request System
- Advanced Auto Farm
- Auto Sell & Cast
- Teleportation System
- Player Modifications
- ESP System
- Anti-AFK & Anti-Kick
- Server Tools

━━━━━━━━━━━━━━━━━━━━━━

Created for educational purposes
Use at your own risk

━━━━━━━━━━━━━━━━━━━━━━

Press F9 to toggle console
Press RightShift to toggle UI
    ]]
    CreditsLabel.TextColor3 = Color3.new(1, 1, 1)
    CreditsLabel.Font = Enum.Font.SourceSans
    CreditsLabel.TextSize = 14
    CreditsLabel.TextYAlignment = Enum.TextYAlignment.Top
    CreditsLabel.Parent = CreditsTab

    yOffset = yOffset + 410

    createButton(CreditsTab, "Close GUI", function()
        ScreenGui:Destroy()
        notify("Fisch Hub", "GUI Closed", 2)
    end)

    CreditsTab.Parent.CanvasSize = UDim2.new(0, 0, 0, yOffset)

    -- ============================================
    -- INITIALIZE FIRST TAB
    -- ============================================
    if #tabs > 0 then
        tabs[1].button.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        tabs[1].content.Visible = true
        currentTab = tabs[1].content
    end

    -- ============================================
    -- UI TOGGLE KEYBIND
    -- ============================================
    game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            MainFrame.Visible = not MainFrame.Visible
        end
    end)

    return ScreenGui
end

-- ============================================
-- INITIALIZATION
-- ============================================
local function initialize()
    log("Initializing Fisch Exploit Hub...")
    
    -- Setup anti-measures
    if Config.AntiAFK then
        AntiModule.antiAFK()
    end
    
    if Config.AntiKick then
        AntiModule.antiKick()
    end
    
    -- Create GUI
    local gui = createGUI()
    
    -- Start main loop
    mainLoop()
    
    -- ESP update loop
    spawn(function()
        while wait(2) do
            if Config.FishESP then
                ESPModule.updateFishESP()
            end
            if Config.PlayerESP then
                ESPModule.updatePlayerESP()
            end
        end
    end)
    
    -- Character respawn handler
    LocalPlayer.CharacterAdded:Connect(function(newCharacter)
        Character = newCharacter
        HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
        wait(1)
        if Config.WalkSpeed ~= 16 then
            PlayerModule.setWalkSpeed(Config.WalkSpeed)
        end
        if Config.JumpPower ~= 50 then
            PlayerModule.setJumpPower(Config.JumpPower)
        end
    end)
    
    notify("Fisch Hub", "Loaded successfully! Press RightShift to toggle", 5)
    log("Initialization complete!")
end

-- ============================================
-- AUTO-EXECUTE
-- ============================================
safeCall(initialize)

-- ============================================
-- RETURN MODULE (for require() support)
-- ============================================
return {
    Config = Config,
    Santa = SantaModule,
    Farm = FarmModule,
    Teleport = TeleportModule,
    ESP = ESPModule,
    Player = PlayerModule,
    Anti = AntiModule,
}
