-- ============================================
-- 7HUB LOADER SCRIPT (KEYLESS CLIENT)
-- ============================================

-- ============================================
-- GAME ID CHECK
-- ============================================
local ALLOWED_GAMES = {
    [96537472072550] = true,
    [9872472334] = true
}

local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function notify(message)
    pcall(function()
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = "[7hub] " .. tostring(message)
        })
    end)
end

if not ALLOWED_GAMES[game.PlaceId] then
    notify("Script only supports Evade and Evade Legacy")
    task.wait(2)
    LocalPlayer:Kick("Script only supports Evade and Evade Legacy")
    return
end

-- ============================================
-- FETCH & LOAD MAIN SCRIPT
-- ============================================
-- ĐẢM BẢO LINK KHÔNG CÓ DẤU / Ở CUỐI
local WORKER_URL = "https://7hub.camminhtam1.workers.dev"

notify("Loading 7hub...")

local success, response = pcall(function()
    return game:HttpGet(WORKER_URL .. "/main")
end)

if success and response and response ~= "" then
    local func, err = loadstring(response)
    if func then
        task.spawn(function()
            local runSuccess, runErr = pcall(func)
            if not runSuccess then 
                warn("[7hub] Main Script Runtime Error: " .. tostring(runErr)) 
            else
                notify("Successfully loaded!")
            end
        end)
    else
        warn("[7hub] Syntax Error: " .. tostring(err))
        notify("Failed to load script (Syntax Error).")
    end
else
    warn("[7hub] Failed to connect to server.")
    notify("Failed to fetch script from server.")
end
