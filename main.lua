-- Fisch Santa Rod Exploit (Anti-Kick Version)
-- エラーコード267対策版

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- 設定
local CONFIG = {
    ROD_NAME = "Santa's Miracle Rod",
    DEBUG = false, -- falseに変更（ログを減らす）
    USE_DELAY = true, -- 遅延を使って検知を回避
}

local AVAILABLE_RODS = {
    "Smurf Rod", "Plastic Rod", "Test Rod",
    "Peppermint Rod", "Gingerbread Rod",
    "Santa's Miracle Rod", "Jinglestar Rod",
    "Christmas Tree Rod", "The Boom Ball",
    "Carrot Rod", "Brick Built Rod"
}

local function log(msg)
    if CONFIG.DEBUG then
        print("[Santa] " .. msg)
    end
end

-- より安全なメタメソッドフック
local function safeHook()
    local success = pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        
        local old = mt.__namecall
        
        mt.__namecall = function(self, ...)
            local args = {...}
            local method = getnamecallmethod()
            
            -- 検知を避けるため、特定の条件でのみフック
            if method == "InvokeServer" and tostring(self):find("santa") then
                if tostring(self) == "santa_IsRodOwned" then
                    return false
                end
            end
            
            return old(self, ...)
        end
        
        setreadonly(mt, true)
    end)
    
    if success then
        log("Hook success")
    end
end

-- より自然なUI操作
local function naturalClick(button, times)
    times = times or 1
    
    for i = 1, times do
        if CONFIG.USE_DELAY then
            wait(0.5 + math.random() * 0.3) -- ランダムな遅延
        end
        
        -- 自然なクリックをシミュレート
        pcall(function()
            for _, conn in pairs(getconnections(button.Activated)) do
                conn:Fire()
            end
        end)
        
        if CONFIG.USE_DELAY then
            wait(0.2)
        end
    end
end

-- UI操作（検知されにくい方法）
local function manipulateUI()
    log("UI manipulation start")
    
    wait(1)
    
    local PlayerGui = LocalPlayer.PlayerGui
    local christmas = PlayerGui:FindFirstChild("christmas")
    
    if not christmas then
        log("Christmas UI not found")
        return false
    end
    
    -- 手紙を開く
    local right = christmas:FindFirstChild("right")
    if right then
        local santasLetter = right:FindFirstChild("SantasLetter")
        if santasLetter then
            log("Opening letter")
            naturalClick(santasLetter)
            wait(1.5)
        end
    end
    
    -- メインUI
    local christmasLetter = christmas:FindFirstChild("ChristmasLetter")
    if not christmasLetter then
        log("ChristmasLetter not found")
        return false
    end
    
    christmasLetter.Visible = true
    
    local safezone = christmasLetter:FindFirstChild("Safezone")
    if not safezone then
        log("Safezone not found")
        return false
    end
    
    -- UI要素の調整
    local dateLabel = safezone:FindFirstChild("Date")
    if dateLabel then
        dateLabel.Visible = false
    end
    
    local signHere = safezone:FindFirstChild("SignHere")
    if signHere then
        signHere.Visible = true
    end
    
    -- テキスト入力
    local textBox = safezone:FindFirstChild("TextBox")
    if not textBox then
        log("TextBox not found")
        return false
    end
    
    wait(0.5)
    textBox.Text = CONFIG.ROD_NAME
    
    wait(0.5)
    
    -- FocusLostを自然に発火
    pcall(function()
        for _, conn in pairs(getconnections(textBox.FocusLost)) do
            conn:Fire()
        end
    end)
    
    wait(1)
    
    -- 確認ボタンを押す（自然な間隔で）
    if signHere then
        log("Clicking confirm button")
        naturalClick(signHere, 6)
        
        log("UI manipulation complete")
        return true
    end
    
    return false
end

-- 直接リクエスト（最後の手段）
local function directRequest()
    log("Direct request")
    
    wait(1)
    
    local events = ReplicatedStorage:FindFirstChild("events")
    if not events then
        return false
    end
    
    local santaRequestRod = events:FindFirstChild("santa_RequestRod")
    if not santaRequestRod then
        return false
    end
    
    local success, result = pcall(function()
        return santaRequestRod:InvokeServer(CONFIG.ROD_NAME)
    end)
    
    if success then
        log("Request success")
        return true
    else
        log("Request failed")
        return false
    end
end

-- カメラリセット
local function resetCamera()
    wait(1)
    pcall(function()
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    end)
end

-- メイン実行
local function main()
    log("Starting execution")
    
    -- ロッド検証
    local isValid = false
    for _, rod in ipairs(AVAILABLE_RODS) do
        if rod == CONFIG.ROD_NAME then
            isValid = true
            break
        end
    end
    
    if not isValid then
        warn("Invalid rod name: " .. CONFIG.ROD_NAME)
        return
    end
    
    -- フックは最小限に
    safeHook()
    
    wait(1)
    
    -- UI操作
    local success = manipulateUI()
    
    if success then
        log("Success")
        resetCamera()
    else
        log("UI failed, trying direct")
        wait(1)
        directRequest()
    end
    
    log("Complete")
end

-- シンプルなGUI
local function createGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SantaGUI"
    ScreenGui.ResetOnSpawn = false
    
    pcall(function()
        ScreenGui.Parent = game.CoreGui
    end)
    
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer.PlayerGui
    end
    
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 300, 0, 200)
    Frame.Position = UDim2.new(0.5, -150, 0.3, 0)
    Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Frame.BorderSizePixel = 1
    Frame.BorderColor3 = Color3.fromRGB(100, 100, 100)
    Frame.Active = true
    Frame.Draggable = true
    Frame.Parent = ScreenGui
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 35)
    Title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    Title.BorderSizePixel = 0
    Title.Text = "Santa Rod"
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 16
    Title.Parent = Frame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.9, 0, 0, 20)
    Label.Position = UDim2.new(0.05, 0, 0, 45)
    Label.BackgroundTransparency = 1
    Label.Text = "Rod Name:"
    Label.TextColor3 = Color3.new(1, 1, 1)
    Label.Font = Enum.Font.SourceSans
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame
    
    local TextBox = Instance.new("TextBox")
    TextBox.Size = UDim2.new(0.9, 0, 0, 30)
    TextBox.Position = UDim2.new(0.05, 0, 0, 70)
    TextBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    TextBox.BorderSizePixel = 1
    TextBox.BorderColor3 = Color3.fromRGB(80, 80, 80)
    TextBox.Text = CONFIG.ROD_NAME
    TextBox.TextColor3 = Color3.new(1, 1, 1)
    TextBox.Font = Enum.Font.SourceSans
    TextBox.TextSize = 13
    TextBox.ClearTextOnFocus = false
    TextBox.Parent = Frame
    
    local ExecButton = Instance.new("TextButton")
    ExecButton.Size = UDim2.new(0.9, 0, 0, 35)
    ExecButton.Position = UDim2.new(0.05, 0, 0, 110)
    ExecButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    ExecButton.BorderSizePixel = 0
    ExecButton.Text = "Execute"
    ExecButton.TextColor3 = Color3.new(1, 1, 1)
    ExecButton.Font = Enum.Font.SourceSansBold
    ExecButton.TextSize = 14
    ExecButton.Parent = Frame
    
    ExecButton.MouseButton1Click:Connect(function()
        CONFIG.ROD_NAME = TextBox.Text
        ExecButton.Text = "Running..."
        ExecButton.BackgroundColor3 = Color3.fromRGB(150, 150, 50)
        
        spawn(function()
            main()
        end)
        
        wait(3)
        ExecButton.Text = "Done"
        ExecButton.BackgroundColor3 = Color3.fromRGB(50, 100, 150)
        wait(2)
        ExecButton.Text = "Execute"
        ExecButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    end)
    
    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0.9, 0, 0, 30)
    CloseButton.Position = UDim2.new(0.05, 0, 0, 155)
    CloseButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    CloseButton.BorderSizePixel = 0
    CloseButton.Text = "Close"
    CloseButton.TextColor3 = Color3.new(1, 1, 1)
    CloseButton.Font = Enum.Font.SourceSans
    CloseButton.TextSize = 13
    CloseButton.Parent = Frame
    
    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)
end

-- 起動
wait(0.5)
createGUI()

-- 自動実行（コメント解除で有効化）
-- wait(3)
-- main()
