-- ============================================
-- 7HUB LOADER SCRIPT (SECURE CLIENT)
-- ============================================
local KEY_FILE = "7hub_key.txt"

-- ============================================
-- GAME ID CHECK
-- ============================================
local ALLOWED_GAMES = {
    [96537472072550] = true,
    [9872472334] = true
}

if not ALLOWED_GAMES[game.PlaceId] then
    game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
        Text = "[7hub] Script only supports Evade and Evade Legacy"
    })
    task.wait(2)
    game:GetService("Players").LocalPlayer:Kick("Script only supports Evade and Evade Legacy")
    return
end

-- ============================================
-- CORE VARIABLES & FUNCTIONS
-- ============================================
local onMessage = function(message)
    warn("[7hub DEBUG] " .. tostring(message))
    pcall(function()
        game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
            Text = "[7hub] " .. tostring(message)
        })
    end)
end

repeat task.wait(1) until game:IsLoaded() or game.Players.LocalPlayer

local requestSending = false
local fRequest = request or http_request or (syn and syn.request) or (http and http.request)
local fGetHwid = gethwid or function() return tostring(game:GetService("Players").LocalPlayer.UserId) end
local HttpService = game:GetService("HttpService")

-- ĐẢM BẢO LINK KHÔNG CÓ DẤU / Ở CUỐI
local WORKER_URL = "https://7hub.camminhtam1.workers.dev"

-- ============================================
-- API COMMUNICATION & UTILS
-- ============================================
local function lDigest(input)
    local inputStr = tostring(input)
    local hashHex = ""
    for i = 1, #inputStr do
        hashHex = hashHex .. string.format("%02x", string.byte(inputStr, i))
    end
    return hashHex
end

local host = "https://api.platoboost.com"
pcall(function()
    local hostRes = fRequest({ Url = host .. "/public/connectivity", Method = "GET" })
    if hostRes.StatusCode ~= 200 and hostRes.StatusCode ~= 429 then
        host = "https://api.platoboost.net"
    end
end)

local function copyLink()
    local success, response = pcall(function()
        return fRequest({
            Url = host .. "/public/start",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                service = 20358,
                identifier = lDigest(fGetHwid())
            })
        })
    end)
    if response and response.StatusCode == 200 then
        local decoded = HttpService:JSONDecode(response.Body)
        if decoded.success then
            local setclip = setclipboard or toclipboard
            if setclip then setclip(decoded.data.url) end
            onMessage("Link copied! Open browser to get key")
            return true
        end
    end
    onMessage("Failed to get link. Please try again.")
    return false
end

local function verifyAndLoadScript(key)
    if requestSending then return false end
    requestSending = true
    local success, response = pcall(function()
        return fRequest({
            Url = WORKER_URL .. "/auth",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode({
                hwid = lDigest(fGetHwid()),
                key = key
            })
        })
    end)
    requestSending = false
    if success and response and response.StatusCode == 200 then
        local scriptCode = response.Body
        local func, err = loadstring(scriptCode)
        if not func then
            onMessage("Lỗi cú pháp Script: " .. tostring(err))
            return false
        end
        task.spawn(function()
            local runSuccess, runErr = pcall(func)
            if not runSuccess then warn("[7hub] Main Script Runtime Error: " .. tostring(runErr)) end
        end)
        return true
    else
        local errorMsg = response and response.Body or "Không thể kết nối Server"
        onMessage("Lỗi xác thực: " .. tostring(errorMsg))
        return false
    end
end

-- ============================================
-- KEY SAVE / LOAD
-- ============================================
local function saveKey(key)
    if writefile then writefile(KEY_FILE, key) end
end

local function loadSavedKey()
    if isfile and readfile and isfile(KEY_FILE) then
        local key = readfile(KEY_FILE)
        if key and key ~= "" then return key end
    end
    return nil
end

local function deleteSavedKey()
    if isfile and delfile and isfile(KEY_FILE) then
        delfile(KEY_FILE)
    end
end

-- ============================================
-- AUTO KEY CHECK
-- ============================================
local savedKey = loadSavedKey()
if savedKey then
    onMessage("Saved key found, verifying...")
    task.wait(1)
    local verified = verifyAndLoadScript(savedKey)
    if verified then
        onMessage("✓ Auto login successful!")
        return
    else
        onMessage("Saved key expired, please get a new key.")
        deleteSavedKey()
        task.wait(1.5)
    end
end

-- ============================================
-- GUI - 7HUB KEY SYSTEM (UI từ loader2)
-- ============================================
task.spawn(function()
    local TweenService = game:GetService("TweenService")
    local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "7hubKeySystem"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = PlayerGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    MainFrame.Size = UDim2.new(0, 400, 0, 300)
    MainFrame.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 12)
    MainCorner.Parent = MainFrame

    -- Header
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.BackgroundColor3 = Color3.fromRGB(255, 169, 18)
    Header.BorderSizePixel = 0
    Header.Size = UDim2.new(1, 0, 0, 60)
    Header.Parent = MainFrame

    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 12)
    HeaderCorner.Parent = Header

    local HeaderGradient = Instance.new("UIGradient")
    HeaderGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 169, 18)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(230, 150, 10))
    }
    HeaderGradient.Rotation = 45
    HeaderGradient.Parent = Header

    local LogoText = Instance.new("TextLabel")
    LogoText.Name = "LogoText"
    LogoText.BackgroundTransparency = 1
    LogoText.Position = UDim2.new(0, 20, 0, 0)
    LogoText.Size = UDim2.new(0.6, 0, 1, 0)
    LogoText.Font = Enum.Font.GothamBold
    LogoText.Text = "7hub"
    LogoText.TextColor3 = Color3.fromRGB(0, 0, 0)
    LogoText.TextSize = 32
    LogoText.TextXAlignment = Enum.TextXAlignment.Left
    LogoText.Parent = Header

    local SubtitleText = Instance.new("TextLabel")
    SubtitleText.Name = "SubtitleText"
    SubtitleText.BackgroundTransparency = 1
    SubtitleText.Position = UDim2.new(0, 20, 0, 32)
    SubtitleText.Size = UDim2.new(0.6, 0, 0, 20)
    SubtitleText.Font = Enum.Font.Gotham
    SubtitleText.Text = "key system"
    SubtitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    SubtitleText.TextSize = 14
    SubtitleText.TextXAlignment = Enum.TextXAlignment.Left
    SubtitleText.Parent = Header

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "CloseBtn"
    CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Position = UDim2.new(1, -45, 0, 15)
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextSize = 16
    CloseBtn.Parent = Header

    local CloseBtnCorner = Instance.new("UICorner")
    CloseBtnCorner.CornerRadius = UDim.new(0, 8)
    CloseBtnCorner.Parent = CloseBtn

    -- Content Frame
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Position = UDim2.new(0, 0, 0, 70)
    ContentFrame.Size = UDim2.new(1, 0, 1, -70)
    ContentFrame.Parent = MainFrame

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Name = "StatusLabel"
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Position = UDim2.new(0, 30, 0, 20)
    StatusLabel.Size = UDim2.new(1, -60, 0, 30)
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.Text = "Enter your key to continue"
    StatusLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
    StatusLabel.TextSize = 14
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Parent = ContentFrame

    -- Input Frame (có viền UIStroke đẹp)
    local InputFrame = Instance.new("Frame")
    InputFrame.Name = "InputFrame"
    InputFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    InputFrame.BorderSizePixel = 0
    InputFrame.Position = UDim2.new(0, 30, 0, 60)
    InputFrame.Size = UDim2.new(1, -60, 0, 45)
    InputFrame.Parent = ContentFrame

    local InputFrameCorner = Instance.new("UICorner")
    InputFrameCorner.CornerRadius = UDim.new(0, 8)
    InputFrameCorner.Parent = InputFrame

    local InputFrameStroke = Instance.new("UIStroke")
    InputFrameStroke.Color = Color3.fromRGB(40, 40, 40)
    InputFrameStroke.Thickness = 1
    InputFrameStroke.Parent = InputFrame

    local KeyInput = Instance.new("TextBox")
    KeyInput.Name = "KeyInput"
    KeyInput.BackgroundTransparency = 1
    KeyInput.Position = UDim2.new(0, 15, 0, 0)
    KeyInput.Size = UDim2.new(1, -30, 1, 0)
    KeyInput.Font = Enum.Font.Gotham
    KeyInput.PlaceholderText = "Enter key here..."
    KeyInput.PlaceholderColor3 = Color3.fromRGB(90, 90, 90)
    KeyInput.Text = ""
    KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyInput.TextSize = 14
    KeyInput.TextXAlignment = Enum.TextXAlignment.Left
    KeyInput.ClearTextOnFocus = false
    KeyInput.Parent = InputFrame

    -- Buttons (xếp dọc, full width)
    local GetKeyBtn = Instance.new("TextButton")
    GetKeyBtn.Name = "GetKeyBtn"
    GetKeyBtn.BackgroundColor3 = Color3.fromRGB(255, 169, 18)
    GetKeyBtn.BorderSizePixel = 0
    GetKeyBtn.Position = UDim2.new(0, 30, 0, 125)
    GetKeyBtn.Size = UDim2.new(1, -60, 0, 40)
    GetKeyBtn.Font = Enum.Font.GothamBold
    GetKeyBtn.Text = "GET KEY"
    GetKeyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    GetKeyBtn.TextSize = 15
    GetKeyBtn.Parent = ContentFrame

    local GetKeyBtnCorner = Instance.new("UICorner")
    GetKeyBtnCorner.CornerRadius = UDim.new(0, 8)
    GetKeyBtnCorner.Parent = GetKeyBtn

    local GetKeyGradient = Instance.new("UIGradient")
    GetKeyGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 169, 18)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(230, 150, 10))
    }
    GetKeyGradient.Rotation = 45
    GetKeyGradient.Parent = GetKeyBtn

    local VerifyBtn = Instance.new("TextButton")
    VerifyBtn.Name = "VerifyBtn"
    VerifyBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    VerifyBtn.BorderSizePixel = 0
    VerifyBtn.Position = UDim2.new(0, 30, 0, 175)
    VerifyBtn.Size = UDim2.new(1, -60, 0, 40)
    VerifyBtn.Font = Enum.Font.GothamBold
    VerifyBtn.Text = "VERIFY KEY"
    VerifyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    VerifyBtn.TextSize = 15
    VerifyBtn.Parent = ContentFrame

    local VerifyBtnCorner = Instance.new("UICorner")
    VerifyBtnCorner.CornerRadius = UDim.new(0, 8)
    VerifyBtnCorner.Parent = VerifyBtn

    -- Draggable
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end

    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    Header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInput and dragging then update(input) end
    end)

    -- Hover Effects
    local function buttonHover(btn, normal, hover)
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = hover}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = normal}):Play()
        end)
    end

    buttonHover(GetKeyBtn, Color3.fromRGB(255, 169, 18), Color3.fromRGB(255, 185, 50))
    buttonHover(VerifyBtn, Color3.fromRGB(35, 35, 35), Color3.fromRGB(55, 55, 55))
    buttonHover(CloseBtn, Color3.fromRGB(255, 50, 50), Color3.fromRGB(200, 30, 30))

    KeyInput.Focused:Connect(function()
        TweenService:Create(InputFrameStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(255, 169, 18), Thickness = 2}):Play()
    end)
    KeyInput.FocusLost:Connect(function()
        TweenService:Create(InputFrameStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(40, 40, 40), Thickness = 1}):Play()
    end)

    -- Button Clicks
    GetKeyBtn.MouseButton1Click:Connect(function()
        StatusLabel.Text = "Getting link..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 169, 18)
        local success = copyLink()
        if success then
            StatusLabel.Text = "✓ Link copied! Open browser to get key"
            StatusLabel.TextColor3 = Color3.fromRGB(0, 220, 80)
        else
            StatusLabel.Text = "✕ Failed to get link"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        end
        task.wait(3)
        StatusLabel.Text = "Enter your key to continue"
        StatusLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
    end)

    VerifyBtn.MouseButton1Click:Connect(function()
        if KeyInput.Text == "" then
            StatusLabel.Text = "✕ Please enter a key!"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
            task.wait(2)
            StatusLabel.Text = "Enter your key to continue"
            StatusLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
            return
        end
        StatusLabel.Text = "Verifying key..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 169, 18)
        VerifyBtn.Text = "PROCESSING..."
        local verified = verifyAndLoadScript(KeyInput.Text)
        if verified then
            saveKey(KeyInput.Text)
            StatusLabel.Text = "✓ Valid key! Loading script..."
            StatusLabel.TextColor3 = Color3.fromRGB(0, 220, 80)
            VerifyBtn.Text = "SUCCESS!"
            task.wait(1.5)
            for i = 0, 1, 0.1 do
                MainFrame.BackgroundTransparency = i
                task.wait(0.03)
            end
            ScreenGui:Destroy()
        else
            StatusLabel.Text = "✕ Invalid or expired key"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
            VerifyBtn.Text = "VERIFY KEY"
            task.wait(3)
            StatusLabel.Text = "Enter your key to continue"
            StatusLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
        end
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        for i = 0, 1, 0.1 do
            MainFrame.BackgroundTransparency = i
            task.wait(0.02)
        end
        ScreenGui:Destroy()
    end)

    -- Entrance Animation
    MainFrame.BackgroundTransparency = 1
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    task.wait(0.1)
    TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 400, 0, 300),
        Position = UDim2.new(0.5, -200, 0.5, -150),
        BackgroundTransparency = 0
    }):Play()
end)
