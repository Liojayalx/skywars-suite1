--[[
    â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—
    â•‘                     SKYWARS ULTIMATE MASTER SUITE                            â•‘
    â•‘   Dalx.wtf Edition v3.2 â€¢ Proprietary DalxUI â€¢ Keybind Manager (M1-M5)       â•‘
    â•‘   High-Ping Fast Bow â€¢ Silent Aim + Target Highlight â€¢ Protected Players     â•‘
    â•‘   Safe-TP Platform â€¢ Mining Automation â€¢ Hitbox Expander â€¢ Reach â€¢ Visuals   â•‘
    â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
]]

--------------------------------------------------------------------------
-- USERNAME ACCESS CONTROL, HARDENED KEY SYSTEM & SENTINEL TELEMETRY
--------------------------------------------------------------------------
local __SUITE_PASSED = false
;(function()
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
    local KEY_FILE              = "SkywarsSuite_Key.txt"
    local REMEMBER_KEY          = false  -- save key to client file

    -- EMERGENCY REMOTE KILL SWITCH CONFIG
    local KILL_SWITCH_ARMED     = false
    local KILL_SWITCH_REASON    = "âš ï¸ Skywars Suite is temporarily offline for emergency maintenance."

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

    -- LIVE CLOUD CONFIG SYNC (GitHub access_config.json)
    pcall(function()
        local HttpService = game:GetService("HttpService")
        local cloudRaw = game:HttpGet("https://raw.githubusercontent.com/Liojayalx/skywars-suite1/main/access_config.json", true)
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
                            footer = { text = "Skywars Suite Studio â€¢ Mobile Telemetry" },
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
        showInGameBanner("DALX Suite â€¢ Access Denied", tostring(reason or "Unauthorized access."), false)
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
        warn("[DALX Suite] ðŸš¨ REMOTE EMERGENCY KILL SWITCH IS ACTIVE.")
        showInGameBanner("DALX Suite â€¢ Emergency Shutdown", KILL_SWITCH_REASON, false)
        if LOG_BANNEDKICK then
            sendDiscordAlert("ðŸš¨ Emergency Kill Switch Block", "User **" .. myName .. "** attempted to run while Kill Switch was armed.", 15548997)
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
        local snoopers = { "simplespy", "hydroxs", "remotespy", "darkdex", "rspy" }
        local function scanCore()
            local targetHui = (type(gethui) == "function" and gethui()) or game:GetService("CoreGui")
            for _, obj in ipairs(targetHui:GetChildren()) do
                local n = obj.Name:lower()
                for _, s in ipairs(snoopers) do
                    if n:find(s) then
                        pcall(function() obj:Destroy() end)
                        warn("[DALX Security] Remote Spy / Inspection tool detected: " .. obj.Name)
                        if LOG_BANNEDKICK then
                            sendDiscordAlert("ðŸ›¡ï¸ Inspection Tool Detected", "User **" .. myName .. "** had spy tool (" .. obj.Name .. ") open.", 15158332)
                        end
                        pcall(function()
                            if lp then lp:Kick("\n[DALX Security]\nInspection tool (" .. obj.Name .. ") detected. Execution aborted.") end
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

    -- Metatable Namecall Hook Guard (Safe Verification)
    pcall(function()
        if type(getrawmetatable) == "function" then
            local gmt = getrawmetatable(game)
            if gmt and type(setreadonly) == "function" then
                -- Check read-only toggling safely without hard kicking on executors with custom userdata wrappers
                pcall(setreadonly, gmt, false)
            end
        end
    end)

    -- 1. Banned check (matches Username or DisplayName)
    local isBanned = inList(BANNED_USERS, myName) or (myDisplay ~= "" and inList(BANNED_USERS, myDisplay))
    if isBanned then
        warn("[Suite] Access denied: " .. myName .. " is blacklisted.")
        if LOG_BANNEDKICK then
            sendDiscordAlert("ðŸš« Blacklisted User Kicked", "Blacklisted user **" .. myName .. "** attempted execution and was kicked.", 15548997)
        end
        kickPlayer("You are blacklisted from this script.")
        return
    end

    -- 2. Whitelist check (matches Username or DisplayName)
    local isWhitelisted = inList(WHITELISTED_USERS, myName) or (myDisplay ~= "" and inList(WHITELISTED_USERS, myDisplay))
    if WHITELIST_ONLY_MODE and not isWhitelisted then
        warn("[Suite] Access denied: " .. myName .. " is not on the whitelist.")
        if LOG_KEYFAIL then
            sendDiscordAlert("â›” Whitelist-Only Block", "Non-whitelisted user **" .. myName .. "** blocked by Whitelist-Only mode.", 15158332)
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
        showInGameBanner("DALX Suite â€¢ Whitelist Verified", isWhitelisted and ("Welcome " .. myName .. "! Full access granted.") or "Key verified successfully.", true)
        if isWhitelisted and LOG_WHITELISTED then
            sendDiscordAlert("â­ Whitelisted User Executed", "Whitelisted user **" .. myName .. "** executed the suite.", 65535)
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
        title.Text = "DALX â€¢ Key System"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextSize = 16
        title.Parent = frame

        local subTitle = Instance.new("TextLabel")
        subTitle.Size = UDim2.new(1, -40, 0, 16)
        subTitle.Position = UDim2.new(0, 20, 0, 30)
        subTitle.BackgroundTransparency = 1
        subTitle.Font = Enum.Font.Gotham
        subTitle.Text = "Not Whitelisted (" .. myName .. ") â€¢ discord.gg/XJCEs3Jgg"
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
                    sendDiscordAlert("ðŸ”‘ Key Verified", "User **" .. myName .. "** passed key authentication (" .. tostring(reasonMsg) .. ").", 5763719, {
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
                        sendDiscordAlert("âŒ Key Failed â€¢ Disconnected", "User **" .. myName .. "** failed 3 key attempts and was kicked.", 15158332, {
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
end)()

-- Top-level hard execution barrier: absolutely NOTHING below runs if not passed
if not __SUITE_PASSED then
    return
end


-- Executor compatibility layer (Potassium / Wave / Synapse / Xeno / Solara etc.)
-- Fills in any missing UNC function so the suite and Infinite Yield tools never crash on load.
do
    local env = (type(getgenv) == "function" and getgenv()) or _G
    if type(getgenv) ~= "function" then pcall(function() getgenv = function() return env end end) end
    local function def(name, fn)
        if type(env[name]) ~= "function" then pcall(function() env[name] = fn end) end
    end
    def("cloneref", function(o) return o end)
    def("newcclosure", function(f) return f end)
    def("checkcaller", function() return false end)
    def("getcallingscript", function() return nil end)
    def("gethui", function() return game:GetService("CoreGui") end)
    def("setclipboard", function() end)
    def("queue_on_teleport", function() end)
    def("isfile", function() return false end)
    def("isfolder", function() return false end)
    def("makefolder", function() end)
    def("writefile", function() end)
    def("readfile", function() return "" end)
    def("firetouchinterest", function() end)
    def("fireproximityprompt", function() end)
    def("getconnections", function() return {} end)
    def("identifyexecutor", function() return "Unknown", "0" end)
    def("getnamecallmethod", function() return "" end)
    -- hookmetamethod: use native if present, else build from getrawmetatable + hookfunction, else harmless no-op
    if type(env.hookmetamethod) ~= "function" then
        pcall(function()
            env.hookmetamethod = function(obj, method, hook)
                if type(getrawmetatable) == "function" and type(hookfunction) == "function" then
                    local mt = getrawmetatable(obj)
                    local orig = mt and rawget(mt, method)
                    if type(orig) == "function" then
                        if type(setreadonly) == "function" then pcall(setreadonly, mt, false) end
                        return hookfunction(orig, hook)
                    end
                end
                return function(...) return nil end
            end
        end)
    end
    if type(env.hookfunction) ~= "function" then
        pcall(function() env.hookfunction = function(f) return f end end)
    end
    if type(env.setreadonly) ~= "function" then
        pcall(function() env.setreadonly = function() end end)
    end
end

if _G.SkywarsSuiteCleanup then
    local _lp = game:GetService("Players").LocalPlayer
    local _ch = _lp and _lp.Character
    local _hm = _ch and _ch:FindFirstChildWhichIsA("Humanoid")
    local _hp = _hm and _hm.Health
    pcall(_G.SkywarsSuiteCleanup)
    if _hm and _hp and _hp > 0 and _hm.Health <= 0 then
        pcall(function() _hm.Health = _hp end)
    end
end

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
local ContextActionService = game:GetService("ContextActionService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local IS_SKYWARS = (game.PlaceId == 855499080)

local queueteleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)

local function rejoinGame()
    if #Players:GetPlayers() <= 1 then
        LocalPlayer:Kick("\n[Infinite Yield] Rejoining server...")
        task.wait()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    else
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
end

-- Fallback if instance teleport fails
pcall(function()
    TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
        if player == LocalPlayer then
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    end)
end)

local Config = {
    WatermarkEnabled = true,
    SoundFXEnabled = true,
    ProximitySoundAlert = true,
    Bypass = true,
    FlyEnabled = false,
    FlySpeed = 1,
    QEfly = true,
    Noclip = false,
    SpeedEnabled = false,
    WalkSpeed = 16,
    JumpEnabled = false,
    JumpPower = 50,
    FlingEnabled = false,
    AntiFlingEnabled = false,
    InfiniteJump = false,
    CtrlTP = false,
    SafeTPEnabled = false,
    SafeTPHeight = 1500,
    SafeTPSize = 30,
    TargetName = "",
    BangSpeed = 3,
    ClickerEnabled = false,
    CPS = 60,
    HoldToClick = false,
    BypassDetection = true,
    SmartRateLimit = false,
    BlockMaxCPS = 25,
    -- High-Ping Fast Bow Engine
    HighPingBowEnabled = true,
    BowAutoShoot = true,
    BowOverdrive = true,
    BowBaseBurst = 4,
    BowMaxBurst = 16,
    -- Shoot Bow Without Holding
    BackgroundBowEnabled = false,
    BackgroundBowAimMode = "Nearest Enemy",
    BackgroundBowInterval = 0.35,
    BackgroundBowMaxRange = 350,
    -- Combat Face (Character Only)
    CombatFaceEnabled = false,
    CombatFaceRange = 75,
    SmoothRotation = false,
    RotationSpeed = 25,
    -- Mining Automation
    AutoMineEnabled = false,
    OreAutoMineEnabled = false,
    MineBehindPlaceFront = false,
    MineBehindHoldKey = true,
    BridgeTunnel3x3 = true,
    BridgeAutoJump = true,
    BridgeAutoPilot = true,
    BridgeLookaheadBlocks = 1,
    BridgeMineBehindBlocks = 5,
    -- Sword Reach Mechanic
    ReachEnabled = false,
    ReachSize = 15,
    ReachVisuals = false,
    ReachColorNormal = Color3.fromRGB(0, 215, 255),
    -- Hitbox Expander & Team Check
    HitboxEnabled = false,
    HitboxSize = 2,
    HitboxTransparency = 0.6,
    HitboxTeamCheck = false,
    HitboxColor = Color3.fromRGB(255, 50, 50),
    HitboxMaterial = Enum.Material.ForceField,
    -- Visuals / ESP
    VisualsEnabled = false,
    HighlightsEnabled = true,
    TracersEnabled = true,
    TagsEnabled = true,
    ShowWeaponInTags = true,
    HighlightColor = Color3.fromRGB(0, 240, 255),
    TracerColor = Color3.fromRGB(0, 240, 255),
    ChamStyle = "Outline Glow Only",
    ESPColorTheme = "Neon Cyan",
    RainbowChroma = false,
    DynamicHealthColor = false,
    TracerOrigin = "Bottom of Screen",
    MaxVisualDistance = 1200,
    -- Atmosphere & World FX
    FieldOfView = 70,
    FullbrightEnabled = false,
    AtmosphereTheme = "Default Sky",
    SelfChamsEnabled = false,
    SelfRainbowAura = false,
    MinecraftGraphics = false,
    MinecraftFogDistance = 650,
    -- Infinite Yield Tools
    IY_TPTool = false,
    IY_BTools = false,
    IY_F3X = false,
    IY_GrabTools = false,
    IY_CopyTools = false,
    IY_DroppableTools = false,
    IY_EquipAll = false,
    IY_UseTools = false,
    IY_ClickTP = false,
    IY_ClickDelete = false,
    IY_ToolReach = false,
    IY_ToolReachSize = 30,
    IY_BoxReach = false,
    IY_BoxReachSize = 30,
    IY_HandleKill = false,
    IY_BlockTool = false,
    IY_DuplicateTools = false,
    IY_ClearTools = false,
    -- Expanded Infinite Yield Tools
    IY_BringTools = false,
    IY_SpawnDeleteTool = false,
    IY_SpawnExplodeTool = false,
    IY_ClickFling = false,
    IY_ToolAura = false,
    IY_ToolAuraRange = 25,
    IY_Spin = false,
    IY_SpinSpeed = 30,
    IY_Float = false,
    IY_Airwalk = false,
    IY_Jesus = false,
    IY_Fullbright = false,
    IY_XRay = false,
    IY_AntiVoid = false,
    IY_AntiSit = false,
    IY_LowGravity = false,
    IY_GravityValue = 45,
    IY_Freecam = false,
    IY_FreecamSpeed = 1.5,
    IY_FreecamTP = true,
    SpinAbilitySpeed = 1,
    -- Keybinds
    Keybinds = {
        Bypass = nil, Fly = nil, Noclip = nil, AntiFling = nil,
        SpeedToggle = nil, JumpToggle = nil, InfiniteJump = nil, CtrlTP = nil,
        SafeTP = nil, Fling = nil, Clicker = nil, Hitbox = nil, CombatFace = nil,
        AutoMine = nil, OreAutoMine = nil, MinePlaceFront = nil, BridgeAutoPilot = nil,
        Reach = nil, Visuals = nil, Highlights = nil, Tracers = nil, Tags = nil,
        Fullbright = nil, Graphics = nil, SelfChams = nil, Bang = nil, Carpet = nil,
        Rejoin = nil, SilentAimToggle = nil, FastBow = nil, BackgroundBow = nil,
        IY_TPTool = nil, IY_BTools = nil, IY_ClickTP = nil, IY_ClickDelete = nil,
        IY_ClickFling = nil, IY_ToolAura = nil, IY_Float = nil, IY_Spin = nil,
        IY_Freecam = nil,
        SpinAbility = nil
    }
}
getgenv().SkywarsConfig = Config

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

--------------------------------------------------------------------------------
-- PERSISTENT PLAYER CONFIGURATION & KEYBIND STORAGE ENGINE
--------------------------------------------------------------------------------

local CONFIG_FOLDER = "SkywarsSuite"
local CONFIG_FILE = CONFIG_FOLDER .. "/" .. tostring(LocalPlayer.UserId) .. ".json"

local ConfigKeyAliases = {
    ["Auto Mine"] = "AutoMineEnabled",
    ["Ore Auto Mine"] = "OreAutoMineEnabled",
    ["Mine Behind, Place Front"] = "MineBehindPlaceFront",
    ["Hold Keybind Mode"] = "MineBehindHoldKey",
    ["3x3 Front Tunnel Mining"] = "BridgeTunnel3x3",
    ["BridgeTunnel3x3Toggle"] = "BridgeTunnel3x3",
    ["3x3 Tunnel"] = "BridgeTunnel3x3",
    ["Auto Jump While Bridging"] = "BridgeAutoJump",
    ["BridgeAutoJumpToggle"] = "BridgeAutoJump",
    ["Auto-Pilot on Double-Tap"] = "BridgeAutoPilot",
    ["BridgeAutoPilotToggle"] = "BridgeAutoPilot",
    ["Bridge Auto-Pilot"] = "BridgeAutoPilot",
    ["Blocks Placed In Front"] = "BridgeLookaheadBlocks",
    ["BridgeLookaheadSlider"] = "BridgeLookaheadBlocks",
    ["Blocks Mined Behind"] = "BridgeMineBehindBlocks",
    ["BridgeMineBehindSlider"] = "BridgeMineBehindBlocks",
    ["Enable WalkSpeed"] = "SpeedEnabled",
    ["WalkSpeed"] = "WalkSpeed",
    ["Enable JumpPower"] = "JumpEnabled",
    ["JumpPower"] = "JumpPower",
    ["Infinite Jump"] = "InfiniteJump",
    ["Master Visuals Switch"] = "VisualsEnabled",
    ["Chams / Highlights"] = "HighlightsEnabled",
    ["Snapline Tracers"] = "TracersEnabled",
    ["3D Floating Tags"] = "TagsEnabled",
    ["Show Held Weapon in Tags"] = "ShowWeaponInTags",
    ["Rainbow Chroma Wave (Animated)"] = "RainbowChroma",
    ["Dynamic Health Colors (G/Y/R)"] = "DynamicHealthColor",
    ["Cham Style"] = "ChamStyle",
    ["ESP Color Theme"] = "ESPColorTheme",
    ["Tracer Origin"] = "TracerOrigin",
    ["Max ESP Distance"] = "MaxVisualDistance",
    ["Field of View (FOV)"] = "FieldOfView",
    ["Fullbright (Void Vision)"] = "FullbrightEnabled",
    ["Atmosphere Sky Preset"] = "AtmosphereTheme",
    ["Minecraft Graphics (Retro Shaders)"] = "MinecraftGraphics",
    ["Minecraft Graphics"] = "MinecraftGraphics",
    ["Self Character Glow (Chams)"] = "SelfChamsEnabled",
    ["Self Rainbow Chroma Aura"] = "SelfRainbowAura",
    ["Bypass"] = "Bypass",
    ["Sword Reach"] = "ReachEnabled",
    ["Reach"] = "ReachEnabled",
    ["Reach Size"] = "ReachSize",
    ["Hitbox Expander"] = "HitboxEnabled",
    ["Hitbox Size"] = "HitboxSize",
    ["Hitbox Transparency"] = "HitboxTransparency",
    ["Hitbox Team Check"] = "HitboxTeamCheck",
    ["Auto Clicker"] = "ClickerEnabled",
    ["CPS"] = "CPS",
    ["Hold To Click"] = "HoldToClick",
    ["Hold Mouse To Click Only"] = "HoldToClick",
    ["HoldToClickToggle"] = "HoldToClick",
    ["Auto-Face Target"] = "CombatFaceEnabled",
    ["Smooth Rotation"] = "SmoothRotation",
    ["Rotation Speed"] = "RotationSpeed",
    ["Combat Face Range"] = "CombatFaceRange",
    ["High-Ping Fast Bow"] = "HighPingBowEnabled",
    ["Bow Overdrive Mode"] = "BowOverdrive",
    ["Base Rapid Burst"] = "BowBaseBurst",
    ["Max Velocity Burst"] = "BowMaxBurst",
    ["Enable Flight"] = "FlyEnabled",
    ["Flight Speed"] = "FlySpeed",
    ["QE Altitude Control"] = "QEfly",
    ["Noclip"] = "Noclip",
    ["Anti-Fling"] = "AntiFlingEnabled",
    ["Player Fling"] = "FlingEnabled",
    ["CTRL + Click TP"] = "CtrlTP",
    ["Safe Island TP"] = "SafeTPEnabled",
    ["Safe TP Height"] = "SafeTPHeight",
    ["Safe TP Platform Size"] = "SafeTPSize",
    ["Watermark HUD"] = "WatermarkEnabled",
    ["Position"] = "WatermarkPosition",
    ["Custom X (%)"] = "WatermarkX",
    ["Custom Y (%)"] = "WatermarkY",
    ["Bow Fire Delay (s)"] = "BowFireDelay",
    ["Sound Effects"] = "SoundFXEnabled",
    ["Audio Chimes & Sound Effects"] = "SoundFXEnabled",
    ["Proximity Threat Audio Alert"] = "ProximitySoundAlert",
    ["Highlights"] = "HighlightsEnabled",
    ["Tracers"] = "TracersEnabled",
    ["Tags"] = "TagsEnabled",
    ["Fullbright"] = "FullbrightEnabled",
    ["Graphics"] = "MinecraftGraphics",
    ["SelfChams"] = "SelfChamsEnabled",
    ["AutoMine"] = "AutoMineEnabled",
    ["OreAutoMine"] = "OreAutoMineEnabled",
    ["MinePlaceFront"] = "MineBehindPlaceFront",
    ["Fly"] = "FlyEnabled",
    ["SpeedToggle"] = "SpeedEnabled",
    ["JumpToggle"] = "JumpEnabled",
    ["Clicker"] = "ClickerEnabled",
    ["FastBow"] = "HighPingBowEnabled",
    ["Automatic Bow Shooting"] = "BowAutoShoot",
    ["BowAutoShoot"] = "BowAutoShoot",
    ["CombatFace"] = "CombatFaceEnabled",
    ["Hitbox"] = "HitboxEnabled",
    ["AntiFling"] = "AntiFlingEnabled",
    ["Fling"] = "FlingEnabled",
    ["SafeTP"] = "SafeTPEnabled",
    ["Visuals"] = "VisualsEnabled",
    ["BridgeAutoPilot"] = "BridgeAutoPilot",
    ["Shoot Bow Without Holding"] = "BackgroundBowEnabled",
    ["BackgroundBow"] = "BackgroundBowEnabled",
    ["Bow Aim Mode"] = "BackgroundBowAimMode",
    ["Bow Fire Interval (s)"] = "BackgroundBowInterval",
    ["Bow Max Range"] = "BackgroundBowMaxRange"
}

local RegisteredControls = {
    Toggles = {},
    Sliders = {},
    Dropdowns = {},
    Keybinds = {}
}

local function serializeKeybind(keyInput)
    if not keyInput then return nil end
    if typeof(keyInput) == "EnumItem" then
        if keyInput.EnumType == Enum.KeyCode then
            return "KeyCode:" .. keyInput.Name
        elseif keyInput.EnumType == Enum.UserInputType then
            return "UserInputType:" .. keyInput.Name
        end
    end
    return nil
end

local function deserializeKeybind(str)
    if not str or type(str) ~= "string" then return nil end
    local enumType, enumName = str:match("^([^:]+):([^:]+)$")
    if enumType == "KeyCode" and Enum.KeyCode[enumName] then
        return Enum.KeyCode[enumName]
    elseif enumType == "UserInputType" and Enum.UserInputType[enumName] then
        return Enum.UserInputType[enumName]
    end
    return nil
end

local function serializeColor3(c)
    if typeof(c) == "Color3" then
        return {r = math.floor(c.R * 255), g = math.floor(c.G * 255), b = math.floor(c.B * 255)}
    end
    return nil
end

local function deserializeColor3(t)
    if type(t) == "table" and t.r and t.g and t.b then
        return Color3.fromRGB(t.r, t.g, t.b)
    end
    return nil
end

local DANGEROUS_OR_EPHEMERAL_OPTIONS = {
    IY_ClickDelete = true,
    IY_ClickTP = true,
    IY_BTools = true,
    IY_ClickFling = true,
    MineBehindPlaceFront = true,
    AutoMineEnabled = true,
    OreAutoMineEnabled = true,
    ClickerEnabled = true,
    IY_SpawnDeleteTool = true,
    IY_SpawnExplodeTool = true,
    FlyEnabled = true,
}

local function serializeConfig()
    local data = {
        UserId = LocalPlayer.UserId,
        Username = LocalPlayer.Name,
        DisplayName = LocalPlayer.DisplayName,
        SavedAt = os.date("%Y-%m-%d %H:%M:%S"),
        Options = {},
        Keybinds = {}
    }

    if Config and Config.Keybinds then
        for k, v in pairs(Config.Keybinds) do
            local s = serializeKeybind(v)
            if s then data.Keybinds[k] = s end
        end
    end

    for k, v in pairs(Config) do
        if k ~= "Keybinds" and k ~= "Connections" and k ~= "Threads" then
            if DANGEROUS_OR_EPHEMERAL_OPTIONS[k] then
                data.Options[k] = false
            else
                local t = type(v)
                if t == "boolean" or t == "number" or t == "string" then
                    data.Options[k] = v
                elseif typeof(v) == "Color3" then
                    data.Options[k] = serializeColor3(v)
                elseif t == "table" and not v.r and not v.ClassName then
                    data.Options[k] = v
                end
            end
        end
    end

    return data
end

local function savePlayerConfig()
    pcall(function()
        if type(writefile) ~= "function" then return end
        if type(isfolder) == "function" and not isfolder(CONFIG_FOLDER) then
            if type(makefolder) == "function" then makefolder(CONFIG_FOLDER) end
        end
        local data = serializeConfig()
        local json = HttpService:JSONEncode(data)
        writefile(CONFIG_FILE, json)
    end)
end

local saveDebounceThread = nil
local function saveConfigDebounced()
    if saveDebounceThread then
        pcall(function() task.cancel(saveDebounceThread) end)
        saveDebounceThread = nil
    end
    saveDebounceThread = task.delay(0.25, function()
        savePlayerConfig()
    end)
end

local function loadPlayerConfig()
    local loaded = false
    pcall(function()
        if type(readfile) ~= "function" or type(isfile) ~= "function" then return end
        if not isfile(CONFIG_FILE) then return end
        local raw = readfile(CONFIG_FILE)
        if not raw or raw == "" then return end
        local data = HttpService:JSONDecode(raw)
        if not data then return end

        if data.Options and type(data.Options) == "table" then
            for k, v in pairs(data.Options) do
                if DANGEROUS_OR_EPHEMERAL_OPTIONS[k] then
                    Config[k] = false
                elseif type(v) == "table" and v.r and v.g and v.b then
                    Config[k] = deserializeColor3(v)
                else
                    Config[k] = v
                end
            end
        end

        if data.Keybinds and type(data.Keybinds) == "table" then
            for k, v in pairs(data.Keybinds) do
                local key = deserializeKeybind(v)
                if key then
                    Config.Keybinds[k] = key
                end
            end
        end
        loaded = true
    end)
    return loaded
end

local function applyConfigToUI()
    for id, toggle in pairs(RegisteredControls.Toggles) do
        local cKey = ConfigKeyAliases[id] or id
        if Config[cKey] ~= nil and toggle.UpdateState then
            pcall(function() toggle:UpdateState(Config[cKey], true) end)
        end
    end
    for id, slider in pairs(RegisteredControls.Sliders) do
        local cKey = ConfigKeyAliases[id] or id
        if Config[cKey] ~= nil and slider.Set then
            pcall(function() slider:Set(Config[cKey], true) end)
        end
    end
    for id, dropdown in pairs(RegisteredControls.Dropdowns) do
        local cKey = ConfigKeyAliases[id] or id
        if Config[cKey] ~= nil and dropdown.Set then
            pcall(function() dropdown:Set(Config[cKey], true) end)
        end
    end
    for k, entry in pairs(RegisteredControls.Keybinds) do
        local curKey = Config.Keybinds and Config.Keybinds[k]
        local keyStr = "[" .. getKeyName(curKey) .. "]"
        local col = curKey and THEME.TextPrimary or THEME.TextDim
        if entry.Button and entry.Button.Parent then
            entry.Button.Text = keyStr
            entry.Button.TextColor3 = col
        end
        if type(entry) == "table" then
            for _, btn in ipairs(entry) do
                if typeof(btn) == "Instance" and btn.Parent then
                    btn.Text = keyStr
                    btn.TextColor3 = col
                end
            end
        end
    end
    updateKeybindIndicatorHUD()
end

loadPlayerConfig()

getgenv().WhitelistedPlayers = getgenv().WhitelistedPlayers or {}

-- Silent Aim Configuration Globals
getgenv().Prediction = getgenv().Prediction or 0.16
getgenv().AimKey = getgenv().AimKey or "t"
getgenv().DontShootThesePeople = getgenv().DontShootThesePeople or {
    "AimLockPsycho";
    "JakeTheMiddleMan";
}

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
local MineBehindToggleObj = nil

local function getKeyName(keyInput)
    if not keyInput then return "None" end
    if typeof(keyInput) == "EnumItem" then
        if keyInput.EnumType == Enum.UserInputType then
            local num = keyInput.Name:match("^MouseButton(%d)$")
            if num then return "M" .. num end
            return keyInput.Name
        elseif keyInput.EnumType == Enum.KeyCode then
            if keyInput == Enum.KeyCode.Backspace or keyInput == Enum.KeyCode.Escape then return "None" end
            return keyInput.Name
        end
    end
    return tostring(keyInput)
end

local function registerKeybindBadge(keybindKey, badgeBtn)
    if not RegisteredControls.Keybinds[keybindKey] then
        RegisteredControls.Keybinds[keybindKey] = {}
    end
    table.insert(RegisteredControls.Keybinds[keybindKey], badgeBtn)
end

local function syncKeybindBadges(keybindKey)
    local curKey = Config.Keybinds and Config.Keybinds[keybindKey]
    local name = getKeyName(curKey)
    local col = curKey and THEME.TextPrimary or THEME.TextDim
    local list = RegisteredControls.Keybinds and RegisteredControls.Keybinds[keybindKey]
    if list then
        if list.Button and list.Button.Parent then
            list.Button.Text = "[" .. name .. "]"
            list.Button.TextColor3 = col
        end
        if type(list) == "table" then
            for _, btn in ipairs(list) do
                if typeof(btn) == "Instance" and btn.Parent then
                    btn.Text = "[" .. name .. "]"
                    btn.TextColor3 = col
                end
            end
        end
    end
    if updateKeybindIndicatorHUD then
        updateKeybindIndicatorHUD()
    end
end

local function startBindingKey(keybindConfigKey, bindBadge, onFinished)
    if isListeningForBind then return end
    isListeningForBind = true
    bindBadge.Text = "[...]"
    bindBadge.TextColor3 = THEME.AccentRed

    local kConn, mConn
    local function endBind()
        if kConn then kConn:Disconnect() kConn = nil end
        if mConn then mConn:Disconnect() mConn = nil end
        task.wait(0.06)
        isListeningForBind = false
    end

    kConn = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            endBind()
            if input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Escape then
                Config.Keybinds[keybindConfigKey] = nil
            else
                Config.Keybinds[keybindConfigKey] = input.KeyCode
            end
            syncKeybindBadges(keybindConfigKey)
            if keybindConfigKey == "SpinAbility" and syncSpinKeybind then
                syncSpinKeybind(Config.Keybinds[keybindConfigKey])
            end
            if onFinished then onFinished(Config.Keybinds[keybindConfigKey]) end
            if saveConfigDebounced then saveConfigDebounced() end
        end
    end)

    mConn = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType.Name:match("^MouseButton%d$") then
            endBind()
            Config.Keybinds[keybindConfigKey] = input.UserInputType
            syncKeybindBadges(keybindConfigKey)
            if onFinished then onFinished(input.UserInputType) end
            if saveConfigDebounced then saveConfigDebounced() end
        end
    end)
end

local function triggerOption(key)
    if not key then return end
    local toggle = RegisteredControls.Toggles[key]
    if not toggle then
        local cKey = ConfigKeyAliases[key]
        if cKey then toggle = RegisteredControls.Toggles[cKey] end
    end
    if not toggle then
        for id, t in pairs(RegisteredControls.Toggles) do
            local cKey = ConfigKeyAliases[id] or id
            if (cKey == key or id == key) and t.UpdateState and t.Get then
                toggle = t
                break
            end
        end
    end
    if toggle and toggle.UpdateState and toggle.Get then
        toggle:UpdateState(not toggle:Get())
        return
    end
    if KeybindRegistry[key] and KeybindRegistry[key].Callback then
        KeybindRegistry[key].Callback()
        return
    end
end

local lastMineBehindPressTick = 0
local bridgeAutoPilotActive = false
local autoPilotMoveDir = Vector3.new(0, 0, -1)
local lastGodbridgeEndTime = 0

local function toggleBridgeAutoPilot(val)
    if val == nil then
        val = not bridgeAutoPilotActive
    end
    bridgeAutoPilotActive = val

    if val then
        if MineBehindToggleObj and not MineBehindToggleObj:Get() then
            MineBehindToggleObj:UpdateState(true)
        end
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.MoveDirection.Magnitude > 0.1 then
            autoPilotMoveDir = hum.MoveDirection.Unit
        elseif root then
            local look = root.CFrame.LookVector
            autoPilotMoveDir = Vector3.new(look.X, 0, look.Z).Unit
        else
            autoPilotMoveDir = Vector3.new(0, 0, -1)
        end
        if Window and Window.Notify then
            Window:Notify({
                Title = "Auto-Pilot",
                Description = "Auto-Pilot ENGAGED! Press key again or [S] to stop.",
                Lifetime = 2.5
            })
        end
    else
        if MineBehindToggleObj and MineBehindToggleObj:Get() then
            MineBehindToggleObj:UpdateState(false)
        end
        if Window and Window.Notify then
            Window:Notify({
                Title = "Auto-Pilot",
                Description = "Auto-Pilot Disengaged.",
                Lifetime = 1.5
            })
        end
    end
end

safeConnect(UserInputService.InputBegan, function(input, gpe)
    if isListeningForBind then return end
    if UserInputService:GetFocusedTextBox() ~= nil then return end

    -- Backward cancel for Auto-Pilot
    if bridgeAutoPilotActive and (input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.Down) then
        toggleBridgeAutoPilot(false)
        return
    end

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
            if matches then
                if keyName == "BridgeAutoPilot" then
                    toggleBridgeAutoPilot()
                elseif keyName == "MinePlaceFront" then
                    local now = tick()
                    local isDoubleTap = (now - lastMineBehindPressTick) < 0.4
                    lastMineBehindPressTick = now

                    if bridgeAutoPilotActive then
                        toggleBridgeAutoPilot(false)
                    elseif isDoubleTap and Config.BridgeAutoPilot then
                        toggleBridgeAutoPilot(true)
                    elseif Config.MineBehindHoldKey then
                        if MineBehindToggleObj and not MineBehindToggleObj:Get() then
                            MineBehindToggleObj:UpdateState(true)
                        end
                    else
                        triggerOption(keyName)
                    end
                else
                    triggerOption(keyName)
                end
            end
        end
    end
end)

safeConnect(UserInputService.InputEnded, function(input)
    if isListeningForBind then return end
    if not Config.MineBehindHoldKey then return end

    local targetInput = Config.Keybinds and Config.Keybinds.MinePlaceFront
    if targetInput then
        local matches = false
        if typeof(targetInput) == "EnumItem" then
            if targetInput.EnumType == Enum.KeyCode and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == targetInput then
                matches = true
            elseif targetInput.EnumType == Enum.UserInputType and input.UserInputType == targetInput then
                matches = true
            end
        end
        if matches then
            -- If Auto-Pilot is engaged, do NOT stop bridging when key is released!
            if bridgeAutoPilotActive then return end
            if MineBehindToggleObj and MineBehindToggleObj:Get() then
                MineBehindToggleObj:UpdateState(false)
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- HIGH-PING FAST BOW ENGINE (Adaptive Network Pipelining)
--------------------------------------------------------------------------------

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

local currentBowTargetPos = nil
local hookedBowCC = nil
local lastBackgroundBowShootTick = 0

local function hookBowClientControl(tool)
    if not tool or not string.find(string.lower(tool.Name), "bow") then return end
    local cc = tool:FindFirstChild("ClientControl")
    if not cc or not cc:IsA("RemoteFunction") or cc == hookedBowCC then return end
    hookedBowCC = cc

    cc.OnClientInvoke = function(...)
        if not IsLocalAlive() then return Vector3.zero end
        if currentBowTargetPos then
            return currentBowTargetPos
        end
        local mouse = LocalPlayer:GetMouse()
        local hitCFrame = mouse.Hit
        if typeof(hitCFrame) == "CFrame" then
            return hitCFrame.Position
        end
        return mouse.Hit.p
    end
end

local function getAnyBowTool()
    local char = LocalPlayer.Character
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") and string.find(string.lower(t.Name), "bow") then
                return t
            end
        end
    end
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and string.find(string.lower(t.Name), "bow") then
                return t
            end
        end
    end
    return nil
end

local isBackgroundBowFiring = false
local function shootBowWithoutHolding(targetOverridePos)
    if isBackgroundBowFiring then return false end
    local char = LocalPlayer.Character
    if not char or not IsLocalAlive() then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end

    local bow = getAnyBowTool()
    if not bow then return false end

    isBackgroundBowFiring = true
    hookBowClientControl(bow)

    local aimPos = targetOverridePos
    if not aimPos then
        if Config.BackgroundBowAimMode == "Nearest Enemy" or not Config.BackgroundBowAimMode then
            local root = getRoot(char)
            local nearestTarget = nil
            local nearestDist = math.huge
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and not isExcluded(p) and p.Character then
                    local hrp = getRoot(p.Character)
                    local phum = p.Character:FindFirstChildOfClass("Humanoid")
                    if hrp and phum and phum.Health > 0 then
                        local dist = (hrp.Position - root.Position).Magnitude
                        if dist < nearestDist and dist <= (Config.BackgroundBowMaxRange or 350) then
                            nearestDist = dist
                            nearestTarget = hrp
                        end
                    end
                end
            end
            if nearestTarget then
                local pred = getgenv().Prediction or 0.16
                local vel = nearestTarget.AssemblyLinearVelocity or nearestTarget.Velocity or Vector3.zero
                aimPos = nearestTarget.Position + vel * pred + Vector3.new(0, 0.4, 0)
            end
        end
    end

    if not aimPos then
        local mouse = LocalPlayer:GetMouse()
        if mouse and mouse.Hit then
            aimPos = mouse.Hit.Position
        end
    end

    if not aimPos then
        isBackgroundBowFiring = false
        return false
    end

    currentBowTargetPos = aimPos

    local sc = bow:FindFirstChild("ServerControl")
    local currentlyHeldTool = char:FindFirstChildOfClass("Tool")
    local inBackpack = (bow.Parent ~= char)

    local burst = 1
    if Config.HighPingBowEnabled then
        local ping = getNetworkPing()
        if Config.BowOverdrive then
            burst = Config.BowMaxBurst or 16
        else
            burst = math.clamp(math.floor(ping / 25), Config.BowBaseBurst or 2, Config.BowMaxBurst or 16)
        end
    end

    pcall(function()
        if inBackpack then
            hum:EquipTool(bow)
        end

        if sc and sc:IsA("RemoteFunction") then
            for _ = 1, burst do
                task.spawn(function()
                    pcall(function() sc:InvokeServer(true) end)
                    pcall(function() sc:InvokeServer(false) end)
                end)
            end
        else
            for _ = 1, burst do
                task.spawn(function()
                    pcall(function() bow:Activate() end)
                end)
            end
        end

        if inBackpack then
            task.defer(function()
                task.wait(0.04)
                if hum then
                    if currentlyHeldTool and currentlyHeldTool.Parent then
                        hum:EquipTool(currentlyHeldTool)
                    else
                        hum:UnequipTools()
                    end
                end
            end)
        end
    end)

    task.delay(0.04, function()
        currentBowTargetPos = nil
        isBackgroundBowFiring = false
    end)
    return true
end

safeSpawn(function()
    while isSuiteActive do
        task.wait(0.05)
        if Config.BackgroundBowEnabled and IsLocalAlive() then
            local now = tick()
            local interval = tonumber(Config.BackgroundBowInterval) or 0.35
            if now - lastBackgroundBowShootTick >= interval then
                lastBackgroundBowShootTick = now
                pcall(function()
                    shootBowWithoutHolding()
                end)
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- SAFE-TP PLATFORM ENGINE
--------------------------------------------------------------------------------

local safeTpPlatform = nil
local safeTpSavedCFrame = nil
local safeTpHeartbeat = nil
local SafeTPToggleObj = nil

local function toggleSafeTP(state)
    Config.SafeTPEnabled = state
    local char = LocalPlayer.Character
    local root = getRoot(char)

    if state then
        if not root or not IsLocalAlive() then
            Config.SafeTPEnabled = false
            if SafeTPToggleObj then SafeTPToggleObj:UpdateState(false) end
            return
        end

        safeTpSavedCFrame = root.CFrame
        local targetPos = safeTpSavedCFrame.Position + Vector3.new(0, Config.SafeTPHeight, 0)

        if safeTpPlatform and safeTpPlatform.Parent then
            safeTpPlatform:Destroy()
        end

        safeTpPlatform = Instance.new("Part")
        safeTpPlatform.Name = "SkywarsSafePlatform"
        safeTpPlatform.Size = Vector3.new(Config.SafeTPSize, 2, Config.SafeTPSize)
        safeTpPlatform.Position = targetPos - Vector3.new(0, 1, 0)
        safeTpPlatform.Anchored = true
        safeTpPlatform.CanCollide = true
        safeTpPlatform.Material = Enum.Material.Neon
        safeTpPlatform.Color = Color3.fromRGB(35, 35, 45)
        safeTpPlatform.Parent = Workspace

        breakVelocity()
        char:PivotTo(CFrame.new(targetPos + Vector3.new(0, 3.5, 0)))
        breakVelocity()

        if safeTpHeartbeat then safeTpHeartbeat:Disconnect() end
        safeTpHeartbeat = RunService.Heartbeat:Connect(function()
            if not Config.SafeTPEnabled then
                if safeTpHeartbeat then safeTpHeartbeat:Disconnect() safeTpHeartbeat = nil end
                return
            end
            local c = LocalPlayer.Character
            local r = getRoot(c)
            if r and safeTpPlatform and safeTpPlatform.Parent then
                if (r.Position.Y < safeTpPlatform.Position.Y - 5) then
                    c:PivotTo(CFrame.new(targetPos + Vector3.new(0, 3.5, 0)))
                    breakVelocity()
                end
            end
        end)
    else
        if safeTpHeartbeat then
            safeTpHeartbeat:Disconnect()
            safeTpHeartbeat = nil
        end

        if char and safeTpSavedCFrame then
            char:PivotTo(safeTpSavedCFrame)
            breakVelocity()
        end

        if safeTpPlatform and safeTpPlatform.Parent then
            safeTpPlatform:Destroy()
            safeTpPlatform = nil
        end
        safeTpSavedCFrame = nil
    end
end

--------------------------------------------------------------------------------
-- 3D REACH CIRCLE VISUALS & LOGIC
--------------------------------------------------------------------------------

local ReachCircleParts = {}

local function createReachCircle()
    for _, part in pairs(ReachCircleParts) do
        if part then part:Destroy() end
    end
    ReachCircleParts = {}
    
    local numParts = 60 
    for i = 1, numParts do
        local part = Instance.new("Part")
        part.Name = "ReachIndicatorSegment"
        part.Size = Vector3.new(0.3, 0.3, 0.5)
        part.Material = Enum.Material.Neon
        part.Color = Config.ReachColorNormal
        part.Transparency = 0.3
        part.CanCollide = false
        part.Anchored = true
        part.Parent = workspace
        
        table.insert(ReachCircleParts, part)
    end
end

local function updateReachCirclePosition(rootPosition)
    if #ReachCircleParts == 0 then return end
    local numParts = #ReachCircleParts
    local angleStep = (math.pi * 2) / numParts
    
    for i, part in ipairs(ReachCircleParts) do
        if part and part.Parent then
            local angle = angleStep * i
            local x = math.cos(angle) * Config.ReachSize
            local z = math.sin(angle) * Config.ReachSize
            local segmentPos = rootPosition + Vector3.new(x, -3, z)
            
            part.CFrame = CFrame.new(segmentPos, rootPosition + Vector3.new(0, -3, 0))
        end
    end
end

local function destroyReachCircle()
    for _, part in pairs(ReachCircleParts) do
        if part then part:Destroy() end
    end
    ReachCircleParts = {}
end

--------------------------------------------------------------------------------
-- ANTIFLING ENGINE
--------------------------------------------------------------------------------

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

-- ============================================================================
-- Character Spin Ability
-- ============================================================================
local ACTION_NAME = "CharacterSpinAbility"
local SPIN_KEYBIND = nil
local SPIN_DURATION = 0.35      -- Total seconds to complete a full 360-degree turn (at 1x speed)
local SPIN_DEGREES = 360        -- Total rotation amount
local COOLDOWN_SECONDS = 0.5    -- Cooldown between spin casts

local isPerformingSpin = false
local lastSpinTick = 0
local spinRenderConn = nil

local function cleanupSpin(humanoid)
    if spinRenderConn then
        pcall(function() spinRenderConn:Disconnect() end)
        spinRenderConn = nil
    end

    if humanoid and humanoid.Parent then
        pcall(function() humanoid.AutoRotate = true end)
    end

    isPerformingSpin = false
end

local function performCharacterSpin()
    local now = os.clock()
    if isPerformingSpin or (now - lastSpinTick < COOLDOWN_SECONDS) then
        return
    end

    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if not rootPart or not humanoid or humanoid.Health <= 0 then
        return
    end

    isPerformingSpin = true
    lastSpinTick = now

    -- Temporarily disable AutoRotate so default movement doesn't counter the spin
    pcall(function() humanoid.AutoRotate = false end)

    local accumulatedDegrees = 0
    local speedMultiplier = math.max(0.1, tonumber(Config.SpinAbilitySpeed) or 1)
    local actualDuration = math.max(0.01, SPIN_DURATION / speedMultiplier)
    local degreesPerSecond = SPIN_DEGREES / actualDuration

    if spinRenderConn then
        pcall(function() spinRenderConn:Disconnect() end)
        spinRenderConn = nil
    end

    spinRenderConn = RunService.RenderStepped:Connect(function(deltaTime)
        local currentChar = LocalPlayer.Character
        local currentRoot = currentChar and currentChar:FindFirstChild("HumanoidRootPart")
        local currentHum = currentChar and currentChar:FindFirstChildOfClass("Humanoid")

        -- Abort immediately if the character died or became invalid
        if not currentRoot or not currentHum or currentHum.Health <= 0 then
            cleanupSpin(currentHum)
            return
        end

        local step = degreesPerSecond * deltaTime
        local remaining = SPIN_DEGREES - accumulatedDegrees

        if step >= remaining then
            step = remaining
            accumulatedDegrees = SPIN_DEGREES
        else
            accumulatedDegrees = accumulatedDegrees + step
        end

        -- Rotate along the vertical (Y) axis
        currentRoot.CFrame = currentRoot.CFrame * CFrame.Angles(0, math.rad(step), 0)

        if accumulatedDegrees >= SPIN_DEGREES then
            cleanupSpin(currentHum)
        end
    end)
end

local function handleSpinInput(actionName, inputState, _inputObject)
    if actionName == ACTION_NAME and inputState == Enum.UserInputState.Begin then
        performCharacterSpin()
        return Enum.ContextActionResult.Sink
    end
    return Enum.ContextActionResult.Pass
end

local function syncSpinKeybind(targetBind)
    pcall(function() ContextActionService:UnbindAction(ACTION_NAME) end)
    if targetBind and typeof(targetBind) == "EnumItem" and targetBind.EnumType == Enum.KeyCode then
        pcall(function()
            ContextActionService:BindAction(ACTION_NAME, handleSpinInput, false, targetBind)
        end)
    end
end

syncSpinKeybind(Config.Keybinds and Config.Keybinds.SpinAbility or SPIN_KEYBIND)

-- Clean up connection when the character respawns
safeConnect(LocalPlayer.CharacterRemoving, function()
    cleanupSpin(nil)
end)

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

local function giveTpTool()
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not backpack then return end
    local existing = backpack:FindFirstChild("TP Tool") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("TP Tool"))
    if existing then existing:Destroy() end

    local TpTool = Instance.new("Tool")
    TpTool.Name = "TP Tool"
    TpTool.RequiresHandle = false
    TpTool.CanBeDropped = false

    TpTool.Activated:Connect(function()
        local mouse = LocalPlayer:GetMouse()
        local char = LocalPlayer.Character
        local root = getRoot(char)
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not mouse or not root or not hum or hum.Health <= 0 then return end
        
        local targetInstance = mouse.Target
        local targetModel = targetInstance and targetInstance:FindFirstAncestorOfClass("Model")
        local targetPlr = targetModel and Players:GetPlayerFromCharacter(targetModel)

        if targetPlr and targetPlr ~= LocalPlayer and targetPlr.Character then
            local tRoot = getRoot(targetPlr.Character)
            if tRoot then
                breakVelocity()
                root.CFrame = tRoot.CFrame * CFrame.new(0, 0, 1.2)
                breakVelocity()
                return
            end
        end

        local hitPos = mouse.Hit.Position
        local currentRot = root.CFrame - root.CFrame.Position
        breakVelocity()
        root.CFrame = CFrame.new(hitPos.X, hitPos.Y + 3.2, hitPos.Z) * currentRot
        breakVelocity()
    end)
    TpTool.Parent = backpack
end

local flingConnection = nil
local function setFling(state)
    Config.FlingEnabled = state
    if flingConnection then flingConnection:Disconnect() flingConnection = nil end
    if state then
        flingConnection = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            local root = getRoot(char)
            if char and root and Config.FlingEnabled then
                root.Velocity = Vector3.new(0, 50000, 0) + Vector3.new(math.random(-10000, 10000), 0, math.random(-10000, 10000))
                root.RotVelocity = Vector3.new(99999, 99999, 99999)
            end
        end)
    end
end

--------------------------------------------------------------------------------
-- MAP UTILITIES (CTRL+TP)
--------------------------------------------------------------------------------

local ctrlTpConn = nil
local function toggleCtrlTP(state)
    Config.CtrlTP = state
    if ctrlTpConn then ctrlTpConn:Disconnect() ctrlTpConn = nil end
    if state then
        local mouse = LocalPlayer:GetMouse()
        ctrlTpConn = mouse.Button1Down:Connect(function()
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and mouse.Target then
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then char:MoveTo(mouse.Hit.p) end
            end
        end)
    end
end

local bangLoop = nil
local bangAnimTrack = nil
local carpetLoop = nil

local function stopBang()
    if bangLoop then bangLoop:Disconnect() bangLoop = nil end
    if bangAnimTrack then pcall(function() bangAnimTrack:Stop() bangAnimTrack:Destroy() end) bangAnimTrack = nil end
end

local function startBang(targetPlr)
    stopBang()
    if not targetPlr or not targetPlr.Character then return end
    local myChar = LocalPlayer.Character
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    local myRoot = getRoot(myChar)
    if not myHum or not myRoot then return end

    local anim = Instance.new("Animation")
    anim.AnimationId = (myHum.RigType == Enum.HumanoidRigType.R15) and "rbxassetid://5918726674" or "rbxassetid://148840371"
    
    pcall(function()
        bangAnimTrack = myHum:LoadAnimation(anim)
        bangAnimTrack:Play()
        bangAnimTrack:AdjustSpeed(Config.BangSpeed)
    end)

    bangLoop = RunService.RenderStepped:Connect(function()
        local tChar = targetPlr.Character
        local tRoot = getRoot(tChar)
        local cHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        myRoot = getRoot(myChar)

        if not tRoot or not myRoot or not cHum or cHum.Health <= 0 then
            stopBang()
            return
        end
        myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 1.1)
    end)
end

local function stopCarpet()
    if carpetLoop then carpetLoop:Disconnect() carpetLoop = nil end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
end

local function startCarpet(targetPlr)
    stopCarpet()
    if not targetPlr or not targetPlr.Character then return end

    carpetLoop = RunService.RenderStepped:Connect(function()
        local myChar = LocalPlayer.Character
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        local myRoot = getRoot(myChar)
        local tChar = targetPlr.Character
        local tRoot = getRoot(tChar)

        if not tRoot or not myRoot or not myHum or myHum.Health <= 0 then
            stopCarpet()
            return
        end

        myHum.PlatformStand = true
        myRoot.CFrame = tRoot.CFrame * CFrame.new(0, -3.2, 0) * CFrame.Angles(math.rad(90), 0, 0)
    end)
end

--------------------------------------------------------------------------------
-- INFINITE YIELD TOOLS SUITE (EVERY TOOL WITH ON/OFF TOGGLE)
--------------------------------------------------------------------------------

local IY = {
    Connections = {},
    SpawnedBTools = {},
    TeleportTool = nil,
    DeleteTool = nil,
    ExplodeTool = nil,
    GrabToolsConn = nil,
    ClickTpConn = nil,
    ClickDelConn = nil,
    ClickFlingConn = nil,
    ToolAuraThread = nil,
    ToolSpamThread = nil,
    HandleKillThread = nil,
    OriginalToolSizes = {},
    OriginalToolGrips = {},
    ReachBoxes = {},
    CopiedTools = {},
    SpinConn = nil,
    FloatPart = nil,
    FloatConn = nil,
    AirwalkPart = nil,
    AirwalkConn = nil,
    JesusPlatform = nil,
    OrigLighting = nil,
    FullbrightConn = nil,
    XRayModifiedParts = {},
    AntiVoidConn = nil,
    AntiSitConn = nil,
    OrigGravity = 196.2,
}

-- 1. Teleport Tool
function IY.toggleTeleportTool(state)
    Config.IY_TPTool = state
    if state then
        if not IY.TeleportTool or not IY.TeleportTool.Parent then
            local tpTool = Instance.new("Tool")
            tpTool.Name = "Teleport Tool"
            tpTool.RequiresHandle = false
            tpTool.CanBeDropped = false
            
            local activatedConn = tpTool.Activated:Connect(function()
                local char = LocalPlayer.Character
                local root = getRoot(char)
                local mouse = LocalPlayer:GetMouse()
                if root and mouse and mouse.Hit then
                    local targetPos = mouse.Hit.Position + Vector3.new(0, 3, 0)
                    root.CFrame = CFrame.new(targetPos, targetPos + root.CFrame.LookVector)
                    breakVelocity()
                end
            end)
            table.insert(IY.Connections, activatedConn)
            
            local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
            if backpack then tpTool.Parent = backpack end
            IY.TeleportTool = tpTool
            if Window and Window.Notify then
                Window:Notify({ Title = "Teleport Tool", Description = "Teleport tool added to inventory.", Lifetime = 2 })
            end
        end
    else
        if IY.TeleportTool then
            pcall(function() IY.TeleportTool:Destroy() end)
            IY.TeleportTool = nil
        end
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        if backpack then
            for _, t in ipairs(backpack:GetChildren()) do
                if t:IsA("Tool") and t.Name == "Teleport Tool" then pcall(function() t:Destroy() end) end
            end
        end
        local char = LocalPlayer.Character
        if char then
            for _, t in ipairs(char:GetChildren()) do
                if t:IsA("Tool") and t.Name == "Teleport Tool" then pcall(function() t:Destroy() end) end
            end
        end
    end
end

-- 2. Classic BTools (HopperBins)
function IY.toggleBTools(state)
    Config.IY_BTools = state
    if state then
        local backpack = LocalPlayer:FindFirstChildWhichIsA("Backpack")
        if backpack then
            local names = { "GameTool (Hammer)", "CloneTool", "DeleteTool", "GrabTool" }
            for i = 1, 4 do
                local bin = Instance.new("HopperBin")
                bin.BinType = i
                bin.Name = names[i] or ("BTool_" .. i)
                bin.Parent = backpack
                table.insert(IY.SpawnedBTools, bin)
            end
            if Window and Window.Notify then
                Window:Notify({ Title = "Classic BTools", Description = "Spawned 4 HopperBins in backpack.", Lifetime = 2 })
            end
        end
    else
        for _, bin in ipairs(IY.SpawnedBTools) do
            pcall(function() bin:Destroy() end)
        end
        table.clear(IY.SpawnedBTools)
        local backpack = LocalPlayer:FindFirstChildWhichIsA("Backpack")
        if backpack then
            for _, c in ipairs(backpack:GetChildren()) do
                if c:IsA("HopperBin") then pcall(function() c:Destroy() end) end
            end
        end
        local char = LocalPlayer.Character
        if char then
            for _, c in ipairs(char:GetChildren()) do
                if c:IsA("HopperBin") then pcall(function() c:Destroy() end) end
            end
        end
    end
end

-- 3. F3X Building Tool
function IY.toggleF3X(state)
    Config.IY_F3X = state
    if state then
        safeSpawn(function()
            pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/refs/heads/main/f3x.lua"))()
                if Window and Window.Notify then
                    Window:Notify({ Title = "F3X Building Tool", Description = "Loaded F3X building tool.", Lifetime = 2 })
                end
            end)
        end)
    else
        local backpack = LocalPlayer:FindFirstChildWhichIsA("Backpack")
        if backpack then
            for _, t in ipairs(backpack:GetChildren()) do
                if t.Name:lower():find("f3x") or t.Name:lower():find("building tools") then
                    pcall(function() t:Destroy() end)
                end
            end
        end
        local char = LocalPlayer.Character
        if char then
            for _, t in ipairs(char:GetChildren()) do
                if t.Name:lower():find("f3x") or t.Name:lower():find("building tools") then
                    pcall(function() t:Destroy() end)
                end
            end
        end
    end
end

-- 4. Auto Grab Dropped Tools
function IY.toggleGrabTools(state)
    Config.IY_GrabTools = state
    if IY.GrabToolsConn then
        IY.GrabToolsConn:Disconnect()
        IY.GrabToolsConn = nil
    end
    if state then
        local function equipDropped(item)
            if item:IsA("BackpackItem") and item:FindFirstChild("Handle") then
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildWhichIsA("Humanoid")
                if hum then
                    pcall(function() hum:EquipTool(item) end)
                end
            end
        end
        for _, child in ipairs(workspace:GetChildren()) do
            equipDropped(child)
        end
        IY.GrabToolsConn = workspace.ChildAdded:Connect(function(child)
            task.wait(0.05)
            equipDropped(child)
        end)
        table.insert(IY.Connections, IY.GrabToolsConn)
        if Window and Window.Notify then
            Window:Notify({ Title = "Auto Grab Tools", Description = "Auto-collecting dropped tools.", Lifetime = 2 })
        end
    end
end

-- 5. Copy Game Tools (ReplicatedStorage & Lighting)
function IY.toggleCopyGameTools(state)
    Config.IY_CopyTools = state
    if state then
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        if not backpack then return end
        local count = 0
        local function scanAndCopy(container)
            if not container then return end
            for _, c in ipairs(container:GetDescendants()) do
                if c:IsA("Tool") or c:IsA("HopperBin") then
                    pcall(function()
                        local cl = c:Clone()
                        cl.Parent = backpack
                        table.insert(IY.CopiedTools, cl)
                        count = count + 1
                    end)
                end
            end
        end
        scanAndCopy(game:GetService("ReplicatedStorage"))
        scanAndCopy(game:GetService("Lighting"))
        if Window and Window.Notify then
            Window:Notify({ Title = "Tools Copied", Description = "Cloned " .. tostring(count) .. " tools to backpack.", Lifetime = 2 })
        end
    else
        for _, t in ipairs(IY.CopiedTools) do
            pcall(function() t:Destroy() end)
        end
        table.clear(IY.CopiedTools)
    end
end

-- 6. Force Droppable Tools
function IY.toggleDroppableTools(state)
    local wasActive = Config.IY_DroppableTools
    Config.IY_DroppableTools = state
    if not state and not wasActive then return end
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    local char = LocalPlayer.Character
    local all = {}
    if backpack then for _, t in ipairs(backpack:GetChildren()) do if t:IsA("Tool") then table.insert(all, t) end end end
    if char then for _, t in ipairs(char:GetChildren()) do if t:IsA("Tool") then table.insert(all, t) end end end
    for _, t in ipairs(all) do
        pcall(function() t.CanBeDropped = state end)
    end
    if Window and Window.Notify then
        Window:Notify({ Title = "Droppable Tools", Description = state and "All inventory tools made droppable." or "Tool droppable setting restored.", Lifetime = 2 })
    end
end

-- 7. Multi-Equip All Tools
function IY.toggleEquipAllTools(state)
    local wasActive = Config.IY_EquipAll
    Config.IY_EquipAll = state
    if not state and not wasActive then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if state then
        if backpack and char then
            for _, t in ipairs(backpack:GetChildren()) do
                if t:IsA("Tool") or t:IsA("HopperBin") then
                    pcall(function() t.Parent = char end)
                end
            end
        end
        if Window and Window.Notify then
            Window:Notify({ Title = "Equip All", Description = "Equipped all tools from backpack.", Lifetime = 2 })
        end
    else
        if hum then
            pcall(function() hum:UnequipTools() end)
        end
    end
end

-- 8. Auto Tool Spam / Continuous Use Loop
function IY.toggleUseTools(state)
    Config.IY_UseTools = state
    if state then
        if IY.ToolSpamThread then task.cancel(IY.ToolSpamThread) end
        IY.ToolSpamThread = safeSpawn(function()
            while Config.IY_UseTools and isSuiteActive do
                pcall(function()
                    local char = LocalPlayer.Character
                    if char then
                        for _, t in ipairs(char:GetChildren()) do
                            if t:IsA("Tool") then t:Activate() end
                        end
                    end
                    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
                    if backpack then
                        for _, t in ipairs(backpack:GetChildren()) do
                            if t:IsA("Tool") then t:Activate() end
                        end
                    end
                end)
                task.wait(0.05)
            end
        end)
    else
        if IY.ToolSpamThread then
            pcall(function() task.cancel(IY.ToolSpamThread) end)
            IY.ToolSpamThread = nil
        end
    end
end

-- 9. Click Teleport (Click TP)
function IY.toggleClickTP(state)
    Config.IY_ClickTP = state
    if IY.ClickTpConn then IY.ClickTpConn:Disconnect() IY.ClickTpConn = nil end
    if state then
        local mouse = LocalPlayer:GetMouse()
        IY.ClickTpConn = mouse.Button1Down:Connect(function()
            if not Config.IY_ClickTP then return end
            if UserInputService:GetFocusedTextBox() ~= nil then return end
            local char = LocalPlayer.Character
            local root = getRoot(char)
            if root and mouse and mouse.Hit then
                local targetPos = mouse.Hit.Position + Vector3.new(0, 3, 0)
                root.CFrame = CFrame.new(targetPos, targetPos + root.CFrame.LookVector)
                breakVelocity()
            end
        end)
        table.insert(IY.Connections, IY.ClickTpConn)
        if Window and Window.Notify then
            Window:Notify({ Title = "Click TP", Description = "Left-click anywhere to teleport.", Lifetime = 2 })
        end
    end
end

-- 10. Click Delete (Click Del) - Safe Mode
function IY.toggleClickDelete(state)
    Config.IY_ClickDelete = state
    if IY.ClickDelConn then IY.ClickDelConn:Disconnect() IY.ClickDelConn = nil end
    if state then
        local mouse = LocalPlayer:GetMouse()
        IY.ClickDelConn = mouse.Button1Down:Connect(function()
            if not Config.IY_ClickDelete then return end
            if UserInputService:GetFocusedTextBox() ~= nil then return end
            -- Guard: Ignore if automated clicker is firing
            if Config.ClickerEnabled and not Config.HoldToClick then return end
            -- Guard: Require holding LeftControl or RightControl to prevent accidental deletion
            local ctrlHeld = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
            if not ctrlHeld then return end
            if mouse and mouse.Target and mouse.Target.Parent then
                local obj = mouse.Target
                if not obj:IsDescendantOf(LocalPlayer.Character) and obj ~= Workspace.Terrain then
                    local char = LocalPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    -- Guard: Never delete the block right beneath our own feet
                    if root and (obj.Position - root.Position).Magnitude < 4.5 and obj.Position.Y < root.Position.Y then
                        return
                    end
                    pcall(function() obj:Destroy() end)
                end
            end
        end)
        table.insert(IY.Connections, IY.ClickDelConn)
        if Window and Window.Notify then
            Window:Notify({ Title = "Click Delete Active", Description = "Hold CTRL + Click any object to delete it safely.", Lifetime = 3 })
        end
    end
end

-- 11. Tool Reach Expander
function IY.toggleToolReach(state)
    Config.IY_ToolReach = state
    local char = LocalPlayer.Character
    if not char then return end
    if state then
        local reachDist = tonumber(Config.IY_ToolReachSize) or 30
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") and t:FindFirstChild("Handle") then
                local h = t.Handle
                if not IY.OriginalToolSizes[h] then IY.OriginalToolSizes[h] = h.Size end
                if not IY.OriginalToolGrips[t] then IY.OriginalToolGrips[t] = t.GripPos end
                h.Massless = true
                h.Size = Vector3.new(0.5, 0.5, reachDist)
                t.GripPos = Vector3.new(0, 0, 0)
                
                if not IY.ReachBoxes[h] then
                    local sBox = Instance.new("SelectionBox")
                    sBox.Name = "IY_ReachBox"
                    sBox.Adornee = h
                    sBox.Color3 = Color3.fromRGB(0, 215, 255)
                    sBox.Parent = h
                    IY.ReachBoxes[h] = sBox
                end
            end
        end
        if Window and Window.Notify then
            Window:Notify({ Title = "Tool Reach", Description = "Extended held tool reach to " .. tostring(Config.IY_ToolReachSize or 30), Lifetime = 2 })
        end
    else
        for h, origSize in pairs(IY.OriginalToolSizes) do
            if h and h.Parent then pcall(function() h.Size = origSize end) end
        end
        for t, origGrip in pairs(IY.OriginalToolGrips) do
            if t and t.Parent then pcall(function() t.GripPos = origGrip end) end
        end
        for _, box in pairs(IY.ReachBoxes) do
            pcall(function() box:Destroy() end)
        end
        table.clear(IY.OriginalToolSizes)
        table.clear(IY.OriginalToolGrips)
        table.clear(IY.ReachBoxes)
    end
end

-- 12. 3D Box Reach
function IY.toggleBoxReach(state)
    Config.IY_BoxReach = state
    local char = LocalPlayer.Character
    if not char then return end
    if state then
        local bSize = tonumber(Config.IY_BoxReachSize) or 30
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") and t:FindFirstChild("Handle") then
                local h = t.Handle
                if not IY.OriginalToolSizes[h] then IY.OriginalToolSizes[h] = h.Size end
                if not IY.OriginalToolGrips[t] then IY.OriginalToolGrips[t] = t.GripPos end
                h.Massless = true
                h.Size = Vector3.new(bSize, bSize, bSize)
                t.GripPos = Vector3.new(0, 0, 0)
                
                if not IY.ReachBoxes[h] then
                    local sBox = Instance.new("SelectionBox")
                    sBox.Name = "IY_ReachBox"
                    sBox.Adornee = h
                    sBox.Color3 = Color3.fromRGB(255, 100, 0)
                    sBox.Parent = h
                    IY.ReachBoxes[h] = sBox
                end
            end
        end
        if Window and Window.Notify then
            Window:Notify({ Title = "3D Box Reach", Description = "Set held tool 3D cube reach to " .. tostring(Config.IY_BoxReachSize or 30), Lifetime = 2 })
        end
    else
        IY.toggleToolReach(false)
    end
end

-- 13. Handle Touch Kill
function IY.toggleHandleKill(state)
    Config.IY_HandleKill = state
    if state then
        if not IY.HandleKillThread then
            IY.HandleKillThread = safeSpawn(function()
                while Config.IY_HandleKill and isSuiteActive do
                    local char = LocalPlayer.Character
                    local tool = char and char:FindFirstChildWhichIsA("Tool")
                    local handle = tool and tool:FindFirstChild("Handle")
                    if handle and type(firetouchinterest) == "function" then
                        for _, plr in ipairs(Players:GetPlayers()) do
                            if plr ~= LocalPlayer and plr.Character and not isExcluded(plr) then
                                local targetRoot = getRoot(plr.Character)
                                local targetHum = plr.Character:FindFirstChildWhichIsA("Humanoid")
                                if targetRoot and targetHum and targetHum.Health > 0 then
                                    pcall(function()
                                        firetouchinterest(handle, targetRoot, 1)
                                        firetouchinterest(handle, targetRoot, 0)
                                    end)
                                end
                            end
                        end
                    end
                    task.wait(0.1)
                end
                IY.HandleKillThread = nil
            end)
            if Window and Window.Notify then
                Window:Notify({ Title = "Handle Kill", Description = "Auto-damaging enemies with held tool handle.", Lifetime = 2 })
            end
        end
    else
        Config.IY_HandleKill = false
        IY.HandleKillThread = nil
    end
end

-- 15. Blockify Tool Mesh
function IY.toggleBlockTool(state)
    Config.IY_BlockTool = state
    if state then
        local char = LocalPlayer.Character
        if char then
            for _, v in ipairs(char:GetChildren()) do
                if v:IsA("Tool") or v:IsA("HopperBin") then
                    for _, c in ipairs(v:GetDescendants()) do
                        if c:IsA("SpecialMesh") then pcall(function() c:Destroy() end) end
                    end
                end
            end
        end
        if Window and Window.Notify then
            Window:Notify({ Title = "Block Tool", Description = "Removed SpecialMesh from held tools.", Lifetime = 2 })
        end
    end
end

-- 16. Duplicate Tools
function IY.toggleDuplicateTools(state)
    Config.IY_DuplicateTools = state
    if state then
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        if backpack then
            local tools = {}
            for _, t in ipairs(backpack:GetChildren()) do
                if t:IsA("Tool") or t:IsA("HopperBin") then table.insert(tools, t) end
            end
            for _, t in ipairs(tools) do
                pcall(function()
                    local cl = t:Clone()
                    cl.Parent = backpack
                end)
            end
            if Window and Window.Notify then
                Window:Notify({ Title = "Duplicate Tools", Description = "Duplicated " .. tostring(#tools) .. " tool(s) in backpack.", Lifetime = 2 })
            end
        end
    end
end

-- 17. Clear All Tools
function IY.toggleClearTools(state)
    Config.IY_ClearTools = state
    if state then
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        if backpack then
            for _, v in ipairs(backpack:GetDescendants()) do
                if v:IsA("Tool") or v:IsA("HopperBin") then pcall(function() v:Destroy() end) end
            end
        end
        local char = LocalPlayer.Character
        if char then
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("Tool") or v:IsA("HopperBin") then pcall(function() v:Destroy() end) end
            end
        end
        if Window and Window.Notify then
            Window:Notify({ Title = "Purge Tools", Description = "Removed all tools from backpack and character.", Lifetime = 2 })
        end
        task.delay(0.2, function()
            Config.IY_ClearTools = false
        end)
    end
end

-- 18. Bring All Dropped Tools
function IY.bringAllTools()
    local char = LocalPlayer.Character
    local root = getRoot(char)
    if not root then return end
    local count = 0
    for _, item in ipairs(workspace:GetDescendants()) do
        if item:IsA("Tool") or item:IsA("BackpackItem") then
            local handle = item:FindFirstChild("Handle")
            local player = Players:GetPlayerFromCharacter(item.Parent)
            if handle and not player then
                pcall(function()
                    handle.CFrame = root.CFrame
                    count = count + 1
                end)
            end
        end
    end
    if Window and Window.Notify then
        Window:Notify({ Title = "Bring Tools", Description = "Brought " .. tostring(count) .. " dropped tool(s).", Lifetime = 2 })
    end
end

-- 19. Equippable Delete Tool
function IY.toggleSpawnDeleteTool(state)
    Config.IY_SpawnDeleteTool = state
    if state then
        if not IY.DeleteTool or not IY.DeleteTool.Parent then
            local dTool = Instance.new("Tool")
            dTool.Name = "Delete Tool"
            dTool.RequiresHandle = false
            dTool.CanBeDropped = false
            local delConn = dTool.Activated:Connect(function()
                local mouse = LocalPlayer:GetMouse()
                if mouse and mouse.Target and not mouse.Target:IsDescendantOf(LocalPlayer.Character) then
                    pcall(function() mouse.Target:Destroy() end)
                end
            end)
            table.insert(IY.Connections, delConn)
            local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
            if backpack then dTool.Parent = backpack end
            IY.DeleteTool = dTool
            if Window and Window.Notify then
                Window:Notify({ Title = "Delete Tool", Description = "Equip and click any block to destroy it.", Lifetime = 2 })
            end
        end
    else
        if IY.DeleteTool then
            pcall(function() IY.DeleteTool:Destroy() end)
            IY.DeleteTool = nil
        end
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        if backpack then
            for _, t in ipairs(backpack:GetChildren()) do
                if t.Name == "Delete Tool" then pcall(function() t:Destroy() end) end
            end
        end
    end
end

-- 20. Equippable Explode Tool
function IY.toggleSpawnExplodeTool(state)
    Config.IY_SpawnExplodeTool = state
    if state then
        if not IY.ExplodeTool or not IY.ExplodeTool.Parent then
            local eTool = Instance.new("Tool")
            eTool.Name = "Explode Tool"
            eTool.RequiresHandle = false
            eTool.CanBeDropped = false
            local expConn = eTool.Activated:Connect(function()
                local mouse = LocalPlayer:GetMouse()
                if mouse and mouse.Hit then
                    pcall(function()
                        local exp = Instance.new("Explosion")
                        exp.Position = mouse.Hit.Position
                        exp.BlastRadius = 15
                        exp.BlastPressure = 500000
                        exp.Parent = workspace
                    end)
                end
            end)
            table.insert(IY.Connections, expConn)
            local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
            if backpack then eTool.Parent = backpack end
            IY.ExplodeTool = eTool
            if Window and Window.Notify then
                Window:Notify({ Title = "Explode Tool", Description = "Equip and click anywhere to detonate.", Lifetime = 2 })
            end
        end
    else
        if IY.ExplodeTool then
            pcall(function() IY.ExplodeTool:Destroy() end)
            IY.ExplodeTool = nil
        end
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        if backpack then
            for _, t in ipairs(backpack:GetChildren()) do
                if t.Name == "Explode Tool" then pcall(function() t:Destroy() end) end
            end
        end
    end
end

-- 21. Click Fling Player
function IY.toggleClickFling(state)
    Config.IY_ClickFling = state
    if IY.ClickFlingConn then IY.ClickFlingConn:Disconnect() IY.ClickFlingConn = nil end
    if state then
        local mouse = LocalPlayer:GetMouse()
        IY.ClickFlingConn = mouse.Button1Down:Connect(function()
            if not Config.IY_ClickFling then return end
            if UserInputService:GetFocusedTextBox() ~= nil then return end
            if mouse and mouse.Target then
                local targetModel = mouse.Target:FindFirstAncestorOfClass("Model")
                local targetPlr = targetModel and Players:GetPlayerFromCharacter(targetModel)
                if targetPlr and targetPlr ~= LocalPlayer and targetPlr.Character then
                    local targetRoot = getRoot(targetPlr.Character)
                    local myRoot = getRoot(LocalPlayer.Character)
                    if targetRoot and myRoot then
                        local prevCF = myRoot.CFrame
                        setFling(true)
                        task.spawn(function()
                            local t = tick()
                            while tick() - t < 0.6 do
                                if targetRoot and targetRoot.Parent then
                                    myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 0)
                                end
                                task.wait()
                            end
                            setFling(false)
                            myRoot.CFrame = prevCF
                            breakVelocity()
                        end)
                        if Window and Window.Notify then
                            Window:Notify({ Title = "Click Fling", Description = "Flung " .. targetPlr.DisplayName, Lifetime = 2 })
                        end
                    end
                end
            end
        end)
        table.insert(IY.Connections, IY.ClickFlingConn)
    end
end

-- 22. Tool Kill Aura
function IY.toggleToolAura(state)
    Config.IY_ToolAura = state
    if state then
        if IY.ToolAuraThread then task.cancel(IY.ToolAuraThread) end
        IY.ToolAuraThread = safeSpawn(function()
            while Config.IY_ToolAura and isSuiteActive do
                pcall(function()
                    local char = LocalPlayer.Character
                    local root = getRoot(char)
                    local tool = char and char:FindFirstChildOfClass("Tool")
                    if not tool then
                        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
                        if backpack then
                            for _, t in ipairs(backpack:GetChildren()) do
                                if t:IsA("Tool") and (t.Name:lower():find("sword") or t.Name:lower():find("axe")) then
                                    t.Parent = char
                                    tool = t
                                    break
                                end
                            end
                        end
                    end
                    if root and tool then
                        local handle = tool:FindFirstChild("Handle")
                        local auraRange = tonumber(Config.IY_ToolAuraRange) or 25
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and not isExcluded(p) and p.Character then
                                local tRoot = getRoot(p.Character)
                                local tHum = p.Character:FindFirstChildOfClass("Humanoid")
                                if tRoot and tHum and tHum.Health > 0 then
                                    local dist = (tRoot.Position - root.Position).Magnitude
                                    if dist <= auraRange then
                                        tool:Activate()
                                        if handle and type(firetouchinterest) == "function" then
                                            firetouchinterest(handle, tRoot, 0)
                                            firetouchinterest(handle, tRoot, 1)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
                task.wait(0.08)
            end
        end)
    else
        if IY.ToolAuraThread then
            pcall(function() task.cancel(IY.ToolAuraThread) end)
            IY.ToolAuraThread = nil
        end
    end
end

-- 23. Spinbot / Character Spin
function IY.toggleSpin(state)
    Config.IY_Spin = state
    if IY.SpinConn then IY.SpinConn:Disconnect() IY.SpinConn = nil end
    if state then
        IY.SpinConn = RunService.RenderStepped:Connect(function(dt)
            if not Config.IY_Spin then return end
            local char = LocalPlayer.Character
            local root = getRoot(char)
            if root then
                local speed = tonumber(Config.IY_SpinSpeed) or 30
                root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(speed * 30 * dt), 0)
            end
        end)
        table.insert(IY.Connections, IY.SpinConn)
    end
end

-- 24. Floating Platform (Float)
function IY.toggleFloat(state)
    Config.IY_Float = state
    if IY.FloatConn then IY.FloatConn:Disconnect() IY.FloatConn = nil end
    if IY.FloatPart then pcall(function() IY.FloatPart:Destroy() end) IY.FloatPart = nil end
    if state then
        local char = LocalPlayer.Character
        local root = getRoot(char)
        if root then
            IY.FloatPart = Instance.new("Part")
            IY.FloatPart.Name = "IY_FloatPlatform"
            IY.FloatPart.Size = Vector3.new(6, 1, 6)
            IY.FloatPart.Transparency = 0.8
            IY.FloatPart.Anchored = true
            IY.FloatPart.CanCollide = true
            IY.FloatPart.Color = Color3.fromRGB(225, 38, 38)
            IY.FloatPart.Position = root.Position - Vector3.new(0, 3.5, 0)
            IY.FloatPart.Parent = workspace
            
            IY.FloatConn = RunService.Heartbeat:Connect(function()
                local c = LocalPlayer.Character
                local r = getRoot(c)
                if r and IY.FloatPart and IY.FloatPart.Parent then
                    IY.FloatPart.Position = Vector3.new(r.Position.X, IY.FloatPart.Position.Y, r.Position.Z)
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                        IY.FloatPart.Position = IY.FloatPart.Position + Vector3.new(0, 0.4, 0)
                    elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                        IY.FloatPart.Position = IY.FloatPart.Position - Vector3.new(0, 0.4, 0)
                    end
                end
            end)
            table.insert(IY.Connections, IY.FloatConn)
        end
    end
end

-- 25. Airwalk
function IY.toggleAirwalk(state)
    Config.IY_Airwalk = state
    if IY.AirwalkConn then IY.AirwalkConn:Disconnect() IY.AirwalkConn = nil end
    if IY.AirwalkPart then pcall(function() IY.AirwalkPart:Destroy() end) IY.AirwalkPart = nil end
    if state then
        local char = LocalPlayer.Character
        local root = getRoot(char)
        if root then
            IY.AirwalkPart = Instance.new("Part")
            IY.AirwalkPart.Name = "IY_AirwalkPart"
            IY.AirwalkPart.Size = Vector3.new(4, 0.8, 4)
            IY.AirwalkPart.Transparency = 1
            IY.AirwalkPart.Anchored = true
            IY.AirwalkPart.CanCollide = true
            IY.AirwalkPart.Parent = workspace
            
            IY.AirwalkConn = RunService.Heartbeat:Connect(function()
                local c = LocalPlayer.Character
                local r = getRoot(c)
                if r and IY.AirwalkPart and IY.AirwalkPart.Parent then
                    IY.AirwalkPart.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.2, r.Position.Z)
                end
            end)
            table.insert(IY.Connections, IY.AirwalkConn)
        end
    end
end

-- 26. Jesus / Water Walk
function IY.toggleJesus(state)
    Config.IY_Jesus = state
    if IY.JesusPlatform then pcall(function() IY.JesusPlatform:Destroy() end) IY.JesusPlatform = nil end
    if state then
        IY.JesusPlatform = Instance.new("Part")
        IY.JesusPlatform.Name = "IY_JesusPlatform"
        IY.JesusPlatform.Size = Vector3.new(4000, 2, 4000)
        IY.JesusPlatform.Position = Vector3.new(0, 14, 0)
        IY.JesusPlatform.Transparency = 0.95
        IY.JesusPlatform.Anchored = true
        IY.JesusPlatform.CanCollide = true
        IY.JesusPlatform.Color = Color3.fromRGB(0, 170, 255)
        IY.JesusPlatform.Parent = workspace
        if Window and Window.Notify then
            Window:Notify({ Title = "Jesus Mode", Description = "Water walk barrier created.", Lifetime = 2 })
        end
    end
end

-- 27. Fullbright
function IY.toggleFullbright(state)
    Config.IY_Fullbright = state
    if IY.FullbrightConn then IY.FullbrightConn:Disconnect() IY.FullbrightConn = nil end
    if state then
        if not IY.OrigLighting then
            IY.OrigLighting = {
                Ambient = Lighting.Ambient,
                Brightness = Lighting.Brightness,
                ClockTime = Lighting.ClockTime,
                GlobalShadows = Lighting.GlobalShadows,
                FogEnd = Lighting.FogEnd
            }
        end
        IY.FullbrightConn = RunService.Heartbeat:Connect(function()
            if not Config.IY_Fullbright then return end
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 1e6
        end)
        table.insert(IY.Connections, IY.FullbrightConn)
    else
        if IY.OrigLighting then
            Lighting.Ambient = IY.OrigLighting.Ambient
            Lighting.Brightness = IY.OrigLighting.Brightness
            Lighting.ClockTime = IY.OrigLighting.ClockTime
            Lighting.GlobalShadows = IY.OrigLighting.GlobalShadows
            Lighting.FogEnd = IY.OrigLighting.FogEnd
        end
    end
end

-- 28. X-Ray Vision
function IY.toggleXRay(state)
    Config.IY_XRay = state
    if state then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsDescendantOf(LocalPlayer.Character) and not (obj.Parent and obj.Parent:FindFirstChildOfClass("Humanoid")) then
                if obj.Transparency < 0.5 then
                    IY.XRayModifiedParts[obj] = obj.Transparency
                    obj.Transparency = 0.55
                end
            end
        end
        if Window and Window.Notify then
            Window:Notify({ Title = "X-Ray Vision", Description = "World blocks made translucent.", Lifetime = 2 })
        end
    else
        for obj, origT in pairs(IY.XRayModifiedParts) do
            if obj and obj.Parent then pcall(function() obj.Transparency = origT end) end
        end
        table.clear(IY.XRayModifiedParts)
    end
end

-- 29. Anti-Void Safety
function IY.toggleAntiVoid(state)
    Config.IY_AntiVoid = state
    if IY.AntiVoidConn then IY.AntiVoidConn:Disconnect() IY.AntiVoidConn = nil end
    if state then
        IY.AntiVoidConn = RunService.Heartbeat:Connect(function()
            if not Config.IY_AntiVoid then return end
            local char = LocalPlayer.Character
            local root = getRoot(char)
            if root and root.Position.Y < 5 then
                breakVelocity()
                root.CFrame = CFrame.new(root.Position.X, 150, root.Position.Z)
                breakVelocity()
                if Window and Window.Notify then
                    Window:Notify({ Title = "Anti-Void", Description = "Rescued from void fall!", Lifetime = 1.5 })
                end
            end
        end)
        table.insert(IY.Connections, IY.AntiVoidConn)
    end
end

-- 30. Anti-Sit
function IY.toggleAntiSit(state)
    Config.IY_AntiSit = state
    if IY.AntiSitConn then IY.AntiSitConn:Disconnect() IY.AntiSitConn = nil end
    if state then
        local function hookHum(hum)
            if not hum then return end
            hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
            hum.Sit = false
        end
        if LocalPlayer.Character then
            hookHum(LocalPlayer.Character:FindFirstChildOfClass("Humanoid"))
        end
        IY.AntiSitConn = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Sit then
                hum.Sit = false
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end)
        table.insert(IY.Connections, IY.AntiSitConn)
    else
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end)
        end
    end
end

-- 31. Low Gravity
function IY.toggleLowGravity(state)
    Config.IY_LowGravity = state
    if state then
        IY.OrigGravity = workspace.Gravity
        workspace.Gravity = tonumber(Config.IY_GravityValue) or 45
        if Window and Window.Notify then
            Window:Notify({ Title = "Low Gravity", Description = "Gravity set to " .. tostring(workspace.Gravity), Lifetime = 2 })
        end
    else
        workspace.Gravity = IY.OrigGravity or 196.2
    end
end

-- 32. Cinematic Freecam (Spectator TP)
local freecamCFrame = nil
local freecamRotX = 0
local freecamRotY = 0
local freecamCharAnchored = false
local freecamConn = nil
local freecamInputConn = nil
local freecamInputEndConn = nil

local freecamNav = {
    Forward = 0,
    Backward = 0,
    Left = 0,
    Right = 0,
    Up = 0,
    Down = 0
}

function IY.teleportToFreecam()
    local char = LocalPlayer.Character
    local root = getRoot(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if freecamCFrame and root and hum and hum.Health > 0 then
        local targetPos = freecamCFrame.Position
        breakVelocity()
        root.CFrame = CFrame.new(targetPos)
        breakVelocity()
        playSound("rbxassetid://9069609268", 0.6)
        if Window and Window.Notify then
            Window:Notify({
                Title = "Spectate Teleport",
                Description = "Teleported character to spectated position!",
                Lifetime = 2.5
            })
        end
    end
end

function IY.toggleFreecam(state)
    Config.IY_Freecam = state
    if freecamConn then
        freecamConn:Disconnect()
        freecamConn = nil
    end
    if freecamInputConn then
        freecamInputConn:Disconnect()
        freecamInputConn = nil
    end
    if freecamInputEndConn then
        freecamInputEndConn:Disconnect()
        freecamInputEndConn = nil
    end

    local char = LocalPlayer.Character
    local root = getRoot(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if state then
        if not root or not hum or hum.Health <= 0 then
            Config.IY_Freecam = false
            return
        end

        freecamCFrame = Camera.CFrame
        local rx, ry, _ = freecamCFrame:ToOrientation()
        freecamRotX = rx
        freecamRotY = ry

        pcall(function()
            if root and not root.Anchored then
                root.Anchored = true
                freecamCharAnchored = true
            end
        end)

        pcall(function()
            Camera.CameraType = Enum.CameraType.Scriptable
        end)

        freecamNav.Forward = 0
        freecamNav.Backward = 0
        freecamNav.Left = 0
        freecamNav.Right = 0
        freecamNav.Up = 0
        freecamNav.Down = 0

        freecamInputConn = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe or UserInputService:GetFocusedTextBox() ~= nil then return end
            if input.KeyCode == Enum.KeyCode.W then freecamNav.Forward = 1
            elseif input.KeyCode == Enum.KeyCode.S then freecamNav.Backward = 1
            elseif input.KeyCode == Enum.KeyCode.A then freecamNav.Left = 1
            elseif input.KeyCode == Enum.KeyCode.D then freecamNav.Right = 1
            elseif input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.Space then freecamNav.Up = 1
            elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.LeftShift then freecamNav.Down = 1
            end
        end)
        table.insert(IY.Connections, freecamInputConn)

        freecamInputEndConn = UserInputService.InputEnded:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.W then freecamNav.Forward = 0
            elseif input.KeyCode == Enum.KeyCode.S then freecamNav.Backward = 0
            elseif input.KeyCode == Enum.KeyCode.A then freecamNav.Left = 0
            elseif input.KeyCode == Enum.KeyCode.D then freecamNav.Right = 0
            elseif input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.Space then freecamNav.Up = 0
            elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.LeftShift then freecamNav.Down = 0
            end
        end)
        table.insert(IY.Connections, freecamInputEndConn)

        freecamConn = RunService.RenderStepped:Connect(function(dt)
            if not Config.IY_Freecam then return end

            if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                local delta = UserInputService:GetMouseDelta()
                freecamRotY = freecamRotY - math.rad(delta.X * 0.4)
                freecamRotX = math.clamp(freecamRotX - math.rad(delta.Y * 0.4), -math.rad(89), math.rad(89))
                UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
            else
                if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCurrentPosition then
                    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                end
            end

            local rotation = CFrame.Angles(0, freecamRotY, 0) * CFrame.Angles(freecamRotX, 0, 0)
            local speedMultiplier = tonumber(Config.IY_FreecamSpeed) or 1.5
            local speed = speedMultiplier * 55 * dt

            local moveVector = (rotation.RightVector * (freecamNav.Right - freecamNav.Left))
                             + (Vector3.new(0, 1, 0) * (freecamNav.Up - freecamNav.Down))
                             + (rotation.LookVector * (freecamNav.Forward - freecamNav.Backward))

            if moveVector.Magnitude > 0 then
                moveVector = moveVector.Unit * speed
            end

            freecamCFrame = CFrame.new(freecamCFrame.Position + moveVector) * rotation
            Camera.CFrame = freecamCFrame
        end)
        table.insert(IY.Connections, freecamConn)

        if Window and Window.Notify then
            Window:Notify({
                Title = "Cinematic Freecam",
                Description = "WASD/QE to fly camera. Hold Right Click to look. Toggle off to TP!",
                Lifetime = 3.5
            })
        end
    else
        if freecamCharAnchored and root then
            pcall(function() root.Anchored = false end)
            freecamCharAnchored = false
        end

        if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCurrentPosition then
            pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.Default end)
        end

        if Config.IY_FreecamTP and freecamCFrame and root and hum and hum.Health > 0 then
            IY.teleportToFreecam()
        end

        pcall(function()
            Camera.CameraType = Enum.CameraType.Custom
            if hum then Camera.CameraSubject = hum end
        end)
    end
end

-- Master cleanup for IY tools
function IY.destroyAll()
    IY.toggleFreecam(false)
    IY.toggleTeleportTool(false)
    IY.toggleBTools(false)
    IY.toggleF3X(false)
    IY.toggleGrabTools(false)
    IY.toggleCopyGameTools(false)
    IY.toggleDroppableTools(false)
    IY.toggleEquipAllTools(false)
    IY.toggleUseTools(false)
    IY.toggleClickTP(false)
    IY.toggleClickDelete(false)
    IY.toggleToolReach(false)
    IY.toggleBoxReach(false)
    IY.toggleHandleKill(false)
    IY.toggleBlockTool(false)
    IY.toggleSpawnDeleteTool(false)
    IY.toggleSpawnExplodeTool(false)
    IY.toggleClickFling(false)
    IY.toggleToolAura(false)
    IY.toggleSpin(false)
    IY.toggleFloat(false)
    IY.toggleAirwalk(false)
    IY.toggleJesus(false)
    IY.toggleFullbright(false)
    IY.toggleXRay(false)
    IY.toggleAntiVoid(false)
    IY.toggleAntiSit(false)
    IY.toggleLowGravity(false)
    for _, c in ipairs(IY.Connections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(IY.Connections)
end

--------------------------------------------------------------------------------
-- HANKI BYPASS & CLEANER THREAD
--------------------------------------------------------------------------------

local hankiCleanerThread = nil

local function initHankiBypass()
    if not getgenv().__SkywarsHankiHooked then
        getgenv().__SkywarsHankiHooked = true
        local blacklistSet = { BodyVelocity = true, BodyPosition = true, BodyThrust = true }

        local newindex
        newindex = hookmetamethod(game, '__newindex', function(obj, idx, val)
            if not checkcaller() then
                if (idx == 'JumpPower' or idx == 'JumpHeight') and obj.Name == 'Humanoid' then
                    if Config.JumpEnabled then return end
                end
                if idx == 'WalkSpeed' and obj.Name == 'Humanoid' then
                    if Config.SpeedEnabled then return end
                end
            end
            return newindex(obj, idx, val)
        end)

        local index
        index = hookmetamethod(game, '__index', function(obj, idx)
            if not checkcaller() then
                if idx == 'WalkSpeed' and index(obj, 'Name') == 'Humanoid' then
                    return 16
                elseif idx == 'JumpPower' and index(obj, 'Name') == 'Humanoid' then
                    return 50
                elseif idx == 'JumpHeight' and index(obj, 'Name') == 'Humanoid' then
                    return 7.2
                end
            end
            return index(obj, idx)
        end)

        local namecall
        namecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            local args = {...}

            if not checkcaller() then
                if method == "FireServer" and tostring(self) == "RespawnServer" then
                    return
                elseif method == "IsA" and blacklistSet[args[1]] then
                    return nil
                end
            end

            local scriptObj = getcallingscript()
            if scriptObj and scriptObj.Parent == nil and scriptObj.Name == "LocalScript" then
                return
            end

            return namecall(self, ...)
        end)
    end

    local getskripts = getscripts or getrunningscripts
    local function purge(v)
        if v and not v:IsDescendantOf(LocalPlayer.Character) and (v.Name == "LocalScript" or v.Name == "Appear") then
            pcall(function()
                v.Parent = workspace
                task.wait(0.01)
                v.Disabled = true
                task.wait(0.01)
                v:Destroy()
            end)
        end
    end

    hankiCleanerThread = safeSpawn(function()
        while isSuiteActive do
            task.wait(10)
            pcall(function()
                if LocalPlayer:FindFirstChild("PlayerGui") then
                    for _, v in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do purge(v) end
                end
                if getskripts then
                    for _, v in ipairs(getskripts()) do purge(v) end
                end
            end)
        end
    end)
end

initHankiBypass()

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

safeConnect(UserInputService.JumpRequest, function()
    if not Config.JumpEnabled then return end
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if hum and root and hum.Health > 0 then
            local targetPower = tonumber(Config.JumpPower) or 50
            if targetPower > 50 then
                local vel = root.AssemblyLinearVelocity or root.Velocity
                if vel then
                    local newVel = Vector3.new(vel.X, targetPower, vel.Z)
                    pcall(function() root.AssemblyLinearVelocity = newVel end)
                    pcall(function() root.Velocity = newVel end)
                end
            end
        end
    end)
end)

--------------------------------------------------------------------------------
-- AUTO CLICKER & DETECTION BYPASS
--------------------------------------------------------------------------------

local isMouseDown = false
local clickAccumulator = 0

local function isMatchActive()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if not char or not hrp or not hum or hum.Health <= 0 then return false end
    if IS_SKYWARS and hrp.Position.Y > 145 then return false end
    return true
end

local function getEquippedTool()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Tool")
end

local function resetToolRateLimits(tool)
    pcall(function()
        local currentTool = tool or getEquippedTool()
        if not currentTool then return end
        local tName = string.lower(currentTool.Name)
        local isWeapon = string.find(tName, "sword") or string.find(tName, "pick") or string.find(tName, "axe") or string.find(tName, "bow")
        local isBlock = string.find(tName, "block") or (currentTool:FindFirstChild("RemoteFunction") ~= nil)
        if not isWeapon and not isBlock then return end

        if type(getconnections) == "function" and currentTool:FindFirstChild("Activated") then
            for _, conn in ipairs(getconnections(currentTool.Activated)) do
                if conn.Function then
                    local uvs = debug.getupvalues(conn.Function)
                    for idx, uv in ipairs(uvs) do
                        if type(uv) == "number" and ((isWeapon and uv >= 1) or (isBlock and uv >= 15)) then
                            debug.setupvalue(conn.Function, idx, 0)
                        elseif type(uv) == "function" then
                            local inner = debug.getupvalues(uv)
                            for i, inVal in ipairs(inner) do
                                if type(inVal) == "number" and ((isWeapon and inVal >= 1) or (isBlock and inVal >= 15)) then
                                    debug.setupvalue(uv, i, 0)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

safeSpawn(function()
    while isSuiteActive do
        task.wait(0.1)
        if Config.BypassDetection then
            resetToolRateLimits()
        end
    end
end)

local function performClick(tool)
    if not tool then return end
    local name = string.lower(tool.Name)

    if string.find(name, "bow") then
        local sc = tool:FindFirstChild("ServerControl")
        if sc and sc:IsA("RemoteFunction") then
            hookBowClientControl(tool)

            local burst = 1
            if Config.HighPingBowEnabled then
                local ping = getNetworkPing()
                if Config.BowOverdrive then
                    burst = Config.BowMaxBurst
                else
                    burst = math.clamp(math.floor(ping / 25), Config.BowBaseBurst, Config.BowMaxBurst)
                end
            end

            for _ = 1, burst do
                task.spawn(function()
                    pcall(function() sc:InvokeServer(true) end)
                    pcall(function() sc:InvokeServer(false) end)
                end)
            end
        else
            tool:Activate()
        end
    else
        tool:Activate()
    end
end

--------------------------------------------------------------------------------
-- AUTO MINING AUTOMATION
--------------------------------------------------------------------------------

local MAX_MINE_DISTANCE = 500
local MINE_DELAY = 0.02
local FIRE_RATE = 0.02
local HITS_PER_CYCLE = 2
local FOCUS_CLOSEST_ONLY = true

directVisualBox = nil
local oreBoxes = {}

local function getEquippedPickaxe()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") then
            local name = item.Name:lower()
            if name:find("pickaxe") or name:find("axe") or name == "pick" then
                return item
            end
        end
    end
    return nil
end

local function getAnyPickaxeTool()
    local equipped = getEquippedPickaxe()
    if equipped then return equipped end
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            if item:IsA("Tool") then
                local name = item.Name:lower()
                if name:find("pickaxe") or name:find("axe") or name == "pick" then
                    return item
                end
            end
        end
    end
    return nil
end

local function ensurePickaxeEquipped()
    local tool = getAnyPickaxeTool()
    if not tool then return nil end
    local char = LocalPlayer.Character
    if char and tool.Parent ~= char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum:EquipTool(tool) end
    end
    return tool
end

local function getAnyPickaxeRemote()
    local tool = getAnyPickaxeTool()
    if tool then
        return tool:FindFirstChildWhichIsA("RemoteEvent")
    end
    return nil
end

local function getOresFolder()
    for _, v in pairs(Workspace:GetChildren()) do
        if v.Name:match("Map") then
            local map = v:FindFirstChild("Map")
            if map then
                local ores = map:FindFirstChild("Ores")
                if ores then return ores end
            end
        end
    end
    return nil
end

local function addOreBox(block)
    if oreBoxes[block] or not block or not block.Parent then return end
    local box = Instance.new("BoxHandleAdornment")
    box.Adornee = block
    box.Size = block.Size + Vector3.new(0.2, 0.2, 0.2)
    box.Color3 = Color3.fromRGB(255, 255, 255)
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Transparency = 0.15
    box.Parent = block
    oreBoxes[block] = box
end

local function removeOreBox(block)
    if oreBoxes[block] then
        pcall(function() oreBoxes[block]:Destroy() end)
        oreBoxes[block] = nil
    end
end

directVisualBox = Instance.new("SelectionBox")
directVisualBox.Color3 = Color3.fromRGB(255, 255, 255)
directVisualBox.LineThickness = 0.03
directVisualBox.SurfaceTransparency = 0.8
directVisualBox.SurfaceColor3 = Color3.fromRGB(255, 255, 255)
directVisualBox.Parent = Workspace

safeSpawn(function()
    while isSuiteActive do
        task.wait(Config.AutoMineEnabled and MINE_DELAY or 0.5)
        if Config.AutoMineEnabled then
            pcall(function()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local equippedPick = getEquippedPickaxe()
                local pickRemote = equippedPick and equippedPick:FindFirstChildWhichIsA("RemoteEvent")

                -- Auto mine only functions if the player is holding the pickaxe
                if root and pickRemote then
                    local op = OverlapParams.new()
                    op.FilterType = Enum.RaycastFilterType.Exclude
                    op.FilterDescendantsInstances = {char}

                    local scanBoxSize = Vector3.new(MAX_MINE_DISTANCE * 2, MAX_MINE_DISTANCE * 2, MAX_MINE_DISTANCE * 2)
                    local rawParts = Workspace:GetPartBoundsInBox(root.CFrame, scanBoxSize, op)
                    
                    local validBlocks = {}
                    local rootPos = root.Position

                    for _, block in ipairs(rawParts) do
                        if block:IsA("BasePart") and block.CanCollide then
                            local dist = (block.Position - rootPos).Magnitude
                            -- Safety: Never auto-mine the floor blocks directly under or supporting the player
                            local isUnderFeet = (math.abs(block.Position.X - rootPos.X) <= 2.8 and math.abs(block.Position.Z - rootPos.Z) <= 2.8 and block.Position.Y <= rootPos.Y)
                            if not isUnderFeet and dist <= MAX_MINE_DISTANCE then
                                table.insert(validBlocks, {part = block, dist = dist})
                            end
                        end
                    end

                    table.sort(validBlocks, function(a, b)
                        return a.dist < b.dist
                    end)

                    local targetCount = FOCUS_CLOSEST_ONLY and 1 or math.min(#validBlocks, 2)

                    for i = 1, math.min(#validBlocks, targetCount) do
                        if not Config.AutoMineEnabled or not getEquippedPickaxe() then break end
                        local block = validBlocks[i].part
                        if block and block.Parent then
                            if directVisualBox then directVisualBox.Adornee = block end
                            for _ = 1, HITS_PER_CYCLE do
                                pickRemote:FireServer(block)
                            end
                        end
                    end
                else
                    if directVisualBox then directVisualBox.Adornee = nil end
                end
            end)
        else
            if directVisualBox then directVisualBox.Adornee = nil end
        end
    end
end)

safeSpawn(function()
    while isSuiteActive do
        task.wait(Config.OreAutoMineEnabled and FIRE_RATE or 0.5)
        if Config.OreAutoMineEnabled then
            pcall(function()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
                local pickaxe = getAnyPickaxeTool()
                local remote = pickaxe and pickaxe:FindFirstChildWhichIsA("RemoteEvent")
                local ores = getOresFolder()

                for block in pairs(oreBoxes) do
                    if not block or not block.Parent then oreBoxes[block] = nil end
                end

                if root and remote and ores and pickaxe then
                    local rootPos = root.Position
                    local validOres = {}

                    for _, block in pairs(ores:GetChildren()) do
                        if block.Name == "Block" and block:IsA("BasePart") then
                            local dist = (block.Position - rootPos).Magnitude
                            if dist <= 18 then
                                table.insert(validOres, {part = block, dist = dist})
                            else
                                removeOreBox(block)
                            end
                        end
                    end

                    table.sort(validOres, function(a, b)
                        return a.dist < b.dist
                    end)

                    local targetCount = FOCUS_CLOSEST_ONLY and 1 or math.min(#validOres, 2)

                    if #validOres > 0 then
                        local currentTool = char:FindFirstChildOfClass("Tool")
                        local wasHoldingPickaxe = (currentTool == pickaxe)

                        -- Auto Ore works without holding pickaxe: temporarily equip if necessary so server accepts the hit
                        if not wasHoldingPickaxe and hum then
                            hum:EquipTool(pickaxe)
                        end

                        for i = 1, math.min(#validOres, targetCount) do
                            if not Config.OreAutoMineEnabled then break end
                            local block = validOres[i].part
                            if block and block.Parent then
                                addOreBox(block)
                                for _ = 1, math.max(HITS_PER_CYCLE * 3, 6) do
                                    pcall(function() remote:FireServer(block) end)
                                end
                            end
                        end

                        -- Restore original tool or unequip if hands were empty
                        if not wasHoldingPickaxe then
                            if currentTool and currentTool.Parent == backpack and hum then
                                hum:EquipTool(currentTool)
                            elseif not currentTool and hum then
                                hum:UnequipTools()
                            end
                        end
                    else
                        for block in pairs(oreBoxes) do removeOreBox(block) end
                    end
                else
                    for block in pairs(oreBoxes) do removeOreBox(block) end
                end
            end)
        else
            for block in pairs(oreBoxes) do removeOreBox(block) end
        end
    end
end)

--------------------------------------------------------------------------------
-- MINE BEHIND, PLACE FRONT (INFINITE BRIDGE) ENGINE
--------------------------------------------------------------------------------

local pendingPlacements = {}
local lastPlaceTick = 0
local lastMineTick = 0

local function getVoxelKey(pos)
    return string.format("%d,%d,%d", math.round(pos.X / 4) * 4, math.round(pos.Y / 4) * 4, math.round(pos.Z / 4) * 4)
end

local function getAnyBlockTool()
    local char = LocalPlayer.Character
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") and item:FindFirstChild("RemoteFunction") and item.Name:lower():find("block") then
                return item
            end
        end
    end
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            if item:IsA("Tool") and item:FindFirstChild("RemoteFunction") and item.Name:lower():find("block") then
                return item
            end
        end
    end
    return nil
end

local function ensureBlockEquipped()
    local tool = getAnyBlockTool()
    if not tool then return nil end
    local char = LocalPlayer.Character
    if char and tool.Parent ~= char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum:EquipTool(tool) end
    end
    return tool
end


local function findBlockAt(pos)
    local op = OverlapParams.new()
    op.FilterType = Enum.RaycastFilterType.Include
    local filter = {}
    local blocksFolder = Workspace:FindFirstChild("GameStorage") and Workspace.GameStorage:FindFirstChild("Blocks")
    if blocksFolder then table.insert(filter, blocksFolder) end
    for _, v in pairs(Workspace:GetChildren()) do
        if v.Name:match("Map") then table.insert(filter, v) end
    end
    if #filter == 0 then table.insert(filter, Workspace) end
    op.FilterDescendantsInstances = filter

    local parts = Workspace:GetPartBoundsInBox(CFrame.new(pos), Vector3.new(3.8, 3.8, 3.8), op)
    for _, p in ipairs(parts) do
        if p:IsA("BasePart") and p.CanCollide and p.Name ~= "HolderBlock" and p.Name ~= "HolderBlock2" then
            return p
        end
    end
    return nil
end

local function isSolidBlockAt(pos)
    local key = getVoxelKey(pos)
    if pendingPlacements[key] and (tick() - pendingPlacements[key] < 0.2) then
        return true, nil
    end

    local part = findBlockAt(pos)
    if part then
        return true, part
    end
    return false, nil
end

local function getCurrentPlayerSpeed()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local velSpeed = 0
    if root then
        local vel = root.AssemblyLinearVelocity or root.Velocity
        if vel then
            velSpeed = Vector3.new(vel.X, 0, vel.Z).Magnitude
        end
    end
    local humSpeed = hum and hum.WalkSpeed or 16
    return math.max(velSpeed, humSpeed, 16)
end

local bridgeHistory = {}
local bridgeHistorySet = {}

local function trackBridgeBlock(pos)
    if not pos then return end
    local key = getVoxelKey(pos)
    if not bridgeHistorySet[key] then
        bridgeHistorySet[key] = true
        table.insert(bridgeHistory, pos)
    end
end

local function executeBlockPlace(targetPos, isEmergency, isRunway)
    local key = getVoxelKey(targetPos)
    local dedupeTtl = (isEmergency or isRunway) and 0.35 or 0.2
    if pendingPlacements[key] and (tick() - pendingPlacements[key] < dedupeTtl) then
        return false
    end

    local currentSpeed = getCurrentPlayerSpeed()
    local placeInterval = (isEmergency or isRunway) and 0 or math.clamp(1.5 / currentSpeed, 0.02, 0.06)
    if not (isEmergency or isRunway) and (tick() - lastPlaceTick < placeInterval) then
        return false
    end

    local blockTool = ensureBlockEquipped() or getAnyBlockTool()
    if not blockTool then return false end
    local rf = blockTool:FindFirstChild("RemoteFunction")
    if not rf then return false end

    local leftVal = blockTool:FindFirstChild("Left")
    if leftVal and leftVal.Value <= 0 then
        -- Out of blocks: immediately equip pickaxe to mine and restock blocks
        ensurePickaxeEquipped()
        return false
    end

    local color = (blockTool:FindFirstChild("Handle") and blockTool.Handle.BrickColor) or BrickColor.new("Rust")

    local neighbors = {
        {offset = Vector3.new(4, 0, 0), normal = Enum.NormalId.Left},
        {offset = Vector3.new(-4, 0, 0), normal = Enum.NormalId.Right},
        {offset = Vector3.new(0, 0, 4), normal = Enum.NormalId.Front},
        {offset = Vector3.new(0, 0, -4), normal = Enum.NormalId.Back},
        {offset = Vector3.new(0, 4, 0), normal = Enum.NormalId.Bottom},
        {offset = Vector3.new(0, -4, 0), normal = Enum.NormalId.Top},
    }

    local adjacentBlock, targetNormal = nil, nil
    for _, n in ipairs(neighbors) do
        local nPos = targetPos + n.offset
        local exists, part = isSolidBlockAt(nPos)
        if exists and part then
            adjacentBlock = part
            targetNormal = n.normal
            break
        end
    end

    local ok = false
    if adjacentBlock and targetNormal then
        ok = pcall(function()
            rf:InvokeServer(adjacentBlock.Position, targetNormal, nil, color, true)
        end)
    else
        ok = pcall(function()
            rf:InvokeServer(nil, Enum.NormalId.Top, targetPos, color, true)
        end)
    end

    if ok then
        pendingPlacements[key] = tick()
        lastPlaceTick = tick()
        trackBridgeBlock(targetPos)

        -- Legit visual arm swing: play directly via Humanoid/Animate WITHOUT calling blockTool:Activate()
        -- (Calling blockTool:Activate() increments BlockLocal's u111 click counter, which trips the 2s cooldown)
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local animate = char and char:FindFirstChild("Animate")
            local toolslash = animate and animate:FindFirstChild("toolslash")
            local slashAnim = toolslash and toolslash:FindFirstChildWhichIsA("Animation")
            if hum and slashAnim then
                local track = hum:LoadAnimation(slashAnim)
                track.Priority = Enum.AnimationPriority.Action
                track:Play(0.05, 1, 2.5)
            end
        end)
    end
    return ok
end

local function executeMineBlock(blockPart, forceImmediate)
    if not (blockPart and blockPart.Parent) then return false end

    local currentSpeed = getCurrentPlayerSpeed()
    local mineInterval = forceImmediate and 0.01 or math.clamp(1.5 / currentSpeed, 0.015, 0.04)
    if not forceImmediate and (tick() - lastMineTick < mineInterval) then return false end

    local pickTool = ensurePickaxeEquipped() or getAnyPickaxeTool()
    local pickRemote = (pickTool and pickTool:FindFirstChildWhichIsA("RemoteEvent")) or getAnyPickaxeRemote()
    if not pickRemote then return false end

    resetToolRateLimits(pickTool)
    lastMineTick = tick()
    for _ = 1, 3 do
        pcall(function()
            pickRemote:FireServer(blockPart)
        end)
    end
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local animate = char and char:FindFirstChild("Animate")
        local toolslash = animate and animate:FindFirstChild("toolslash")
        local slashAnim = toolslash and toolslash:FindFirstChildWhichIsA("Animation")
        if hum and slashAnim then
            local track = hum:LoadAnimation(slashAnim)
            track.Priority = Enum.AnimationPriority.Action
            track:Play(0.05, 1, 2.5)
        end
    end)
    return true
end

local function executeFrontTunnelMine(currentPosUnder, dirX, dirZ, floorY)
    if not Config.BridgeTunnel3x3 then return false end

    local pickTool = ensurePickaxeEquipped() or getAnyPickaxeTool()
    local pickRemote = (pickTool and pickTool:FindFirstChildWhichIsA("RemoteEvent")) or getAnyPickaxeRemote()
    if not pickRemote then return false end

    local perpX, perpZ = -dirZ, dirX
    local obstacles = {}

    -- Scan 1 to 2 steps ahead (4 studs and 8 studs ahead)
    for step = 1, 2 do
        local baseAhead = currentPosUnder + Vector3.new(dirX * step * 4, 0, dirZ * step * 4)
        -- 3 columns: Center first (0), then Left (-1), then Right (1)
        for _, col in ipairs({0, -1, 1}) do
            local colOffset = Vector3.new(perpX * col * 4, 0, perpZ * col * 4)
            -- 3 rows: Feet level (+4), Torso level (+8), Head level (+12)
            for _, row in ipairs({1, 2, 3}) do
                local checkPos = baseAhead + colOffset + Vector3.new(0, row * 4, 0)
                local part = findBlockAt(checkPos)
                if part and part.Parent and part.CanCollide and part.Name ~= "HolderBlock" and part.Name ~= "HolderBlock2" then
                    if not part:IsDescendantOf(LocalPlayer.Character) then
                        table.insert(obstacles, {
                            part = part,
                            priority = (col == 0 and 0 or 2) + (row == 1 and 0 or (row == 2 and 1 or 2)) + (step * 3)
                        })
                    end
                end
            end
        end
    end

    if #obstacles > 0 then
        table.sort(obstacles, function(a, b)
            return a.priority < b.priority
        end)

        local currentSpeed = getCurrentPlayerSpeed()
        local mineInterval = math.clamp(1.2 / currentSpeed, 0.02, 0.05)
        if tick() - lastMineTick >= mineInterval then
            lastMineTick = tick()
            local hitLimit = math.min(#obstacles, 3)
            for i = 1, hitLimit do
                local target = obstacles[i].part
                if target and target.Parent then
                    for _ = 1, 4 do
                        pcall(function()
                            pickRemote:FireServer(target)
                        end)
                    end
                end
            end
        end
        return true
    end
    return false
end

local bridgeActiveAxis = nil
local bridgeLockedGridX = nil
local bridgeLockedGridZ = nil
local bridgeLockedFloorY = nil
local bridgeLastDirX = 0
local bridgeLastDirZ = 0

-- Frame-perfect continuous auto-pilot movement & auto-jumping (bunny-hop) while bridging
safeConnect(RunService.Heartbeat, function()
    if not isSuiteActive or not Config.MineBehindPlaceFront then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    -- Auto-Pilot autonomous locomotion
    if bridgeAutoPilotActive and Config.BridgeAutoPilot then
        if hum.MoveDirection.Magnitude > 0.1 then
            -- Steer: update auto-pilot heading if player inputs directional control
            autoPilotMoveDir = hum.MoveDirection.Unit
        else
            -- Hands-free cruise in current heading
            hum:Move(autoPilotMoveDir, false)
        end
    end

    -- Continuous Auto-Jump (bunny hop) while moving
    if Config.BridgeAutoJump then
        if (hum.MoveDirection.Magnitude > 0.1 or (bridgeAutoPilotActive and autoPilotMoveDir.Magnitude > 0.1)) and hum.FloorMaterial ~= Enum.Material.Air then
            hum.Jump = true
        end
    end
end)

safeSpawn(function()
    while isSuiteActive do
        task.wait(Config.MineBehindPlaceFront and 0.02 or 0.3)
        if Config.MineBehindPlaceFront then
            pcall(function()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if not char or not root or not hum or hum.Health <= 0 then return end
                if IS_SKYWARS and root.Position.Y > 145 then return end

                local rawFloorY = math.round((root.Position.Y - 5) / 4) * 4

                local moveDir = hum.MoveDirection
                if moveDir.Magnitude < 0.1 then
                    if bridgeAutoPilotActive and autoPilotMoveDir.Magnitude > 0.1 then
                        moveDir = autoPilotMoveDir
                        hum:Move(autoPilotMoveDir, false)
                    else
                        -- Safety: Never run infinite bridge or mine behind while standing still
                        return
                    end
                end
                local flatDir = Vector3.new(moveDir.X, 0, moveDir.Z).Unit

                local rootGridX = math.round(root.Position.X / 4) * 4
                local rootGridZ = math.round(root.Position.Z / 4) * 4

                -- Jump & Elevation Handling:
                -- Detect if character is airborne (jumping or falling)
                local humState = hum:GetState()
                local isAirborne = (hum.FloorMaterial == Enum.Material.Air)
                    or (humState == Enum.HumanoidStateType.Jumping)
                    or (humState == Enum.HumanoidStateType.Freefall)

                -- Continuous Auto-Jump (Bunny Hop) while bridging
                if Config.BridgeAutoJump and not isAirborne and (hum.FloorMaterial ~= Enum.Material.Air) then
                    hum.Jump = true
                end

                -- Check solid ground at the raw foot level
                local isGroundedOnSolid = isSolidBlockAt(Vector3.new(rootGridX, rawFloorY, rootGridZ))

                if isGroundedOnSolid then
                    -- Player is standing on solid ground/island -> lock to this floor level
                    bridgeLockedFloorY = rawFloorY
                elseif not bridgeLockedFloorY then
                    bridgeLockedFloorY = rawFloorY
                end

                -- Lock floorY to bridge height so jumping does NOT elevate the bridge or leave gaps
                local floorY = bridgeLockedFloorY or rawFloorY
                local playerFootPos = Vector3.new(rootGridX, floorY, rootGridZ)
                local isPlayerOnSolid = isSolidBlockAt(playerFootPos)

                -- If player is on solid ground or bridging just started, establish cardinal baseline
                if isGroundedOnSolid or not bridgeActiveAxis then
                    bridgeLockedGridX = rootGridX
                    bridgeLockedGridZ = rootGridZ
                    if math.abs(flatDir.X) >= math.abs(flatDir.Z) then
                        bridgeActiveAxis = "X"
                    else
                        bridgeActiveAxis = "Z"
                    end
                end

                -- Sharp 90° Turn Enforcement (ONLY | or —, NEVER \ or /)
                if bridgeActiveAxis == "Z" then
                    -- Turn from Z to X immediately when player presses D or A (moving right/left)
                    if math.abs(flatDir.X) >= 0.35 and (math.abs(flatDir.X) >= (math.abs(flatDir.Z) * 0.9) or isAirborne) then
                        -- Register the orphan forward block placed along Z before turn to guarantee it is mined (no backward T)
                        local oldForwardPos = Vector3.new(bridgeLockedGridX, floorY, rootGridZ + bridgeLastDirZ * 4)
                        trackBridgeBlock(oldForwardPos)

                        local cornerPos = Vector3.new(bridgeLockedGridX, floorY, rootGridZ)
                        if not isSolidBlockAt(cornerPos) then
                            executeBlockPlace(cornerPos, true, false)
                        end
                        trackBridgeBlock(cornerPos)
                        bridgeActiveAxis = "X"
                        bridgeLockedGridZ = rootGridZ
                        bridgeLastDirX = math.sign(flatDir.X)
                    end
                elseif bridgeActiveAxis == "X" then
                    -- Turn from X to Z when player presses W or S (forward/backward)
                    if math.abs(flatDir.Z) >= 0.35 and (math.abs(flatDir.X) < 0.35 or math.abs(flatDir.Z) > (math.abs(flatDir.X) * 1.25)) then
                        -- Register the orphan forward block placed along X before turn to guarantee it is mined (no backward T)
                        local oldForwardPos = Vector3.new(rootGridX + bridgeLastDirX * 4, floorY, bridgeLockedGridZ)
                        trackBridgeBlock(oldForwardPos)

                        local cornerPos = Vector3.new(rootGridX, floorY, bridgeLockedGridZ)
                        if not isSolidBlockAt(cornerPos) then
                            executeBlockPlace(cornerPos, true, false)
                        end
                        trackBridgeBlock(cornerPos)
                        bridgeActiveAxis = "Z"
                        bridgeLockedGridX = rootGridX
                        bridgeLastDirZ = math.sign(flatDir.Z)
                    end
                end

                local dirX, dirZ = 0, 0
                local currentPosUnder

                if bridgeActiveAxis == "X" then
                    dirX = math.sign(flatDir.X)
                    if dirX == 0 then dirX = (bridgeLastDirX ~= 0 and bridgeLastDirX) or 1 end
                    dirZ = 0
                    bridgeLastDirX = dirX
                    currentPosUnder = Vector3.new(rootGridX, floorY, bridgeLockedGridZ)
                else
                    dirX = 0
                    dirZ = math.sign(flatDir.Z)
                    if dirZ == 0 then dirZ = (bridgeLastDirZ ~= 0 and bridgeLastDirZ) or 1 end
                    bridgeLastDirZ = dirZ
                    currentPosUnder = Vector3.new(bridgeLockedGridX, floorY, rootGridZ)
                end

                -- 1. Anti-Fall: Instantly place directly under feet if missing (locked to bridge line)
                if not isSolidBlockAt(currentPosUnder) then
                    executeBlockPlace(currentPosUnder, true, false)
                end
                trackBridgeBlock(currentPosUnder)

                -- 2. 3x3 Front Tunnel Mining: Bores through walls, mountains & obstacle blocks ahead
                local frontBlocked = executeFrontTunnelMine(currentPosUnder, dirX, dirZ, floorY)

                -- 3. Legit Runway Lookahead: Stride-Synced Placement + Airborne Jump Support
                local currentSpeed = getCurrentPlayerSpeed()
                local ping = (getNetworkPing and getNetworkPing()) or 60

                local userBlocksAhead = tonumber(Config.BridgeLookaheadBlocks) or 1
                -- While jumping, place at least 2 blocks ahead so landing pad is solid before touchdown
                local minAhead = isAirborne and 2 or 1
                local lookaheadCount = math.max(userBlocksAhead, minAhead)

                -- Forward progress along walking axis relative to current block center (-2 to +2 studs)
                local forwardOffset = (root.Position.X - rootGridX) * dirX + (root.Position.Z - rootGridZ) * dirZ

                for step = 1, lookaheadCount do
                    -- Proactively bridge runway while airborne or stepping towards edge
                    local shouldPlace = isAirborne
                        or (step == 1 and (forwardOffset >= -0.8 or currentSpeed >= 12))
                        or (step > 1 and (forwardOffset >= 0.5 or currentSpeed >= 20))

                    if shouldPlace then
                        local offsetDist = step * 4
                        local posAhead = currentPosUnder + Vector3.new(dirX * offsetDist, 0, dirZ * offsetDist)
                        if not isSolidBlockAt(posAhead) then
                            executeBlockPlace(posAhead, false, true)
                        end
                        trackBridgeBlock(posAhead)
                    end
                end

                -- 4. Exhaustive Mine Behind: Mines EVERY block trailing behind & cleans all turn artifacts (no backward T)
                if not frontBlocked then
                    local safeMineDist = 5.2

                    local i = 1
                    local minedCount = 0
                    while i <= #bridgeHistory and minedCount < 4 do
                        local bPos = bridgeHistory[i]
                        local key = getVoxelKey(bPos)
                        local dist = (Vector3.new(root.Position.X, floorY, root.Position.Z) - bPos).Magnitude

                        -- Check if block is currently in front along the active walking direction
                        local toBlock = bPos - currentPosUnder
                        local isAhead = (toBlock.X * dirX + toBlock.Z * dirZ) > 1.0

                        if not isAhead and dist >= safeMineDist then
                            local bPart = findBlockAt(bPos)
                            if bPart then
                                executeMineBlock(bPart, true)
                                minedCount = minedCount + 1
                                i = i + 1
                            else
                                -- Block is already broken/gone -> clean from queue
                                bridgeHistorySet[key] = nil
                                table.remove(bridgeHistory, i)
                            end
                        else
                            if not isAhead and not findBlockAt(bPos) then
                                bridgeHistorySet[key] = nil
                                table.remove(bridgeHistory, i)
                            else
                                i = i + 1
                            end
                        end
                    end

                    -- Fallback: Axial trail check behind player
                    local userBlocksBehind = tonumber(Config.BridgeMineBehindBlocks) or 5
                    for step = 1, userBlocksBehind do
                        local dist = math.max(safeMineDist, 5.2) + (step - 1) * 4
                        local bPos = currentPosUnder - Vector3.new(dirX * dist, 0, dirZ * dist)
                        local bPart = findBlockAt(bPos)
                        if bPart then
                            local playerDist = (Vector3.new(root.Position.X, floorY, root.Position.Z) - bPart.Position).Magnitude
                            if playerDist >= safeMineDist then
                                executeMineBlock(bPart, false)
                                break
                            end
                        end
                    end
                end
            end)
        end
    end
end)

--------------------------------------------------------------------------------
-- COMBAT TARGET FINDER
--------------------------------------------------------------------------------

local function getClosestCombatTarget()
    local char = LocalPlayer.Character
    local root = getRoot(char)
    if not root or (IS_SKYWARS and root.Position.Y > 145) then return nil end

    local closestDist = Config.CombatFaceRange
    local bestTarget = nil

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and not isExcluded(p) then
            local c = p.Character
            local hrp = c and c:FindFirstChild("HumanoidRootPart")
            local h = c and c:FindFirstChildOfClass("Humanoid")

            if c and hrp and h and h.Health > 0 and (not IS_SKYWARS or hrp.Position.Y < 145) then
                local dist = (hrp.Position - root.Position).Magnitude
                if dist <= closestDist then
                    closestDist = dist
                    bestTarget = hrp
                end
            end
        end
    end

    return bestTarget
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
    if selfHighlight then selfHighlight.Enabled = false end
end

local function destroyAllVisuals()
    for _, d in pairs(TrackedEntities) do
        if d.Highlight then pcall(function() d.Highlight:Destroy() end) end
        if d.Billboard then pcall(function() d.Billboard:Destroy() end) end
        if d.Tracer then pcall(function() d.Tracer:Remove() end) end
    end
    if selfHighlight then pcall(function() selfHighlight:Destroy() end) selfHighlight = nil end
    table.clear(TrackedEntities)
end

safeConnect(Players.PlayerRemoving, function(player) removeTracker(player) end)

local VisualPresets = {
    ["Neon Cyan"] = Color3.fromRGB(0, 240, 255),
    ["Amethyst Purple"] = Color3.fromRGB(180, 50, 255),
    ["Sakura Pink"] = Color3.fromRGB(255, 105, 180),
    ["Emerald Matrix"] = Color3.fromRGB(50, 255, 110),
    ["Sunset Orange"] = Color3.fromRGB(255, 120, 20),
    ["Ghost White"] = Color3.fromRGB(240, 240, 255),
    ["Blood Red"] = Color3.fromRGB(255, 45, 45),
}

local function getCurrentVisualColor(healthRatio)
    if Config.RainbowChroma then
        return Color3.fromHSV((tick() * 0.4) % 1, 0.85, 1)
    end
    if Config.DynamicHealthColor and healthRatio then
        if healthRatio >= 0.75 then
            return Color3.fromRGB(50, 255, 100)
        elseif healthRatio >= 0.35 then
            return Color3.fromRGB(255, 210, 40)
        else
            return Color3.fromRGB(255, 45, 45)
        end
    end
    return Config.HighlightColor or Color3.fromRGB(0, 240, 255)
end

local selfHighlight = nil
local function updateSelfHighlight()
    local char = LocalPlayer.Character
    if not char then return end
    if Config.SelfChamsEnabled then
        if not selfHighlight or selfHighlight.Parent ~= char then
            if selfHighlight then pcall(function() selfHighlight:Destroy() end) end
            selfHighlight = Instance.new("Highlight")
            selfHighlight.Name = "DALX_SelfChams"
            selfHighlight.Adornee = char
            selfHighlight.Parent = char
        end
        local selfColor = Config.SelfRainbowAura and Color3.fromHSV((tick() * 0.5) % 1, 0.9, 1) or (Config.HighlightColor or Color3.fromRGB(0, 240, 255))
        selfHighlight.FillColor = selfColor
        selfHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        selfHighlight.FillTransparency = 0.55
        selfHighlight.OutlineTransparency = 0
        selfHighlight.Enabled = true
    else
        if selfHighlight then
            selfHighlight.Enabled = false
        end
    end
end

local originalLighting = nil
local function applyFullbright(enabled)
    Config.FullbrightEnabled = enabled
    if not originalLighting then
        originalLighting = {
            Brightness = Lighting.Brightness,
            ClockTime = Lighting.ClockTime,
            FogEnd = Lighting.FogEnd,
            FogStart = Lighting.FogStart,
            FogColor = Lighting.FogColor,
            GlobalShadows = Lighting.GlobalShadows,
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient,
        }
    end
    if enabled then
        pcall(function()
            Lighting.Ambient = Color3.fromRGB(220, 220, 220)
            Lighting.OutdoorAmbient = Color3.fromRGB(220, 220, 220)
            Lighting.Brightness = 2.5
            Lighting.FogEnd = 100000
        end)
    else
        pcall(function()
            if originalLighting then
                Lighting.Ambient = originalLighting.Ambient or Color3.fromRGB(128, 128, 128)
                Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient or Color3.fromRGB(128, 128, 128)
                Lighting.Brightness = originalLighting.Brightness
                Lighting.FogEnd = originalLighting.FogEnd
            end
        end)
    end
end

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

local function applyAtmosphereTheme(theme)
    Config.AtmosphereTheme = theme
    if not originalLighting then
        originalLighting = {
            Brightness = Lighting.Brightness,
            ClockTime = Lighting.ClockTime,
            FogEnd = Lighting.FogEnd,
            FogStart = Lighting.FogStart,
            FogColor = Lighting.FogColor,
            GlobalShadows = Lighting.GlobalShadows,
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient,
        }
    end
    local fx = Lighting:FindFirstChild("DALX_AtmosphereSky")
    if fx then pcall(function() fx:Destroy() end) end
    if theme == "Default Sky" then
        if originalLighting then
            Lighting.ClockTime = originalLighting.ClockTime
            Lighting.Brightness = originalLighting.Brightness
            Lighting.FogColor = originalLighting.FogColor
            Lighting.FogEnd = originalLighting.FogEnd
            Lighting.GlobalShadows = originalLighting.GlobalShadows
        end
    elseif theme == "Midnight Cyber" then
        pcall(function()
            Lighting.ClockTime = 0
            Lighting.Brightness = 1.2
            Lighting.FogColor = Color3.fromRGB(12, 16, 32)
            Lighting.FogEnd = 3500
        end)
    elseif theme == "Vaporwave Purple" then
        pcall(function()
            Lighting.ClockTime = 18.2
            Lighting.Brightness = 1.5
            Lighting.FogColor = Color3.fromRGB(80, 20, 100)
            Lighting.FogEnd = 2500
        end)
    elseif theme == "Sunset Golden Hour" then
        pcall(function()
            Lighting.ClockTime = 17.6
            Lighting.Brightness = 1.8
            Lighting.FogColor = Color3.fromRGB(130, 55, 20)
            Lighting.FogEnd = 3500
        end)
    elseif theme == "Minecraft Retro" then
        applyMinecraftGraphics(true)
    end
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
-- RADAR & THREAT SCANNER HELPER FUNCTIONS
--------------------------------------------------------------------------------

local function scanPlayerArmor(plr)
    if not plr or not plr.Character then return "None" end
    local armorFound = {}
    for _, child in ipairs(plr.Character:GetChildren()) do
        local name = string.lower(child.Name)
        if child:IsA("Accessory") or child:IsA("Model") or child:IsA("Part") then
            if string.find(name, "obsidian") or string.find(name, "void") then
                return "Obsidian (Tier 5)"
            elseif string.find(name, "diamond") or string.find(name, "crystal") then
                table.insert(armorFound, "Diamond")
            elseif string.find(name, "gold") then
                table.insert(armorFound, "Gold")
            elseif string.find(name, "iron") or string.find(name, "steel") then
                table.insert(armorFound, "Iron")
            end
        end
    end
    if #armorFound > 0 then
        return armorFound[1] .. " Armor"
    end
    return "Leather / Standard"
end

local function scanPlayerWeapon(plr)
    if not plr or not plr.Character then return "None" end
    local tool = plr.Character:FindFirstChildOfClass("Tool")
    if tool then return tool.Name end
    local bp = plr:FindFirstChildOfClass("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and (string.find(string.lower(t.Name), "sword") or string.find(string.lower(t.Name), "bow")) then
                return t.Name .. " (Holstered)"
            end
        end
    end
    return "Unarmed / Fists"
end

local function getClosestEnemyInfo()
    local char = LocalPlayer.Character
    local root = getRoot(char)
    if not root then return nil, 0 end
    local closest = math.huge
    local target = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and not isExcluded(p) and p.Character then
            local hrp = getRoot(p.Character)
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local dist = (hrp.Position - root.Position).Magnitude
                if dist < closest then
                    closest = dist
                    target = p
                end
            end
        end
    end
    return target, closest
end

--------------------------------------------------------------------------------
-- WATERMARK HUD (Dalx.wtf Top-Left Aesthetic)
--------------------------------------------------------------------------------

local watermarkGui = nil
local watermarkFrame = nil
local watermarkFpsConn = nil

local function getGuiParent()
    local target = (type(gethui) == "function" and gethui()) or CoreGui
    if not target or target == CoreGui then
        local lp = Players.LocalPlayer
        if lp and lp:FindFirstChild("PlayerGui") then
            return lp.PlayerGui
        end
    end
    return target
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
                local configKey = ConfigKeyAliases[name] or (id and ConfigKeyAliases[id]) or id or name
                local state = (Config and Config[configKey] ~= nil and Config[configKey]) or (tCfg.Default or false)
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

                    registerKeybindBadge(keybindConfigKey, bindBtn)
                    bindBtn.MouseButton1Click:Connect(function()
                        startBindingKey(keybindConfigKey, bindBtn)
                    end)

                    KeybindRegistry[keybindConfigKey] = {
                        DisplayName = name,
                        Callback = function()
                            toggleObj:UpdateState(not state)
                        end,
                        GetState = function() return state end
                    }
                end

                function toggleObj:UpdateState(newState, skipSave)
                    state = newState
                    chk.BackgroundColor3 = state and THEME.AccentRed or THEME.WidgetBg
                    cStroke.Color = state and THEME.AccentRed or THEME.WidgetBorder
                    chkMark.Visible = state
                    if Config and Config[configKey] ~= nil then
                        Config[configKey] = state
                    end
                    cb(state)
                    updateKeybindIndicatorHUD()
                    if not skipSave and saveConfigDebounced then
                        saveConfigDebounced()
                    end
                end
                function toggleObj:Set(newState, skipSave) self:UpdateState(newState, skipSave) end
                function toggleObj:Get() return state end

                local function onToggle() toggleObj:UpdateState(not state) end
                chk.MouseButton1Click:Connect(onToggle)
                lbl.MouseButton1Click:Connect(onToggle)

                RegisteredControls.Toggles[id or name] = toggleObj
                if id then RegisteredControls.Toggles[id] = toggleObj end
                if name then RegisteredControls.Toggles[name] = toggleObj end
                if configKey then RegisteredControls.Toggles[configKey] = toggleObj end
                if keybindConfigKey then RegisteredControls.Toggles[keybindConfigKey] = toggleObj end

                if state then cb(state) end
                updateBoxSize()
                return toggleObj
            end

            function sectionObj:Slider(sCfg, id)
                local name = sCfg.Name or "Slider"
                local min = sCfg.Minimum or 0
                local max = sCfg.Maximum or 100
                local configKey = ConfigKeyAliases[name] or (id and ConfigKeyAliases[id]) or id or name
                local currentVal = (Config and type(Config[configKey]) == "number" and Config[configKey]) or (sCfg.Default or min)
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
                function sliderObj:Set(newVal, skipSave)
                    currentVal = math.clamp(newVal, min, max)
                    fill.Size = UDim2.new(math.clamp((currentVal - min) / (max - min), 0, 1), 0, 1, 0)
                    label.Text = name .. ": " .. getValString(currentVal)
                    if Config then
                        Config[configKey] = currentVal
                    end
                    cb(currentVal)
                    if not skipSave and saveConfigDebounced then
                        saveConfigDebounced()
                    end
                end
                function sliderObj:Update(newVal, skipSave) self:Set(newVal, skipSave) end
                function sliderObj:Get() return currentVal end

                sliderObj:Set(currentVal, true)

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

                RegisteredControls.Sliders[id or name] = sliderObj

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
                    if curKey then bindBadge.TextColor3 = THEME.TextPrimary end
                    Instance.new("UICorner", bindBadge).CornerRadius = UDim.new(0, 2)
                    local bbStroke = Instance.new("UIStroke", bindBadge) bbStroke.Color = THEME.WidgetBorder bbStroke.Thickness = 1

                    registerKeybindBadge(keybindConfigKey, bindBadge)
                    bindBadge.MouseButton1Click:Connect(function()
                        startBindingKey(keybindConfigKey, bindBadge)
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
                local configKey = ConfigKeyAliases[name] or (id and ConfigKeyAliases[id]) or id or name
                local currentSel = (Config and Config[configKey] ~= nil and Config[configKey]) or (dCfg.Default or (options[1] or "None"))
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
                    for k, v in pairs(currentSel) do
                        if type(k) == "string" and v == true then
                            selectedDict[k] = true
                        elseif type(v) == "string" then
                            selectedDict[v] = true
                        end
                    end
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
                        optBtn.TextColor3 = (multi and selectedDict[opt]) and THEME.AccentRed or THEME.TextPrimary
                        optBtn.TextXAlignment = Enum.TextXAlignment.Left
                        optBtn.ZIndex = 16
                        optBtn.Text = "  " .. tostring(opt)

                        optBtn.MouseButton1Click:Connect(function()
                            if multi then
                                selectedDict[opt] = not selectedDict[opt]
                                optBtn.TextColor3 = selectedDict[opt] and THEME.AccentRed or THEME.TextPrimary
                                if Config then Config[configKey] = selectedDict end
                                cb(selectedDict)
                                if saveConfigDebounced then saveConfigDebounced() end
                            else
                                currentSel = opt
                                selector.Text = "  " .. tostring(opt) .. "  +"
                                dropFrame.Visible = false
                                isOpen = false
                                container.Size = UDim2.new(1, 0, 0, 44)
                                updateBoxSize()
                                if Config then Config[configKey] = currentSel end
                                cb(currentSel)
                                if saveConfigDebounced then saveConfigDebounced() end
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
                function dropdownObj:Set(newSel, skipSave)
                    if multi then
                        selectedDict = {}
                        if type(newSel) == "table" then
                            for k, v in pairs(newSel) do
                                if type(k) == "string" and v == true then
                                    selectedDict[k] = true
                                elseif type(v) == "string" then
                                    selectedDict[v] = true
                                end
                            end
                        end
                        if Config then Config[configKey] = selectedDict end
                        refreshOptions()
                        cb(selectedDict)
                    else
                        currentSel = newSel
                        selector.Text = "  " .. tostring(currentSel) .. "  +"
                        if Config then Config[configKey] = currentSel end
                        cb(currentSel)
                    end
                    if not skipSave and saveConfigDebounced then saveConfigDebounced() end
                end
                function dropdownObj:UpdateSelection(newSel, skipSave) self:Set(newSel, skipSave) end
                function dropdownObj:Get() return multi and selectedDict or currentSel end

                RegisteredControls.Dropdowns[id or name] = dropdownObj

                if currentSel then cb(currentSel) end
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
-- INITIALIZE DALX WINDOW
--------------------------------------------------------------------------------

local Window = DalxUI:CreateWindow({
    Title = "Dalx.wtf",
    Size = UDim2.fromOffset(680, 520)
})
_G.SkywarsSuiteWindow = Window

--------------------------------------------------------------------------------
-- REGISTER MENU TABS
--------------------------------------------------------------------------------

local tabs = {
    Combat = Window:Tab({ Name = "Combat" }),
    Skywars = Window:Tab({ Name = "Skywars" }),
    Radar = Window:Tab({ Name = "Radar" }),
    Movement = Window:Tab({ Name = "Movement" }),
    Trolling = Window:Tab({ Name = "Trolls" }),
    Visuals = Window:Tab({ Name = "Visuals" }),
    InfiniteYield = Window:Tab({ Name = "Infinite Yield" }),
    Keybinds = Window:Tab({ Name = "Keybinds" }),
    Settings = Window:Tab({ Name = "Settings" })
}

--------------------------------------------------------------------------------
-- COMBAT TAB
--------------------------------------------------------------------------------
;(function()
local combatLeft = tabs.Combat:Section({ Side = "Left", Title = "Security & Anti-Cheat" })
combatLeft:Toggle({ 
    Name = "Bypass", 
    Default = true, 
    Keybind = "Bypass",
    Callback = function(val) Config.Bypass = val end 
}, "BypassToggle")

combatLeft:Header({ Text = "Auto Clicker" })
combatLeft:Toggle({ 
    Name = "Auto Clicker Enabled", 
    Default = false, 
    Keybind = "Clicker",
    Callback = function(val) Config.ClickerEnabled = val end 
}, "ClickerToggle")

combatLeft:Toggle({ 
    Name = "Hold Mouse To Click Only", 
    Default = false, 
    Callback = function(val) Config.HoldToClick = val end 
}, "HoldToClickToggle")

combatLeft:Slider({ 
    Name = "Clicks Per Second (CPS)", 
    Default = 60, 
    Minimum = 1, 
    Maximum = 1000, 
    Precision = 0, 
    Callback = function(val) Config.CPS = val end 
}, "CPSSlider")

combatLeft:Toggle({ 
    Name = "Smart Rate Limit (Anti-Ban)", 
    Default = false, 
    Callback = function(val) Config.SmartRateLimit = val end 
}, "SmartRateLimitToggle")

combatLeft:Toggle({ Name = "Detector Bypass", Default = true, Callback = function(val) Config.BypassDetection = val end }, "DetectorBypassToggle")

combatLeft:Header({ Text = "High-Ping Fast Bow & Auto Shoot" })
combatLeft:Toggle({
    Name = "Automatic Bow Shooting",
    Default = true,
    Callback = function(val) Config.BowAutoShoot = val end
}, "BowAutoShootToggle")

combatLeft:Toggle({
    Name = "High-Ping Acceleration",
    Default = true,
    Keybind = "FastBow",
    Callback = function(val) Config.HighPingBowEnabled = val end
}, "FastBowToggle")

combatLeft:Toggle({
    Name = "Latency Overdrive (Max Burst)",
    Default = true,
    Callback = function(val) Config.BowOverdrive = val end
}, "BowOverdriveToggle")

combatLeft:Slider({
    Name = "Max Burst Multiplier",
    Default = 16,
    Minimum = 2,
    Maximum = 30,
    Precision = 0,
    Callback = function(val) Config.BowMaxBurst = val end
}, "BowMaxBurstSlider")

combatLeft:Header({ Text = "Shoot Bow Without Holding" })
combatLeft:Toggle({
    Name = "Shoot Bow Without Holding",
    Default = false,
    Keybind = "BackgroundBow",
    Callback = function(val) Config.BackgroundBowEnabled = val end
}, "BackgroundBowToggle")

combatLeft:Dropdown({
    Name = "Bow Aim Mode",
    Options = { "Nearest Enemy", "Mouse Cursor" },
    Default = "Nearest Enemy",
    Callback = function(val) Config.BackgroundBowAimMode = val end
}, "BackgroundBowAimModeDropdown")

combatLeft:Slider({
    Name = "Bow Fire Interval (s)",
    Default = 0.35,
    Minimum = 0.1,
    Maximum = 2.0,
    Precision = 2,
    Callback = function(val) Config.BackgroundBowInterval = val end
}, "BackgroundBowIntervalSlider")

combatLeft:Slider({
    Name = "Bow Max Range",
    Default = 350,
    Minimum = 50,
    Maximum = 600,
    Precision = 0,
    Callback = function(val) Config.BackgroundBowMaxRange = val end
}, "BackgroundBowMaxRangeSlider")

combatLeft:Button({
    Name = "🏹 Fire Bow Shot Now",
    Callback = function()
        local shot = shootBowWithoutHolding()
        if shot then
            Window:Notify({ Title = "Bow Shot", Description = "Fired arrow without equipping bow!", Lifetime = 1.5 })
        else
            Window:Notify({ Title = "Bow", Description = "No bow found in inventory or character.", Lifetime = 2 })
        end
    end
})

combatLeft:Header({ Text = "Silent Aim" })
local SilentAimToggleObj
local SilentAimToggle = combatLeft:Toggle({
    Name = "Silent Aim Enabled",
    Default = true,
    Keybind = "SilentAimToggle",
    Callback = function(val)
        getgenv().SilentAimEnabled = val
    end
}, "SilentAimToggle")
SilentAimToggleObj = SilentAimToggle

combatLeft:Header({ Text = "Protected Players" })
combatLeft:Toggle({
    Name = "Team Check (skip teammates)",
    Default = false,
    Callback = function(val) Config.HitboxTeamCheck = val end
}, "TeamCheckToggle")

local ProtectedDropdown
ProtectedDropdown = combatLeft:Dropdown({
    Name = "Protected Players (select)",
    Multi = true,
    Options = getOtherPlayerNames(),
    Default = {},
    Callback = function(sel)
        table.clear(selectedExcluded)
        if type(sel) == "table" then
            for k, v in pairs(sel) do
                if v == true then selectedExcluded[k] = true
                elseif type(v) == "string" then selectedExcluded[v] = true end
            end
        end
    end
}, "ProtectedDropdown")

combatLeft:Input({
    Name = "Add Protected Player (type name)",
    Placeholder = "Username or display name",
    Callback = function(text)
        text = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if text == "" then return end
        local lower = text:lower()
        local final = text
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower():sub(1, #lower) == lower or p.DisplayName:lower():sub(1, #lower) == lower then
                final = p.Name
                break
            end
        end
        if not table.find(getgenv().DontShootThesePeople, final) then
            table.insert(getgenv().DontShootThesePeople, final)
        end
        Window:Notify({ Title = "Protected", Description = final .. " will not be targeted.", Lifetime = 2 })
    end
}, "ProtectedInput")

combatLeft:Button({
    Name = "Refresh Player List",
    Callback = function()
        pcall(function()
            local updatedList = getOtherPlayerNames()
            ProtectedDropdown:SetOptions(updatedList)
        end)
    end
})

combatLeft:Button({
    Name = "Clear Protected List",
    Callback = function()
        table.clear(selectedExcluded)
        getgenv().DontShootThesePeople = {}
        pcall(function() ProtectedDropdown:UpdateSelection({}) end)
        Window:Notify({ Title = "Protected", Description = "Protected list cleared.", Lifetime = 2 })
    end
})

local combatRight = tabs.Combat:Section({ Side = "Right", Title = "Combat Tracking & Range" })
combatRight:Toggle({
    Name = "Auto-Face Target", 
    Default = false,
    Keybind = "CombatFace",
    Callback = function(val)
        Config.CombatFaceEnabled = val
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not val and hum then hum.AutoRotate = true end
    end
}, "FaceToggle")

combatRight:Slider({
    Name = "Facing Range (Studs)", Default = 75, Minimum = 15, Maximum = 250, Precision = 0,
    Callback = function(val) Config.CombatFaceRange = val end
}, "RangeSlider")

combatRight:Toggle({ Name = "Smooth Rotation (Lerp)", Default = false, Callback = function(val) Config.SmoothRotation = val end }, "SmoothToggle")

combatRight:Header({ Text = "Hitbox Expander" })
combatRight:Toggle({ 
    Name = "Enable Hitboxes", 
    Default = false, 
    Keybind = "Hitbox",
    Callback = function(val) 
        Config.HitboxEnabled = val 
        if not val then resetAllHitboxes() end 
    end 
}, "HitboxToggle")
combatRight:Slider({ Name = "Hitbox Size", Default = 2, Minimum = 1, Maximum = 15, Precision = 1, Callback = function(val) Config.HitboxSize = val end }, "HitboxSizeSlider")

combatRight:Header({ Text = "Sword Reach Mechanic" })
combatRight:Toggle({
    Name = "Enable Reach", 
    Default = false,
    Keybind = "Reach",
    Callback = function(val)
        Config.ReachEnabled = val
        if not val then
            destroyReachCircle()
            Config.ReachVisuals = false
        end
    end
}, "ReachToggle")
combatRight:Slider({
    Name = "Reach Distance", Default = 15, Minimum = 3, Maximum = 50, Precision = 1,
    Callback = function(val) Config.ReachSize = val end
}, "ReachSizeSlider")
combatRight:Toggle({
    Name = "Show Reach Circle Indicator", Default = false,
    Callback = function(val)
        Config.ReachVisuals = val
        if val then
            createReachCircle()
        else
            destroyReachCircle()
        end
    end
}, "ReachVisualsToggle")
end)() -- Combat Tab

--------------------------------------------------------------------------------
-- SKYWARS & MAP TAB
--------------------------------------------------------------------------------
;(function()
local farmLeft = tabs.Skywars:Section({ Side = "Left", Title = "Automation & World" })
farmLeft:Toggle({
    Name = "Auto Mine", 
    Default = false,
    Keybind = "AutoMine",
    Callback = function(val)
        Config.AutoMineEnabled = val
        if val and not directVisualBox then
            directVisualBox = Instance.new("SelectionBox")
            directVisualBox.Color3 = Color3.fromRGB(255, 255, 255)
            directVisualBox.LineThickness = 0.03
            directVisualBox.SurfaceTransparency = 0.8
            directVisualBox.SurfaceColor3 = Color3.fromRGB(255, 255, 255)
            directVisualBox.Parent = Workspace
        elseif not val and directVisualBox then
            directVisualBox.Adornee = nil
        end
    end
}, "AutoMineToggle")

farmLeft:Toggle({
    Name = "Ore Auto Mine", 
    Default = false,
    Keybind = "OreAutoMine",
    Callback = function(val)
        Config.OreAutoMineEnabled = val
        if not val then
            for block in pairs(oreBoxes) do removeOreBox(block) end
        end
    end
}, "OreMineToggle")

local preBridgeEquippedTool = nil

MineBehindToggleObj = farmLeft:Toggle({
    Name = "Mine Behind, Place Front",
    Default = false,
    Keybind = "MinePlaceFront",
    Callback = function(val)
        Config.MineBehindPlaceFront = val
        bridgeActiveAxis = nil
        bridgeLockedGridX = nil
        bridgeLockedGridZ = nil
        bridgeLockedFloorY = nil
        table.clear(bridgeHistory)
        table.clear(bridgeHistorySet)
        table.clear(pendingPlacements)

        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if val then
            preBridgeEquippedTool = getEquippedTool()
            ensurePickaxeEquipped()
        else
            -- Restore block tool immediately so user can build / godbridge manually
            if preBridgeEquippedTool and preBridgeEquippedTool.Parent and hum then
                pcall(function() hum:EquipTool(preBridgeEquippedTool) end)
            else
                ensureBlockEquipped()
            end
            preBridgeEquippedTool = nil
            bridgeAutoPilotActive = false
            lastGodbridgeEndTime = tick()
        end
        if Window and Window.Notify and not Config.MineBehindHoldKey then
            Window:Notify({
                Title = "Infinite Bridge",
                Description = val and "Mining block behind with pickaxe & placing in front." or "Mine Behind, Place Front disabled.",
                Lifetime = 2
            })
        end
    end
}, "MineBehindPlaceFrontToggle")

farmLeft:Toggle({
    Name = "Hold Keybind Mode",
    Default = true,
    Callback = function(val)
        Config.MineBehindHoldKey = val
    end
}, "MineBehindHoldToggle")

farmLeft:Toggle({
    Name = "Bridge Auto-Pilot",
    Default = false,
    Keybind = "BridgeAutoPilot",
    Callback = function(val)
        toggleBridgeAutoPilot(val)
    end
}, "BridgeAutoPilotToggle")

farmLeft:Toggle({
    Name = "Auto Jump While Bridging",
    Default = true,
    Callback = function(val)
        Config.BridgeAutoJump = val
    end
}, "BridgeAutoJumpToggle")

farmLeft:Toggle({
    Name = "3x3 Front Tunnel Mining",
    Default = true,
    Callback = function(val)
        Config.BridgeTunnel3x3 = val
    end
}, "BridgeTunnel3x3Toggle")

farmLeft:Slider({
    Name = "Blocks Placed In Front",
    Default = 1,
    Minimum = 1,
    Maximum = 8,
    Precision = 0,
    Callback = function(val)
        Config.BridgeLookaheadBlocks = val
    end
}, "BridgeLookaheadSlider")

farmLeft:Slider({
    Name = "Blocks Mined Behind",
    Default = 5,
    Minimum = 1,
    Maximum = 10,
    Precision = 0,
    Callback = function(val)
        Config.BridgeMineBehindBlocks = val
    end
}, "BridgeMineBehindSlider")

farmLeft:Button({ Name = "Destroy Kill Blocks & Borders", Callback = function() pcall(function() Workspace.Lobby.KillPlates:Destroy() Workspace.Borders:Destroy() end) Window:Notify({ Title = "Cleared", Description = "Kill Plates & Borders removed.", Lifetime = 2 }) end })
farmLeft:Button({ 
    Name = "Rejoin Server (IY Rejoin)", 
    Keybind = "Rejoin",
    Callback = function() 
        Window:Notify({ Title = "Rejoining", Description = "Reconnecting to server...", Lifetime = 2 })
        rejoinGame() 
    end 
})

local farmRight = tabs.Skywars:Section({ Side = "Right", Title = "Mining Guidance" })
farmRight:Paragraph({
    Header = "Automation Guidance",
    Body = "• Auto Mine automatically focuses on and mines the closest collidable map block when you are holding your pickaxe.\n• Ore Auto Mine automatically locates and mines all rare ores in reach without needing to hold your pickaxe.\n• Mine Behind, Place Front builds an infinite bridge across the void by placing a block in front and mining the block behind.\n• 3x3 Front Tunnel Mining automatically bores a 3x3 tunnel through any walls, mountains or obstacle blocks ahead so your bridge continues uninterrupted."
})
end)() -- Skywars Tab

--------------------------------------------------------------------------------
-- MATCH RADAR TAB
--------------------------------------------------------------------------------
;(function()
local radarLeft = tabs.Radar:Section({ Side = "Left", Title = "Threat Scanner & Target Lock" })
local radarTargetParagraph = radarLeft:Paragraph({
    Header = "Nearest Threat Status",
    Body = "Scanning battlefield for enemies..."
})

radarLeft:Button({
    Name = "🎯 Lock Nearest Enemy as Target",
    Callback = function()
        local enemy, dist = getClosestEnemyInfo()
        if enemy then
            Config.TargetName = enemy.Name
            playSound("rbxassetid://9069609268", 0.7)
            Window:Notify({
                Title = "Target Locked",
                Description = string.format("Locked onto %s (%.0f studs)", enemy.DisplayName, dist),
                Lifetime = 3
            })
        else
            Window:Notify({ Title = "Radar", Description = "No active enemies found.", Lifetime = 2 })
        end
    end
})

radarLeft:Button({
    Name = "⚡ Teleport 15 Studs Above Nearest",
    Callback = function()
        local enemy, dist = getClosestEnemyInfo()
        local char = LocalPlayer.Character
        local root = getRoot(char)
        if enemy and enemy.Character and root then
            local enemyRoot = getRoot(enemy.Character)
            if enemyRoot then
                breakVelocity()
                root.CFrame = enemyRoot.CFrame * CFrame.new(0, 15, 0)
                breakVelocity()
                playSound("rbxassetid://9069609268", 0.6)
                Window:Notify({ Title = "Tactical Warp", Description = "Teleported 15 studs above " .. enemy.DisplayName, Lifetime = 2.5 })
            end
        else
            Window:Notify({ Title = "Radar", Description = "Target not reachable.", Lifetime = 2 })
        end
    end
})

radarLeft:Button({
    Name = "🌪️ Fling Nearest Enemy",
    Callback = function()
        local enemy = getClosestEnemyInfo()
        if enemy and enemy.Character then
            local enemyRoot = getRoot(enemy.Character)
            local root = getRoot(LocalPlayer.Character)
            if enemyRoot and root then
                setFling(true)
                local oldCf = root.CFrame
                task.spawn(function()
                    local start = tick()
                    while tick() - start < 0.6 do
                        if enemyRoot and enemyRoot.Parent then
                            root.CFrame = enemyRoot.CFrame * CFrame.new(0, 0, 0)
                        end
                        task.wait()
                    end
                    setFling(false)
                    root.CFrame = oldCf
                    breakVelocity()
                end)
                Window:Notify({ Title = "Combat", Description = "Flinging " .. enemy.DisplayName .. "!", Lifetime = 2 })
            end
        end
    end
})

local radarRight = tabs.Radar:Section({ Side = "Right", Title = "Lobby & Match Inspector" })
local matchInspectorParagraph = radarRight:Paragraph({
    Header = "Match Live Overview",
    Body = "Loading lobby analysis..."
})

radarRight:Button({
    Name = "🔄 Force Radar Rescan",
    Callback = function()
        playSound("rbxassetid://6895079853", 0.4)
        Window:Notify({ Title = "Match Radar", Description = "Radar scan refreshed.", Lifetime = 1.5 })
    end
})

safeSpawn(function()
    while isSuiteActive do
        task.wait(0.6)
        if not Window or not Window.ScreenGui or not Window.ScreenGui.Parent then break end
        pcall(function()
            local enemy, dist = getClosestEnemyInfo()
            if enemy and enemy.Character then
                local hum = enemy.Character:FindFirstChildOfClass("Humanoid")
                local hp = hum and math.floor(hum.Health) or 0
                local armor = scanPlayerArmor(enemy)
                local weapon = scanPlayerWeapon(enemy)
                local threatDesc = string.format("• Player: %s (@%s)\n• Distance: %d studs\n• Health: %d HP\n• Armor: %s\n• Weapon: %s",
                    enemy.DisplayName, enemy.Name, math.floor(dist), hp, armor, weapon)
                radarTargetParagraph:Set({ Header = "Nearest Threat Status", Body = threatDesc })
            else
                local emptyDesc = "• No enemy targets detected within active range.\n• You may be in the pre-game lobby or alone."
                radarTargetParagraph:Set({ Header = "Nearest Threat Status", Body = emptyDesc })
            end

            local total = #Players:GetPlayers()
            local inDangerZone = 0
            local bowThreats = 0
            local root = getRoot(LocalPlayer.Character)
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local hrp = getRoot(p.Character)
                    if hrp and root and (hrp.Position - root.Position).Magnitude <= 50 then
                        inDangerZone = inDangerZone + 1
                    end
                    local w = scanPlayerWeapon(p)
                    if string.find(string.lower(w), "bow") then
                        bowThreats = bowThreats + 1
                    end
                end
            end

            local overviewText = string.format("• Total Players in Server: %d\n• Threats within 50 studs: %d\n• Ranged Bow Threats: %d\n• Latency: %d ms",
                total, inDangerZone, bowThreats, getNetworkPing())
            matchInspectorParagraph:Set({ Header = "Match Live Overview", Body = overviewText })
        end)
    end
end)
end)() -- Radar Tab

--------------------------------------------------------------------------------
-- MOVEMENT TAB
--------------------------------------------------------------------------------
;(function()
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
    Callback = function(val) Config.SpeedEnabled = val if not val then local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") if h then h.WalkSpeed = 16 end end end 
}, "SpeedToggle")
moveLeft:Slider({ Name = "WalkSpeed", Default = 16, Minimum = 16, Maximum = 100, Precision = 0, Callback = function(val) Config.WalkSpeed = val end }, "WalkSpeedSlider")

moveLeft:Toggle({ 
    Name = "Enable JumpPower", 
    Default = false, 
    Keybind = "JumpToggle",
    Callback = function(val)
        Config.JumpEnabled = val
        local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then
            h.UseJumpPower = true
            h.JumpPower = val and (Config.JumpPower or 50) or 50
            local grav = workspace.Gravity > 0 and workspace.Gravity or 196.2
            h.JumpHeight = val and (((Config.JumpPower or 50) * (Config.JumpPower or 50)) / (2 * grav)) or 7.2
        end
    end 
}, "JumpModToggle")
moveLeft:Slider({
    Name = "JumpPower",
    Default = 50,
    Minimum = 50,
    Maximum = 250,
    Precision = 0,
    Callback = function(val)
        Config.JumpPower = val
        if Config.JumpEnabled then
            local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if h then
                h.UseJumpPower = true
                h.JumpPower = val
                local grav = workspace.Gravity > 0 and workspace.Gravity or 196.2
                h.JumpHeight = (val * val) / (2 * grav)
            end
        end
    end
}, "JumpPowerSlider")

local spinSection = tabs.Movement:Section({ Side = "Left", Title = "360 Spin Ability" })
spinSection:Button({ 
    Name = "360 Spin Ability", 
    Keybind = "SpinAbility",
    Callback = function() performCharacterSpin() end 
})
spinSection:Slider({
    Name = "Spin Speed",
    Default = 1,
    Minimum = 1,
    Maximum = 15,
    Precision = 1,
    Callback = function(val)
        Config.SpinAbilitySpeed = val
    end
}, "SpinAbilitySpeedSlider")

local moveRight = tabs.Movement:Section({ Side = "Right", Title = "Collision & Exploits" })
moveRight:Toggle({
    Name = "Anti-Fling", 
    Default = false,
    Keybind = "AntiFling",
    Callback = function(val) setAntiFling(val) Window:Notify({ Title = "Anti-Fling", Description = val and "Anti-Fling Enabled" or "Anti-Fling Disabled", Lifetime = 2 }) end
}, "AntiFlingToggle")

moveRight:Toggle({ 
    Name = "Noclip", 
    Default = false, 
    Keybind = "Noclip",
    Callback = function(val) setNoclip(val) end 
}, "NoclipToggle")

moveRight:Toggle({ 
    Name = "Infinite Jump", 
    Default = false, 
    Keybind = "InfiniteJump",
    Callback = function(val) setInfiniteJump(val) end 
}, "InfJumpToggle")

moveRight:Toggle({ 
    Name = "CTRL + Click TP", 
    Default = false, 
    Keybind = "CtrlTP",
    Callback = function(val) toggleCtrlTP(val) end 
}, "CtrlTpToggle")

moveRight:Button({ Name = "Give TP Tool", Callback = function() giveTpTool() Window:Notify({ Title = "Inventory", Description = "TP Tool added to backpack!", Lifetime = 2.5 }) end })

moveRight:Toggle({ 
    Name = "Fling Aura", 
    Default = false, 
    Keybind = "Fling",
    Callback = function(val) setFling(val) end 
}, "FlingToggle")

moveRight:Header({ Text = "Safe-TP Platform" })
SafeTPToggleObj = moveRight:Toggle({
    Name = "Safe-TP Platform",
    Default = false,
    Keybind = "SafeTP",
    Callback = function(val)
        toggleSafeTP(val)
        Window:Notify({
            Title = "Safe-TP Platform",
            Description = val and "Teleported to Safe Platform!" or "Returned to Previous Position.",
            Lifetime = 2
        })
    end
}, "SafeTPToggle")

moveRight:Slider({
    Name = "Safe-TP Height",
    Default = 1500,
    Minimum = 200,
    Maximum = 5000,
    Precision = 0,
    Callback = function(val)
        Config.SafeTPHeight = val
    end
}, "SafeTPHeightSlider")
end)() -- Movement Tab

--------------------------------------------------------------------------------
-- TROLL & FUN TAB
--------------------------------------------------------------------------------
;(function()
local trollLeft = tabs.Trolling:Section({ Side = "Left", Title = "Target Selector & Trolls" })
local PlayerDropdown = nil
pcall(function()
    PlayerDropdown = trollLeft:Dropdown({
        Name = "Select Target Player",
        Multi = false,
        Options = getPlayerNamesList(),
        Default = "None",
        Callback = function(val)
            if val and val ~= "None" then
                Config.TargetName = val
                Window:Notify({ Title = "Target Selected", Description = "Locked onto " .. val, Lifetime = 2 })
            end
        end
    }, "PlayerTargetDropdown")
end)

trollLeft:Button({
    Name = "Refresh Player List",
    Callback = function()
        local updatedList = getPlayerNamesList()
        if PlayerDropdown then
            pcall(function() PlayerDropdown:SetOptions(updatedList) end)
        end
        Window:Notify({ Title = "Players Refreshed", Description = "Found " .. tostring(#updatedList) .. " player(s).", Lifetime = 2 })
    end,
})

trollLeft:Header({ Text = "Action Trolls" })
trollLeft:Toggle({
    Name = "Enable Bang", 
    Default = false,
    Keybind = "Bang",
    Callback = function(val)
        if val then
            local target = getPlayerByName(Config.TargetName)
            if target then
                startBang(target)
                Window:Notify({ Title = "Bang", Description = "Attached to " .. target.DisplayName, Lifetime = 2 })
            else
                Window:Notify({ Title = "Target Missing", Description = "Select a target player from the dropdown first.", Lifetime = 2.5 })
            end
        else
            stopBang()
        end
    end,
}, "BangToggle")

trollLeft:Slider({
    Name = "Bang Speed", Default = 3, Minimum = 1, Maximum = 25, Precision = 1,
    Callback = function(val)
        Config.BangSpeed = val
        if bangAnimTrack then bangAnimTrack:AdjustSpeed(val) end
    end,
}, "BangSpeedSlider")

trollLeft:Toggle({
    Name = "Enable Carpet", 
    Default = false,
    Keybind = "Carpet",
    Callback = function(val)
        if val then
            local target = getPlayerByName(Config.TargetName)
            if target then
                startCarpet(target)
                Window:Notify({ Title = "Carpet", Description = "Laying under " .. target.DisplayName, Lifetime = 2 })
            else
                Window:Notify({ Title = "Target Missing", Description = "Select a target player from the dropdown first.", Lifetime = 2.5 })
            end
        else
            stopCarpet()
        end
    end,
}, "CarpetToggle")

local trollRight = tabs.Trolling:Section({ Side = "Right", Title = "External Loadstrings" })
trollRight:Button({ Name = "Universal Vehicle Fly", Callback = function() loadstring(game:HttpGet(('https://raw.githubusercontent.com/zachisfunny/Universal-Vehicle-Fly/main/Script'),true))() end })
trollRight:Button({ Name = "Universal Reach Script", Callback = function() loadstring(game:HttpGet(('https://raw.githubusercontent.com/zachisfunny/Universal-Reach/main/Reach%20Script'),true))() end })
trollRight:Button({ Name = "Attach To Back Script", Callback = function() loadstring(game:HttpGet(('https://raw.githubusercontent.com/zachisfunny/Attach-to-back-Script/main/Script'),true))() end })
end)() -- Troll Tab

--------------------------------------------------------------------------------
-- VISUALS TAB
--------------------------------------------------------------------------------
;(function()
local visLeft = tabs.Visuals:Section({ Side = "Left", Title = "Player ESP & Custom Themes" })

visLeft:Header({ Text = "Master Controls" })
visLeft:Toggle({ 
    Name = "Master Visuals Switch", 
    Default = false, 
    Keybind = "Visuals",
    Callback = function(val) Config.VisualsEnabled = val if not val then hideAllVisuals() end end 
}, "ESPMasterToggle")

visLeft:Dropdown({
    Name = "ESP Color Theme",
    Options = {"Neon Cyan", "Amethyst Purple", "Sakura Pink", "Emerald Matrix", "Sunset Orange", "Ghost White", "Blood Red"},
    Default = "Neon Cyan",
    Callback = function(val)
        Config.ESPColorTheme = val
        if VisualPresets[val] then
            Config.HighlightColor = VisualPresets[val]
            Config.TracerColor = VisualPresets[val]
        end
    end
}, "ESPThemeDropdown")

visLeft:Toggle({
    Name = "Rainbow Chroma Wave (Animated)",
    Default = false,
    Callback = function(val) Config.RainbowChroma = val end
}, "RainbowChromaToggle")

visLeft:Toggle({
    Name = "Dynamic Health Colors (G/Y/R)",
    Default = false,
    Callback = function(val) Config.DynamicHealthColor = val end
}, "HealthColorsToggle")

visLeft:Header({ Text = "Chams & Highlights" })
visLeft:Toggle({ Name = "Chams / Highlights", Default = true, Callback = function(val) Config.HighlightsEnabled = val end }, "ChamsToggle")
visLeft:Dropdown({
    Name = "Cham Style",
    Options = {"Outline Glow Only", "Solid Fill", "Ghost / Pulse", "Wireframe / Hologram"},
    Default = "Outline Glow Only",
    Callback = function(val) Config.ChamStyle = val end
}, "ChamStyleDropdown")

visLeft:Header({ Text = "Tracers & Tags" })
visLeft:Toggle({ Name = "Snapline Tracers", Default = true, Callback = function(val) Config.TracersEnabled = val end }, "TracersToggle")
visLeft:Dropdown({
    Name = "Tracer Origin",
    Options = {"Bottom of Screen", "Center Crosshair", "Top of Screen"},
    Default = "Bottom of Screen",
    Callback = function(val) Config.TracerOrigin = val end
}, "TracerOriginDropdown")

visLeft:Toggle({ Name = "3D Floating Tags", Default = true, Callback = function(val) Config.TagsEnabled = val end }, "TagsToggle")
visLeft:Toggle({ Name = "Show Held Weapon in Tags", Default = true, Callback = function(val) Config.ShowWeaponInTags = val end }, "WeaponInTagsToggle")
visLeft:Slider({ Name = "Max ESP Distance", Default = 1200, Minimum = 100, Maximum = 2500, Precision = 0, Callback = function(val) Config.MaxVisualDistance = val end }, "MaxESPDistSlider")

local visRight = tabs.Visuals:Section({ Side = "Right", Title = "World FX & Character Aesthetics" })

visRight:Header({ Text = "Camera & FOV" })
visRight:Slider({
    Name = "Field of View (FOV)",
    Default = 70,
    Minimum = 70,
    Maximum = 120,
    Precision = 0,
    Callback = function(val)
        Config.FieldOfView = val
        if Camera then Camera.FieldOfView = val end
    end
}, "FOVSlider")

visRight:Header({ Text = "Lighting & Atmosphere" })
visRight:Toggle({
    Name = "Fullbright (Void Vision)",
    Default = false,
    Callback = function(val) applyFullbright(val) end
}, "FullbrightToggle")

visRight:Dropdown({
    Name = "Atmosphere Sky Preset",
    Options = {"Default Sky", "Midnight Cyber", "Vaporwave Purple", "Sunset Golden Hour", "Minecraft Retro"},
    Default = "Default Sky",
    Callback = function(val) applyAtmosphereTheme(val) end
}, "AtmosphereDropdown")

visRight:Toggle({ 
    Name = "Minecraft Graphics (Retro Shaders)", 
    Default = false, 
    Keybind = "Graphics",
    Callback = function(val) applyMinecraftGraphics(val) end 
}, "ShaderToggle")

visRight:Header({ Text = "Self Aesthetics" })
visRight:Toggle({
    Name = "Self Character Glow (Chams)",
    Default = false,
    Callback = function(val)
        Config.SelfChamsEnabled = val
        updateSelfHighlight()
    end
}, "SelfChamsToggle")

visRight:Toggle({
    Name = "Self Rainbow Chroma Aura",
    Default = false,
    Callback = function(val)
        Config.SelfRainbowAura = val
        updateSelfHighlight()
    end
}, "SelfRainbowToggle")

visRight:Paragraph({
    Header = "Visual Guidance",
    Body = "• Outline Glow Only gives competitive clean player outlines without screen obstruction.\n• Rainbow Chroma smoothly shifts colors in real-time across ESP and self aura.\n• Dynamic Health Colors displays green, yellow, or red based on enemy HP.\n• Fullbright removes all void fog and dark lighting so you can spot players anywhere."
})
end)() -- Visuals Tab

--------------------------------------------------------------------------------
-- INFINITE YIELD TAB (ALL TOOLS WITH ON/OFF TOGGLES)
--------------------------------------------------------------------------------
;(function()
local iyLeft = tabs.InfiniteYield:Section({ Side = "Left", Title = "Tool Spawners & Inventory Controls" })

iyLeft:Header({ Text = "Tool Spawners" })
iyLeft:Toggle({
    Name = "Teleport Tool (TP Tool)",
    Default = false,
    Keybind = "IY_TPTool",
    Callback = function(val)
        IY.toggleTeleportTool(val)
    end
}, "IYTPToolToggle")

iyLeft:Toggle({
    Name = "Classic BTools (HopperBins)",
    Default = false,
    Keybind = "IY_BTools",
    Callback = function(val)
        IY.toggleBTools(val)
    end
}, "IYBToolsToggle")

iyLeft:Toggle({
    Name = "F3X Building Tool",
    Default = false,
    Callback = function(val)
        IY.toggleF3X(val)
    end
}, "IYF3XToggle")

iyLeft:Toggle({
    Name = "Equippable Delete Tool",
    Default = false,
    Callback = function(val)
        IY.toggleSpawnDeleteTool(val)
    end
}, "IYSpawnDeleteToolToggle")

iyLeft:Toggle({
    Name = "Equippable Explode Tool",
    Default = false,
    Callback = function(val)
        IY.toggleSpawnExplodeTool(val)
    end
}, "IYSpawnExplodeToolToggle")

iyLeft:Header({ Text = "Inventory & Item Automation" })
iyLeft:Button({
    Name = "Bring All Dropped Tools",
    Callback = function()
        IY.bringAllTools()
    end
})

iyLeft:Toggle({
    Name = "Auto Grab Dropped Tools",
    Default = false,
    Callback = function(val)
        IY.toggleGrabTools(val)
    end
}, "IYGrabToolsToggle")

iyLeft:Toggle({
    Name = "Copy Game Tools (Storage)",
    Default = false,
    Callback = function(val)
        IY.toggleCopyGameTools(val)
    end
}, "IYCopyToolsToggle")

iyLeft:Toggle({
    Name = "Force Droppable Tools",
    Default = false,
    Callback = function(val)
        IY.toggleDroppableTools(val)
    end
}, "IYDroppableToolsToggle")

iyLeft:Toggle({
    Name = "Equip All Tools (Multi-Equip)",
    Default = false,
    Callback = function(val)
        IY.toggleEquipAllTools(val)
    end
}, "IYEquipAllToggle")

iyLeft:Toggle({
    Name = "Auto Tool Spam (Use Tools)",
    Default = false,
    Callback = function(val)
        IY.toggleUseTools(val)
    end
}, "IYUseToolsToggle")

iyLeft:Toggle({
    Name = "Duplicate Inventory Tools",
    Default = false,
    Callback = function(val)
        IY.toggleDuplicateTools(val)
    end
}, "IYDuplicateToolsToggle")

iyLeft:Toggle({
    Name = "Clear All Tools (Purge)",
    Default = false,
    Callback = function(val)
        IY.toggleClearTools(val)
    end
}, "IYClearToolsToggle")


local iyRight = tabs.InfiniteYield:Section({ Side = "Right", Title = "Tool Modifiers, Hitboxes & Mouse" })

iyRight:Header({ Text = "Mouse Click Tools" })
iyRight:Toggle({
    Name = "Click Teleport (Click TP)",
    Default = false,
    Keybind = "IY_ClickTP",
    Callback = function(val)
        IY.toggleClickTP(val)
    end
}, "IYClickTPToggle")

iyRight:Toggle({
    Name = "Click Delete (Click Del)",
    Default = false,
    Keybind = "IY_ClickDelete",
    Callback = function(val)
        IY.toggleClickDelete(val)
    end
}, "IYClickDeleteToggle")

iyRight:Toggle({
    Name = "Click Fling Player",
    Default = false,
    Keybind = "IY_ClickFling",
    Callback = function(val)
        IY.toggleClickFling(val)
    end
}, "IYClickFlingToggle")

iyRight:Header({ Text = "Tool Hitbox & Combat Reach" })
iyRight:Toggle({
    Name = "Tool Reach Expander",
    Default = false,
    Callback = function(val)
        IY.toggleToolReach(val)
    end
}, "IYToolReachToggle")

iyRight:Slider({
    Name = "Tool Reach Distance",
    Default = 30,
    Minimum = 5,
    Maximum = 150,
    Precision = 0,
    Callback = function(val)
        Config.IY_ToolReachSize = val
        if Config.IY_ToolReach then
            IY.toggleToolReach(true)
        end
    end
}, "IYToolReachSlider")

iyRight:Toggle({
    Name = "3D Cube Box Reach",
    Default = false,
    Callback = function(val)
        IY.toggleBoxReach(val)
    end
}, "IYBoxReachToggle")

iyRight:Slider({
    Name = "3D Box Reach Size",
    Default = 30,
    Minimum = 5,
    Maximum = 150,
    Precision = 0,
    Callback = function(val)
        Config.IY_BoxReachSize = val
        if Config.IY_BoxReach then
            IY.toggleBoxReach(true)
        end
    end
}, "IYBoxReachSlider")

iyRight:Toggle({
    Name = "Tool Kill Aura",
    Default = false,
    Keybind = "IY_ToolAura",
    Callback = function(val)
        IY.toggleToolAura(val)
    end
}, "IYToolAuraToggle")

iyRight:Slider({
    Name = "Kill Aura Range",
    Default = 25,
    Minimum = 5,
    Maximum = 75,
    Precision = 0,
    Callback = function(val)
        Config.IY_ToolAuraRange = val
    end
}, "IYAuraRangeSlider")

iyRight:Toggle({
    Name = "Handle Touch Kill (Handle Kill)",
    Default = false,
    Callback = function(val)
        IY.toggleHandleKill(val)
    end
}, "IYHandleKillToggle")

iyRight:Header({ Text = "Character, Physics & Vision Glitches" })
iyRight:Toggle({
    Name = "Blockify Tool Mesh",
    Default = false,
    Callback = function(val)
        IY.toggleBlockTool(val)
    end
}, "IYBlockToolToggle")

iyRight:Toggle({
    Name = "Spinbot (Character Spin)",
    Default = false,
    Keybind = "IY_Spin",
    Callback = function(val)
        IY.toggleSpin(val)
    end
}, "IYSpinToggle")

iyRight:Slider({
    Name = "Spin Speed",
    Default = 30,
    Minimum = 5,
    Maximum = 100,
    Precision = 0,
    Callback = function(val)
        Config.IY_SpinSpeed = val
    end
}, "IYSpinSpeedSlider")

iyRight:Toggle({
    Name = "Floating Platform (Float)",
    Default = false,
    Keybind = "IY_Float",
    Callback = function(val)
        IY.toggleFloat(val)
    end
}, "IYFloatToggle")

iyRight:Toggle({
    Name = "Airwalk (Walk on Air)",
    Default = false,
    Callback = function(val)
        IY.toggleAirwalk(val)
    end
}, "IYAirwalkToggle")

iyRight:Toggle({
    Name = "Jesus Mode (Water Walk)",
    Default = false,
    Callback = function(val)
        IY.toggleJesus(val)
    end
}, "IYJesusToggle")

iyRight:Toggle({
    Name = "Fullbright (Max Lighting)",
    Default = false,
    Callback = function(val)
        IY.toggleFullbright(val)
    end
}, "IYFullbrightToggle")

iyRight:Toggle({
    Name = "X-Ray Vision (Wallhack)",
    Default = false,
    Callback = function(val)
        IY.toggleXRay(val)
    end
}, "IYXRayToggle")

iyRight:Toggle({
    Name = "Anti-Void (Void Rescue)",
    Default = false,
    Callback = function(val)
        IY.toggleAntiVoid(val)
    end
}, "IYAntiVoidToggle")

iyRight:Toggle({
    Name = "Anti-Sit (Disable Seated)",
    Default = false,
    Callback = function(val)
        IY.toggleAntiSit(val)
    end
}, "IYAntiSitToggle")

iyRight:Toggle({
    Name = "Low Gravity Mode",
    Default = false,
    Callback = function(val)
        IY.toggleLowGravity(val)
    end
}, "IYLowGravityToggle")

iyRight:Slider({
    Name = "Custom Gravity",
    Default = 45,
    Minimum = 0,
    Maximum = 196,
    Precision = 0,
    Callback = function(val)
        Config.IY_GravityValue = val
        if Config.IY_LowGravity then
            IY.toggleLowGravity(true)
        end
    end
}, "IYGravitySlider")

iyRight:Header({ Text = "Cinematic Freecam (Spectate-TP)" })
iyRight:Toggle({
    Name = "Freecam (Spectate-TP)",
    Default = false,
    Keybind = "IY_Freecam",
    Callback = function(val)
        IY.toggleFreecam(val)
    end
}, "IYFreecamToggle")

iyRight:Toggle({
    Name = "Teleport on Deactivate",
    Default = true,
    Callback = function(val)
        Config.IY_FreecamTP = val
    end
}, "IYFreecamTPToggle")

iyRight:Button({
    Name = "Teleport to Camera Now",
    Callback = function()
        IY.teleportToFreecam()
    end
})

iyRight:Slider({
    Name = "Freecam Speed",
    Default = 1.5,
    Minimum = 0.5,
    Maximum = 10,
    Precision = 1,
    Callback = function(val)
        Config.IY_FreecamSpeed = val
    end
}, "IYFreecamSpeedSlider")
end)() -- Infinite Yield Tab

--------------------------------------------------------------------------------
-- KEYBINDS TAB (Universal Keybind Hub & Live Search)
--------------------------------------------------------------------------------
;(function()
local MASTER_KEYBIND_ITEMS = {
    -- Combat & Offense
    { Key = "Bypass", Name = "Security / Anti-Cheat Bypass", Category = "Combat", Desc = "Toggles Hanki bypass & wall interaction" },
    { Key = "Reach", Name = "Sword Reach Expander", Category = "Combat", Desc = "Expands sword hit distance" },
    { Key = "Hitbox", Name = "Hitbox Expander", Category = "Combat", Desc = "Enlarges opponent character hitboxes" },
    { Key = "Clicker", Name = "Auto Clicker", Category = "Combat", Desc = "Simulates high-speed left mouse clicks" },
    { Key = "FastBow", Name = "High-Ping Fast Bow", Category = "Combat", Desc = "Rapid burst arrow velocity & fire rate" },
    { Key = "SilentAimToggle", Name = "Silent Aim (AimLock)", Category = "Combat", Desc = "Directs arrows/sword hits to nearest target" },
    { Key = "CombatFace", Name = "Auto-Face Target", Category = "Combat", Desc = "Faces nearest opponent" },
    { Key = "BackgroundBow", Name = "Shoot Bow Without Holding", Category = "Combat", Desc = "Shoots arrows from backpack without equipping bow" },

    -- Skywars & Farming
    { Key = "AutoMine", Name = "Auto Mine", Category = "Skywars", Desc = "Fast block break when holding pickaxe" },
    { Key = "OreAutoMine", Name = "Ore Auto Mine", Category = "Skywars", Desc = "Auto-targets and mines nearby ores" },
    { Key = "MinePlaceFront", Name = "Mine Behind, Place Front", Category = "Skywars", Desc = "Mines rear block and bridges forward" },
    { Key = "BridgeAutoPilot", Name = "Bridge Auto-Pilot", Category = "Skywars", Desc = "Hands-free continuous godbridging cruise" },
    { Key = "SafeTP", Name = "Safe Island TP", Category = "Skywars", Desc = "Teleports to safe platform above void" },
    { Key = "Rejoin", Name = "Rejoin Server", Category = "Skywars", Desc = "Rejoins current place instance" },

    -- Movement & Locomotion
    { Key = "Fly", Name = "Flight Mode", Category = "Movement", Desc = "True physics fly with directional velocity" },
    { Key = "SpeedToggle", Name = "WalkSpeed Assist", Category = "Movement", Desc = "Toggles custom walkspeed multiplier" },
    { Key = "JumpToggle", Name = "JumpPower Assist", Category = "Movement", Desc = "Toggles high jump & upward assist" },
    { Key = "InfiniteJump", Name = "Infinite Jump", Category = "Movement", Desc = "Allows continuous mid-air jumping" },
    { Key = "SpinAbility", Name = "360 Spin Ability", Category = "Movement", Desc = "High-velocity rotation defensive spin" },
    { Key = "AntiFling", Name = "Anti-Fling Shield", Category = "Movement", Desc = "Zeros collision physics against troll flings" },
    { Key = "Noclip", Name = "Noclip Collision", Category = "Movement", Desc = "Phases through all map walls & blocks" },
    { Key = "CtrlTP", Name = "CTRL + Click TP", Category = "Movement", Desc = "Teleports player to clicked location" },
    { Key = "Fling", Name = "Player Fling", Category = "Movement", Desc = "Flings colliding targets into the void" },

    -- Visuals & ESP
    { Key = "Visuals", Name = "Master Visuals Switch", Category = "Visuals", Desc = "Toggles all ESP, chams, and tags" },
    { Key = "Highlights", Name = "Chams / Highlights ESP", Category = "Visuals", Desc = "Silhouetted player chams through walls" },
    { Key = "Tracers", Name = "Snapline Tracers", Category = "Visuals", Desc = "Draws distance lines to all enemies" },
    { Key = "Tags", Name = "3D Floating Billboard Tags", Category = "Visuals", Desc = "Shows health, distance, and held weapon" },
    { Key = "Fullbright", Name = "Fullbright (Void Vision)", Category = "Visuals", Desc = "Max ambient brightness in dark maps" },
    { Key = "Graphics", Name = "Minecraft Retro Shaders", Category = "Visuals", Desc = "Nostalgic pixelated texture graphics" },
    { Key = "SelfChams", Name = "Self Character Glow", Category = "Visuals", Desc = "Highlights your local character model" },

    -- Infinite Yield & Utilities
    { Key = "IY_ClickTP", Name = "Click Teleport (Tool)", Category = "Infinite Yield", Desc = "Equip and click anywhere to teleport" },
    { Key = "IY_ClickDelete", Name = "Click Delete (Tool)", Category = "Infinite Yield", Desc = "Equip and click blocks to delete them" },
    { Key = "IY_ClickFling", Name = "Click Fling (Tool)", Category = "Infinite Yield", Desc = "Equip and click enemies to fling them" },
    { Key = "IY_ToolAura", Name = "Tool Hitbox Aura", Category = "Infinite Yield", Desc = "Attacks all nearby enemies in radius" },
    { Key = "IY_Float", Name = "Air Float Platform", Category = "Infinite Yield", Desc = "Invisible platform under feet to float" },
    { Key = "IY_Spin", Name = "IY Continuous Spin", Category = "Infinite Yield", Desc = "Continuous body rotation spinner" },
    { Key = "IY_Freecam", Name = "Cinematic Freecam", Category = "Infinite Yield", Desc = "Detaches camera with teleport option" },
    { Key = "IY_BTools", Name = "Spawn Building Tools", Category = "Infinite Yield", Desc = "Adds BTools (Move, Delete) to backpack" },
    { Key = "IY_TPTool", Name = "Spawn Teleport Tool", Category = "Infinite Yield", Desc = "Adds permanent teleport tool to inventory" },
    { Key = "Bang", Name = "Bang Target Troll", Category = "Trolling", Desc = "Troll animation attachment onto target" },
    { Key = "Carpet", Name = "Magic Carpet Troll", Category = "Trolling", Desc = "Troll carpet attachment underneath target" }
}

for _, item in ipairs(MASTER_KEYBIND_ITEMS) do
    if Config.Keybinds[item.Key] == nil then
        Config.Keybinds[item.Key] = nil
    end
end

local kbControlSection = tabs.Keybinds:Section({ Side = "Left", Title = "Keybind Hub & Live Search" })

local searchContainer = Instance.new("Frame", kbControlSection.Box)
searchContainer.Size = UDim2.new(1, 0, 0, 30)
searchContainer.BackgroundColor3 = THEME.WidgetBg
searchContainer.BorderSizePixel = 0
Instance.new("UICorner", searchContainer).CornerRadius = UDim.new(0, 3)
local scStroke = Instance.new("UIStroke", searchContainer)
scStroke.Color = THEME.WidgetBorder
scStroke.Thickness = 1

local searchIcon = Instance.new("TextLabel", searchContainer)
searchIcon.Size = UDim2.new(0, 24, 1, 0)
searchIcon.Position = UDim2.new(0, 4, 0, 0)
searchIcon.BackgroundTransparency = 1
searchIcon.Font = Enum.Font.GothamBold
searchIcon.TextSize = 12
searchIcon.TextColor3 = THEME.TextDim
searchIcon.Text = "🔍"

local searchInput = Instance.new("TextBox", searchContainer)
searchInput.Size = UDim2.new(1, -54, 1, 0)
searchInput.Position = UDim2.new(0, 26, 0, 0)
searchInput.BackgroundTransparency = 1
searchInput.Font = Enum.Font.GothamMedium
searchInput.TextSize = 11
searchInput.TextColor3 = THEME.TextPrimary
searchInput.PlaceholderText = "Search by feature, key [E, M2], or category..."
searchInput.PlaceholderColor3 = THEME.TextMuted
searchInput.ClearTextOnFocus = false
searchInput.Text = ""

local clearSearchBtn = Instance.new("TextButton", searchContainer)
clearSearchBtn.Size = UDim2.new(0, 20, 0, 20)
clearSearchBtn.Position = UDim2.new(1, -24, 0.5, -10)
clearSearchBtn.BackgroundTransparency = 1
clearSearchBtn.Font = Enum.Font.GothamBold
clearSearchBtn.TextSize = 11
clearSearchBtn.TextColor3 = THEME.TextDim
clearSearchBtn.Text = "✕"
clearSearchBtn.Visible = false

local catFilterFrame = Instance.new("Frame", kbControlSection.Box)
catFilterFrame.Size = UDim2.new(1, 0, 0, 22)
catFilterFrame.BackgroundTransparency = 1
local catLayout = Instance.new("UIListLayout", catFilterFrame)
catLayout.FillDirection = Enum.FillDirection.Horizontal
catLayout.Padding = UDim.new(0, 4)

local activeCategoryFilter = "All"
local activeSearchQuery = ""
local categoryButtons = {}
local categories = { "All", "Combat", "Skywars", "Movement", "Visuals", "Infinite Yield" }

local countLabel = Instance.new("TextLabel", kbControlSection.Box)
countLabel.Size = UDim2.new(1, 0, 0, 16)
countLabel.BackgroundTransparency = 1
countLabel.Font = Enum.Font.Gotham
countLabel.TextSize = 10
countLabel.TextColor3 = THEME.TextDim
countLabel.TextXAlignment = Enum.TextXAlignment.Left
countLabel.Text = "Showing " .. tostring(#MASTER_KEYBIND_ITEMS) .. " / " .. tostring(#MASTER_KEYBIND_ITEMS) .. " keybinds"

local registeredRowFrames = {}
local entrySections = {}

local function refreshKeybindFilter()
    local visibleCount = 0
    local q = string.lower(string.gsub(activeSearchQuery, "^%s*(.-)%s*$", "%1"))
    clearSearchBtn.Visible = (q ~= "")

    for _, entry in ipairs(registeredRowFrames) do
        local item = entry.Item
        local row = entry.Row
        local keyName = getKeyName(Config.Keybinds[item.Key])

        local matchesSearch = true
        if q ~= "" then
            matchesSearch = string.find(string.lower(item.Name), q, 1, true) or
                            string.find(string.lower(item.Category), q, 1, true) or
                            string.find(string.lower(item.Desc or ""), q, 1, true) or
                            string.find(string.lower(item.Key), q, 1, true) or
                            string.find(string.lower(keyName), q, 1, true) or
                            string.find(string.lower("[" .. keyName .. "]"), q, 1, true)
        end

        local matchesCat = (activeCategoryFilter == "All") or (item.Category == activeCategoryFilter)

        local isVisible = matchesSearch and matchesCat
        row.Visible = isVisible
        if isVisible then
            visibleCount = visibleCount + 1
        end
    end

    countLabel.Text = "Showing " .. tostring(visibleCount) .. " / " .. tostring(#MASTER_KEYBIND_ITEMS) .. " keybinds"
    
    for _, sec in ipairs(entrySections) do
        if sec and sec.UpdateSize then sec:UpdateSize() end
    end
end

for _, cat in ipairs(categories) do
    local btn = Instance.new("TextButton", catFilterFrame)
    btn.Size = UDim2.new(0, 0, 1, 0)
    btn.AutomaticSize = Enum.AutomaticSize.X
    local pad = Instance.new("UIPadding", btn)
    pad.PaddingLeft = UDim.new(0, 6)
    pad.PaddingRight = UDim.new(0, 6)
    btn.BackgroundColor3 = (cat == "All") and THEME.AccentRed or THEME.WidgetBg
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 10
    btn.TextColor3 = (cat == "All") and THEME.White or THEME.TextDim
    btn.Text = cat
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 2)
    local bStroke = Instance.new("UIStroke", btn)
    bStroke.Color = (cat == "All") and THEME.AccentRed or THEME.WidgetBorder
    bStroke.Thickness = 1

    categoryButtons[cat] = btn

    btn.MouseButton1Click:Connect(function()
        activeCategoryFilter = cat
        for cName, cBtn in pairs(categoryButtons) do
            local isSel = (cName == activeCategoryFilter)
            cBtn.BackgroundColor3 = isSel and THEME.AccentRed or THEME.WidgetBg
            cBtn.TextColor3 = isSel and THEME.White or THEME.TextDim
            local st = cBtn:FindFirstChildOfClass("UIStroke")
            if st then st.Color = isSel and THEME.AccentRed or THEME.WidgetBorder end
        end
        refreshKeybindFilter()
    end)
end

searchInput:GetPropertyChangedSignal("Text"):Connect(function()
    activeSearchQuery = searchInput.Text
    refreshKeybindFilter()
end)

clearSearchBtn.MouseButton1Click:Connect(function()
    searchInput.Text = ""
    activeSearchQuery = ""
    refreshKeybindFilter()
end)

kbControlSection:Button({
    Name = "❌ Clear All Keybinds (Reset to None)",
    Callback = function()
        for _, item in ipairs(MASTER_KEYBIND_ITEMS) do
            Config.Keybinds[item.Key] = nil
            syncKeybindBadges(item.Key)
        end
        if saveConfigDebounced then saveConfigDebounced() end
        Window:Notify({ Title = "Keybinds Cleared", Description = "All keybinds have been set to [None].", Lifetime = 2 })
        refreshKeybindFilter()
    end
})

kbControlSection:Button({
    Name = "💾 Save Keybinds to Profile",
    Callback = function()
        if savePlayerConfig then savePlayerConfig() end
        Window:Notify({ Title = "Keybinds Saved", Description = "Keybind profile successfully saved to disk!", Lifetime = 2 })
    end
})

local kbCombatSec = tabs.Keybinds:Section({ Side = "Left", Title = "Combat & Targeting" })
local kbSkywarsSec = tabs.Keybinds:Section({ Side = "Left", Title = "Skywars & Farming" })
local kbMoveSec = tabs.Keybinds:Section({ Side = "Right", Title = "Movement & Locomotion" })
local kbVisSec = tabs.Keybinds:Section({ Side = "Right", Title = "Visuals & Aesthetics" })
local kbIySec = tabs.Keybinds:Section({ Side = "Right", Title = "Infinite Yield & Misc" })

table.insert(entrySections, kbControlSection)
table.insert(entrySections, kbCombatSec)
table.insert(entrySections, kbSkywarsSec)
table.insert(entrySections, kbMoveSec)
table.insert(entrySections, kbVisSec)
table.insert(entrySections, kbIySec)

local function createKeybindRow(sec, item)
    local box = sec.Box
    local row = Instance.new("Frame", box)
    row.Name = "KBRow_" .. item.Key
    row.Size = UDim2.new(1, 0, 0, 32)
    row.BackgroundColor3 = THEME.WidgetBg
    row.BackgroundTransparency = 0.4
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 3)
    local rStroke = Instance.new("UIStroke", row)
    rStroke.Color = THEME.WidgetBorder
    rStroke.Thickness = 1

    local nameLabel = Instance.new("TextLabel", row)
    nameLabel.Size = UDim2.new(1, -112, 0, 16)
    nameLabel.Position = UDim2.new(0, 8, 0, 2)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamMedium
    nameLabel.TextSize = 11
    nameLabel.TextColor3 = THEME.TextPrimary
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Text = item.Name

    local descLabel = Instance.new("TextLabel", row)
    descLabel.Size = UDim2.new(1, -112, 0, 12)
    descLabel.Position = UDim2.new(0, 8, 0, 17)
    descLabel.BackgroundTransparency = 1
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 9
    descLabel.TextColor3 = THEME.TextMuted
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Text = item.Desc or item.Category

    local testBtn = Instance.new("TextButton", row)
    testBtn.Size = UDim2.new(0, 42, 0, 20)
    testBtn.Position = UDim2.new(1, -100, 0.5, -10)
    testBtn.BackgroundColor3 = THEME.GroupboxBg
    testBtn.Font = Enum.Font.GothamBold
    testBtn.TextSize = 9
    testBtn.TextColor3 = THEME.TextDim
    testBtn.Text = "Trigger"
    Instance.new("UICorner", testBtn).CornerRadius = UDim.new(0, 2)
    local tbStroke = Instance.new("UIStroke", testBtn)
    tbStroke.Color = THEME.WidgetBorder
    tbStroke.Thickness = 1

    testBtn.MouseEnter:Connect(function()
        testBtn.BackgroundColor3 = THEME.WidgetHover
        testBtn.TextColor3 = THEME.TextPrimary
    end)
    testBtn.MouseLeave:Connect(function()
        testBtn.BackgroundColor3 = THEME.GroupboxBg
        testBtn.TextColor3 = THEME.TextDim
    end)
    testBtn.MouseButton1Click:Connect(function()
        testBtn.BackgroundColor3 = THEME.AccentRed
        task.delay(0.12, function()
            pcall(function() testBtn.BackgroundColor3 = THEME.GroupboxBg end)
        end)
        triggerOption(item.Key)
    end)

    local curKey = Config.Keybinds[item.Key]
    local bindBadge = Instance.new("TextButton", row)
    bindBadge.Name = "KeybindBadge_" .. item.Key
    bindBadge.Size = UDim2.new(0, 52, 0, 20)
    bindBadge.Position = UDim2.new(1, -54, 0.5, -10)
    bindBadge.BackgroundColor3 = THEME.GroupboxBg
    bindBadge.Font = Enum.Font.Code
    bindBadge.TextSize = 10
    bindBadge.TextColor3 = curKey and THEME.TextPrimary or THEME.TextDim
    bindBadge.Text = "[" .. getKeyName(curKey) .. "]"
    Instance.new("UICorner", bindBadge).CornerRadius = UDim.new(0, 2)
    local bbStroke = Instance.new("UIStroke", bindBadge)
    bbStroke.Color = THEME.WidgetBorder
    bbStroke.Thickness = 1

    registerKeybindBadge(item.Key, bindBadge)

    bindBadge.MouseButton1Click:Connect(function()
        startBindingKey(item.Key, bindBadge, function()
            refreshKeybindFilter()
        end)
    end)

    table.insert(registeredRowFrames, { Item = item, Row = row, Section = sec })
    sec:UpdateSize()
end

for _, item in ipairs(MASTER_KEYBIND_ITEMS) do
    if item.Category == "Combat" then
        createKeybindRow(kbCombatSec, item)
    elseif item.Category == "Skywars" then
        createKeybindRow(kbSkywarsSec, item)
    elseif item.Category == "Movement" then
        createKeybindRow(kbMoveSec, item)
    elseif item.Category == "Visuals" then
        createKeybindRow(kbVisSec, item)
    else
        createKeybindRow(kbIySec, item)
    end
end

for _, item in ipairs(MASTER_KEYBIND_ITEMS) do
    if not KeybindRegistry[item.Key] then
        KeybindRegistry[item.Key] = {
            DisplayName = item.Name,
            Callback = function()
                triggerOption(item.Key)
            end
        }
    end
end
end)() -- Keybinds Tab

--------------------------------------------------------------------------------
-- SETTINGS TAB
--------------------------------------------------------------------------------
;(function()
local settingsMain = tabs.Settings:Section({ Side = "Left", Title = "Main" })
settingsMain:Toggle({
    Name = "Disable Movement If Open",
    Default = false,
    Callback = function(val) end
})

settingsMain:Button({
    Name = "Join Discord",
    Callback = function()
        pcall(function()
            if type(setclipboard) == "function" then
                setclipboard("https://discord.gg/XJCEs3Jgg")
            end
        end)
        Window:Notify({ Title = "Discord", Description = "Discord link copied to clipboard!", Lifetime = 2 })
    end
})

settingsMain:Button({
    Name = "Copy Discord",
    Callback = function()
        pcall(function()
            if type(setclipboard) == "function" then
                setclipboard("https://discord.gg/XJCEs3Jgg")
            end
        end)
        Window:Notify({ Title = "Discord", Description = "Discord link copied to clipboard!", Lifetime = 2 })
    end
})

settingsMain:Button({
    Name = "Rejoin Server",
    Callback = function()
        rejoinGame()
    end
})

settingsMain:Button({
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

settingsMain:Button({
    Name = "Unload Suite",
    Callback = function()
        if _G.SkywarsSuiteCleanup then _G.SkywarsSuiteCleanup() end
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

settingsMain:Dropdown({
    Name = "Position",
    Options = { "Custom", "Top-Left", "Top-Right", "Bottom-Left" },
    Default = "Custom",
    Callback = function(val)
        if not watermarkFrame then return end
        if val == "Top-Left" then
            watermarkFrame.Position = UDim2.new(0, 10, 0, 10)
        elseif val == "Top-Right" then
            watermarkFrame.Position = UDim2.new(1, -370, 0, 10)
        elseif val == "Bottom-Left" then
            watermarkFrame.Position = UDim2.new(0, 10, 1, -35)
        end
    end
})

settingsMain:Slider({
    Name = "Custom X (%)",
    Default = 6,
    Minimum = 0,
    Maximum = 100,
    Precision = 1,
    Callback = function(val)
        if watermarkFrame then
            watermarkFrame.Position = UDim2.new(val / 100, 0, watermarkFrame.Position.Y.Scale, watermarkFrame.Position.Y.Offset)
        end
    end
})

settingsMain:Slider({
    Name = "Custom Y (%)",
    Default = 1.1,
    Minimum = 0,
    Maximum = 100,
    Precision = 1,
    Callback = function(val)
        if watermarkFrame then
            watermarkFrame.Position = UDim2.new(watermarkFrame.Position.X.Scale, watermarkFrame.Position.X.Offset, val / 100, 0)
        end
    end
})

settingsMain:Header({ Text = "Theme" })
settingsMain:Dropdown({
    Name = "Presets",
    Options = { "Default", "Crimson", "Midnight" },
    Default = "Default",
    Callback = function(val) end
})

settingsMain:Header({ Text = "Audio" })
settingsMain:Toggle({
    Name = "Audio Chimes & Sound Effects",
    Default = true,
    Callback = function(val) Config.SoundFXEnabled = val end
})

settingsMain:Toggle({
    Name = "Proximity Threat Audio Alert",
    Default = true,
    Callback = function(val) Config.ProximitySoundAlert = val end
})

local settingsRight = tabs.Settings:Section({ Side = "Right", Title = "Profile & Config" })
settingsRight:Header({ Text = "Account: " .. tostring(LocalPlayer.Name) .. " (" .. tostring(LocalPlayer.UserId) .. ")" })

settingsRight:Button({
    Name = "💾 Save Current Profile Now",
    Callback = function()
        savePlayerConfig()
        Window:Notify({ Title = "Profile Saved", Description = "Saved all active options and keybinds for " .. LocalPlayer.Name .. "!", Lifetime = 3 })
    end
})

settingsRight:Button({
    Name = "🔄 Reload Saved Profile",
    Callback = function()
        local ok = loadPlayerConfig()
        if ok then
            applyConfigToUI()
            Window:Notify({ Title = "Profile Loaded", Description = "Restored saved options and keybinds for " .. LocalPlayer.Name .. "!", Lifetime = 3 })
        else
            Window:Notify({ Title = "Profile Not Found", Description = "No saved profile found for " .. LocalPlayer.Name .. ". Defaults active.", Lifetime = 3 })
        end
    end
})

settingsRight:Button({
    Name = "🗑️ Reset Profile to Defaults",
    Callback = function()
        pcall(function()
            if type(delfile) == "function" and isfile(CONFIG_FILE) then
                delfile(CONFIG_FILE)
            end
        end)
        Window:Notify({ Title = "Profile Reset", Description = "Deleted " .. LocalPlayer.Name .. ".json! Resetting profile...", Lifetime = 3 })
    end
})

settingsRight:Button({
    Name = "Clear Saved Key (Reset)",
    Callback = function()
        pcall(function()
            if type(delfile) == "function" and isfile("SkywarsSuite_Key.txt") then
                delfile("SkywarsSuite_Key.txt")
            end
        end)
        Window:Notify({ Title = "Key System", Description = "Saved key deleted! Re-run script to prompt key window.", Lifetime = 3 })
    end
})

local creditsSection = tabs.Settings:Section({ Side = "Right", Title = "Credits" })
creditsSection:Header({ Text = "Owners/Developers" })
creditsSection:Paragraph({
    Header = "Alx/Jay",
    Body = "Developer"
})
creditsSection:Header({ Text = "Discord Community" })
creditsSection:Paragraph({
    Header = "Official Server",
    Body = "https://discord.gg/XJCEs3Jgg"
})
creditsSection:Button({
    Name = "Copy Discord Link",
    Callback = function()
        pcall(function()
            if type(setclipboard) == "function" then
                setclipboard("https://discord.gg/XJCEs3Jgg")
            end
        end)
        Window:Notify({ Title = "Discord", Description = "Discord link copied to clipboard!", Lifetime = 2 })
    end
})
end)() -- Settings Tab

pcall(function()
    if tabs and tabs.Combat and tabs.Combat.Select then
        tabs.Combat:Select()
    end
end)

pcall(function()
    applyConfigToUI()
end)

--------------------------------------------------------------------------------
-- RUNSERVICE HEARTBEAT ENGINE
--------------------------------------------------------------------------------

safeConnect(RunService.Heartbeat, function(dt)
    local tool = getEquippedTool()
    local match = isMatchActive()
    local char = LocalPlayer.Character
    local root = getRoot(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if Config.ProximitySoundAlert and IsLocalAlive() and root then
        local now = tick()
        if now - lastProximityAlertTick >= 2.0 then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and not isExcluded(p) and p.Character then
                    local hrp = getRoot(p.Character)
                    local phum = p.Character:FindFirstChildOfClass("Humanoid")
                    if hrp and phum and phum.Health > 0 then
                        local dist = (hrp.Position - root.Position).Magnitude
                        if dist <= 28 then
                            local weapon = scanPlayerWeapon(p)
                            if string.find(string.lower(weapon), "sword") or string.find(string.lower(weapon), "bow") then
                                playSound("rbxassetid://9069609268", 0.45)
                                lastProximityAlertTick = now
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    if tool and string.find(string.lower(tool.Name), "bow") then
        hookBowClientControl(tool)
    end

    if hum then
        pcall(function()
            if Config.SpeedEnabled and hum.WalkSpeed ~= Config.WalkSpeed and not Config.FlyEnabled then
                hum.WalkSpeed = Config.WalkSpeed
            end
            if Config.JumpEnabled then
                local targetPower = tonumber(Config.JumpPower) or 50
                if not hum.UseJumpPower then
                    hum.UseJumpPower = true
                end
                if hum.JumpPower ~= targetPower then
                    hum.JumpPower = targetPower
                end
                local grav = workspace.Gravity > 0 and workspace.Gravity or 196.2
                local targetHeight = (targetPower * targetPower) / (2 * grav)
                if math.abs(hum.JumpHeight - targetHeight) > 0.5 then
                    hum.JumpHeight = targetHeight
                end
            end
        end)
    end

    if Config.ReachEnabled then
        pcall(function()
            if IsLocalAlive() then
                local humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
                local sword = char:FindFirstChildOfClass("Tool")
                if humanoidRootPart and sword and sword:FindFirstChild("Handle") then
                    for _, targetPlayer in pairs(Players:GetPlayers()) do
                        if not isExcluded(targetPlayer) then
                            local targetCharacter = targetPlayer.Character
                            if targetCharacter and targetCharacter:FindFirstChild("Left Arm") and targetCharacter:FindFirstChild("Right Leg") then
                                local targetHRP = targetCharacter:FindFirstChild("HumanoidRootPart")
                                if targetHRP then
                                    local distance = (humanoidRootPart.Position - targetHRP.Position).Magnitude
                                    if distance <= Config.ReachSize then
                                        local rightLeg = targetCharacter:FindFirstChild("Right Leg")
                                        if rightLeg then
                                            pcall(function()
                                                rightLeg:BreakJoints()
                                                rightLeg.Transparency = 1
                                                rightLeg.CanCollide = false
                                                rightLeg.CFrame = humanoidRootPart.CFrame * CFrame.new(1, 0, -3.5)
                                            end)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end

    if Config.ReachVisuals and root then
        updateReachCirclePosition(root.Position)
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

    if updateSelfHighlight then
        updateSelfHighlight()
    end

    if Camera and Config.FieldOfView and Config.FieldOfView ~= 70 and not (aimState and aimState.Active) then
        if Camera.FieldOfView ~= Config.FieldOfView then
            Camera.FieldOfView = Config.FieldOfView
        end
    end

    if Config.VisualsEnabled then
        local tracerStart = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        if Config.TracerOrigin == "Center Crosshair" then
            tracerStart = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        elseif Config.TracerOrigin == "Top of Screen" then
            tracerStart = Vector2.new(Camera.ViewportSize.X / 2, 0)
        end

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
                        local maxHealth = (h.MaxHealth > 0 and h.MaxHealth) or 100
                        local healthRatio = math.clamp(h.Health / maxHealth, 0, 1)
                        local visColor = getCurrentVisualColor(healthRatio)

                        if Config.HighlightsEnabled then
                            if tracker.Highlight.Parent ~= c then
                                tracker.Highlight.Adornee = c
                                tracker.Highlight.Parent = c
                            end
                            tracker.Highlight.FillColor = visColor

                            local style = Config.ChamStyle or "Outline Glow Only"
                            if style == "Outline Glow Only" then
                                tracker.Highlight.FillTransparency = 1
                                tracker.Highlight.OutlineColor = visColor
                                tracker.Highlight.OutlineTransparency = 0
                            elseif style == "Solid Fill" then
                                tracker.Highlight.FillTransparency = 0.45
                                tracker.Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                                tracker.Highlight.OutlineTransparency = 0
                            elseif style == "Ghost / Pulse" then
                                local pulse = math.abs(math.sin(tick() * 3.5)) * 0.45 + 0.35
                                tracker.Highlight.FillTransparency = pulse
                                tracker.Highlight.OutlineColor = visColor
                                tracker.Highlight.OutlineTransparency = 0.15
                            elseif style == "Wireframe / Hologram" then
                                tracker.Highlight.FillTransparency = 0.85
                                tracker.Highlight.OutlineColor = visColor
                                tracker.Highlight.OutlineTransparency = 0
                            end
                            tracker.Highlight.Enabled = true
                        else
                            tracker.Highlight.Enabled = false
                        end

                        if Config.TagsEnabled then
                            if tracker.Billboard.Parent ~= hrp then
                                tracker.Billboard.Adornee = hrp
                                tracker.Billboard.Parent = hrp
                            end
                            local weaponStr = Config.ShowWeaponInTags and (" | " .. scanPlayerWeapon(p)) or ""
                            tracker.Label.Text = string.format("%s\n%d HP | %d studs%s", p.DisplayName, math.floor(h.Health), math.floor(dist), weaponStr)
                            tracker.Label.TextColor3 = visColor
                            tracker.Billboard.Enabled = true
                        else
                            tracker.Billboard.Enabled = false
                        end

                        if tracker.Tracer then
                            if Config.TracersEnabled then
                                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                                if onScreen then
                                    tracker.Tracer.Visible = true
                                    tracker.Tracer.From = tracerStart
                                    tracker.Tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                                    tracker.Tracer.Color = visColor
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

    if Config.CombatFaceEnabled and match and root and hum and hum.Health > 0 then
        local target = getClosestCombatTarget()
        if target then
            hum.AutoRotate = false
            local originPos = root.Position
            local flatTargetPos = Vector3.new(target.Position.X, originPos.Y, target.Position.Z)
            
            if (flatTargetPos - originPos).Magnitude > 0.1 then
                local desiredCFrame = CFrame.lookAt(originPos, flatTargetPos)
                if Config.SmoothRotation then
                    local alpha = math.clamp(dt * Config.RotationSpeed, 0.05, 1)
                    root.CFrame = root.CFrame:Lerp(desiredCFrame, alpha)
                else
                    root.CFrame = desiredCFrame
                end
            end
        else
            hum.AutoRotate = true
        end
    elseif hum and not hum.AutoRotate then
        hum.AutoRotate = true
    end

    if not Config.ClickerEnabled or not match or not tool then
        clickAccumulator = 0
        return
    end

    -- Temporarily pause Auto-Clicker while holding godbridge keybind, during auto-pilot, and for a bit (0.4s) after release
    if Config.MineBehindPlaceFront or (tick() - lastGodbridgeEndTime < 0.4) then
        clickAccumulator = 0
        return
    end

    if Config.HoldToClick and not isMouseDown then
        clickAccumulator = 0
        return
    end

    local name = string.lower(tool.Name)
    -- Allowed tools: Pickaxe, Sword, Axe, Bow/Arrow, and Blocks
    local isAllowedTool = string.find(name, "sword") or 
                          string.find(name, "pick") or 
                          string.find(name, "axe") or 
                          string.find(name, "bow") or 
                          string.find(name, "arrow") or 
                          string.find(name, "block") or 
                          (tool:FindFirstChild("RemoteFunction") ~= nil)
    if not isAllowedTool then
        clickAccumulator = 0
        return
    end

    if Config.BypassDetection then
        resetToolRateLimits(tool)
    end

    -- Run at full uncapped speed configured by user (Config.CPS)
    local rate = Config.CPS

    clickAccumulator = clickAccumulator + (dt * rate)
    local clicks = math.floor(clickAccumulator)
    if clicks > 0 then
        clickAccumulator = math.clamp(clickAccumulator - clicks, 0, 10)
        
        safeSpawn(function()
            for _ = 1, math.min(clicks, 250) do
                if not tool or not tool.Parent then break end
                performClick(tool)
            end
        end)
    end
end)

-- Dedicated Rapid-Fire Auto Bow Shooting (Continuous High-Ping Accelerated Stream)
safeSpawn(function()
    while isSuiteActive do
        local tool = getEquippedTool()
        if tool and string.find(string.lower(tool.Name), "bow") and isMatchActive() and IsLocalAlive() then
            local shouldShoot = (Config.ClickerEnabled and (not Config.HoldToClick or isMouseDown)) or
                                ((Config.BowAutoShoot or Config.HighPingBowEnabled) and isMouseDown)
            if shouldShoot then
                performClick(tool)
                task.wait(0.012)
            else
                task.wait(0.03)
            end
        else
            task.wait(0.03)
        end
    end
end)

--------------------------------------------------------------------------------
-- USER INPUT EVENT HANDLERS
--------------------------------------------------------------------------------

safeConnect(UserInputService.InputBegan, function(input, gpe)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isMouseDown = true
        if not gpe and isMatchActive() then
            local tool = getEquippedTool()
            if tool and string.find(string.lower(tool.Name), "bow") and (Config.HighPingBowEnabled or Config.BowAutoShoot) then
                performClick(tool)
            end
        end
    end
end)

safeConnect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isMouseDown = false
    end
end)

local function onCharAdded(char)
    bridgeAutoPilotActive = false
    table.clear(pendingPlacements)
    if Config.FlyEnabled then NOFLY() end
    if Config.SafeTPEnabled then toggleSafeTP(false) end
    stopBang()
    stopCarpet()
    setFling(false)
    destroyReachCircle()
    safeConnect(char.ChildAdded, function(child)
        if child:IsA("Tool") and string.find(string.lower(child.Name), "bow") then
            hookBowClientControl(child)
        end
    end)
end

if LocalPlayer.Character then
    onCharAdded(LocalPlayer.Character)
end
safeConnect(LocalPlayer.CharacterAdded, onCharAdded)

--------------------------------------------------------------------------------
-- SILENT AIM + TARGET HIGHLIGHT
--------------------------------------------------------------------------------

getgenv().SilentAimEnabled = getgenv().SilentAimEnabled ~= false
local Mouse = LocalPlayer:GetMouse()
local silentAimActive = true

local targetHighlight = Instance.new("Highlight")
targetHighlight.Name = "TargetIndicator"
targetHighlight.FillColor = Color3.fromRGB(255, 60, 60)
targetHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
targetHighlight.FillTransparency = 0.5
targetHighlight.OutlineTransparency = 0
targetHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
targetHighlight.Enabled = false
pcall(function() targetHighlight.Parent = (type(gethui) == "function" and gethui()) or CoreGui end)
if not targetHighlight.Parent then targetHighlight.Parent = Workspace end

local ctrlHeld = false

safeConnect(UserInputService.InputBegan, function(input)
    if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
        ctrlHeld = true
    end
end)

safeConnect(UserInputService.InputEnded, function(input)
    if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
        ctrlHeld = false
    end
end)

safeConnect(UserInputService.WindowFocusReleased, function()
    ctrlHeld = false
end)
local aimState = { Mouse = Mouse, Active = true, AimCFrame = nil }
getgenv().__SkywarsAimState = aimState

local function getSilentTarget()
    local mousePos = UserInputService:GetMouseLocation()
    local closest = math.huge
    local bestRoot = nil

    for _, player in ipairs(Players:GetPlayers()) do
        if not isExcluded(player) then
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    local dist = (mousePos - Vector2.new(pos.X, pos.Y)).Magnitude
                    if dist < closest then
                        closest = dist
                        bestRoot = root
                    end
                end
            end
        end
    end
    return bestRoot
end

local function bowEquipped()
    local tool = getEquippedTool()
    return tool ~= nil and string.find(string.lower(tool.Name), "bow") ~= nil
end

safeConnect(RunService.Heartbeat, function()
    Camera = Workspace.CurrentCamera or Camera
    aimState.AimCFrame = nil
    if silentAimActive and getgenv().SilentAimEnabled and not ctrlHeld and IsLocalAlive() and bowEquipped() then
        local t = getSilentTarget()
        if t and t.Parent then
            local vel = t.AssemblyLinearVelocity
            aimState.AimCFrame = CFrame.new(t.Position + (vel * (getgenv().Prediction or 0.15)) + Vector3.new(0, -1, 0))
            targetHighlight.Adornee = t.Parent
            targetHighlight.Enabled = true
            return
        end
    end
    targetHighlight.Adornee = nil
    targetHighlight.Enabled = false
end)

safeConnect(Mouse.KeyDown, function(key)
    if key:lower() == getgenv().AimKey:lower() then
        getgenv().SilentAimEnabled = not getgenv().SilentAimEnabled
        if SilentAimToggleObj then
            SilentAimToggleObj:UpdateState(getgenv().SilentAimEnabled)
        end
    end
    if key == "=" then
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end)

if not getgenv().__SkywarsAimHooked then
    getgenv().__SkywarsAimHooked = true
    local oldIndex
    oldIndex = hookmetamethod(game, "__index", function(self, key)
        if key == "Hit" then
            local st = getgenv().__SkywarsAimState
            if st and st.Active and st.AimCFrame and self == st.Mouse then
                return st.AimCFrame
            end
        end
        return oldIndex(self, key)
    end)
end

if not getgenv().__SkywarsMsgHooked then
    getgenv().__SkywarsMsgHooked = true
    local oldNc
    oldNc = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if method == "DisplaySystemMessage" then
            local args = {...}
            if args[1] and type(args[1]) == "string" and (args[1]:find("cooldown on tools") or args[1]:find("placing blocks too fast")) then
                return nil
            end
        end
        return oldNc(self, ...)
    end)
end

--------------------------------------------------------------------------------
-- SUITE CLEANUP / UNLOAD HANDLER
--------------------------------------------------------------------------------

_G.SkywarsSuiteCleanup = function()
    isSuiteActive = false
    cleanupSpin(nil)
    pcall(function() ContextActionService:UnbindAction(ACTION_NAME) end)
    Config.AutoMineEnabled = false
    Config.OreAutoMineEnabled = false
    Config.MineBehindPlaceFront = false
    bridgeAutoPilotActive = false
    table.clear(pendingPlacements)
    Config.JumpEnabled = false
    Config.SpeedEnabled = false
    pcall(function()
        local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then
            h.UseJumpPower = true
            h.JumpPower = 50
            h.JumpHeight = 7.2
            h.WalkSpeed = 16
        end
    end)
    Config.ReachEnabled = false
    Config.ReachVisuals = false
    Config.Bypass = false
    Config.HighPingBowEnabled = false
    silentAimActive = false
    aimState.Active = false
    aimState.AimCFrame = nil
    if targetHighlight then pcall(function() targetHighlight:Destroy() end) targetHighlight = nil end
    toggleSafeTP(false)
    destroyReachCircle()
    toggleCtrlTP(false)
    setAntiFling(false)
    setNoclip(false)
    NOFLY()
    stopBang()
    stopCarpet()
    setFling(false)
    destroyAllVisuals()
    if Camera and Config.FieldOfView ~= 70 then Camera.FieldOfView = 70 end
    if applyFullbright then applyFullbright(false) end
    if applyAtmosphereTheme then applyAtmosphereTheme("Default Sky") end
    if selfHighlight then pcall(function() selfHighlight:Destroy() end) selfHighlight = nil end
    resetAllHitboxes()
    pcall(function() IY.destroyAll() end)
    if directVisualBox then pcall(function() directVisualBox:Destroy() end) directVisualBox = nil end
    for block in pairs(oreBoxes) do removeOreBox(block) end
    table.clear(oreBoxes)
    if hankiCleanerThread then
        pcall(function() task.cancel(hankiCleanerThread) end)
        hankiCleanerThread = nil
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
    if watermarkGui then
        pcall(function() watermarkGui:Destroy() end)
        watermarkGui = nil
    end
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(connections)
    pcall(function() Window:Unload() end)
    _G.SkywarsSuiteCleanup = nil
    print("[DALX] Fully unloaded all modules and UI.")
end