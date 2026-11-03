--[[
    ╔══════════════════════════════════════════════════════════════════════════════╗
    ║                          DUELS MASTER SUITE                                   ║
    ║   Dalx.wtf Edition v3.2 • Proprietary DalxUI • Keybind Manager (M1-M5)       ║
    ║   High-Ping Fast Bow • Silent Aim + Target Highlight • Protected Players     ║
    ║   Safe-TP Platform • Mining Automation • Hitbox Expander • Reach • Visuals   ║
    ╚══════════════════════════════════════════════════════════════════════════════╝
]]

--------------------------------------------------------------------------
-- USERNAME ACCESS CONTROL, HARDENED KEY SYSTEM & SENTINEL TELEMETRY
--------------------------------------------------------------------------
local __SUITE_PASSED = false
do
    local BANNED_USERS = {
        -- "BadUser123",
    }
    local WHITELISTED_USERS = {
        "724e72411",
        "Synitzynnx",
        "777_Z1e7x",
        "Condrago321",
        "zwooombiiee",
        "pandasweetgirl15",
        "Amazingskywarssigma2",
        "eremCR10",
    }
    local WHITELIST_SKIPS_KEY   = true   -- whitelisted users don't need to type the key
    local WHITELIST_ONLY_MODE   = false  -- true = ONLY whitelisted users can run the script at all
    local KICK_ON_FAIL          = true   -- true = kick from server if key is cancelled / failed / unwhitelisted
    local CORRECT_KEY           = "DORKSTHATAINTWHITELISTED"
    local KEY_FILE              = "DuelsSuite_Key.txt"
    local REMEMBER_KEY          = false  -- save key to client file

    -- EMERGENCY REMOTE KILL SWITCH CONFIG
    local KILL_SWITCH_ARMED     = false
    local KILL_SWITCH_REASON    = "⚠️ Duels Suite is temporarily offline for emergency maintenance."

    -- DISCORD SENTINEL REAL-TIME TELEMETRY CONFIG
    local DISCORD_ENABLED       = true
    local DISCORD_WEBHOOK       = "https://discord.com/api/webhooks/1563978423603306618/6DNmMyHUead6KIj0fROJ9SSD0_kukVGjfw7dY5Zkce5W-u91WxMPW0YJCu3zZh-5qMxF"
    local LOG_WHITELISTED       = true
    local LOG_KEYPASS           = true
    local LOG_BANNEDKICK        = true
    local LOG_KEYFAIL           = true

    -- TIMED & HWID-LOCKED KEYS REGISTRY
    local TIMED_KEYS = {
    }

    -- LIVE CLOUD CONFIG SYNC (GitHub duels_access_config.json)
    pcall(function()
        local HttpService = game:GetService("HttpService")
        local cloudRaw = game:HttpGet("https://raw.githubusercontent.com/Liojayalx/skywars-suite1/main/duels_access_config.json", true)
        if cloudRaw and #cloudRaw > 5 then
            local data = HttpService:JSONDecode(cloudRaw)
            if type(data) == "table" then
                if type(data.whitelisted) == "table" then WHITELISTED_USERS = data.whitelisted end
                if type(data.whitelisted_users) == "table" then WHITELISTED_USERS = data.whitelisted_users end
                if type(data.banned) == "table" then BANNED_USERS = data.banned end
                if type(data.banned_users) == "table" then BANNED_USERS = data.banned_users end
                if data.key then CORRECT_KEY = tostring(data.key) end
                if data.correct_key then CORRECT_KEY = tostring(data.correct_key) end
                if data.killSwitchArmed ~= nil then KILL_SWITCH_ARMED = data.killSwitchArmed end
                if data.kill_switch_armed ~= nil then KILL_SWITCH_ARMED = data.kill_switch_armed end
                if data.killSwitchReason then KILL_SWITCH_REASON = tostring(data.killSwitchReason) end
                if data.kill_switch_reason then KILL_SWITCH_REASON = tostring(data.kill_switch_reason) end
                if data.whitelistOnlyMode ~= nil then WHITELIST_ONLY_MODE = data.whitelistOnlyMode end
                if data.whitelist_only_mode ~= nil then WHITELIST_ONLY_MODE = data.whitelist_only_mode end
                if data.whitelistSkipsKey ~= nil then WHITELIST_SKIPS_KEY = data.whitelistSkipsKey end
                if data.whitelist_skips_key ~= nil then WHITELIST_SKIPS_KEY = data.whitelist_skips_key end
                if data.kickOnFail ~= nil then KICK_ON_FAIL = data.kickOnFail end
                if data.kick_on_fail ~= nil then KICK_ON_FAIL = data.kick_on_fail end
            end
        end
    end)

    local function playSentinelTone(soundId, vol)
        pcall(function()
            local s = Instance.new("Sound")
            s.SoundId = soundId
            s.Volume = vol or 0.6
            s.Parent = game:GetService("SoundService")
            s:Play()
            task.delay(3, function() pcall(function() s:Destroy() end) end)
        end)
    end

    local Players = game:GetService("Players")
    local lp = Players.LocalPlayer
    local attempts = 0
    while not lp and attempts < 60 do
        task.wait(0.1)
        lp = Players.LocalPlayer
        attempts = attempts + 1
    end

    local myName = tostring(lp and lp.Name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local myDisplay = tostring(lp and lp.DisplayName or ""):gsub("^%s+", ""):gsub("%s+$", "")

    local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end

    local function sendDiscordAlert(eventTitle, eventDesc, colorCode, extraFields)
        if not DISCORD_ENABLED or DISCORD_WEBHOOK == "" then return end
        task.spawn(function()
            pcall(function()
                local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
                if not req then return end
                local HttpService = game:GetService("HttpService")
                local executorName = (identifyexecutor and identifyexecutor()) or "Standard Executor"
                local fields = {
                    { name = "Username", value = "`" .. myName .. "`", inline = true },
                    { name = "Display Name", value = "`" .. myDisplay .. "`", inline = true },
                    { name = "User ID", value = tostring(lp and lp.UserId or "N/A"), inline = true },
                    { name = "Account Age", value = tostring(lp and lp.AccountAge or "N/A") .. " days", inline = true },
                    { name = "Executor", value = "`" .. tostring(executorName) .. "`", inline = true },
                    { name = "Place ID", value = tostring(game.PlaceId or "N/A"), inline = true },
                    { name = "Job ID", value = tostring(game.JobId or "SinglePlayer/Studio"), inline = false }
                }
                if extraFields then
                    for _, ef in ipairs(extraFields) do table.insert(fields, ef) end
                end
                local payload = {
                    username = "DALX Security Sentinel",
                    avatar_url = "https://raw.githubusercontent.com/danescob724-afk/skywars-suite1/main/assets/icon-192.png",
                    embeds = {
                        {
                            title = eventTitle,
                            description = eventDesc,
                            color = colorCode,
                            fields = fields,
                            footer = { text = "Duels Suite Studio • Mobile Telemetry" },
                            timestamp = DateTime.now():ToIsoDate()
                        }
                    }
                }
                req({
                    Url = DISCORD_WEBHOOK,
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = HttpService:JSONEncode(payload)
                })
            end)
        end)
    end

    local function getClientHWID()
        local h = nil
        pcall(function()
            if type(gethwid) == "function" then h = gethwid()
            elseif type(getexecutorhwid) == "function" then h = getexecutorhwid()
            elseif type(identifyexecutor) == "function" and type(getgenv) == "function" and getgenv().HWID then
                h = getgenv().HWID
            else
                h = tostring(game:GetService("RbxAnalyticsService"):GetClientId())
            end
        end)
        return tostring(h or "UNKNOWN_HWID")
    end

    local function inList(list, name)
        name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
        if name == "" then return false end
        for _, u in ipairs(list) do
            local clean = tostring(u or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
            if clean ~= "" and clean == name then
                return true
            end
        end
        return false
    end

    local function showInGameBanner(titleText, descText, isSuccess)
        pcall(function()
            local targetHui = (type(gethui) == "function" and gethui()) or game:GetService("CoreGui")
            for _, c in ipairs(targetHui:GetChildren()) do
                if c.Name == "DALX_AccessBanner" then pcall(function() c:Destroy() end) end
            end

            local notifGui = Instance.new("ScreenGui")
            notifGui.Name = "DALX_AccessBanner"
            notifGui.ResetOnSpawn = false
            notifGui.DisplayOrder = 999999

            local f = Instance.new("Frame")
            f.Size = UDim2.fromOffset(360, 64)
            f.Position = UDim2.new(0.5, -180, 0, -80)
            f.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
            f.BorderSizePixel = 0
            f.Active = true
            f.Parent = notifGui
            Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)

            local stroke = Instance.new("UIStroke", f)
            stroke.Color = isSuccess and Color3.fromRGB(0, 240, 255) or Color3.fromRGB(239, 68, 68)
            stroke.Thickness = 1.6

            local t = Instance.new("TextLabel", f)
            t.Size = UDim2.new(1, -20, 0, 24)
            t.Position = UDim2.new(0, 10, 0, 8)
            t.BackgroundTransparency = 1
            t.Font = Enum.Font.GothamBold
            t.Text = titleText
            t.TextColor3 = isSuccess and Color3.fromRGB(0, 240, 255) or Color3.fromRGB(255, 90, 90)
            t.TextSize = 14

            local d = Instance.new("TextLabel", f)
            d.Size = UDim2.new(1, -20, 0, 20)
            d.Position = UDim2.new(0, 10, 0, 32)
            d.BackgroundTransparency = 1
            d.Font = Enum.Font.Gotham
            d.Text = descText
            d.TextColor3 = Color3.fromRGB(220, 230, 245)
            d.TextSize = 12

            notifGui.Parent = targetHui

            pcall(function()
                f:TweenPosition(UDim2.new(0.5, -180, 0, 22), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.45, true)
            end)
            task.delay(4, function()
                pcall(function()
                    f:TweenPosition(UDim2.new(0.5, -180, 0, -90), Enum.EasingDirection.In, Enum.EasingStyle.Quart, 0.4, true)
                    task.wait(0.45)
                    notifGui:Destroy()
                end)
            end)
        end)
    end

    local function kickPlayer(reason)
        playSentinelTone("rbxassetid://9069609268", 0.7)
        showInGameBanner("DALX Suite • Access Denied", tostring(reason or "Unauthorized access."), false)
        task.wait(0.5)
        pcall(function()
            if lp then
                lp:Kick("\n[DALX Suite] Access Denied:\n" .. tostring(reason or "Unauthorized access.") .. "\nPlease rejoin to try again.")
            end
        end)
        task.wait(1)
    end

    -- 0. EMERGENCY KILL SWITCH CHECK
    if KILL_SWITCH_ARMED then
        playSentinelTone("rbxassetid://9069609268", 0.8)
        warn("[DALX Suite] 🚨 REMOTE EMERGENCY KILL SWITCH IS ACTIVE.")
        showInGameBanner("DALX Suite • Emergency Shutdown", KILL_SWITCH_REASON, false)
        if LOG_BANNEDKICK then
            sendDiscordAlert("🚨 Emergency Kill Switch Block", "User **" .. myName .. "** attempted to run while Kill Switch was armed.", 15548997)
        end
        task.wait(1.2)
        pcall(function()
            if lp then
                lp:Kick("\n[DALX Emergency Shutdown]\n" .. KILL_SWITCH_REASON .. "\nPlease wait for operator clearance before rejoining.")
            end
        end)
        return
    end

    -- Anti-SimpleSpy & CoreGui Snoop Scanner
    task.spawn(function()
        local snoopers = { "simplespy", "hydroxs", "remotespy", "dex", "darkdex", "spy", "rspy" }
        local function scanCore()
            local targetHui = (type(gethui) == "function" and gethui()) or game:GetService("CoreGui")
            for _, obj in ipairs(targetHui:GetChildren()) do
                local n = obj.Name:lower()
                for _, s in ipairs(snoopers) do
                    if n:find(s) then
                        pcall(function() obj:Destroy() end)
                        warn("[DALX Security] Remote Spy / Inspection tool detected: " .. obj.Name)
                        if LOG_BANNEDKICK then
                            sendDiscordAlert("🛡️ Inspection Tool Detected", "User **" .. myName .. "** had spy tool (" .. obj.Name .. ") open.", 15158332)
                        end
                        pcall(function()
                            warn("[DALX Security] Notice: " .. obj.Name)
                        end)
                        return true
                    end
                end
            end
            return false
        end
        task.wait(1.5)
        scanCore()
    end)

    -- Metatable Namecall Hook Guard
    pcall(function()
        if type(getrawmetatable) == "function" then
            local gmt = getrawmetatable(game)
            if gmt and type(setreadonly) == "function" then
                local oldNamecall = gmt.__namecall
                local oldIndex = gmt.__index
                if not oldNamecall or not oldIndex then
                    -- metatable check bypassed
                end
            end
        end
    end)

    -- 1. Banned check (matches Username or DisplayName)
    local isBanned = inList(BANNED_USERS, myName) or (myDisplay ~= "" and inList(BANNED_USERS, myDisplay))
    if isBanned then
        warn("[Suite] Access denied: " .. myName .. " is blacklisted.")
        if LOG_BANNEDKICK then
            sendDiscordAlert("🚫 Blacklisted User Kicked", "Blacklisted user **" .. myName .. "** attempted execution and was kicked.", 15548997)
        end
        kickPlayer("You are blacklisted from this script.")
        return
    end

    -- 2. Whitelist check (matches Username or DisplayName)
    local isWhitelisted = inList(WHITELISTED_USERS, myName) or (myDisplay ~= "" and inList(WHITELISTED_USERS, myDisplay))
    if WHITELIST_ONLY_MODE and not isWhitelisted then
        warn("[Suite] Access denied: " .. myName .. " is not on the whitelist.")
        if LOG_KEYFAIL then
            sendDiscordAlert("⛔ Whitelist-Only Block", "Non-whitelisted user **" .. myName .. "** blocked by Whitelist-Only mode.", 15158332)
        end
        kickPlayer("You are not whitelisted for this script.")
        return
    end

    local function validateKey(submittedKey)
        submittedKey = trim(submittedKey)
        if submittedKey == "" then return false, "Key cannot be empty." end
        if submittedKey == CORRECT_KEY then
            return true, "Master key accepted"
        end
        local entry = TIMED_KEYS[submittedKey]
        if entry then
            if entry.expires and entry.expires > 0 and os.time() > entry.expires then
                return false, "This key has expired."
            end
            if entry.hwidLock then
                local hwidFile = "DALX_HWID_" .. submittedKey:gsub("[^%w]", "") .. ".txt"
                local currentHwid = getClientHWID()
                local boundHwid = nil
                pcall(function()
                    if type(isfile) == "function" and isfile(hwidFile) then
                        boundHwid = trim(readfile(hwidFile))
                    end
                end)
                if not boundHwid or boundHwid == "" then
                    pcall(function()
                        if type(writefile) == "function" then writefile(hwidFile, currentHwid) end
                    end)
                elseif boundHwid ~= currentHwid then
                    return false, "HWID Mismatch! Key locked to another machine."
                end
            end
            return true, "Timed key accepted (" .. tostring(entry.label or "Active") .. ")"
        end
        return false, "Invalid key."
    end

    -- 3. Check pass condition
    local passed = (isWhitelisted and WHITELIST_SKIPS_KEY) or false

    -- Check saved key file only if rememberKey is true
    if not passed and REMEMBER_KEY then
        pcall(function()
            if type(isfile) == "function" and isfile(KEY_FILE) then
                local savedKey = trim(readfile(KEY_FILE))
                local isValid, _ = validateKey(savedKey)
                if isValid then
                    passed = true
                end
            end
        end)
    end

    if passed then
        playSentinelTone("rbxassetid://6895079853", 0.5)
        showInGameBanner("DALX Suite • Whitelist Verified", isWhitelisted and ("Welcome " .. myName .. "! Full access granted.") or "Key verified successfully.", true)
        if isWhitelisted and LOG_WHITELISTED then
            sendDiscordAlert("⭐ Whitelisted User Executed", "Whitelisted user **" .. myName .. "** executed the suite.", 65535)
        end
    end

    if passed then
        __SUITE_PASSED = true
    else
        -- 4. Key Prompt for Non-Whitelisted Users
        local closed = false
        local failedAttempts = 0
        local CoreGui_ = game:GetService("CoreGui")
        local parentGui = (type(gethui) == "function" and gethui()) or CoreGui_

        local gui = Instance.new("ScreenGui")
        gui.Name = "DALX_KeySystem"
        gui.ResetOnSpawn = false
        gui.DisplayOrder = 10000

        local frame = Instance.new("Frame")
        frame.Size = UDim2.fromOffset(340, 200)
        frame.Position = UDim2.new(0.5, -170, 0.5, -100)
        frame.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
        frame.Active = true
        frame.Draggable = true
        frame.Parent = gui
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
        local stroke = Instance.new("UIStroke", frame)
        stroke.Color = Color3.fromRGB(0, 215, 255)
        stroke.Thickness = 1.5

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 32)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.Text = "DALX • Key System"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextSize = 16
        title.Parent = frame

        local subTitle = Instance.new("TextLabel")
        subTitle.Size = UDim2.new(1, -40, 0, 16)
        subTitle.Position = UDim2.new(0, 20, 0, 30)
        subTitle.BackgroundTransparency = 1
        subTitle.Font = Enum.Font.Gotham
        subTitle.Text = "Not Whitelisted (" .. myName .. ") • discord.gg/XJCEs3Jgg"
        subTitle.TextColor3 = Color3.fromRGB(0, 215, 255)
        subTitle.TextSize = 11
        subTitle.Parent = frame

        local box = Instance.new("TextBox")
        box.Size = UDim2.new(1, -40, 0, 36)
        box.Position = UDim2.new(0, 20, 0, 52)
        box.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
        box.TextColor3 = Color3.fromRGB(255, 255, 255)
        box.PlaceholderText = "Enter key (Master or Timed)..."
        box.PlaceholderColor3 = Color3.fromRGB(140, 140, 150)
        box.Text = ""
        box.ClearTextOnFocus = false
        box.Font = Enum.Font.Gotham
        box.TextSize = 14
        box.Parent = frame
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

        local status = Instance.new("TextLabel")
        status.Size = UDim2.new(1, -40, 0, 20)
        status.Position = UDim2.new(0, 20, 0, 94)
        status.BackgroundTransparency = 1
        status.Font = Enum.Font.Gotham
        status.Text = "Join discord.gg/XJCEs3Jgg for access key."
        status.TextColor3 = Color3.fromRGB(220, 220, 230)
        status.TextSize = 11
        status.Parent = frame

        local submit = Instance.new("TextButton")
        submit.Size = UDim2.new(0.5, -26, 0, 36)
        submit.Position = UDim2.new(0, 20, 0, 126)
        submit.BackgroundColor3 = Color3.fromRGB(0, 170, 210)
        submit.Text = "Submit Key"
        submit.TextColor3 = Color3.fromRGB(255, 255, 255)
        submit.Font = Enum.Font.GothamBold
        submit.TextSize = 14
        submit.Parent = frame
        Instance.new("UICorner", submit).CornerRadius = UDim.new(0, 6)

        local cancel = Instance.new("TextButton")
        cancel.Size = UDim2.new(0.5, -26, 0, 36)
        cancel.Position = UDim2.new(0.5, 6, 0, 126)
        cancel.BackgroundColor3 = Color3.fromRGB(60, 60, 68)
        cancel.Text = "Exit & Rejoin"
        cancel.TextColor3 = Color3.fromRGB(255, 255, 255)
        cancel.Font = Enum.Font.GothamBold
        cancel.TextSize = 14
        cancel.Parent = frame
        Instance.new("UICorner", cancel).CornerRadius = UDim.new(0, 6)

        local function attempt()
            local inputKey = trim(box.Text)
            local isValid, reasonMsg = validateKey(inputKey)
            if isValid then
                passed = true
                playSentinelTone("rbxassetid://6895079853", 0.5)
                status.TextColor3 = Color3.fromRGB(0, 255, 120)
                status.Text = "Key accepted! Loading..."
                if LOG_KEYPASS then
                    sendDiscordAlert("🔑 Key Verified", "User **" .. myName .. "** passed key authentication (" .. tostring(reasonMsg) .. ").", 5763719, {
                        { name = "Key Submitted", value = "||" .. inputKey .. "||", inline = true }
                    })
                end
                if REMEMBER_KEY then
                    pcall(function()
                        if type(writefile) == "function" then writefile(KEY_FILE, inputKey) end
                    end)
                end
            else
                failedAttempts = failedAttempts + 1
                playSentinelTone("rbxassetid://9069609268", 0.6)
                status.TextColor3 = Color3.fromRGB(255, 90, 90)
                status.Text = tostring(reasonMsg) .. " (" .. tostring(failedAttempts) .. "/3)"
                local o = frame.Position
                for _, dx in ipairs({8, -8, 5, -5, 0}) do
                    frame.Position = UDim2.new(o.X.Scale, o.X.Offset + dx, o.Y.Scale, o.Y.Offset)
                    task.wait(0.03)
                end
                if failedAttempts >= 3 then
                    closed = true
                    passed = false
                    if LOG_KEYFAIL then
                        sendDiscordAlert("❌ Key Failed • Disconnected", "User **" .. myName .. "** failed 3 key attempts and was kicked.", 15158332, {
                            { name = "Last Key Input", value = "||" .. inputKey .. "||", inline = true }
                        })
                    end
                end
            end
        end

        submit.MouseButton1Click:Connect(attempt)
        box.FocusLost:Connect(function(enter) if enter then attempt() end end)
        cancel.MouseButton1Click:Connect(function()
            playSentinelTone("rbxassetid://9069609268", 0.6)
            closed = true
            passed = false
        end)

        pcall(function() gui.Parent = parentGui end)
        if not gui.Parent then gui.Parent = CoreGui_ end

        local elapsed = 0
        while not passed and not closed and elapsed < 60 do
            task.wait(1)
            elapsed = elapsed + 1
            if not passed and not closed then
                status.Text = "Key required (" .. tostring(60 - elapsed) .. "s left to enter key)"
            end
        end

        pcall(function() gui:Destroy() end)

        if passed then
            __SUITE_PASSED = true
        else
            warn("[Suite] Access denied: Key was not entered. Kicking player.")
            if KICK_ON_FAIL then
                kickPlayer("You did not enter the required access key.\nPlease rejoin to try again.")
            end
            return
        end
    end
end

-- Top-level hard execution barrier: absolutely NOTHING below runs if not passed
if not __SUITE_PASSED then
    return
end

if _G.DuelsSuiteCleanup then pcall(_G.DuelsSuiteCleanup) end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--------------------------------------------------------------------------------
-- ANTI-KICK & BAC SHIELD (Blocks BAC-6589 and Game Anticheat Kick Calls)
--------------------------------------------------------------------------------
pcall(function()
    if typeof(hookfunction) == "function" and typeof(newcclosure) == "function" and LocalPlayer then
        local oldKick
        oldKick = hookfunction(LocalPlayer.Kick, newcclosure(function(self, ...)
            if not checkcaller() and (self == LocalPlayer or self == nil) then
                warn("[BAC Anti-Kick Shield] Blocked LocalPlayer:Kick! Message:", ...)
                return nil
            end
            return oldKick(self, ...)
        end))
    end
end)

pcall(function()
    if typeof(hookmetamethod) == "function" and typeof(newcclosure) == "function" then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if not checkcaller() then
                if (method == "Kick" or method == "kick") and (self == LocalPlayer or self == Players or self == nil) then
                    warn("[BAC Anti-Kick Shield] Blocked __namecall Kick! Args:", ...)
                    return nil
                end
                if method == "FireServer" or method == "fireServer" then
                    local remoteName = string.lower(tostring(self.Name))
                    if remoteName:find("bac") or remoteName:find("anticheat") or remoteName:find("ban") or remoteName:find("detection") or remoteName:find("report") then
                        warn("[BAC Anti-Kick Shield] Blocked detection remote:", self:GetFullName())
                        return nil
                    end
                end
            end
            return oldNamecall(self, ...)
        end))
    end
end)

local function rejoinGame()
    if #Players:GetPlayers() <= 1 then
        LocalPlayer:Kick("\n[Duels Suite] Rejoining server...")
        task.wait()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    else
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
end

local Config = {
    WatermarkEnabled = true,
    SoundFXEnabled = true,
    ProximitySoundAlert = false,

    -- Combat & Aim
    SilentAimEnabled = false,
    SilentPart = "Head",
    SilentPrediction = 0.08,
    SilentWallCheck = false,
    SilentFOV = 180,
    SilentShowFOV = true,
    SilentHitChance = 100,

    AimbotEnabled = false,
    AimbotHoldRMB = true,
    AimbotPart = "Head",
    AimbotSmoothness = 0.25,
    AimbotPrediction = 0.08,
    AimbotWallCheck = false,
    AimbotFOV = 160,

    Triggerbot = false,
    AutoKnife = false,
    AutoKnifeDistance = 15,

    Spinbot = false,
    SpinSpeed = 25,

    -- Movement
    FlyEnabled = false,
    FlySpeed = 1,
    QEfly = true,
    Noclip = false,
    SpeedEnabled = false,
    WalkSpeed = 16,
    JumpEnabled = false,
    JumpPower = 50,
    AntiFlingEnabled = false,
    InfiniteJump = false,

    -- Hitbox
    HitboxEnabled = false,
    HitboxSize = 6,
    HitboxTransparency = 0.6,
    HitboxTeamCheck = false,
    HitboxColor = Color3.fromRGB(255, 50, 50),
    HitboxMaterial = Enum.Material.ForceField,

    -- Visuals / ESP
    VisualsEnabled = false,
    HighlightsEnabled = true,
    TracersEnabled = true,
    TagsEnabled = true,
    RoleColors = true,
    HighlightColor = Color3.fromRGB(255, 45, 45),
    TracerColor = Color3.fromRGB(255, 75, 75),
    MaxVisualDistance = 1200,
    MinecraftGraphics = false,
    MinecraftFogDistance = 650,

    KillSound = false,
    KillSoundId = "rbxassetid://9069609268",
    SoundVolume = 0.6,
    Keybinds = {
        Fly = nil, Noclip = nil, AntiFling = nil, SpeedToggle = nil,
        JumpToggle = nil, InfiniteJump = nil, Hitbox = nil, Visuals = nil,
        Graphics = nil, SilentAim = nil, Aimbot = nil, Triggerbot = nil,
        AutoKnife = nil, Spinbot = nil
    }
}

getgenv().WhitelistedPlayers = getgenv().WhitelistedPlayers or {}

local function getNetworkPing()
    local ping = nil
    pcall(function()
        ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    if not ping or ping <= 0 then
        pcall(function()
            ping = Stats.PerformanceStats.Ping:GetValue()
        end)
    end
    if not ping or ping <= 0 then
        ping = 60
    end
    return math.floor(ping + 0.5)
end





local connections = {}
local isSuiteActive = true
local backgroundThreads = {}

local function safeSpawn(fn)
    local th = task.spawn(fn)
    table.insert(backgroundThreads, th)
    return th
end

local function safeConnect(signal, fn)
    local conn = signal:Connect(fn)
    table.insert(connections, conn)
    return conn
end

local function getRoot(char)
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
end

local function IsLocalAlive()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return char and hum and hum.Health > 0
end

local function breakVelocity()
    local char = LocalPlayer.Character
    if char then
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
                pcall(function()
                    v.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    v.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                end)
                pcall(function()
                    v.Velocity = Vector3.new(0, 0, 0)
                    v.RotVelocity = Vector3.new(0, 0, 0)
                end)
            end
        end
    end
end

local function getPlayerByName(str)
    if not str or str == "" then return nil end
    local query = string.lower(str)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if string.lower(p.Name):sub(1, #query) == query or string.lower(p.DisplayName):sub(1, #query) == query then
                return p
            end
        end
    end
    return nil
end

local function getPlayerNamesList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(list, p.Name) end
    end
    table.sort(list)
    if #list == 0 then table.insert(list, "None") end
    return list
end

local function getOtherPlayerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(names, p.Name) end
    end
    table.sort(names)
    return names
end

--------------------------------------------------------------------------------
-- PROTECTED PLAYERS & WHITELIST FILTER
--------------------------------------------------------------------------------

local selectedExcluded = {}

local function isExcluded(player)
    if not player or player == LocalPlayer then return true end
    if Config.HitboxTeamCheck and LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then
        return true
    end
    if selectedExcluded[player.Name] then return true end
    local n, dn = player.Name:lower(), player.DisplayName:lower()
    for _, e in ipairs(getgenv().DontShootThesePeople or {}) do
        local l = tostring(e):lower()
        if l == n or l == dn then return true end
    end
    if getgenv().WhitelistedPlayers and getgenv().WhitelistedPlayers[player.Name] then
        return true
    end
    return false
end

--------------------------------------------------------------------------------
-- KEYBIND REGISTRY & M1-M5 MOUSE BUTTON SUPPORT
--------------------------------------------------------------------------------

local KeybindRegistry = {}
local isListeningForBind = false

local function getKeyName(keyInput)
    if not keyInput then return "None" end
    if typeof(keyInput) == "EnumItem" then
        if keyInput.EnumType == Enum.UserInputType then
            local num = keyInput.Name:match("^MouseButton(%d)$")
            if num then return "M" .. num end
        elseif keyInput.EnumType == Enum.KeyCode then
            if keyInput == Enum.KeyCode.Backspace or keyInput == Enum.KeyCode.Escape then return "None" end
            return keyInput.Name
        end
    end
    return tostring(keyInput)
end

safeConnect(UserInputService.InputBegan, function(input, gpe)
    if gpe or isListeningForBind then return end
    if UserInputService:GetFocusedTextBox() ~= nil then return end

    for keyName, targetInput in pairs(Config.Keybinds) do
        if targetInput then
            local matches = false
            if typeof(targetInput) == "EnumItem" then
                if targetInput.EnumType == Enum.KeyCode and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == targetInput then
                    matches = true
                elseif targetInput.EnumType == Enum.UserInputType and input.UserInputType == targetInput then
                    matches = true
                end
            end
            if matches and KeybindRegistry[keyName] and KeybindRegistry[keyName].Callback then
                KeybindRegistry[keyName].Callback()
            end
        end
    end
end)

local antiFlingStepped = nil
local function setAntiFling(state)
    Config.AntiFlingEnabled = state
    if antiFlingStepped then
        antiFlingStepped:Disconnect()
        antiFlingStepped = nil
    end

    if state then
        antiFlingStepped = RunService.Stepped:Connect(function()
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    for _, child in ipairs(player.Character:GetDescendants()) do
                        if child:IsA("BasePart") then
                            child.CanCollide = false
                        end
                    end
                end
            end
        end)
    end
end

setAntiFling(false)

--------------------------------------------------------------------------------
-- MOVEMENT FEATURES
--------------------------------------------------------------------------------

local Noclipping = nil
local noclipOriginalCollide = {}
local function setNoclip(state)
    Config.Noclip = state
    if Noclipping then Noclipping:Disconnect() Noclipping = nil end

    if state then
        Noclipping = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char and Config.Noclip then
                for _, child in ipairs(char:GetDescendants()) do
                    if child:IsA("BasePart") and child.CanCollide then
                        noclipOriginalCollide[child] = true
                        child.CanCollide = false
                    end
                end
            end
        end)
    else
        for part in pairs(noclipOriginalCollide) do
            if part and part.Parent then
                pcall(function() part.CanCollide = true end)
            end
        end
        table.clear(noclipOriginalCollide)
    end
end


--------------------------------------------------------------------------------
-- FLIGHT LOGIC
--------------------------------------------------------------------------------

local flyKeyDown, flyKeyUp = nil, nil
local function NOFLY()
    Config.FlyEnabled = false
    if flyKeyDown then flyKeyDown:Disconnect() flyKeyDown = nil end
    if flyKeyUp then flyKeyUp:Disconnect() flyKeyUp = nil end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
    pcall(function() Camera.CameraType = Enum.CameraType.Custom end)
end

local function sFLY()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then repeat task.wait() until char:FindFirstChildOfClass("Humanoid") humanoid = char:FindFirstChildOfClass("Humanoid") end
    if flyKeyDown then flyKeyDown:Disconnect() flyKeyDown = nil end
    if flyKeyUp then flyKeyUp:Disconnect() flyKeyUp = nil end
    local T = getRoot(char) if not T then return end

    local CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
    local lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
    local SPEED = 0

    Config.FlyEnabled = true
    local BG = Instance.new("BodyGyro") local BV = Instance.new("BodyVelocity")
    BG.P = 9e4 BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9) BG.CFrame = T.CFrame BG.Parent = T
    BV.Velocity = Vector3.new(0, 0, 0) BV.MaxForce = Vector3.new(9e9, 9e9, 9e9) BV.Parent = T

    safeSpawn(function()
        repeat task.wait()
            if humanoid then humanoid.PlatformStand = true end
            if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0 then SPEED = 50 else SPEED = 0 end
            if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 or (CONTROL.Q + CONTROL.E) ~= 0 then
                BV.Velocity = ((Camera.CFrame.LookVector * (CONTROL.F + CONTROL.B)) + ((Camera.CFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).Position) - Camera.CFrame.Position)) * SPEED
                lCONTROL = {F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R}
            elseif SPEED ~= 0 then
                BV.Velocity = ((Camera.CFrame.LookVector * (lCONTROL.F + lCONTROL.B)) + ((Camera.CFrame * CFrame.new(lCONTROL.L + lCONTROL.R, (lCONTROL.F + lCONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).Position) - Camera.CFrame.Position)) * SPEED
            else
                BV.Velocity = Vector3.new(0, 0, 0)
            end
            BG.CFrame = Camera.CFrame
        until not Config.FlyEnabled
        BG:Destroy() BV:Destroy()
        if humanoid then humanoid.PlatformStand = false end
    end)

    flyKeyDown = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.W then CONTROL.F = Config.FlySpeed
        elseif input.KeyCode == Enum.KeyCode.S then CONTROL.B = -Config.FlySpeed
        elseif input.KeyCode == Enum.KeyCode.A then CONTROL.L = -Config.FlySpeed
        elseif input.KeyCode == Enum.KeyCode.D then CONTROL.R = Config.FlySpeed
        elseif input.KeyCode == Enum.KeyCode.E and Config.QEfly then CONTROL.Q = Config.FlySpeed * 2
        elseif input.KeyCode == Enum.KeyCode.Q and Config.QEfly then CONTROL.E = -Config.FlySpeed * 2 end
        pcall(function() Camera.CameraType = Enum.CameraType.Track end)
    end)

    flyKeyUp = UserInputService.InputEnded:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.W then CONTROL.F = 0
        elseif input.KeyCode == Enum.KeyCode.S then CONTROL.B = 0
        elseif input.KeyCode == Enum.KeyCode.A then CONTROL.L = 0
        elseif input.KeyCode == Enum.KeyCode.D then CONTROL.R = 0
        elseif input.KeyCode == Enum.KeyCode.E then CONTROL.Q = 0
        elseif input.KeyCode == Enum.KeyCode.Q then CONTROL.E = 0 end
    end)
end

local function setFlightState(state)
    if state then NOFLY() task.wait() sFLY() else NOFLY() end
end

local infJumpConn = nil
local function setInfiniteJump(state)
    Config.InfiniteJump = state
    if infJumpConn then infJumpConn:Disconnect() infJumpConn = nil end
    if state then
        infJumpConn = UserInputService.JumpRequest:Connect(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
end


--------------------------------------------------------------------------------
-- HITBOX EXPANDER HELPERS
--------------------------------------------------------------------------------

local ORIGINAL_SIZE = Vector3.new(2, 2, 1)
local function resetHitbox(character)
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.Size = ORIGINAL_SIZE hrp.Transparency = 1 hrp.CanCollide = false end
end

local function resetAllHitboxes()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then resetHitbox(player.Character) end
    end
end

--------------------------------------------------------------------------------
-- VISUALS & ESP TRACKERS
--------------------------------------------------------------------------------

local TrackedEntities = {}
local function removeTracker(player)
    local d = TrackedEntities[player]
    if d then
        if d.Highlight then pcall(function() d.Highlight:Destroy() end) end
        if d.Billboard then pcall(function() d.Billboard:Destroy() end) end
        if d.Tracer then pcall(function() d.Tracer:Remove() end) end
        TrackedEntities[player] = nil
    end
end

local function getOrCreateTracker(player)
    if TrackedEntities[player] then return TrackedEntities[player] end
    local d = {}
    
    local hl = Instance.new("Highlight")
    hl.FillColor = Config.HighlightColor
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.5
    hl.Enabled = false
    d.Highlight = hl

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 160, 0, 45)
    bb.StudsOffset = Vector3.new(0, 3.2, 0)
    bb.AlwaysOnTop = true
    bb.Enabled = false

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.Text = player.DisplayName
    label.Parent = bb
    d.Billboard = bb d.Label = label

    if Drawing then
        local line = Drawing.new("Line")
        line.Visible = false
        line.Color = Config.TracerColor
        line.Thickness = 1.5
        d.Tracer = line
    end

    TrackedEntities[player] = d
    return d
end

local function hideAllVisuals()
    for _, d in pairs(TrackedEntities) do
        if d.Highlight then d.Highlight.Enabled = false end
        if d.Billboard then d.Billboard.Enabled = false end
        if d.Tracer then d.Tracer.Visible = false end
    end
end

local function destroyAllVisuals()
    for _, d in pairs(TrackedEntities) do
        if d.Highlight then pcall(function() d.Highlight:Destroy() end) end
        if d.Billboard then pcall(function() d.Billboard:Destroy() end) end
        if d.Tracer then pcall(function() d.Tracer:Remove() end) end
    end
    table.clear(TrackedEntities)
end

safeConnect(Players.PlayerRemoving, function(player) removeTracker(player) end)

local originalLighting = nil
local function applyMinecraftGraphics(enabled)
    if not originalLighting then
        originalLighting = {
            Brightness = Lighting.Brightness,
            ClockTime = Lighting.ClockTime,
            FogEnd = Lighting.FogEnd,
            FogStart = Lighting.FogStart,
            FogColor = Lighting.FogColor,
            GlobalShadows = Lighting.GlobalShadows,
        }
    end

    local fx = Lighting:FindFirstChild("DALX_MinecraftFX")
    local sky = Lighting:FindFirstChild("DALX_MinecraftSky")

    if not enabled then
        if fx then pcall(function() fx:Destroy() end) end
        if sky then pcall(function() sky:Destroy() end) end
        Lighting.Brightness = originalLighting.Brightness
        Lighting.ClockTime = originalLighting.ClockTime
        Lighting.FogEnd = originalLighting.FogEnd
        Lighting.FogStart = originalLighting.FogStart
        Lighting.FogColor = originalLighting.FogColor
        Lighting.GlobalShadows = originalLighting.GlobalShadows
        return
    end

    if not fx then
        fx = Instance.new("Folder")
        fx.Name = "DALX_MinecraftFX"
        fx.Parent = Lighting
    end

    if not sky then
        sky = Instance.new("Sky")
        sky.Name = "DALX_MinecraftSky"
        sky.SkyboxBk = "rbxassetid://159454299"
        sky.SkyboxDn = "rbxassetid://159454296"
        sky.SkyboxFt = "rbxassetid://159454293"
        sky.SkyboxLf = "rbxassetid://159454286"
        sky.SkyboxRt = "rbxassetid://159454300"
        sky.SkyboxUp = "rbxassetid://159454288"
        sky.CelestialBodiesShown = true
        sky.Parent = Lighting
    end

    Lighting.ClockTime = 14
    Lighting.Brightness = 2.2
    Lighting.FogColor = Color3.fromRGB(180, 215, 255)
    Lighting.FogStart = 120
    Lighting.FogEnd = Config.MinecraftFogDistance
    Lighting.GlobalShadows = true
end

--------------------------------------------------------------------------------
-- AUDIO MANAGER & SOUND EFFECTS
--------------------------------------------------------------------------------

local lastProximityAlertTick = 0
local function playSound(soundId, volume)
    if not Config.SoundFXEnabled then return end
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = soundId
        s.Volume = volume or 0.6
        s.Parent = game:GetService("SoundService")
        s:Play()
        task.delay(3, function() pcall(function() s:Destroy() end) end)
    end)
end

task.defer(function()
    task.wait(0.2)
    playSound("rbxassetid://6895079853", 0.55)
end)


--------------------------------------------------------------------------------
-- WATERMARK HUD (Dalx.wtf Top-Left Aesthetic)
--------------------------------------------------------------------------------

local watermarkGui = nil
local watermarkFrame = nil
local watermarkFpsConn = nil

local function getGuiParent()
    if type(gethui) == "function" then
        local h = gethui()
        if h then return h end
    end
    return CoreGui
end

pcall(function()
    local targetHui = getGuiParent()
    for _, c in ipairs(targetHui:GetChildren()) do
        if c.Name == "DALX_MobileToggleGui" or c.Name == "UniversalFPSCounter" then
            c:Destroy()
        end
    end
end)

local function createWatermarkHUD()
    local targetHui = getGuiParent()
    for _, c in ipairs(targetHui:GetChildren()) do
        if c.Name == "DALX_WatermarkHUD" then pcall(function() c:Destroy() end) end
    end

    watermarkGui = Instance.new("ScreenGui")
    watermarkGui.Name = "DALX_WatermarkHUD"
    watermarkGui.ResetOnSpawn = false
    watermarkGui.DisplayOrder = 99998
    watermarkGui.Enabled = Config.WatermarkEnabled

    watermarkFrame = Instance.new("Frame")
    watermarkFrame.Name = "WatermarkFrame"
    watermarkFrame.Size = UDim2.new(0, 360, 0, 22)
    watermarkFrame.Position = UDim2.new(0, 10, 0, 10)
    watermarkFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 13)
    watermarkFrame.BackgroundTransparency = 0.05
    watermarkFrame.BorderSizePixel = 0
    watermarkFrame.Active = true
    watermarkFrame.Draggable = true
    watermarkFrame.Parent = watermarkGui

    local stroke = Instance.new("UIStroke", watermarkFrame)
    stroke.Color = Color3.fromRGB(40, 40, 50)
    stroke.Thickness = 1

    local topRedLine = Instance.new("Frame", watermarkFrame)
    topRedLine.Size = UDim2.new(1, 0, 0, 1.5)
    topRedLine.Position = UDim2.new(0, 0, 0, 0)
    topRedLine.BackgroundColor3 = Color3.fromRGB(225, 38, 38)
    topRedLine.BorderSizePixel = 0

    local btmRedLine = Instance.new("Frame", watermarkFrame)
    btmRedLine.Size = UDim2.new(1, 0, 0, 1.5)
    btmRedLine.Position = UDim2.new(0, 0, 1, -1.5)
    btmRedLine.BackgroundColor3 = Color3.fromRGB(225, 38, 38)
    btmRedLine.BorderSizePixel = 0

    local contentLabel = Instance.new("TextLabel", watermarkFrame)
    contentLabel.Size = UDim2.new(1, -12, 1, -3)
    contentLabel.Position = UDim2.new(0, 6, 0, 1)
    contentLabel.BackgroundTransparency = 1
    contentLabel.Font = Enum.Font.Code
    contentLabel.TextSize = 11
    contentLabel.TextColor3 = Color3.fromRGB(235, 235, 242)
    contentLabel.TextXAlignment = Enum.TextXAlignment.Left
    contentLabel.Text = string.format("Dalx.wtf | v3.2 | %s | 60 fps | 0ms", tostring(LocalPlayer.Name))

    local lastUpdate = tick()
    local frames = 0
    watermarkFpsConn = RunService.RenderStepped:Connect(function()
        if not watermarkGui or not watermarkGui.Parent or not watermarkGui.Enabled then return end
        frames = frames + 1
        local now = tick()
        if now - lastUpdate >= 0.4 then
            local fps = math.floor(frames / (now - lastUpdate) + 0.5)
            local ping = getNetworkPing()
            contentLabel.Text = string.format("Dalx.wtf | v3.2 | %s | %d fps | %dms", tostring(LocalPlayer.Name), fps, ping)
            frames = 0
            lastUpdate = now
        end
    end)

    pcall(function() watermarkGui.Parent = targetHui end)
end
createWatermarkHUD()

--------------------------------------------------------------------------------
-- KEYBIND REGISTRY HELPERS (Floating Keybinds HUD Removed)
--------------------------------------------------------------------------------

local keybindIndicatorGui = nil
local keybindIndicatorFrame = nil
local keybindListContainer = nil

local function updateKeybindIndicatorHUD()
    -- Keybind indicator HUD removed per user request
end


--------------------------------------------------------------------------------
-- PROPRIETARY DALX TACTICAL UI FRAMEWORK (DALX.WTF AESTHETIC)
--------------------------------------------------------------------------------

local THEME = {
    MainBg = Color3.fromRGB(13, 13, 16),
    HeaderBg = Color3.fromRGB(10, 10, 13),
    TabBarBg = Color3.fromRGB(11, 11, 14),
    GroupboxBg = Color3.fromRGB(16, 16, 21),
    GroupboxBorder = Color3.fromRGB(36, 36, 48),
    WindowBorder = Color3.fromRGB(42, 42, 54),
    AccentRed = Color3.fromRGB(225, 38, 38),
    AccentDark = Color3.fromRGB(150, 22, 22),
    AccentHover = Color3.fromRGB(245, 50, 50),
    WidgetBg = Color3.fromRGB(22, 22, 28),
    WidgetHover = Color3.fromRGB(28, 28, 36),
    WidgetBorder = Color3.fromRGB(44, 44, 58),
    TextPrimary = Color3.fromRGB(235, 235, 242),
    TextDim = Color3.fromRGB(150, 150, 165),
    TextMuted = Color3.fromRGB(85, 85, 100),
    White = Color3.fromRGB(255, 255, 255)
}

local DalxUI = {}
DalxUI.__index = DalxUI

local currentMenuKey = Enum.KeyCode.LeftAlt
local isMenuOpen = true
local isListeningForMenuKey = false

function DalxUI:CreateWindow(winConfig)
    winConfig = winConfig or {}
    local self = setmetatable({}, DalxUI)
    self.Title = winConfig.Title or "Dalx.wtf"
    self.Size = winConfig.Size or UDim2.new(0, 680, 0, 520)
    self.Tabs = {}
    self.ActiveTab = nil

    local targetHui = getGuiParent()
    for _, c in ipairs(targetHui:GetChildren()) do
        if c.Name == "DALX_TacticalMenu" then pcall(function() c:Destroy() end) end
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DALX_TacticalMenu"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 99999
    self.ScreenGui = screenGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = self.Size
    mainFrame.Position = UDim2.new(0.5, -340, 0.5, -265)
    mainFrame.BackgroundColor3 = THEME.MainBg
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = false
    mainFrame.Parent = screenGui
    self.MainFrame = mainFrame

    local corner = Instance.new("UICorner", mainFrame) corner.CornerRadius = UDim.new(0, 3)
    local stroke = Instance.new("UIStroke", mainFrame) stroke.Color = THEME.WindowBorder stroke.Thickness = 1.2

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 32)
    header.BackgroundColor3 = THEME.HeaderBg
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    local headerCorner = Instance.new("UICorner", header) headerCorner.CornerRadius = UDim.new(0, 3)

    local dragging, dragStart, startPos = false, nil, nil
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true dragStart = input.Position startPos = mainFrame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local titleLabel = Instance.new("TextLabel", header)
    titleLabel.Size = UDim2.new(0, 200, 1, 0)
    titleLabel.Position = UDim2.new(0, 12, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 13
    titleLabel.TextColor3 = THEME.TextPrimary
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = self.Title

    local menuKeyBtn = Instance.new("TextButton", header)
    menuKeyBtn.Name = "MenuKeybindButton"
    menuKeyBtn.Size = UDim2.new(0, 80, 0, 20)
    menuKeyBtn.Position = UDim2.new(1, -90, 0, 6)
    menuKeyBtn.BackgroundColor3 = THEME.WidgetBg
    menuKeyBtn.Font = Enum.Font.Code
    menuKeyBtn.TextSize = 10
    menuKeyBtn.TextColor3 = THEME.AccentRed
    menuKeyBtn.Text = "[" .. currentMenuKey.Name .. "]"
    Instance.new("UICorner", menuKeyBtn).CornerRadius = UDim.new(0, 2)
    local keyStroke = Instance.new("UIStroke", menuKeyBtn) keyStroke.Color = THEME.WidgetBorder keyStroke.Thickness = 1

    menuKeyBtn.MouseButton1Click:Connect(function()
        if isListeningForMenuKey then return end
        isListeningForMenuKey = true
        menuKeyBtn.Text = "[...]"
        local conn
        conn = UserInputService.InputBegan:Connect(function(inKey)
            if inKey.UserInputType == Enum.UserInputType.Keyboard then
                conn:Disconnect()
                if inKey.KeyCode ~= Enum.KeyCode.Escape then
                    currentMenuKey = inKey.KeyCode
                end
                menuKeyBtn.Text = "[" .. currentMenuKey.Name .. "]"
                task.wait(0.1)
                isListeningForMenuKey = false
            end
        end)
    end)

    local redDivider = Instance.new("Frame", mainFrame)
    redDivider.Name = "RedDivider"
    redDivider.Size = UDim2.new(1, 0, 0, 1.5)
    redDivider.Position = UDim2.new(0, 0, 0, 32)
    redDivider.BackgroundColor3 = THEME.AccentRed
    redDivider.BorderSizePixel = 0

    local tabBar = Instance.new("ScrollingFrame", mainFrame)
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, 0, 0, 30)
    tabBar.Position = UDim2.new(0, 0, 0, 34)
    tabBar.BackgroundColor3 = THEME.TabBarBg
    tabBar.BorderSizePixel = 0
    tabBar.ScrollBarThickness = 0
    tabBar.ScrollingDirection = Enum.ScrollingDirection.X
    tabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
    tabBar.CanvasSize = UDim2.new(0, 0, 0, 0)

    local tabLayout = Instance.new("UIListLayout", tabBar)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 2)

    local tabPadding = Instance.new("UIPadding", tabBar)
    tabPadding.PaddingLeft = UDim.new(0, 10)
    tabPadding.PaddingRight = UDim.new(0, 10)
    tabPadding.PaddingTop = UDim.new(0, 3)

    local container = Instance.new("Frame", mainFrame)
    container.Name = "Container"
    container.Size = UDim2.new(1, -20, 1, -74)
    container.Position = UDim2.new(0, 10, 0, 68)
    container.BackgroundTransparency = 1
    container.ClipsDescendants = true
    self.Container = container

    local notifyContainer = Instance.new("Frame", screenGui)
    notifyContainer.Name = "NotifyContainer"
    notifyContainer.Size = UDim2.new(0, 260, 0, 300)
    notifyContainer.Position = UDim2.new(1, -270, 1, -310)
    notifyContainer.BackgroundTransparency = 1
    local notifyLayout = Instance.new("UIListLayout", notifyContainer)
    notifyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    notifyLayout.Padding = UDim.new(0, 6)
    self.NotifyContainer = notifyContainer

    pcall(function() screenGui.Parent = targetHui end)

    function self:Toggle(forceState)
        if forceState ~= nil then
            isMenuOpen = forceState
        else
            isMenuOpen = not isMenuOpen
        end
        mainFrame.Visible = isMenuOpen
    end

    function self:SetState(state) self:Toggle(state) end

    function self:Notify(opt)
        local title = opt.Title or "Notification"
        local desc = opt.Description or opt.Body or ""
        local life = opt.Lifetime or 2.5

        local toast = Instance.new("Frame")
        toast.Size = UDim2.new(1, 0, 0, 48)
        toast.BackgroundColor3 = THEME.GroupboxBg
        toast.BorderSizePixel = 0
        toast.Parent = self.NotifyContainer

        Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 2)
        local s = Instance.new("UIStroke", toast) s.Color = THEME.GroupboxBorder s.Thickness = 1

        local bar = Instance.new("Frame", toast)
        bar.Size = UDim2.new(0, 3, 1, 0)
        bar.BackgroundColor3 = THEME.AccentRed
        bar.BorderSizePixel = 0

        local tLabel = Instance.new("TextLabel", toast)
        tLabel.Size = UDim2.new(1, -14, 0, 18)
        tLabel.Position = UDim2.new(0, 10, 0, 4)
        tLabel.BackgroundTransparency = 1
        tLabel.Font = Enum.Font.GothamBold
        tLabel.TextSize = 11
        tLabel.TextColor3 = THEME.TextPrimary
        tLabel.TextXAlignment = Enum.TextXAlignment.Left
        tLabel.Text = title

        local dLabel = Instance.new("TextLabel", toast)
        dLabel.Size = UDim2.new(1, -14, 0, 22)
        dLabel.Position = UDim2.new(0, 10, 0, 22)
        dLabel.BackgroundTransparency = 1
        dLabel.Font = Enum.Font.Gotham
        dLabel.TextSize = 10
        dLabel.TextColor3 = THEME.TextDim
        dLabel.TextXAlignment = Enum.TextXAlignment.Left
        dLabel.TextWrapped = true
        dLabel.Text = desc

        task.delay(life, function()
            pcall(function()
                local tw = TweenService:Create(toast, TweenInfo.new(0.25), { BackgroundTransparency = 1 })
                tw:Play()
                tw.Completed:Connect(function() toast:Destroy() end)
            end)
        end)
    end

    function self:Unload()
        pcall(function() self.ScreenGui:Destroy() end)
        if watermarkGui then pcall(function() watermarkGui:Destroy() end) end
        if watermarkFpsConn then pcall(function() watermarkFpsConn:Disconnect() end) end
        if keybindIndicatorGui then pcall(function() keybindIndicatorGui:Destroy() end) end
        print("[DALX] Unloaded UI.")
    end

    function self:Tab(tabCfg)
        local tabName = tabCfg.Name or "Tab"
        local tabBtn = Instance.new("TextButton", tabBar)
        tabBtn.Name = "Tab_" .. tabName
        tabBtn.Size = UDim2.new(0, 68, 0, 24)
        tabBtn.AutomaticSize = Enum.AutomaticSize.X
        local tabBtnPad = Instance.new("UIPadding", tabBtn)
        tabBtnPad.PaddingLeft = UDim.new(0, 8)
        tabBtnPad.PaddingRight = UDim.new(0, 8)
        tabBtn.BackgroundColor3 = THEME.TabBarBg
        tabBtn.BackgroundTransparency = 1
        tabBtn.BorderSizePixel = 0
        tabBtn.Font = Enum.Font.GothamMedium
        tabBtn.TextSize = 11
        tabBtn.TextColor3 = THEME.TextDim
        tabBtn.Text = tabName

        local underline = Instance.new("Frame", tabBtn)
        underline.Name = "Underline"
        underline.Size = UDim2.new(1, 0, 0, 2)
        underline.Position = UDim2.new(0, 0, 1, -2)
        underline.BackgroundColor3 = THEME.AccentRed
        underline.BorderSizePixel = 0
        underline.Visible = false

        local page = Instance.new("Frame", self.Container)
        page.Name = "Page_" .. tabName
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.ClipsDescendants = true
        page.Visible = false

        local leftCol = Instance.new("ScrollingFrame", page)
        leftCol.Name = "LeftColumn"
        leftCol.Size = UDim2.new(0.5, -6, 1, 0)
        leftCol.Position = UDim2.new(0, 0, 0, 0)
        leftCol.BackgroundTransparency = 1
        leftCol.BorderSizePixel = 0
        leftCol.ScrollBarThickness = 3
        leftCol.ScrollBarImageColor3 = THEME.AccentRed
        leftCol.ScrollBarImageTransparency = 0
        leftCol.CanvasSize = UDim2.new(0, 0, 0, 0)
        leftCol.AutomaticCanvasSize = Enum.AutomaticSize.None
        leftCol.ScrollingDirection = Enum.ScrollingDirection.Y
        leftCol.ClipsDescendants = true

        local leftLayout = Instance.new("UIListLayout", leftCol)
        leftLayout.Padding = UDim.new(0, 10)
        local leftPad = Instance.new("UIPadding", leftCol)
        leftPad.PaddingTop = UDim.new(0, 6)
        leftPad.PaddingRight = UDim.new(0, 6)
        leftPad.PaddingBottom = UDim.new(0, 10)

        local rightCol = Instance.new("ScrollingFrame", page)
        rightCol.Name = "RightColumn"
        rightCol.Size = UDim2.new(0.5, -6, 1, 0)
        rightCol.Position = UDim2.new(0.5, 6, 0, 0)
        rightCol.BackgroundTransparency = 1
        rightCol.BorderSizePixel = 0
        rightCol.ScrollBarThickness = 3
        rightCol.ScrollBarImageColor3 = THEME.AccentRed
        rightCol.ScrollBarImageTransparency = 0
        rightCol.CanvasSize = UDim2.new(0, 0, 0, 0)
        rightCol.AutomaticCanvasSize = Enum.AutomaticSize.None
        rightCol.ScrollingDirection = Enum.ScrollingDirection.Y
        rightCol.ClipsDescendants = true

        local rightLayout = Instance.new("UIListLayout", rightCol)
        rightLayout.Padding = UDim.new(0, 10)
        local rightPad = Instance.new("UIPadding", rightCol)
        rightPad.PaddingTop = UDim.new(0, 6)
        rightPad.PaddingRight = UDim.new(0, 6)
        rightPad.PaddingBottom = UDim.new(0, 10)

        local function updateCanvasSizes()
            if not leftLayout or not rightLayout then return end
            local leftH = leftLayout and (leftLayout.AbsoluteContentSize.Y + 24) or 0
            local rightH = rightLayout and (rightLayout.AbsoluteContentSize.Y + 24) or 0
            leftCol.CanvasSize = UDim2.new(0, 0, 0, leftH)
            rightCol.CanvasSize = UDim2.new(0, 0, 0, rightH)
        end

        leftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSizes)
        rightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSizes)

        local tabObj = {
            Name = tabName,
            Button = tabBtn,
            Underline = underline,
            Page = page,
            LeftCol = leftCol,
            RightCol = rightCol,
            Window = self
        }
        self.Tabs[tabName] = tabObj

        function tabObj:Select()
            for _, t in pairs(self.Window.Tabs) do
                pcall(function()
                    if t.Page then t.Page.Visible = false end
                    if t.Button then t.Button.TextColor3 = THEME.TextDim end
                    if t.Underline then t.Underline.Visible = false end
                end)
            end
            pcall(function()
                page.Visible = true
                tabBtn.TextColor3 = THEME.White
                underline.Visible = true
                updateCanvasSizes()
            end)
            self.Window.ActiveTab = tabObj
        end

        tabBtn.MouseButton1Click:Connect(function()
            pcall(function() tabObj:Select() end)
        end)

        if not self.ActiveTab or tabName == "Combat" then
            page.Visible = true
            tabBtn.TextColor3 = THEME.White
            underline.Visible = true
            self.ActiveTab = tabObj
        else
            page.Visible = false
            tabBtn.TextColor3 = THEME.TextDim
            underline.Visible = false
        end

        function tabObj:Section(secCfg)
            local side = (secCfg and secCfg.Side == "Right") and self.RightCol or self.LeftCol
            local groupTitle = (secCfg and secCfg.Title) or ""

            local box = Instance.new("Frame")
            box.Name = "Groupbox_" .. groupTitle
            box.Size = UDim2.new(1, -6, 0, 60)
            box.BackgroundColor3 = THEME.GroupboxBg
            box.BorderSizePixel = 0
            box.ClipsDescendants = false
            box.Parent = side

            Instance.new("UICorner", box).CornerRadius = UDim.new(0, 2)
            local s = Instance.new("UIStroke", box) s.Color = THEME.GroupboxBorder s.Thickness = 1

            local titleFrame = Instance.new("Frame", box)
            titleFrame.Size = UDim2.new(1, -8, 0, 18)
            titleFrame.BackgroundTransparency = 1
            titleFrame.ClipsDescendants = false

            local titleText = Instance.new("TextLabel", titleFrame)
            titleText.Size = UDim2.new(1, 0, 1, 0)
            titleText.BackgroundTransparency = 1
            titleText.Font = Enum.Font.GothamBold
            titleText.TextSize = 11
            titleText.TextColor3 = THEME.TextPrimary
            titleText.Text = " " .. (groupTitle ~= "" and groupTitle or "Section")
            titleText.TextXAlignment = Enum.TextXAlignment.Left

            local pad = Instance.new("UIPadding", box)
            pad.PaddingTop = UDim.new(0, 8)
            pad.PaddingBottom = UDim.new(0, 10)
            pad.PaddingLeft = UDim.new(0, 8)
            pad.PaddingRight = UDim.new(0, 8)

            local boxLayout = Instance.new("UIListLayout", box)
            boxLayout.Padding = UDim.new(0, 8)

            local function updateBoxSize()
                local totalH = 0
                for _, child in ipairs(box:GetChildren()) do
                    if child:IsA("GuiObject") and child ~= titleFrame then
                        totalH = totalH + child.Size.Y.Offset + boxLayout.Padding.Offset
                    end
                end
                local h = math.max(totalH + 34, boxLayout.AbsoluteContentSize.Y + 24, 50)
                box.Size = UDim2.new(1, -6, 0, h)
                updateCanvasSizes()
                task.defer(function()
                    if box and box.Parent then
                        local tH = 0
                        for _, child in ipairs(box:GetChildren()) do
                            if child:IsA("GuiObject") and child ~= titleFrame then
                                tH = tH + child.Size.Y.Offset + boxLayout.Padding.Offset
                            end
                        end
                        local h2 = math.max(tH + 34, boxLayout.AbsoluteContentSize.Y + 24, 50)
                        box.Size = UDim2.new(1, -6, 0, h2)
                        updateCanvasSizes()
                    end
                end)
            end
            boxLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateBoxSize)

            local sectionObj = { Box = box, TitleLabel = titleText, UpdateSize = updateBoxSize }

            function sectionObj:Header(hdrCfg)
                local txt = (type(hdrCfg) == "table" and hdrCfg.Text) or tostring(hdrCfg)
                if groupTitle == "" then
                    titleText.Text = " " .. txt .. " "
                    groupTitle = txt
                    return
                end
                local divRow = Instance.new("Frame", box)
                divRow.Size = UDim2.new(1, 0, 0, 16)
                divRow.BackgroundTransparency = 1
                divRow.ClipsDescendants = false

                local line1 = Instance.new("Frame", divRow)
                line1.Size = UDim2.new(0.2, 0, 0, 1)
                line1.Position = UDim2.new(0, 0, 0.5, 0)
                line1.BackgroundColor3 = THEME.WidgetBorder
                line1.BorderSizePixel = 0

                local dLabel = Instance.new("TextLabel", divRow)
                dLabel.Size = UDim2.new(0.6, 0, 1, 0)
                dLabel.Position = UDim2.new(0.2, 0, 0, 0)
                dLabel.BackgroundTransparency = 1
                dLabel.Font = Enum.Font.GothamBold
                dLabel.TextSize = 10
                dLabel.TextColor3 = THEME.TextDim
                dLabel.Text = txt

                local line2 = Instance.new("Frame", divRow)
                line2.Size = UDim2.new(0.2, 0, 0, 1)
                line2.Position = UDim2.new(0.8, 0, 0.5, 0)
                line2.BackgroundColor3 = THEME.WidgetBorder
                line2.BorderSizePixel = 0
                updateBoxSize()
            end

            function sectionObj:Toggle(tCfg, id)
                local name = tCfg.Name or "Toggle"
                local state = tCfg.Default or false
                local cb = tCfg.Callback or function() end
                local keybindConfigKey = tCfg.Keybind or tCfg.Key

                local row = Instance.new("Frame", box)
                row.Size = UDim2.new(1, 0, 0, 22)
                row.BackgroundTransparency = 1
                row.ClipsDescendants = false

                local chk = Instance.new("TextButton", row)
                chk.Size = UDim2.new(0, 13, 0, 13)
                chk.Position = UDim2.new(0, 2, 0.5, -6)
                chk.BackgroundColor3 = state and THEME.AccentRed or THEME.WidgetBg
                chk.BorderSizePixel = 0
                chk.Text = ""
                local cCorner = Instance.new("UICorner", chk) cCorner.CornerRadius = UDim.new(0, 2)
                local cStroke = Instance.new("UIStroke", chk) cStroke.Color = state and THEME.AccentRed or THEME.WidgetBorder cStroke.Thickness = 1

                local chkMark = Instance.new("Frame", chk)
                chkMark.Size = UDim2.new(0, 5, 0, 5)
                chkMark.Position = UDim2.new(0.5, -2, 0.5, -2)
                chkMark.BackgroundColor3 = THEME.White
                chkMark.BorderSizePixel = 0
                chkMark.Visible = state

                local lbl = Instance.new("TextButton", row)
                lbl.Size = UDim2.new(1, -70, 1, 0)
                lbl.Position = UDim2.new(0, 22, 0, 0)
                lbl.BackgroundTransparency = 1
                lbl.Font = Enum.Font.GothamMedium
                lbl.TextSize = 11
                lbl.TextColor3 = THEME.TextPrimary
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Text = name

                local toggleObj = {}

                if keybindConfigKey then
                    local bindBtn = Instance.new("TextButton", row)
                    bindBtn.Name = "KeybindBadge"
                    bindBtn.Size = UDim2.new(0, 48, 0, 16)
                    bindBtn.Position = UDim2.new(1, -50, 0.5, -8)
                    bindBtn.BackgroundColor3 = THEME.WidgetBg
                    bindBtn.Font = Enum.Font.Code
                    bindBtn.TextSize = 10
                    bindBtn.TextColor3 = THEME.TextDim
                    local curKey = (Config and Config.Keybinds and Config.Keybinds[keybindConfigKey])
                    bindBtn.Text = "[" .. getKeyName(curKey) .. "]"
                    Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0, 2)
                    local bStroke = Instance.new("UIStroke", bindBtn) bStroke.Color = THEME.WidgetBorder bStroke.Thickness = 1

                    local isBinding = false
                    bindBtn.MouseButton1Click:Connect(function()
                        if isBinding or isListeningForBind then return end
                        isBinding = true
                        isListeningForBind = true
                        bindBtn.Text = "[...]"
                        bindBtn.TextColor3 = THEME.AccentRed

                        local kConn, mConn
                        local function endBind()
                            if kConn then kConn:Disconnect() kConn = nil end
                            if mConn then mConn:Disconnect() mConn = nil end
                            task.wait(0.05)
                            isBinding = false
                            isListeningForBind = false
                        end

                        kConn = UserInputService.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.Keyboard then
                                endBind()
                                if input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Escape then
                                    Config.Keybinds[keybindConfigKey] = nil
                                    bindBtn.Text = "[None]"
                                    bindBtn.TextColor3 = THEME.TextDim
                                else
                                    Config.Keybinds[keybindConfigKey] = input.KeyCode
                                    bindBtn.Text = "[" .. input.KeyCode.Name .. "]"
                                    bindBtn.TextColor3 = THEME.TextPrimary
                                end
                                updateKeybindIndicatorHUD()
                            end
                        end)

                        mConn = UserInputService.InputBegan:Connect(function(input)
                            if input.UserInputType.Name:match("^MouseButton%d$") then
                                endBind()
                                Config.Keybinds[keybindConfigKey] = input.UserInputType
                                bindBtn.Text = "[" .. getKeyName(input.UserInputType) .. "]"
                                bindBtn.TextColor3 = THEME.TextPrimary
                                updateKeybindIndicatorHUD()
                            end
                        end)
                    end)

                    KeybindRegistry[keybindConfigKey] = {
                        DisplayName = name,
                        Callback = function()
                            toggleObj:UpdateState(not state)
                        end,
                        GetState = function() return state end
                    }
                end

                function toggleObj:UpdateState(newState)
                    state = newState
                    chk.BackgroundColor3 = state and THEME.AccentRed or THEME.WidgetBg
                    cStroke.Color = state and THEME.AccentRed or THEME.WidgetBorder
                    chkMark.Visible = state
                    cb(state)
                    updateKeybindIndicatorHUD()
                end
                function toggleObj:Set(newState) self:UpdateState(newState) end
                function toggleObj:Get() return state end

                local function onToggle() toggleObj:UpdateState(not state) end
                chk.MouseButton1Click:Connect(onToggle)
                lbl.MouseButton1Click:Connect(onToggle)

                if state then cb(state) end
                updateBoxSize()
                return toggleObj
            end

            function sectionObj:Slider(sCfg, id)
                local name = sCfg.Name or "Slider"
                local min = sCfg.Minimum or 0
                local max = sCfg.Maximum or 100
                local currentVal = sCfg.Default or min
                local precision = sCfg.Precision or 0
                local cb = sCfg.Callback or function() end
                local step = precision > 0 and (1 / (10 ^ precision)) or 1

                local container = Instance.new("Frame", box)
                container.Size = UDim2.new(1, 0, 0, 32)
                container.BackgroundTransparency = 1
                container.ClipsDescendants = false

                local label = Instance.new("TextLabel", container)
                label.Size = UDim2.new(1, -44, 0, 16)
                label.BackgroundTransparency = 1
                label.Font = Enum.Font.GothamMedium
                label.TextSize = 11
                label.TextColor3 = THEME.TextPrimary
                label.TextXAlignment = Enum.TextXAlignment.Left

                local function getValString(val)
                    if precision > 0 then
                        return string.format("%." .. precision .. "f", val)
                    else
                        return tostring(math.floor(val + 0.5))
                    end
                end

                local plusBtn = Instance.new("TextButton", container)
                plusBtn.Size = UDim2.new(0, 18, 0, 15)
                plusBtn.Position = UDim2.new(1, -18, 0, 0)
                plusBtn.BackgroundColor3 = THEME.WidgetBg
                plusBtn.Font = Enum.Font.Code
                plusBtn.TextSize = 11
                plusBtn.TextColor3 = THEME.TextPrimary
                plusBtn.Text = "+"
                Instance.new("UICorner", plusBtn).CornerRadius = UDim.new(0, 2)
                local pStroke = Instance.new("UIStroke", plusBtn) pStroke.Color = THEME.WidgetBorder pStroke.Thickness = 1

                local minusBtn = Instance.new("TextButton", container)
                minusBtn.Size = UDim2.new(0, 18, 0, 15)
                minusBtn.Position = UDim2.new(1, -38, 0, 0)
                minusBtn.BackgroundColor3 = THEME.WidgetBg
                minusBtn.Font = Enum.Font.Code
                minusBtn.TextSize = 11
                minusBtn.TextColor3 = THEME.TextPrimary
                minusBtn.Text = "-"
                Instance.new("UICorner", minusBtn).CornerRadius = UDim.new(0, 2)
                local mStroke = Instance.new("UIStroke", minusBtn) mStroke.Color = THEME.WidgetBorder mStroke.Thickness = 1

                local track = Instance.new("Frame", container)
                track.Size = UDim2.new(1, 0, 0, 8)
                track.Position = UDim2.new(0, 0, 0, 20)
                track.BackgroundColor3 = THEME.WidgetBg
                Instance.new("UICorner", track).CornerRadius = UDim.new(0, 2)
                local tStroke = Instance.new("UIStroke", track) tStroke.Color = THEME.WidgetBorder tStroke.Thickness = 1

                local fill = Instance.new("Frame", track)
                fill.Size = UDim2.new(math.clamp((currentVal - min) / (max - min), 0, 1), 0, 1, 0)
                fill.BackgroundColor3 = THEME.AccentRed
                fill.BorderSizePixel = 0
                Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 2)

                local sliderObj = {}
                function sliderObj:Set(newVal)
                    currentVal = math.clamp(newVal, min, max)
                    fill.Size = UDim2.new(math.clamp((currentVal - min) / (max - min), 0, 1), 0, 1, 0)
                    label.Text = name .. ": " .. getValString(currentVal)
                    cb(currentVal)
                end
                function sliderObj:Update(newVal) self:Set(newVal) end
                function sliderObj:Get() return currentVal end

                sliderObj:Set(currentVal)

                plusBtn.MouseButton1Click:Connect(function() sliderObj:Set(currentVal + step) end)
                minusBtn.MouseButton1Click:Connect(function() sliderObj:Set(currentVal - step) end)

                local draggingSlider = false
                local function updateDrag(input)
                    local trackPos = track.AbsolutePosition.X
                    local trackWidth = track.AbsoluteSize.X
                    local rel = math.clamp((input.Position.X - trackPos) / trackWidth, 0, 1)
                    local calculated = min + (max - min) * rel
                    if precision == 0 then calculated = math.floor(calculated + 0.5) end
                    sliderObj:Set(calculated)
                end

                track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        draggingSlider = true updateDrag(input)
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        updateDrag(input)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        draggingSlider = false
                    end
                end)

                updateBoxSize()
                return sliderObj
            end

            function sectionObj:Button(bCfg)
                local name = bCfg.Name or "Button"
                local cb = bCfg.Callback or function() end
                local keybindConfigKey = bCfg.Keybind

                local btn = Instance.new("TextButton", box)
                btn.Size = UDim2.new(1, 0, 0, 24)
                btn.BackgroundColor3 = THEME.WidgetBg
                btn.Font = Enum.Font.GothamMedium
                btn.TextSize = 11
                btn.TextColor3 = THEME.TextPrimary
                btn.Text = name
                btn.ClipsDescendants = false
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 2)
                local bStroke = Instance.new("UIStroke", btn) bStroke.Color = THEME.WidgetBorder bStroke.Thickness = 1

                if keybindConfigKey then
                    local bindBadge = Instance.new("TextButton", btn)
                    bindBadge.Name = "KeybindBadge"
                    bindBadge.Size = UDim2.new(0, 48, 0, 16)
                    bindBadge.Position = UDim2.new(1, -52, 0.5, -8)
                    bindBadge.BackgroundColor3 = THEME.GroupboxBg
                    bindBadge.Font = Enum.Font.Code
                    bindBadge.TextSize = 10
                    bindBadge.TextColor3 = THEME.TextDim
                    local curKey = (Config and Config.Keybinds and Config.Keybinds[keybindConfigKey])
                    bindBadge.Text = "[" .. getKeyName(curKey) .. "]"
                    Instance.new("UICorner", bindBadge).CornerRadius = UDim.new(0, 2)
                    local bbStroke = Instance.new("UIStroke", bindBadge) bbStroke.Color = THEME.WidgetBorder bbStroke.Thickness = 1

                    local isBinding = false
                    bindBadge.MouseButton1Click:Connect(function()
                        if isBinding or isListeningForBind then return end
                        isBinding = true isListeningForBind = true
                        bindBadge.Text = "[...]"
                        bindBadge.TextColor3 = THEME.AccentRed

                        local kConn, mConn
                        local function endBind()
                            if kConn then kConn:Disconnect() kConn = nil end
                            if mConn then mConn:Disconnect() mConn = nil end
                            task.wait(0.05)
                            isBinding = false isListeningForBind = false
                        end

                        kConn = UserInputService.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.Keyboard then
                                endBind()
                                if input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Escape then
                                    Config.Keybinds[keybindConfigKey] = nil
                                    bindBadge.Text = "[None]"
                                    bindBadge.TextColor3 = THEME.TextDim
                                else
                                    Config.Keybinds[keybindConfigKey] = input.KeyCode
                                    bindBadge.Text = "[" .. input.KeyCode.Name .. "]"
                                    bindBadge.TextColor3 = THEME.TextPrimary
                                end
                            end
                        end)

                        mConn = UserInputService.InputBegan:Connect(function(input)
                            if input.UserInputType.Name:match("^MouseButton%d$") then
                                endBind()
                                Config.Keybinds[keybindConfigKey] = input.UserInputType
                                bindBadge.Text = "[" .. getKeyName(input.UserInputType) .. "]"
                                bindBadge.TextColor3 = THEME.TextPrimary
                            end
                        end)
                    end)

                    KeybindRegistry[keybindConfigKey] = {
                        DisplayName = name,
                        Callback = cb
                    }
                end

                btn.MouseEnter:Connect(function() btn.BackgroundColor3 = THEME.WidgetHover bStroke.Color = THEME.TextDim end)
                btn.MouseLeave:Connect(function() btn.BackgroundColor3 = THEME.WidgetBg bStroke.Color = THEME.WidgetBorder end)
                btn.MouseButton1Click:Connect(function()
                    btn.BackgroundColor3 = THEME.AccentRed
                    task.delay(0.12, function() pcall(function() btn.BackgroundColor3 = THEME.WidgetBg end) end)
                    cb()
                end)

                local btnObj = {}
                function btnObj:UpdateName(newName) btn.Text = newName end
                function btnObj:SetText(newName) btn.Text = newName end
                updateBoxSize()
                return btnObj
            end

            function sectionObj:Dropdown(dCfg, id)
                local name = dCfg.Name or "Dropdown"
                local options = dCfg.Options or {}
                local currentSel = dCfg.Default or (options[1] or "None")
                local multi = dCfg.Multi or false
                local cb = dCfg.Callback or function() end
                local isOpen = false

                local container = Instance.new("Frame", box)
                container.Size = UDim2.new(1, 0, 0, 44)
                container.BackgroundTransparency = 1
                container.ClipsDescendants = false

                local label = Instance.new("TextLabel", container)
                label.Size = UDim2.new(1, 0, 0, 16)
                label.BackgroundTransparency = 1
                label.Font = Enum.Font.GothamMedium
                label.TextSize = 11
                label.TextColor3 = THEME.TextPrimary
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Text = name

                local selector = Instance.new("TextButton", container)
                selector.Size = UDim2.new(1, 0, 0, 24)
                selector.Position = UDim2.new(0, 0, 0, 18)
                selector.BackgroundColor3 = THEME.WidgetBg
                selector.Font = Enum.Font.GothamMedium
                selector.TextSize = 11
                selector.TextColor3 = THEME.TextPrimary
                selector.TextXAlignment = Enum.TextXAlignment.Left
                selector.Text = "  " .. tostring(type(currentSel) == "table" and "Multiple Selected" or currentSel) .. "  +"
                Instance.new("UICorner", selector).CornerRadius = UDim.new(0, 2)
                local dStroke = Instance.new("UIStroke", selector) dStroke.Color = THEME.WidgetBorder dStroke.Thickness = 1

                local dropFrame = Instance.new("ScrollingFrame", container)
                dropFrame.Size = UDim2.new(1, 0, 0, 100)
                dropFrame.Position = UDim2.new(0, 0, 0, 44)
                dropFrame.BackgroundColor3 = THEME.MainBg
                dropFrame.BorderSizePixel = 0
                dropFrame.ScrollBarThickness = 2
                dropFrame.ScrollBarImageColor3 = THEME.AccentRed
                dropFrame.ZIndex = 15
                dropFrame.Visible = false
                Instance.new("UICorner", dropFrame).CornerRadius = UDim.new(0, 2)
                local dfStroke = Instance.new("UIStroke", dropFrame) dfStroke.Color = THEME.AccentRed dfStroke.Thickness = 1
                local dropLayout = Instance.new("UIListLayout", dropFrame)
                dropLayout.Padding = UDim.new(0, 2)

                local dropdownObj = {}
                local selectedDict = {}
                if multi and type(currentSel) == "table" then
                    for _, v in pairs(currentSel) do selectedDict[v] = true end
                end

                local function refreshOptions()
                    for _, c in ipairs(dropFrame:GetChildren()) do
                        if c:IsA("TextButton") then c:Destroy() end
                    end
                    dropFrame.CanvasSize = UDim2.new(0, 0, 0, #options * 22)
                    for _, opt in ipairs(options) do
                        local optBtn = Instance.new("TextButton", dropFrame)
                        optBtn.Size = UDim2.new(1, 0, 0, 20)
                        optBtn.BackgroundColor3 = THEME.WidgetBg
                        optBtn.Font = Enum.Font.Gotham
                        optBtn.TextSize = 10
                        optBtn.TextColor3 = THEME.TextPrimary
                        optBtn.TextXAlignment = Enum.TextXAlignment.Left
                        optBtn.ZIndex = 16
                        optBtn.Text = "  " .. tostring(opt)

                        optBtn.MouseButton1Click:Connect(function()
                            if multi then
                                selectedDict[opt] = not selectedDict[opt]
                                optBtn.TextColor3 = selectedDict[opt] and THEME.AccentRed or THEME.TextPrimary
                                cb(selectedDict)
                            else
                                currentSel = opt
                                selector.Text = "  " .. tostring(opt) .. "  +"
                                dropFrame.Visible = false
                                isOpen = false
                                container.Size = UDim2.new(1, 0, 0, 44)
                                updateBoxSize()
                                cb(currentSel)
                            end
                        end)
                    end
                end
                refreshOptions()

                selector.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    dropFrame.Visible = isOpen
                    container.Size = UDim2.new(1, 0, 0, isOpen and 148 or 44)
                    updateBoxSize()
                end)

                function dropdownObj:SetOptions(newOpts) options = newOpts refreshOptions() end
                function dropdownObj:Refresh(newOpts) self:SetOptions(newOpts) end
                function dropdownObj:Update(newOpts) self:SetOptions(newOpts) end
                function dropdownObj:ClearOptions() options = {} refreshOptions() end
                function dropdownObj:InsertOptions(newOpts)
                    for _, o in ipairs(newOpts) do table.insert(options, o) end
                    refreshOptions()
                end
                function dropdownObj:UpdateSelection(newSel)
                    if multi then
                        selectedDict = {}
                        if type(newSel) == "table" then
                            for _, v in pairs(newSel) do selectedDict[v] = true end
                        end
                    else
                        currentSel = newSel
                        selector.Text = "  " .. tostring(currentSel) .. "  +"
                    end
                end

                updateBoxSize()
                return dropdownObj
            end

            function sectionObj:Input(iCfg, id)
                local name = iCfg.Name or "Input"
                local placeholder = iCfg.Placeholder or "Enter text..."
                local cb = iCfg.Callback or function() end

                local container = Instance.new("Frame", box)
                container.Size = UDim2.new(1, 0, 0, 44)
                container.BackgroundTransparency = 1
                container.ClipsDescendants = false

                local label = Instance.new("TextLabel", container)
                label.Size = UDim2.new(1, 0, 0, 16)
                label.BackgroundTransparency = 1
                label.Font = Enum.Font.GothamMedium
                label.TextSize = 11
                label.TextColor3 = THEME.TextPrimary
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Text = name

                local boxInput = Instance.new("TextBox", container)
                boxInput.Size = UDim2.new(1, 0, 0, 24)
                boxInput.Position = UDim2.new(0, 0, 0, 18)
                boxInput.BackgroundColor3 = THEME.WidgetBg
                boxInput.Font = Enum.Font.Gotham
                boxInput.TextSize = 11
                boxInput.TextColor3 = THEME.TextPrimary
                boxInput.PlaceholderText = placeholder
                boxInput.PlaceholderColor3 = THEME.TextMuted
                boxInput.ClearTextOnFocus = false
                boxInput.Text = ""
                Instance.new("UICorner", boxInput).CornerRadius = UDim.new(0, 2)
                local iStroke = Instance.new("UIStroke", boxInput) iStroke.Color = THEME.WidgetBorder iStroke.Thickness = 1

                boxInput.FocusLost:Connect(function(enter) cb(boxInput.Text) end)

                local inputObj = {}
                function inputObj:Set(txt) boxInput.Text = txt end
                function inputObj:Get() return boxInput.Text end
                updateBoxSize()
                return inputObj
            end

            function sectionObj:Paragraph(pCfg)
                local header = pCfg.Header or pCfg.Title or "Status"
                local body = pCfg.Body or pCfg.Content or ""

                local frame = Instance.new("Frame", box)
                frame.Size = UDim2.new(1, 0, 0, 28)
                frame.AutomaticSize = Enum.AutomaticSize.Y
                frame.BackgroundColor3 = THEME.WidgetBg
                frame.BorderSizePixel = 0
                frame.ClipsDescendants = false
                Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 2)
                local pStroke = Instance.new("UIStroke", frame) pStroke.Color = THEME.WidgetBorder pStroke.Thickness = 1

                local pPad = Instance.new("UIPadding", frame)
                pPad.PaddingTop = UDim.new(0, 6)
                pPad.PaddingBottom = UDim.new(0, 6)
                pPad.PaddingLeft = UDim.new(0, 8)
                pPad.PaddingRight = UDim.new(0, 8)

                local pLayout = Instance.new("UIListLayout", frame)
                pLayout.Padding = UDim.new(0, 4)

                local hLabel = Instance.new("TextLabel", frame)
                hLabel.Size = UDim2.new(1, 0, 0, 14)
                hLabel.BackgroundTransparency = 1
                hLabel.Font = Enum.Font.GothamBold
                hLabel.TextSize = 11
                hLabel.TextColor3 = THEME.AccentRed
                hLabel.TextXAlignment = Enum.TextXAlignment.Left
                hLabel.Text = header

                local bLabel = Instance.new("TextLabel", frame)
                bLabel.Size = UDim2.new(1, 0, 0, 0)
                bLabel.AutomaticSize = Enum.AutomaticSize.Y
                bLabel.BackgroundTransparency = 1
                bLabel.Font = Enum.Font.Gotham
                bLabel.TextSize = 10
                bLabel.TextColor3 = THEME.TextDim
                bLabel.TextXAlignment = Enum.TextXAlignment.Left
                bLabel.TextWrapped = true
                bLabel.Text = body

                local paraObj = {}
                function paraObj:Set(data)
                    if type(data) == "table" then
                        if data.Header then hLabel.Text = data.Header end
                        if data.Body then bLabel.Text = data.Body end
                    elseif type(data) == "string" then
                        bLabel.Text = data
                    end
                    updateBoxSize()
                end
                function paraObj:SetDesc(txt) bLabel.Text = txt updateBoxSize() end
                function paraObj:SetText(txt) bLabel.Text = txt updateBoxSize() end
                updateBoxSize()
                return paraObj
            end

            return sectionObj
        end

        self.Tabs[tabName] = tabObj
        return tabObj
    end

    UserInputService.InputBegan:Connect(function(input, gpe)
        if isListeningForMenuKey or isListeningForBind then return end
        if UserInputService:GetFocusedTextBox() ~= nil then return end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == currentMenuKey then
            self:Toggle()
        end
    end)

    return self
end



--------------------------------------------------------------------------------
-- DUELS HELPERS
--------------------------------------------------------------------------------

local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function equipByName(name)
    local hum = getHumanoid()
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not hum or not bp then return false end
    local tool = bp:FindFirstChild(name)
    if not tool then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and string.find(string.lower(t.Name), string.lower(name)) then tool = t break end
        end
    end
    if tool then
        pcall(function() hum:EquipTool(tool) end)
        return true
    end
    return false
end

--------------------------------------------------------------------------------
-- ROLE DETECTION & COMBAT ENGINE
--------------------------------------------------------------------------------

local function getPlayerRole(player)
    if not player then return "Innocent" end
    local char = player.Character
    local bp = player:FindFirstChildOfClass("Backpack")
    
    local function hasItem(keyword)
        if char then
            for _, item in ipairs(char:GetChildren()) do
                if item:IsA("Tool") and string.find(string.lower(item.Name), keyword) then
                    return true
                end
            end
        end
        if bp then
            for _, item in ipairs(bp:GetChildren()) do
                if item:IsA("Tool") and string.find(string.lower(item.Name), keyword) then
                    return true
                end
            end
        end
        return false
    end

    if hasItem("knife") then
        return "Murderer"
    elseif hasItem("gun") or hasItem("revolver") then
        return "Sheriff"
    end

    local team = player.Team and player.Team.Name:lower()
    if team then
        if team:find("murd") then return "Murderer" end
        if team:find("sher") then return "Sheriff" end
    end

    return "Innocent"
end

local function isPartVisible(part, ignoreChar)
    if not part then return false end
    local origin = Camera.CFrame.Position
    local dir = part.Position - origin
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = { LocalPlayer.Character, ignoreChar, Camera }
    rayParams.IgnoreWater = true
    local res = Workspace:Raycast(origin, dir, rayParams)
    return res == nil or res.Instance:IsDescendantOf(ignoreChar)
end

local function getTargetClosestToMouse(partName, maxDist, fovRadius, wallCheck)
    local mousePos = UserInputService:GetMouseLocation()
    local bestTarget = nil
    local shortestFovDist = fovRadius or math.huge

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and not isExcluded(p) then
            local char = p.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if char and hum and hum.Health > 0 then
                local targetPart = char:FindFirstChild(partName) or getRoot(char)
                if targetPart then
                    local dist3D = (targetPart.Position - Camera.CFrame.Position).Magnitude
                    if dist3D <= (maxDist or 1500) then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                        if onScreen then
                            local fovDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                            if fovDist <= shortestFovDist then
                                if not wallCheck or isPartVisible(targetPart, char) then
                                    shortestFovDist = fovDist
                                    bestTarget = targetPart
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end

local fovCircle = nil
pcall(function()
    if Drawing and Drawing.new then
        fovCircle = Drawing.new("Circle")
        fovCircle.Thickness = 1.5
        fovCircle.NumSides = 36
        fovCircle.Filled = false
        fovCircle.Transparency = 0.8
        fovCircle.Color = Color3.fromRGB(255, 60, 60)
        fovCircle.Visible = false
    end
end)

-- Metamethod hook for Silent Aim (Gun shots and Knife throws)
if not getgenv().__DuelsAimHooked then
    getgenv().__DuelsAimHooked = true
    pcall(function()
        if typeof(hookmetamethod) == "function" and typeof(newcclosure) == "function" then
            local oldIndex
            oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
                if not checkcaller() and Config.SilentAimEnabled and (key == "Hit" or key == "hit") then
                    if math.random(1, 100) <= (Config.SilentHitChance or 100) then
                        local tPart = getTargetClosestToMouse(Config.SilentPart, Config.MaxVisualDistance, Config.SilentFOV, Config.SilentWallCheck)
                        if tPart then
                            local predPos = tPart.Position + (tPart.AssemblyLinearVelocity * (Config.SilentPrediction or 0.08))
                            return CFrame.new(predPos)
                        end
                    end
                end
                if not checkcaller() and Config.SilentAimEnabled and (key == "Target" or key == "target") then
                    local tPart = getTargetClosestToMouse(Config.SilentPart, Config.MaxVisualDistance, Config.SilentFOV, Config.SilentWallCheck)
                    if tPart then
                        return tPart
                    end
                end
                return oldIndex(self, key)
            end))
        end
    end)
end

--------------------------------------------------------------------------------
-- INITIALIZE DALX WINDOW
--------------------------------------------------------------------------------

local Window = DalxUI:CreateWindow({
    Title = "Dalx.wtf | Duels",
    Size = UDim2.fromOffset(680, 520)
})
_G.DuelsSuiteWindow = Window

local tabs = {
    Combat = Window:Tab({ Name = "Combat" }),
    Movement = Window:Tab({ Name = "Movement" }),
    Visuals = Window:Tab({ Name = "Visuals" }),
    Misc = Window:Tab({ Name = "Misc" }),
    Settings = Window:Tab({ Name = "Settings" })
}

--------------------------------------------------------------------------------
-- COMBAT TAB
--------------------------------------------------------------------------------

local combatLeft = tabs.Combat:Section({ Side = "Left", Title = "Silent Aim & Lock" })
combatLeft:Toggle({
    Name = "Silent Aim (Gun & Knife)",
    Default = false,
    Keybind = "SilentAim",
    Callback = function(val)
        Config.SilentAimEnabled = val
        if fovCircle then fovCircle.Visible = val and Config.SilentShowFOV end
    end
}, "SilentAimToggle")
combatLeft:Dropdown({
    Name = "Target Hitbox",
    Default = "Head",
    Options = { "Head", "HumanoidRootPart", "Torso" },
    Callback = function(val) Config.SilentPart = val end
}, "SilentPartDrop")
combatLeft:Slider({ Name = "Silent FOV", Default = 180, Minimum = 40, Maximum = 600, Precision = 0, Callback = function(val) Config.SilentFOV = val end }, "SilentFOVSlider")
combatLeft:Slider({ Name = "Prediction", Default = 0.08, Minimum = 0, Maximum = 0.3, Precision = 2, Callback = function(val) Config.SilentPrediction = val end }, "SilentPredSlider")
combatLeft:Slider({ Name = "Hit Chance %", Default = 100, Minimum = 10, Maximum = 100, Precision = 0, Callback = function(val) Config.SilentHitChance = val end }, "SilentChanceSlider")
combatLeft:Toggle({ Name = "Show FOV Circle", Default = true, Callback = function(val) Config.SilentShowFOV = val if fovCircle then fovCircle.Visible = Config.SilentAimEnabled and val end end }, "SilentShowFOVToggle")
combatLeft:Toggle({ Name = "Wall Check", Default = false, Callback = function(val) Config.SilentWallCheck = val end }, "SilentWallToggle")

combatLeft:Header({ Text = "Camera Lock Aimbot" })
combatLeft:Toggle({
    Name = "Aimbot Camera Lock",
    Default = false,
    Keybind = "Aimbot",
    Callback = function(val) Config.AimbotEnabled = val end
}, "AimbotToggle")
combatLeft:Toggle({ Name = "Hold Right Click (RMB)", Default = true, Callback = function(val) Config.AimbotHoldRMB = val end }, "AimbotRMBToggle")
combatLeft:Slider({ Name = "Aimbot FOV", Default = 160, Minimum = 40, Maximum = 500, Precision = 0, Callback = function(val) Config.AimbotFOV = val end }, "AimbotFOVSlider")
combatLeft:Slider({ Name = "Smoothness", Default = 0.25, Minimum = 0.05, Maximum = 0.95, Precision = 2, Callback = function(val) Config.AimbotSmoothness = val end }, "AimbotSmoothSlider")

local combatRight = tabs.Combat:Section({ Side = "Right", Title = "Automation & Hitbox" })
combatRight:Toggle({
    Name = "Triggerbot (Auto Shoot)",
    Default = false,
    Keybind = "Triggerbot",
    Callback = function(val) Config.Triggerbot = val end
}, "TriggerbotToggle")
combatRight:Toggle({
    Name = "Auto Knife Aura (Slash)",
    Default = false,
    Keybind = "AutoKnife",
    Callback = function(val) Config.AutoKnife = val end
}, "AutoKnifeToggle")
combatRight:Slider({ Name = "Knife Aura Distance", Default = 15, Minimum = 5, Maximum = 30, Precision = 0, Callback = function(val) Config.AutoKnifeDistance = val end }, "KnifeDistSlider")
combatRight:Toggle({
    Name = "Spinbot Anti-Aim",
    Default = false,
    Keybind = "Spinbot",
    Callback = function(val) Config.Spinbot = val end
}, "SpinbotToggle")
combatRight:Slider({ Name = "Spin Speed", Default = 25, Minimum = 5, Maximum = 100, Precision = 0, Callback = function(val) Config.SpinSpeed = val end }, "SpinSpeedSlider")

combatRight:Header({ Text = "Hitbox Expander" })
combatRight:Toggle({
    Name = "Enable Hitbox Expander",
    Default = false,
    Keybind = "Hitbox",
    Callback = function(val)
        Config.HitboxEnabled = val
        if not val then resetAllHitboxes() end
    end
}, "HitboxToggle")
combatRight:Slider({ Name = "Hitbox Size", Default = 6, Minimum = 2, Maximum = 30, Precision = 0, Callback = function(val) Config.HitboxSize = val end }, "HitboxSizeSlider")
combatRight:Slider({ Name = "Hitbox Transparency", Default = 0.6, Minimum = 0, Maximum = 1, Precision = 1, Callback = function(val) Config.HitboxTransparency = val end }, "HitboxTransSlider")

combatRight:Header({ Text = "Quick Weapons" })
combatRight:Button({
    Name = "Equip Gun",
    Callback = function()
        if not equipByName("DefaultGun") and not equipByName("gun") then
            Window:Notify({ Title = "Weapons", Description = "No gun found in backpack.", Lifetime = 2 })
        end
    end
})
combatRight:Button({
    Name = "Equip Knife",
    Callback = function()
        if not equipByName("DefaultKnife") and not equipByName("knife") then
            Window:Notify({ Title = "Weapons", Description = "No knife found in backpack.", Lifetime = 2 })
        end
    end
})

--------------------------------------------------------------------------------
-- MOVEMENT TAB
--------------------------------------------------------------------------------

local moveLeft = tabs.Movement:Section({ Side = "Left", Title = "Flight & Locomotion" })
moveLeft:Toggle({
    Name = "Enable Flight",
    Default = false,
    Keybind = "Fly",
    Callback = function(val) setFlightState(val) end
}, "FlyToggle")
moveLeft:Slider({ Name = "Flight Speed", Default = 1, Minimum = 1, Maximum = 10, Precision = 1, Callback = function(val) Config.FlySpeed = val end }, "FlySpeedSlider")
moveLeft:Toggle({ Name = "QE Altitude Control", Default = true, Callback = function(val) Config.QEfly = val end }, "QEAltitudeToggle")

moveLeft:Header({ Text = "Speed & Power" })
moveLeft:Toggle({
    Name = "Enable WalkSpeed",
    Default = false,
    Keybind = "SpeedToggle",
    Callback = function(val)
        Config.SpeedEnabled = val
        if not val then local h = getHumanoid() if h then h.WalkSpeed = 16 end end
    end
}, "SpeedToggle")
moveLeft:Slider({ Name = "WalkSpeed", Default = 16, Minimum = 16, Maximum = 100, Precision = 0, Callback = function(val) Config.WalkSpeed = val end }, "WalkSpeedSlider")
moveLeft:Toggle({
    Name = "Enable JumpPower",
    Default = false,
    Keybind = "JumpToggle",
    Callback = function(val)
        Config.JumpEnabled = val
        if not val then local h = getHumanoid() if h then h.JumpPower = 50 end end
    end
}, "JumpModToggle")
moveLeft:Slider({ Name = "JumpPower", Default = 50, Minimum = 50, Maximum = 250, Precision = 0, Callback = function(val) Config.JumpPower = val end }, "JumpPowerSlider")

local moveRight = tabs.Movement:Section({ Side = "Right", Title = "Collision & Jump" })
moveRight:Toggle({ Name = "Noclip", Default = false, Keybind = "Noclip", Callback = function(val) setNoclip(val) end }, "NoclipToggle")
moveRight:Toggle({ Name = "Infinite Jump", Default = false, Keybind = "InfiniteJump", Callback = function(val) setInfiniteJump(val) end }, "InfJumpToggle")
moveRight:Toggle({
    Name = "Anti-Fling",
    Default = false,
    Keybind = "AntiFling",
    Callback = function(val) setAntiFling(val) end
}, "AntiFlingToggle")

--------------------------------------------------------------------------------
-- VISUALS TAB
--------------------------------------------------------------------------------

local visLeft = tabs.Visuals:Section({ Side = "Left", Title = "Enemy ESP" })
visLeft:Toggle({
    Name = "Master Visuals Switch",
    Default = false,
    Keybind = "Visuals",
    Callback = function(val) Config.VisualsEnabled = val if not val then hideAllVisuals() end end
}, "ESPMasterToggle")
visLeft:Toggle({ Name = "Chams / Highlights", Default = true, Callback = function(val) Config.HighlightsEnabled = val end }, "ChamsToggle")
visLeft:Toggle({ Name = "Snapline Tracers", Default = true, Callback = function(val) Config.TracersEnabled = val end }, "TracersToggle")
visLeft:Toggle({ Name = "3D Floating Tags", Default = true, Callback = function(val) Config.TagsEnabled = val end }, "TagsToggle")
visLeft:Toggle({ Name = "Role Colors (Murd/Sheriff)", Default = true, Callback = function(val) Config.RoleColors = val end }, "RoleColorsToggle")

local visRight = tabs.Visuals:Section({ Side = "Right", Title = "World" })
visRight:Toggle({
    Name = "Fullbright",
    Default = false,
    Callback = function(val)
        Lighting.Brightness = val and 2 or 1
        Lighting.ClockTime = val and 14 or 12
        Lighting.GlobalShadows = not val
    end
})
visRight:Toggle({
    Name = "Minecraft Graphics",
    Default = false,
    Keybind = "Graphics",
    Callback = function(val) applyMinecraftGraphics(val) end
}, "ShaderToggle")

--------------------------------------------------------------------------------
-- MISC TAB
--------------------------------------------------------------------------------

local miscLeft = tabs.Misc:Section({ Side = "Left", Title = "Sounds" })
miscLeft:Toggle({ Name = "Kill Sound", Default = false, Callback = function(val) Config.KillSound = val end }, "KillSoundToggle")
miscLeft:Input({
    Name = "Kill Sound ID",
    Placeholder = "rbxassetid://...",
    Callback = function(txt)
        if txt and txt ~= "" then
            if tonumber(txt) then txt = "rbxassetid://" .. txt end
            Config.KillSoundId = txt
        end
    end
})
miscLeft:Slider({ Name = "Volume", Default = 0.6, Minimum = 0, Maximum = 1, Precision = 1, Callback = function(val) Config.SoundVolume = val end }, "SoundVolumeSlider")

local miscRight = tabs.Misc:Section({ Side = "Right", Title = "Server" })
miscRight:Button({ Name = "Rejoin Server", Callback = function() rejoinGame() end })
miscRight:Button({
    Name = "Copy Join Script",
    Callback = function()
        pcall(function()
            if type(setclipboard) == "function" then
                setclipboard(string.format('game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s", game.Players.LocalPlayer)', game.PlaceId, game.JobId))
            end
        end)
        Window:Notify({ Title = "Clipboard", Description = "Join script copied to clipboard!", Lifetime = 2 })
    end
})

--------------------------------------------------------------------------------
-- SETTINGS TAB
--------------------------------------------------------------------------------

local settingsMain = tabs.Settings:Section({ Side = "Left", Title = "Main" })
settingsMain:Button({
    Name = "Unload Suite",
    Callback = function()
        if _G.DuelsSuiteCleanup then _G.DuelsSuiteCleanup() end
    end
})

settingsMain:Header({ Text = "Watermark" })
settingsMain:Toggle({
    Name = "Enabled",
    Default = true,
    Callback = function(val)
        Config.WatermarkEnabled = val
        if watermarkGui then watermarkGui.Enabled = val end
    end
})

settingsMain:Header({ Text = "Audio" })
settingsMain:Toggle({
    Name = "Audio Chimes & Sound Effects",
    Default = true,
    Callback = function(val) Config.SoundFXEnabled = val end
})

local CONFIG_KEYS = {
    "FlySpeed", "WalkSpeed", "JumpPower", "HitboxSize", "HitboxTransparency",
    "MaxVisualDistance", "KillSoundId", "SoundVolume"
}
local configName = "default"

local settingsRight = tabs.Settings:Section({ Side = "Right", Title = "Config" })
settingsRight:Input({
    Name = "Config Name",
    Placeholder = "Enter configuration profile...",
    Callback = function(txt)
        if txt and txt ~= "" then configName = txt:gsub("[^%w_%-]", "") end
    end
})
settingsRight:Button({
    Name = "Save Config",
    Callback = function()
        local data = {}
        for _, k in ipairs(CONFIG_KEYS) do data[k] = Config[k] end
        local ok = pcall(function()
            writefile("DuelsSuite_" .. configName .. ".json", HttpService:JSONEncode(data))
        end)
        Window:Notify({ Title = "Config", Description = ok and ("Saved '" .. configName .. "'.") or "Saving not supported by this executor.", Lifetime = 2 })
    end
})
settingsRight:Button({
    Name = "Load Config",
    Callback = function()
        local ok = pcall(function()
            local data = HttpService:JSONDecode(readfile("DuelsSuite_" .. configName .. ".json"))
            for _, k in ipairs(CONFIG_KEYS) do
                if data[k] ~= nil then Config[k] = data[k] end
            end
        end)
        Window:Notify({ Title = "Config", Description = ok and ("Loaded '" .. configName .. "' (values apply live; re-toggle options).") or "No saved config found.", Lifetime = 2.5 })
    end
})
settingsRight:Button({
    Name = "Clear Saved Key (Reset)",
    Callback = function()
        pcall(function()
            if type(delfile) == "function" and isfile("DuelsSuite_Key.txt") then
                delfile("DuelsSuite_Key.txt")
            end
        end)
        Window:Notify({ Title = "Key System", Description = "Saved key deleted! Re-run script to prompt key window.", Lifetime = 3 })
    end
})

local creditsSection = tabs.Settings:Section({ Side = "Right", Title = "Credits" })
creditsSection:Header({ Text = "Owners/Developers" })
creditsSection:Paragraph({ Header = "Alx/Jay", Body = "Developer" })

pcall(function()
    if tabs and tabs.Combat and tabs.Combat.Select then tabs.Combat:Select() end
end)

--------------------------------------------------------------------------------
-- ENGINE (HEARTBEAT)
--------------------------------------------------------------------------------

safeConnect(RunService.Heartbeat, function()
    local char = LocalPlayer.Character
    local root = getRoot(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if hum then
        pcall(function()
            if Config.SpeedEnabled and hum.WalkSpeed ~= Config.WalkSpeed and not Config.FlyEnabled then
                hum.WalkSpeed = Config.WalkSpeed
            end
            if Config.JumpEnabled and hum.JumpPower ~= Config.JumpPower then
                hum.JumpPower = Config.JumpPower
            end
        end)
    end

    if Config.HitboxEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                local phum = player.Character:FindFirstChildOfClass("Humanoid")
                if hrp and phum and phum.Health > 0 then
                    if not isExcluded(player) then
                        hrp.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
                        hrp.Transparency = Config.HitboxTransparency
                        hrp.Color = Config.HitboxColor
                        hrp.Material = Config.HitboxMaterial
                        hrp.CanCollide = false
                    else
                        resetHitbox(player.Character)
                    end
                end
            end
        end
    end

    if Config.Triggerbot and IsLocalAlive() then
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool and string.find(string.lower(tool.Name), "gun") then
            local t = getTargetClosestToMouse("HumanoidRootPart", 500, 35, true)
            if t then
                pcall(function() tool:Activate() end)
            end
        end
    end

    if Config.AutoKnife and IsLocalAlive() then
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool and string.find(string.lower(tool.Name), "knife") then
            local myRoot = getRoot(LocalPlayer.Character)
            if myRoot then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and not isExcluded(p) then
                        local eChar = p.Character
                        local eRoot = getRoot(eChar)
                        local eHum = eChar and eChar:FindFirstChildOfClass("Humanoid")
                        if eRoot and eHum and eHum.Health > 0 then
                            if (eRoot.Position - myRoot.Position).Magnitude <= (Config.AutoKnifeDistance or 15) then
                                pcall(function() tool:Activate() end)
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    if Config.VisualsEnabled then
        local bottom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local c = p.Character
                local hrp = c and c:FindFirstChild("HumanoidRootPart")
                local h = c and c:FindFirstChildOfClass("Humanoid")
                local alive = c and hrp and h and h.Health > 0

                if alive then
                    local tracker = getOrCreateTracker(p)
                    local dist = root and (hrp.Position - root.Position).Magnitude or 0

                    if dist <= Config.MaxVisualDistance then
                        local role = getPlayerRole(p)
                        local roleTag = (role ~= "Innocent") and (" [" .. role .. "]") or ""
                        local roleColor = Config.RoleColors and (
                            role == "Murderer" and Color3.fromRGB(255, 45, 45) or
                            role == "Sheriff" and Color3.fromRGB(45, 140, 255) or
                            Color3.fromRGB(60, 255, 60)
                        ) or Config.HighlightColor

                        if Config.HighlightsEnabled then
                            if tracker.Highlight.Parent ~= c then
                                tracker.Highlight.Adornee = c
                                tracker.Highlight.Parent = c
                            end
                            tracker.Highlight.FillColor = roleColor
                            tracker.Highlight.Enabled = true
                        else
                            tracker.Highlight.Enabled = false
                        end

                        if Config.TagsEnabled then
                            if tracker.Billboard.Parent ~= hrp then
                                tracker.Billboard.Adornee = hrp
                                tracker.Billboard.Parent = hrp
                            end
                            tracker.Label.Text = string.format("%s%s\n%d HP | %d studs", p.DisplayName, roleTag, math.floor(h.Health), math.floor(dist))
                            tracker.Billboard.Enabled = true
                        else
                            tracker.Billboard.Enabled = false
                        end

                        if tracker.Tracer then
                            if Config.TracersEnabled then
                                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                                if onScreen then
                                    tracker.Tracer.Visible = true
                                    tracker.Tracer.From = bottom
                                    tracker.Tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                                    tracker.Tracer.Color = roleColor
                                else
                                    tracker.Tracer.Visible = false
                                end
                            else
                                tracker.Tracer.Visible = false
                            end
                        end
                    else
                        if tracker.Highlight then tracker.Highlight.Enabled = false end
                        if tracker.Billboard then tracker.Billboard.Enabled = false end
                        if tracker.Tracer then tracker.Tracer.Visible = false end
                    end
                else
                    local tracker = TrackedEntities[p]
                    if tracker then
                        if tracker.Highlight then tracker.Highlight.Enabled = false end
                        if tracker.Billboard then tracker.Billboard.Enabled = false end
                        if tracker.Tracer then tracker.Tracer.Visible = false end
                    end
                end
            end
        end
    else
        hideAllVisuals()
    end
end)

--------------------------------------------------------------------------------
-- RENDERSTEPPED ENGINE (Aimbot Camera Lock, FOV Circle, Spinbot)
--------------------------------------------------------------------------------

safeConnect(RunService.RenderStepped, function()
    if fovCircle then
        local mPos = UserInputService:GetMouseLocation()
        fovCircle.Position = mPos
        fovCircle.Radius = Config.SilentFOV
        fovCircle.Visible = Config.SilentAimEnabled and Config.SilentShowFOV
    end

    if Config.AimbotEnabled and IsLocalAlive() then
        local isAimHeld = not Config.AimbotHoldRMB or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        if isAimHeld then
            local targetPart = getTargetClosestToMouse(Config.AimbotPart, Config.MaxVisualDistance, Config.AimbotFOV, Config.AimbotWallCheck)
            if targetPart then
                local predPos = targetPart.Position + (targetPart.AssemblyLinearVelocity * (Config.AimbotPrediction or 0.08))
                local camPos = Camera.CFrame.Position
                local targetCFrame = CFrame.new(camPos, predPos)
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, math.clamp(1 - (Config.AimbotSmoothness or 0.25), 0.05, 1))
            end
        end
    end

    if Config.Spinbot and IsLocalAlive() then
        local myRoot = getRoot(LocalPlayer.Character)
        if myRoot then
            myRoot.CFrame = myRoot.CFrame * CFrame.Angles(0, math.rad(Config.SpinSpeed or 25), 0)
        end
    end
end)

--------------------------------------------------------------------------------
-- KILL SOUND (plays when a player's Humanoid you were near dies)
--------------------------------------------------------------------------------

local function watchPlayerDeath(p)
    if p == LocalPlayer then return end
    local function hook(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if not hum then return end
        safeConnect(hum.Died, function()
            if not Config.KillSound or not Config.SoundFXEnabled then return end
            local myRoot = getRoot(LocalPlayer.Character)
            local theirRoot = getRoot(char)
            if myRoot and theirRoot and (myRoot.Position - theirRoot.Position).Magnitude <= 60 then
                playSound(Config.KillSoundId, Config.SoundVolume)
            end
        end)
    end
    if p.Character then task.spawn(hook, p.Character) end
    safeConnect(p.CharacterAdded, hook)
end

for _, p in ipairs(Players:GetPlayers()) do watchPlayerDeath(p) end
safeConnect(Players.PlayerAdded, watchPlayerDeath)

--------------------------------------------------------------------------------
-- CHARACTER LIFECYCLE
--------------------------------------------------------------------------------

safeConnect(LocalPlayer.CharacterAdded, function()
    if Config.FlyEnabled then NOFLY() end
end)

--------------------------------------------------------------------------------
-- SUITE CLEANUP / UNLOAD HANDLER
--------------------------------------------------------------------------------

_G.DuelsSuiteCleanup = function()
    isSuiteActive = false
    Config.HitboxEnabled = false
    Config.VisualsEnabled = false
    pcall(setAntiFling, false)
    pcall(setNoclip, false)
    pcall(setInfiniteJump, false)
    pcall(NOFLY)
    pcall(resetAllHitboxes)
    pcall(destroyAllVisuals)
    if fovCircle then
        pcall(function() fovCircle:Remove() end)
        fovCircle = nil
    end
    for _, th in ipairs(backgroundThreads) do
        pcall(function() task.cancel(th) end)
    end
    table.clear(backgroundThreads)
    if watermarkFpsConn then
        pcall(function() watermarkFpsConn:Disconnect() end)
        watermarkFpsConn = nil
    end
    if keybindIndicatorGui then pcall(function() keybindIndicatorGui:Destroy() end) keybindIndicatorGui = nil end
    if watermarkGui then pcall(function() watermarkGui:Destroy() end) watermarkGui = nil end
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(connections)
    pcall(function() Window:Unload() end)
    _G.DuelsSuiteCleanup = nil
    print("[DALX Duels] Fully unloaded all modules and UI.")
end

