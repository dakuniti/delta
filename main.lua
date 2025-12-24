-- Fisch Santa Rod Request Exploit (Delta Fixed)
-- ZIndexBehavior エラーを修正

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- 設定
local CONFIG = {
    ROD_NAME = "Santa's Miracle Rod",
    DEBUG = true,
}

-- 利用可能なロッド一覧
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

local function warn_log(msg)
    warn("[Santa] " .. msg)
end

-- DataControllerバイパス
local function bypassDataController()
    log("DataControllerをバイパス中...")
    
    pcall(function()
        local DataController = require(ReplicatedStorage.client.legacyControllers.DataController)
        local oldFetch = DataController.fetch
        
        DataController.fetch = function(key)
            if key == "Fischmas2025" then
                log("Fischmas2025データを偽装")
                return {
                    RodWished = "",
                    hasWished = false
                }
            end
            return oldFetch(key)
        end
        
        log("DataController バイパス成功")
    end)
end

-- メタメソッドフック
local function hookRemoteEvents()
    log("RemoteEventをフック中...")
    
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    local oldIndex = mt.__index
    
    setreadonly(mt, false)
    
    mt.__namecall = function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        
        if method == "InvokeServer" then
            if self.Name == "santa_IsRodOwned" then
                log("santa_IsRodOwned フック - false返却")
                return false
            end
            
            if self.Name == "santa_RequestRod" then
                log("santa_RequestRod 呼び出し: " .. tostring(args[1]))
            end
        end
        
        return oldNamecall(self, ...)
    end
    
    mt.__index = function(self, key)
        local result = oldIndex(self, key)
        
        if typeof(self) == "Instance" and self:IsA("GuiObject") then
            if self.Name == "ChristmasLetter" and key == "Visible" then
                return true
            end
            
            if self.Name == "SignHere" and key == "Visible" then
                return true
            end
            
            if self.Name == "Date" and key == "Visible" then
                return false
            end
        end
        
        return result
    end
    
    setreadonly(mt, true)
    log("フック完了")
end

-- UI操作
local function manipulateUI()
    log("UI操作開始...")
    
    wait(1)
    
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
    if not PlayerGui then
        warn_log("PlayerGui見つからず")
        return false
    end
    
    local christmas = PlayerGui:WaitForChild("christmas", 5)
    if not christmas then
        warn_log("christmas UI見つからず")
        return false
    end
    
    -- SantasLetterボタンクリック
    local right = christmas:FindFirstChild("right")
    if right then
        local santasLetter = right:FindFirstChild("SantasLetter")
        if santasLetter then
            log("SantasLetterボタン押下")
            
            for _, conn in pairs(getconnections(santasLetter.Activated)) do
                conn:Fire()
            end
            
            wait(1)
        end
    end
    
    -- ChristmasLetter強制表示
    local christmasLetter = christmas:FindFirstChild("ChristmasLetter")
    if christmasLetter then
        log("ChristmasLetter表示")
        christmasLetter.Visible = true
        
        local safezone = christmasLetter:FindFirstChild("Safezone")
        if safezone then
            -- Date非表示
            local dateLabel = safezone:FindFirstChild("Date")
            if dateLabel then
                dateLabel.Visible = false
            end
            
            -- SignHere表示
            local signHere = safezone:FindFirstChild("SignHere")
            if signHere then
                signHere.Visible = true
            end
            
            -- TextBox入力
            local textBox = safezone:FindFirstChild("TextBox")
            if textBox then
                log("テキスト入力: " .. CONFIG.ROD_NAME)
                textBox.Text = CONFIG.ROD_NAME
                
                for _, conn in pairs(getconnections(textBox.FocusLost)) do
                    conn:Fire()
                end
                
                wait(0.5)
                
                -- SignHere 6回クリック
                if signHere then
                    log("SignHere 6回クリック開始...")
                    
                    for i = 1, 6 do
                        wait(0.3)
                        
                        for _, conn in pairs(getconnections(signHere.Activated)) do
                            conn:Fire()
                        end
                        
                        log("クリック " .. i .. "/6")
                    end
                    
                    log("UI操作完了!")
                    return true
                end
            end
        end
    end
    
    return false
end

-- 直接リクエスト
local function directRequest()
    log("直接リクエスト送信...")
    
    local events = ReplicatedStorage:FindFirstChild("events")
    if not events then
        warn_log("eventsフォルダ見つからず")
        return false
    end
    
    local santaRequestRod = events:FindFirstChild("santa_RequestRod")
    if not santaRequestRod then
        warn_log("santa_RequestRod見つからず")
        return false
    end
    
    local success, result = pcall(function()
        return santaRequestRod:InvokeServer(CONFIG.ROD_NAME)
    end)
    
    if success then
        log("SUCCESS! 結果: " .. tostring(result))
        return true
    else
        warn_log("FAILED! エラー: " .. tostring(result))
        return false
    end
end

-- カメラリセット
local function resetCamera()
    wait(1)
    local camera = workspace.CurrentCamera
    if camera then
        camera.CameraType = Enum.CameraType.Custom
        log("カメラリセット")
    end
end

-- メイン実行
local function main()
    log("========================================")
    log("  Fisch Santa Rod Exploit")
    log("========================================")
    log("ターゲット: " .. CONFIG.ROD_NAME)
    log("")
    
    -- ロッド検証
    local isValid = false
    for _, rod in ipairs(AVAILABLE_RODS) do
        if rod == CONFIG.ROD_NAME then
            isValid = true
            break
        end
    end
    
    if not isValid then
        warn_log("無効なロッド名!")
        warn_log("利用可能なロッド:")
        for _, rod in ipairs(AVAILABLE_RODS) do
            print("  - " .. rod)
        end
        return
    end
    
    log("Step 1: フック設定")
    hookRemoteEvents()
    
    log("Step 2: DataControllerバイパス")
    bypassDataController()
    
    log("Step 3: UI操作")
    local uiSuccess = manipulateUI()
    
    if uiSuccess then
        log("SUCCESS: UI操作完了")
        resetCamera()
    else
        log("WARNING: UI失敗 - 直接リクエスト試行")
        wait(1)
        
        if directRequest() then
            log("SUCCESS: 直接リクエスト完了")
        else
            warn_log("ERROR: 全ての方法が失敗")
        end
    end
    
    log("")
    log("========================================")
    log("  実行完了")
    log("========================================")
end

-- GUI作成（ZIndexBehavior削除）
local function createGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SantaExploitGUI"
    ScreenGui.ResetOnSpawn = false
    -- ZIndexBehaviorを削除（Deltaで非対応）
    
    pcall(function()
        ScreenGui.Parent = game:GetService("CoreGui")
    end)
    
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer.PlayerGui
    end
    
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 350, 0, 250)
    Frame.Position = UDim2.new(0.5, -175, 0.3, 0)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Frame.BorderSizePixel = 0
    Frame.Active = true
    Frame.Draggable = true
    Frame.Parent = ScreenGui
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = Frame
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 50)
    Title.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    Title.Text = "Santa Rod Exploit"
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 20
    Title.Parent = Frame
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 12)
    TitleCorner.Parent = Title
    
    local RodLabel = Instance.new("TextLabel")
    RodLabel.Size = UDim2.new(0.9, 0, 0, 25)
    RodLabel.Position = UDim2.new(0.05, 0, 0, 60)
    RodLabel.BackgroundTransparency = 1
    RodLabel.Text = "Rod Name:"
    RodLabel.TextColor3 = Color3.new(1, 1, 1)
    RodLabel.Font = Enum.Font.Gotham
    RodLabel.TextSize = 14
    RodLabel.TextXAlignment = Enum.TextXAlignment.Left
    RodLabel.Parent = Frame
    
    local TextBox = Instance.new("TextBox")
    TextBox.Size = UDim2.new(0.9, 0, 0, 40)
    TextBox.Position = UDim2.new(0.05, 0, 0, 90)
    TextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    TextBox.Text = CONFIG.ROD_NAME
    TextBox.TextColor3 = Color3.new(1, 1, 1)
    TextBox.Font = Enum.Font.Gotham
    TextBox.TextSize = 14
    TextBox.ClearTextOnFocus = false
    TextBox.Parent = Frame
    
    local TextBoxCorner = Instance.new("UICorner")
    TextBoxCorner.CornerRadius = UDim.new(0, 8)
    TextBoxCorner.Parent = TextBox
    
    local ExecuteButton = Instance.new("TextButton")
    ExecuteButton.Size = UDim2.new(0.9, 0, 0, 45)
    ExecuteButton.Position = UDim2.new(0.05, 0, 0, 145)
    ExecuteButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    ExecuteButton.Text = "Request Rod"
    ExecuteButton.TextColor3 = Color3.new(1, 1, 1)
    ExecuteButton.Font = Enum.Font.GothamBold
    ExecuteButton.TextSize = 18
    ExecuteButton.Parent = Frame
    
    local ExecuteCorner = Instance.new("UICorner")
    ExecuteCorner.CornerRadius = UDim.new(0, 8)
    ExecuteCorner.Parent = ExecuteButton
    
    ExecuteButton.MouseButton1Click:Connect(function()
        CONFIG.ROD_NAME = TextBox.Text
        ExecuteButton.Text = "Executing..."
        ExecuteButton.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
        
        spawn(function()
            main()
        end)
        
        wait(2)
        ExecuteButton.Text = "Done!"
        ExecuteButton.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
        
        wait(2)
        ExecuteButton.Text = "Request Rod"
        ExecuteButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    end)
    
    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0.9, 0, 0, 35)
    CloseButton.Position = UDim2.new(0.05, 0, 0, 200)
    CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    CloseButton.Text = "Close"
    CloseButton.TextColor3 = Color3.new(1, 1, 1)
    CloseButton.Font = Enum.Font.Gotham
    CloseButton.TextSize = 14
    CloseButton.Parent = Frame
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 8)
    CloseCorner.Parent = CloseButton
    
    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)
    
    log("GUI作成完了")
end

-- スクリプト起動
log("スクリプト読み込み完了")
log("GUIを起動中...")
createGUI()

-- オートスタート（コメント解除で有効化）
-- wait(3)
-- main()
