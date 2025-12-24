-- Fisch Santa Rod Request Exploit (Delta Compatible)
-- Metamethod Hookを使用してサンタメニューを強制的に開く

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- 設定
local CONFIG = {
    ROD_NAME = "Santa's Miracle Rod", -- リクエストしたいロッドの名前を変更
    DEBUG = true, -- デバッグログを表示
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
        print("[🎅 Santa Exploit] " .. msg)
    end
end

local function warn_log(msg)
    warn("[🎅 Santa Exploit] " .. msg)
end

-- DataControllerのフック
local function bypassDataController()
    log("DataControllerをバイパス中...")
    
    local success = pcall(function()
        local DataController = require(ReplicatedStorage.client.legacyControllers.DataController)
        
        -- fetchメソッドをフック
        local oldFetch = DataController.fetch
        DataController.fetch = function(key)
            if key == "Fischmas2025" then
                log("Fischmas2025データを偽装")
                return {
                    RodWished = "", -- まだ願っていないことにする
                    hasWished = false
                }
            end
            return oldFetch(key)
        end
        
        log("DataController バイパス成功")
    end)
    
    if not success then
        warn_log("DataController バイパス失敗")
    end
end

-- RemoteEventのフック
local function hookRemoteEvents()
    log("RemoteEventをフック中...")
    
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    local oldIndex = mt.__index
    
    setreadonly(mt, false)
    
    mt.__namecall = newcclosure(function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        
        -- InvokeServerをフック
        if method == "InvokeServer" then
            if self.Name == "santa_IsRodOwned" then
                log("santa_IsRodOwned をフック - false を返す")
                return false -- 常に所有していないことにする
            end
            
            if self.Name == "santa_RequestRod" then
                log("santa_RequestRod が呼ばれました: " .. tostring(args[1]))
            end
        end
        
        return oldNamecall(self, ...)
    end)
    
    mt.__index = newcclosure(function(self, key)
        local result = oldIndex(self, key)
        
        -- Visibleプロパティをフック（メニューを強制表示）
        if typeof(self) == "Instance" and self:IsA("GuiObject") then
            if self.Name == "ChristmasLetter" and key == "Visible" then
                log("ChristmasLetter.Visible をフック")
                return true
            end
            
            if self.Name == "SignHere" and key == "Visible" then
                log("SignHere.Visible をフック")
                return true
            end
            
            if self.Name == "Date" and key == "Visible" then
                log("Date.Visible をフック - 非表示")
                return false
            end
        end
        
        return result
    end)
    
    setreadonly(mt, true)
    log("Metamethod フック完了")
end

-- モジュールのToggle関数を直接呼び出す
local function forceOpenMenu()
    log("メニューを強制的に開いています...")
    
    local success, result = pcall(function()
        -- christmas モジュールを探す
        local christmas = ReplicatedStorage:FindFirstChild("shared")
        if christmas then
            christmas = christmas:FindFirstChild("modules")
            if christmas then
                christmas = christmas:FindFirstChild("christmas")
                if christmas then
                    local christmasModule = require(christmas)
                    
                    -- init関数を呼ぶ
                    if christmasModule.init then
                        christmasModule.init()
                        log("christmas.init() 実行")
                    end
                    
                    -- Toggle関数を呼ぶ
                    if christmasModule.Toggle then
                        christmasModule:Toggle(true)
                        log("christmas:Toggle(true) 実行")
                        return true
                    end
                end
            end
        end
        return false
    end)
    
    if success and result then
        log("メニューを開くことに成功")
        return true
    else
        warn_log("メニューを開けませんでした")
        return false
    end
end

-- UIを直接操作
local function manipulateUI()
    log("UIを直接操作します...")
    
    wait(1)
    
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
    if not PlayerGui then
        warn_log("PlayerGuiが見つかりません")
        return false
    end
    
    local christmas = PlayerGui:WaitForChild("christmas", 5)
    if not christmas then
        warn_log("christmas UIが見つかりません")
        return false
    end
    
    -- SantasLetterボタンをクリック
    local right = christmas:FindFirstChild("right")
    if right then
        local santasLetter = right:FindFirstChild("SantasLetter")
        if santasLetter then
            log("SantasLetterボタンを押します")
            
            -- ボタンの全てのコネクションを発火
            for _, connection in pairs(getconnections(santasLetter.Activated)) do
                connection:Fire()
            end
            
            wait(1)
        end
    end
    
    -- ChristmasLetterを強制表示
    local christmasLetter = christmas:FindFirstChild("ChristmasLetter")
    if christmasLetter then
        log("ChristmasLetterを強制表示")
        christmasLetter.Visible = true
        
        local safezone = christmasLetter:FindFirstChild("Safezone")
        if safezone then
            -- Dateを非表示
            local dateLabel = safezone:FindFirstChild("Date")
            if dateLabel then
                dateLabel.Visible = false
            end
            
            -- SignHereを表示
            local signHere = safezone:FindFirstChild("SignHere")
            if signHere then
                signHere.Visible = true
            end
            
            -- TextBoxに入力
            local textBox = safezone:FindFirstChild("TextBox")
            if textBox then
                log("テキストボックスに入力: " .. CONFIG.ROD_NAME)
                textBox.Text = CONFIG.ROD_NAME
                
                -- FocusLostを発火
                for _, connection in pairs(getconnections(textBox.FocusLost)) do
                    connection:Fire()
                end
                
                wait(0.5)
                
                -- SignHereボタンをクリック（6回）
                if signHere then
                    log("SignHereボタンを6回クリックします...")
                    
                    for i = 1, 6 do
                        wait(0.3)
                        
                        for _, connection in pairs(getconnections(signHere.Activated)) do
                            connection:Fire()
                        end
                        
                        log("クリック " .. i .. "/6")
                    end
                    
                    log("UIの操作が完了しました")
                    return true
                end
            end
        end
    end
    
    return false
end

-- 直接RemoteEventを呼び出す
local function directRequest()
    log("サーバーに直接リクエストを送信...")
    
    local events = ReplicatedStorage:FindFirstChild("events")
    if not events then
        warn_log("ReplicatedStorage.eventsが見つかりません")
        return false
    end
    
    local santaRequestRod = events:FindFirstChild("santa_RequestRod")
    if not santaRequestRod then
        warn_log("santa_RequestRodが見つかりません")
        return false
    end
    
    local success, result = pcall(function()
        return santaRequestRod:InvokeServer(CONFIG.ROD_NAME)
    end)
    
    if success then
        log("✅ サーバーリクエスト成功!")
        log("結果: " .. tostring(result))
        return true
    else
        warn_log("❌ サーバーリクエスト失敗: " .. tostring(result))
        return false
    end
end

-- カメラをリセット
local function resetCamera()
    wait(1)
    local camera = workspace.CurrentCamera
    if camera then
        camera.CameraType = Enum.CameraType.Custom
        log("カメラをリセット")
    end
end

-- メイン実行
local function main()
    log("========================================")
    log("  Fisch Santa Rod Exploit (Delta)")
    log("========================================")
    log("ターゲットロッド: " .. CONFIG.ROD_NAME)
    log("")
    
    -- ロッドが有効かチェック
    local isValid = false
    for _, rod in ipairs(AVAILABLE_RODS) do
        if rod == CONFIG.ROD_NAME then
            isValid = true
            break
        end
    end
    
    if not isValid then
        warn_log("❌ 無効なロッド名です!")
        warn_log("利用可能なロッド:")
        for _, rod in ipairs(AVAILABLE_RODS) do
            print("  - " .. rod)
        end
        return
    end
    
    log("ステップ1: Metamethodフックを設定...")
    hookRemoteEvents()
    
    log("ステップ2: DataControllerをバイパス...")
    bypassDataController()
    
    log("ステップ3: UIを操作...")
    local uiSuccess = manipulateUI()
    
    if uiSuccess then
        log("✅ UI操作成功 - ロッドがリクエストされました")
        resetCamera()
    else
        log("⚠️ UI操作失敗 - 直接リクエストを試みます...")
        wait(1)
        
        if directRequest() then
            log("✅ 直接リクエスト成功!")
        else
            warn_log("❌ 全ての方法が失敗しました")
        end
    end
    
    log("")
    log("========================================")
    log("  実行完了")
    log("========================================")
end

-- GUIコントロールパネル
local function createGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SantaExploitGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local success = pcall(function()
        ScreenGui.Parent = game:GetService("CoreGui")
    end)
    
    if not success then
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
    Title.Text = "🎅 Santa Rod Exploit"
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
    ExecuteButton.Text = "🎁 Request Rod"
    ExecuteButton.TextColor3 = Color3.new(1, 1, 1)
    ExecuteButton.Font = Enum.Font.GothamBold
    ExecuteButton.TextSize = 18
    ExecuteButton.Parent = Frame
    
    local ExecuteCorner = Instance.new("UICorner")
    ExecuteCorner.CornerRadius = UDim.new(0, 8)
    ExecuteCorner.Parent = ExecuteButton
    
    ExecuteButton.MouseButton1Click:Connect(function()
        CONFIG.ROD_NAME = TextBox.Text
        ExecuteButton.Text = "⏳ Executing..."
        ExecuteButton.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
        
        task.spawn(main)
        
        wait(2)
        ExecuteButton.Text = "✅ Done!"
        ExecuteButton.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
        
        wait(2)
        ExecuteButton.Text = "🎁 Request Rod"
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
    
    log("GUIを作成しました")
end

-- 実行
log("スクリプト読み込み完了")
log("GUIを起動しています...")
createGUI()

-- オートスタートの場合はこれをアンコメント
-- wait(3)
-- main()
