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
            Url = WORKER_URL .. "/auth", -- Thêm /auth để vào đúng cổng xác thực
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
        
        -- Chạy script trong một luồng riêng để không làm treo UI Loader
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

local function saveKey(key) if writefile then writefile(KEY_FILE, key) end end
local function loadSavedKey()
    if isfile and readfile and isfile(KEY_FILE) then
        local key = readfile(KEY_FILE)
        if key and key ~= "" then return key end
    end
    return nil
end

-- ============================================
-- AUTO KEY CHECK & GUI
-- ============================================

local savedKey = loadSavedKey()
if savedKey then
    onMessage("Saved key found, verifying...")
    if verifyAndLoadScript(savedKey) then
        onMessage("✓ Auto login successful!")
        return 
    end
end

task.spawn(function()
    local TweenService = game:GetService("TweenService")
    local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "7hubKeySystem"
    ScreenGui.Parent = PlayerGui

    local MainFrame = Instance.new("Frame")
    MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    MainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    MainFrame.Size = UDim2.new(0, 400, 0, 300)
    MainFrame.Parent = ScreenGui
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

    local Header = Instance.new("Frame")
    Header.BackgroundColor3 = Color3.fromRGB(255, 169, 18)
    Header.Size = UDim2.new(1, 0, 0, 60)
    Header.Parent = MainFrame
    Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Position = UDim2.new(0, 30, 0, 90)
    StatusLabel.Size = UDim2.new(1, -60, 0, 30)
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.Text = "Enter your key to continue"
    StatusLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
    StatusLabel.TextSize = 14
    StatusLabel.Parent = MainFrame

    local KeyInput = Instance.new("TextBox")
    KeyInput.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    KeyInput.Position = UDim2.new(0, 30, 0, 130)
    KeyInput.Size = UDim2.new(1, -60, 0, 45)
    KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyInput.PlaceholderText = "Enter key here..."
    KeyInput.Parent = MainFrame
    Instance.new("UICorner", KeyInput).CornerRadius = UDim.new(0, 8)

    local GetKeyBtn = Instance.new("TextButton")
    GetKeyBtn.Text = "GET KEY"
    GetKeyBtn.BackgroundColor3 = Color3.fromRGB(255, 169, 18)
    GetKeyBtn.Position = UDim2.new(0, 30, 0, 190)
    GetKeyBtn.Size = UDim2.new(0.43, 0, 0, 40)
    GetKeyBtn.Parent = MainFrame
    Instance.new("UICorner", GetKeyBtn).CornerRadius = UDim.new(0, 8)

    local VerifyBtn = Instance.new("TextButton")
    VerifyBtn.Text = "VERIFY KEY"
    VerifyBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    VerifyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    VerifyBtn.Position = UDim2.new(0.53, 0, 0, 190)
    VerifyBtn.Size = UDim2.new(0.43, 0, 0, 40)
    VerifyBtn.Parent = MainFrame
    Instance.new("UICorner", VerifyBtn).CornerRadius = UDim.new(0, 8)

    GetKeyBtn.MouseButton1Click:Connect(function()
        if copyLink() then
            StatusLabel.Text = "✓ Link copied to clipboard!"
            StatusLabel.TextColor3 = Color3.fromRGB(0, 220, 80)
            task.wait(2)
            StatusLabel.Text = "Enter your key to continue"
            StatusLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
        end
    end)

    VerifyBtn.MouseButton1Click:Connect(function()
        StatusLabel.Text = "Verifying key..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 169, 18)
        
        if verifyAndLoadScript(KeyInput.Text) then
            saveKey(KeyInput.Text)
            StatusLabel.Text = "✓ Valid key! Loading script..."
            StatusLabel.TextColor3 = Color3.fromRGB(0, 220, 80)
            task.wait(1)
            ScreenGui:Destroy()
        else
            StatusLabel.Text = "✕ Invalid or expired key"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
            task.wait(2)
            StatusLabel.Text = "Enter your key to continue"
            StatusLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
        end
    end)
end)
