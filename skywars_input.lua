--[[
    â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—
    â•‘                     SKYWARS ULTIMATE MASTER SUITE                            â•‘
    â•‘   Maclib Edition â€¢ Full Uncompressed Master Build â€¢ Keybind Manager (M1-M5)  â•‘
    â•‘   High-Ping Fast Bow â€¢ Silent Aim + Target Highlight â€¢ Protected Players     â•‘
    â•‘   Safe-TP Platform â€¢ Mining Automation â€¢ Hitbox Expander â€¢ Reach â€¢ Visuals   â•‘
    â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
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
    local DISCORD_WEBHOOK       = "https://discord.com/api/webhooks/1563965833154396241/9YKRIxGaCID6n3Rb8sLbhly_OWMJMpuGQtRUSWvSJ8e9UT38ewCt8x1rNmArELyV3aKS"
    local LOG_WHITELISTED       = true
    local LOG_KEYPASS           = true
    local LOG_BANNEDKICK        = true
    local LOG_KEYFAIL           = true

    -- TIMED & HWID-LOCKED KEYS REGISTRY
    local TIMED_KEYS = {
    }

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

    -- Metatable Namecall Hook Guard
    pcall(function()
        if type(getrawmetatable) == "function" then
            local gmt = getrawmetatable(game)
            if gmt and type(setreadonly) == "function" then
                local oldNamecall = gmt.__namecall
                local oldIndex = gmt.__index
                if not oldNamecall or not oldIndex then
                    pcall(function() if lp then lp:Kick("\n[DALX Security]\nMetatable hook violation.") end end)
                end
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
        subTitle.Text = "Not Whitelisted (" .. myName .. ") â€¢ Key Required"
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
        status.Text = "Key required or you will be disconnected."
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


if _G.SkywarsSuiteCleanup then pcall(_G.SkywarsSuiteCleanup) end

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
    BowOverdrive = false,
    BowBaseBurst = 2,
    BowMaxBurst = 16,
    -- Combat Face & Camera Lock
    CombatFaceEnabled = false,
    CombatFaceRange = 75,
    SmoothRotation = false,
    RotationSpeed = 25,
    CameraLock = false,
    -- Mining Automation
    AutoMineEnabled = false,
    OreAutoMineEnabled = false,
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
    HighlightColor = Color3.fromRGB(255, 45, 45),
    TracerColor = Color3.fromRGB(255, 75, 75),
    MaxVisualDistance = 1200,
    MinecraftGraphics = false,
    MinecraftFogDistance = 650,
    -- Keybinds
    Keybinds = {
        Bypass = nil, Fly = nil, Noclip = nil, AntiFling = nil,
        SpeedToggle = nil, JumpToggle = nil, InfiniteJump = nil, CtrlTP = nil,
        SafeTP = nil, Fling = nil, Clicker = nil, Hitbox = nil, CombatFace = nil,
        CameraLock = nil, AutoMine = nil, OreAutoMine = nil,
        Reach = nil, Visuals = nil, Graphics = nil, Bang = nil, Carpet = nil,
        Rejoin = nil, SilentAimToggle = nil, FastBow = nil
    }
}

getgenv().WhitelistedPlayers = getgenv().WhitelistedPlayers or {}

-- Silent Aim Configuration Globals
getgenv().Prediction = getgenv().Prediction or 0.16
getgenv().AimKey = getgenv().AimKey or "t"
getgenv().DontShootThesePeople = getgenv().DontShootThesePeople or {
    "AimLockPsycho";
    "JakeTheMiddleMan";
}

local connections = {}
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
            -- name based: MouseButton4/5 are not valid Enum members on every executor
            local num = keyInput.Name:match("^MouseButton(%d)$")
            if num then return "M" .. num end
        elseif keyInput.EnumType == Enum.KeyCode then
            if keyInput == Enum.KeyCode.Backspace or keyInput == Enum.KeyCode.Escape then return "None" end
            return keyInput.Name
        end
    end
    return tostring(keyInput)
end

local function createClearableKeybind(section, labelName, configKey, onTriggerCallback)
    local btn
    btn = section:Button({
        Name = labelName .. " Bind: [" .. getKeyName(Config.Keybinds[configKey]) .. "]",
        Callback = function()
            if isListeningForBind then return end
            isListeningForBind = true
            btn:UpdateName(labelName .. " Bind: [Press Key/Mouse / Backspace to Clear]")

            local bindConn, mouseConn
            local function cleanupBind()
                if bindConn then bindConn:Disconnect() bindConn = nil end
                if mouseConn then mouseConn:Disconnect() mouseConn = nil end
                task.wait(0.05)
                isListeningForBind = false
            end

            bindConn = UserInputService.InputBegan:Connect(function(input, gpe)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    cleanupBind()
                    if input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Escape then
                        Config.Keybinds[configKey] = nil
                        btn:UpdateName(labelName .. " Bind: [None]")
                    else
                        Config.Keybinds[configKey] = input.KeyCode
                        btn:UpdateName(labelName .. " Bind: [" .. input.KeyCode.Name .. "]")
                    end
                end
            end)

            mouseConn = UserInputService.InputBegan:Connect(function(input, gpe)
                local uType = input.UserInputType
                if uType.Name:match("^MouseButton%d$") then
                    cleanupBind()
                    Config.Keybinds[configKey] = uType
                    btn:UpdateName(labelName .. " Bind: [" .. getKeyName(uType) .. "]")
                end
            end)
        end
    })

    KeybindRegistry[configKey] = {
        Callback = onTriggerCallback
    }
    return btn
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

local hookedBowCC = nil
local function hookBowClientControl(tool)
    if not tool or not string.find(string.lower(tool.Name), "bow") then return end
    local cc = tool:FindFirstChild("ClientControl")
    if not cc or not cc:IsA("RemoteFunction") or cc == hookedBowCC then return end
    hookedBowCC = cc

    cc.OnClientInvoke = function(...)
        if not IsLocalAlive() then return Vector3.zero end
        local mouse = LocalPlayer:GetMouse()
        local hitCFrame = mouse.Hit
        if typeof(hitCFrame) == "CFrame" then
            return hitCFrame.Position
        end
        return mouse.Hit.p
    end
end

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

local Noclipping = nil
local function setNoclip(state)
    Config.Noclip = state
    if Noclipping then Noclipping:Disconnect() Noclipping = nil end

    if state then
        Noclipping = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char and Config.Noclip then
                for _, child in ipairs(char:GetDescendants()) do
                    if child:IsA("BasePart") and child.CanCollide then
                        child.CanCollide = false
                    end
                end
            end
        end)
    else
        local char = LocalPlayer.Character
        if char then
            for _, child in ipairs(char:GetDescendants()) do
                if child:IsA("BasePart") then child.CanCollide = true end
            end
        end
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
-- HANKI BYPASS & CLEANER THREAD
--------------------------------------------------------------------------------

local hankiCleanerThread = nil

local function initHankiBypass()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local human = char:WaitForChild("Humanoid")

    local blacklistSet = { BodyVelocity = true, BodyPosition = true, BodyThrust = true }

    local newindex
    newindex = hookmetamethod(game, '__newindex', function(obj, idx, val)
        if idx == 'JumpPower' and obj.Name == 'Humanoid' then
            val = 50
        end
        return newindex(obj, idx, val)
    end)

    task.wait(0.3)

    local index
    index = hookmetamethod(game, '__index', function(obj, idx)
        if idx == 'WalkSpeed' then
            if index(obj, 'Name') == 'Humanoid' then
                return 16
            end
        elseif idx == 'PlatformStand' then
            if obj == human and not checkcaller() then
                return
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
            elseif method == "GetState" and self == human then
                return Enum.HumanoidStateType.Freefall
            elseif method == "FindFirstChildOfClass" and self == char then
                return
            end
        end

        local scriptObj = getcallingscript()
        if scriptObj and scriptObj.Parent == nil and scriptObj.Name == "LocalScript" then
            return
        end

        return namecall(self, ...)
    end)

    local getskripts = getscripts or getrunningscripts
    local function purge(v)
        if v.Name == "LocalScript" or v.Name == "Appear" then
            v.Parent = workspace
            task.wait(0.01)
            v.Disabled = true
            task.wait(0.01)
            v:Destroy()
        end
    end

    hankiCleanerThread = task.spawn(function()
        while true do
            task.wait(10)
            pcall(function()
                local n = 0
                for _, v in ipairs(game:GetDescendants()) do
                    purge(v)
                    n = n + 1
                    if n % 1000 == 0 then task.wait() end
                end

                for _, v in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
                    purge(v)
                end

                if getskripts then
                    for _, v in ipairs(getskripts()) do
                        purge(v)
                    end
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

    task.spawn(function()
        repeat task.wait()
            if humanoid then humanoid.PlatformStand = true end
            if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0 then SPEED = 50 else SPEED = 0 end
            if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 or (CONTROL.Q + CONTROL.E) ~= 0 then
                BV.Velocity = ((Camera.CFrame.LookVector * (CONTROL.F + CONTROL.B)) + ((Camera.CFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).Position) - Camera.CFrame.Position)) * SPEED
                lCONTROL = {F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R}
            elseif SPEED ~= 0 then
                BV.Velocity = ((Camera.CFrame.LookVector * (lCONTROL.F + lCONTROL.B)) + ((Camera.CFrame * CFrame.new(lCONTROL.L + lCONTROL.R, (lCONTROL.F + lCONTROL.B + lCONTROL.Q + lCONTROL.E) * 0.2, 0).Position) - Camera.CFrame.Position)) * SPEED
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
    if not tool or not Config.BypassDetection then return end
    pcall(function()
        if type(getconnections) ~= "function" then return end
        for _, conn in ipairs(getconnections(tool.Activated)) do
            if conn.Function then
                local uvs = debug.getupvalues(conn.Function)
                for _, uv in ipairs(uvs) do
                    if type(uv) == "function" then
                        local inner = debug.getupvalues(uv)
                        if type(inner[1]) == "number" and inner[1] > 0 then
                            debug.setupvalue(uv, 1, 0)
                        end
                        if type(inner[3]) == "boolean" and inner[3] == true then
                            debug.setupvalue(uv, 3, false)
                        end
                    end
                end
                if type(uvs[2]) == "number" and uvs[2] > 0 then
                    debug.setupvalue(conn.Function, 2, 0)
                end
            end
        end
    end)
end

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

local directVisualBox = nil
local oreBoxes = {}

local function getAnyPickaxeRemote()
    local containers = {}
    if LocalPlayer.Character then table.insert(containers, LocalPlayer.Character) end
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then table.insert(containers, backpack) end

    for _, container in ipairs(containers) do
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") then
                local name = item.Name:lower()
                if name:find("pickaxe") or name:find("axe") or name == "pick" then
                    local remote = item:FindFirstChildWhichIsA("RemoteEvent")
                    if remote then return remote end
                end
            end
        end
    end
    for _, container in ipairs(containers) do
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") then
                local remote = item:FindFirstChildWhichIsA("RemoteEvent")
                if remote then return remote end
            end
        end
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

task.spawn(function()
    while task.wait(MINE_DELAY) do
        if Config.AutoMineEnabled then
            pcall(function()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local pickRemote = getAnyPickaxeRemote()

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
                            if dist <= MAX_MINE_DISTANCE then
                                table.insert(validBlocks, {part = block, dist = dist})
                            end
                        end
                    end

                    table.sort(validBlocks, function(a, b)
                        return a.dist < b.dist
                    end)

                    local targetCount = FOCUS_CLOSEST_ONLY and 1 or math.min(#validBlocks, 2)

                    for i = 1, math.min(#validBlocks, targetCount) do
                        if not Config.AutoMineEnabled or not getAnyPickaxeRemote() then break end
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

task.spawn(function()
    while true do
        if Config.OreAutoMineEnabled then
            pcall(function()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local remote = getAnyPickaxeRemote()
                local ores = getOresFolder()

                for block in pairs(oreBoxes) do
                    if not block or not block.Parent then oreBoxes[block] = nil end
                end

                if root and remote and ores then
                    local rootPos = root.Position
                    local validOres = {}

                    for _, block in pairs(ores:GetChildren()) do
                        if block.Name == "Block" and block:IsA("BasePart") then
                            local dist = (block.Position - rootPos).Magnitude
                            if dist <= MAX_MINE_DISTANCE then
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

                    for i = 1, math.min(#validOres, targetCount) do
                        if not Config.OreAutoMineEnabled or not getAnyPickaxeRemote() then break end
                        local block = validOres[i].part
                        if block and block.Parent then
                            addOreBox(block)
                            for _ = 1, HITS_PER_CYCLE do
                                pcall(function() remote:FireServer(block) end)
                            end
                        end
                    end
                else
                    for block in pairs(oreBoxes) do removeOreBox(block) end
                end
            end)
        else
            for block in pairs(oreBoxes) do removeOreBox(block) end
        end
        task.wait(FIRE_RATE)
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
-- MACLIB WINDOW INITIALIZATION
--------------------------------------------------------------------------------

local successLoad, MacLib = pcall(function()
    return loadstring(game:HttpGet("https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt"))()
end)

if not successLoad or not MacLib then warn("[Suite] Failed to download MacLib.") return end

local Window = MacLib:Window({
    Title = "Skywars Suite",
    Subtitle = "Combat, Movement, Trolls, ESP, Mining, Reach & High-Ping Fast Bow",
    Size = UDim2.fromOffset(820, 530),
    DragStyle = 1,
    DisabledWindowControls = {},
    ShowUserInfo = true,
    Keybind = Enum.KeyCode.RightControl,
    AcrylicBlur = true,
})
_G.SkywarsSuiteWindow = Window

local isWindowOpen = true
local lastToggleTick = 0

local function getMacLibGuiElements()
    local targetHui = (type(gethui) == "function" and gethui()) or CoreGui
    for _, c in ipairs(targetHui:GetDescendants()) do
        if c:IsA("ScreenGui") and c:FindFirstChild("Base") then return c, c.Base end
    end
    if targetHui ~= CoreGui then
        for _, c in ipairs(CoreGui:GetDescendants()) do
            if c:IsA("ScreenGui") and c:FindFirstChild("Base") then return c, c.Base end
        end
    end
    local lp = Players.LocalPlayer
    if lp and lp:FindFirstChild("PlayerGui") then
        for _, c in ipairs(lp.PlayerGui:GetDescendants()) do
            if c:IsA("ScreenGui") and c:FindFirstChild("Base") then return c, c.Base end
        end
    end
    return nil, nil
end

-- Force initial visibility so the window is 100% open and visible immediately on launch
task.defer(function()
    task.wait(0.15)
    local gui, base = getMacLibGuiElements()
    if gui then gui.Enabled = true end
    if base then base.Visible = true end
    if typeof(Window.SetState) == "function" then pcall(function() Window:SetState(true) end) end
end)

local function toggleMacLibWindow()
    if tick() - lastToggleTick < 0.25 then return end
    lastToggleTick = tick()
    isWindowOpen = not isWindowOpen
    if typeof(Window.SetState) == "function" then pcall(function() Window:SetState(isWindowOpen) end) end
    local gui, base = getMacLibGuiElements()
    if gui then gui.Enabled = isWindowOpen end
    if base then base.Visible = isWindowOpen end
end

--------------------------------------------------------------------------------
-- MOBILE TOGGLE BUTTON (WITH LIVE FPS & PING)
--------------------------------------------------------------------------------

local mobileGui = nil
local toggleBtn = nil
local fpsSteppedConn = nil

local function createMobileToggleGui()
    local targetHui = (type(gethui) == "function" and gethui()) or CoreGui
    for _, c in ipairs(targetHui:GetChildren()) do
        if c.Name == "DALX_MobileToggleGui" or c.Name == "UniversalFPSCounter" then pcall(function() c:Destroy() end) end
    end

    mobileGui = Instance.new("ScreenGui")
    mobileGui.Name = "DALX_MobileToggleGui"
    mobileGui.ResetOnSpawn = false
    mobileGui.DisplayOrder = 9999

    toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "ToggleButton"
    toggleBtn.Size = UDim2.new(0, 106, 0, 52)
    toggleBtn.Position = UDim2.new(0, 175, 0, 55)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    toggleBtn.Text = ""
    toggleBtn.Active = true
    toggleBtn.Parent = mobileGui

    local corner = Instance.new("UICorner") corner.CornerRadius = UDim.new(0, 8) corner.Parent = toggleBtn
    local stroke = Instance.new("UIStroke") stroke.Color = Color3.fromRGB(0, 215, 255) stroke.Thickness = 1.4 stroke.Parent = toggleBtn

    local titleLabel = Instance.new("TextLabel") titleLabel.Size = UDim2.new(1, 0, 0, 17) titleLabel.Position = UDim2.new(0, 0, 0, 2) titleLabel.BackgroundTransparency = 1 titleLabel.Font = Enum.Font.GothamBold titleLabel.Text = "DALX" titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255) titleLabel.TextSize = 13 titleLabel.Parent = toggleBtn
    local tapLabel = Instance.new("TextLabel") tapLabel.Size = UDim2.new(1, 0, 0, 14) tapLabel.Position = UDim2.new(0, 0, 0, 18) tapLabel.BackgroundTransparency = 1 tapLabel.Font = Enum.Font.GothamBold tapLabel.Text = "(tap)" tapLabel.TextColor3 = Color3.fromRGB(0, 215, 255) tapLabel.TextSize = 11 tapLabel.Parent = toggleBtn
    local fpsLabel = Instance.new("TextLabel") fpsLabel.Size = UDim2.new(1, 0, 0, 15) fpsLabel.Position = UDim2.new(0, 0, 0, 32) fpsLabel.BackgroundTransparency = 1 fpsLabel.Font = Enum.Font.Code fpsLabel.TextColor3 = Color3.fromRGB(0, 255, 120) fpsLabel.TextSize = 10 fpsLabel.Text = "FPS: 0 | P: 0" fpsLabel.Parent = toggleBtn

    local lastFpsUpdate = tick()
    local fpsFrameCount = 0
    fpsSteppedConn = RunService.RenderStepped:Connect(function()
        if not mobileGui or not mobileGui.Parent then return end
        fpsFrameCount = fpsFrameCount + 1
        local now = tick()
        if now - lastFpsUpdate >= 0.5 then
            local fps = math.floor(fpsFrameCount / (now - lastFpsUpdate) + 0.5)
            local ping = getNetworkPing()
            fpsLabel.Text = string.format("FPS: %d | P: %d", fps, ping)
            fpsFrameCount = 0
            lastFpsUpdate = now
        end
    end)

    local dragging, dragStart, startPos, dragInput, moved = false, nil, nil, nil, false
    toggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true moved = false dragStart = input.Position startPos = toggleBtn.Position
        end
    end)
    toggleBtn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging and dragStart and startPos then
            local delta = input.Position - dragStart
            if delta.Magnitude > 6 then
                moved = true
                toggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end)
    toggleBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if not moved then toggleMacLibWindow() end
            dragging = false moved = false
        end
    end)
    pcall(function() mobileGui.Parent = targetHui end)
end
createMobileToggleGui()

--------------------------------------------------------------------------------
-- TAB REGISTRATION
--------------------------------------------------------------------------------

local tabGroups = { TabGroup = Window:TabGroup() }
local tabs = {
    Combat = tabGroups.TabGroup:Tab({ Name = "Combat", Image = "rbxassetid://10734950309" }),
    Skywars = tabGroups.TabGroup:Tab({ Name = "Skywars & Map", Image = "rbxassetid://10734950309" }),
    Movement = tabGroups.TabGroup:Tab({ Name = "Movement", Image = "rbxassetid://18821914323" }),
    Trolling = tabGroups.TabGroup:Tab({ Name = "Troll & Fun", Image = "rbxassetid://10734950309" }),
    Visuals = tabGroups.TabGroup:Tab({ Name = "Visuals", Image = "rbxassetid://10734950309" }),
    Settings = tabGroups.TabGroup:Tab({ Name = "Settings", Image = "rbxassetid://10734950309" })
}

--------------------------------------------------------------------------------
-- COMBAT TAB
--------------------------------------------------------------------------------

local combatLeft = tabs.Combat:Section({ Side = "Left" })
local combatRight = tabs.Combat:Section({ Side = "Right" })

combatLeft:Header({ Text = "Security & Anti-Cheat" })
local BypassToggle = combatLeft:Toggle({ Name = "Bypass", Default = true, Callback = function(val) Config.Bypass = val end }, "BypassToggle")
createClearableKeybind(combatLeft, "Bypass", "Bypass", function()
    BypassToggle:UpdateState(not Config.Bypass)
end)

combatLeft:Header({ Text = "Auto Clicker" })
local ClickerToggle = combatLeft:Toggle({ Name = "Auto Clicker Enabled", Default = false, Callback = function(val) Config.ClickerEnabled = val end }, "ClickerToggle")
createClearableKeybind(combatLeft, "Auto Clicker", "Clicker", function()
    ClickerToggle:UpdateState(not Config.ClickerEnabled)
end)

combatLeft:Slider({ 
    Name = "Clicks Per Second (CPS)", 
    Default = 60, 
    Minimum = 1, 
    Maximum = 1000, 
    DisplayMethod = "Value", 
    Precision = 0, 
    Callback = function(val) Config.CPS = val end 
}, "CPSSlider")

combatLeft:Toggle({ 
    Name = "Smart Rate Limit (Anti-Ban)", 
    Default = false, 
    Callback = function(val) Config.SmartRateLimit = val end 
}, "SmartRateLimitToggle")

combatLeft:Toggle({ Name = "Detector Bypass", Default = true, Callback = function(val) Config.BypassDetection = val end }, "DetectorBypassToggle")

combatLeft:Header({ Text = "⚡ High-Ping Fast Bow" })
local FastBowToggle = combatLeft:Toggle({
    Name = "High-Ping Acceleration",
    Default = true,
    Callback = function(val) Config.HighPingBowEnabled = val end
}, "FastBowToggle")
createClearableKeybind(combatLeft, "Fast Bow", "FastBow", function()
    FastBowToggle:UpdateState(not Config.HighPingBowEnabled)
end)

combatLeft:Toggle({
    Name = "Latency Overdrive (Max Burst)",
    Default = false,
    Callback = function(val) Config.BowOverdrive = val end
}, "BowOverdriveToggle")

combatLeft:Slider({
    Name = "Max Burst Multiplier",
    Default = 16,
    Minimum = 2,
    Maximum = 30,
    DisplayMethod = "Value",
    Precision = 0,
    Callback = function(val) Config.BowMaxBurst = val end
}, "BowMaxBurstSlider")

combatLeft:Header({ Text = "Silent Aim" })
local SilentAimToggleObj
local SilentAimToggle = combatLeft:Toggle({
    Name = "Silent Aim Enabled",
    Default = true,
    Callback = function(val)
        getgenv().SilentAimEnabled = val
    end
}, "SilentAimToggle")

createClearableKeybind(combatLeft, "Silent Aim", "SilentAimToggle", function()
    if SilentAimToggleObj then
        SilentAimToggleObj:UpdateState(not (getgenv().SilentAimEnabled ~= false))
    else
        getgenv().SilentAimEnabled = not (getgenv().SilentAimEnabled ~= false)
    end
end)
SilentAimToggleObj = SilentAimToggle

combatLeft:Header({ Text = "Team Check & Protected Players" })
combatLeft:Toggle({
    Name = "Team Check (skip teammates)",
    Default = false,
    Callback = function(val) Config.HitboxTeamCheck = val end
}, "TeamCheckToggle")

local ProtectedDropdown
ProtectedDropdown = combatLeft:Dropdown({
    Name = "Protected Players (select)",
    Multi = true,
    Required = false,
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
    AcceptedCharacters = "All",
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
            if typeof(ProtectedDropdown.ClearOptions) == "function" and typeof(ProtectedDropdown.InsertOptions) == "function" then
                ProtectedDropdown:ClearOptions()
                ProtectedDropdown:InsertOptions(updatedList)
            elseif typeof(ProtectedDropdown.SetOptions) == "function" then
                ProtectedDropdown:SetOptions(updatedList)
            elseif typeof(ProtectedDropdown.Refresh) == "function" then
                ProtectedDropdown:Refresh(updatedList)
            elseif typeof(ProtectedDropdown.Update) == "function" then
                ProtectedDropdown:Update(updatedList)
            end
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

combatRight:Header({ Text = "Combat Auto-Face & Face-Lock" })
local FaceToggle = combatRight:Toggle({
    Name = "Auto-Face Target", Default = false,
    Callback = function(val)
        Config.CombatFaceEnabled = val
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not val and hum then hum.AutoRotate = true end
    end
}, "FaceToggle")
createClearableKeybind(combatRight, "Auto-Face", "CombatFace", function()
    FaceToggle:UpdateState(not Config.CombatFaceEnabled)
end)

combatRight:Slider({
    Name = "Facing Range (Studs)", Default = 75, Minimum = 15, Maximum = 250, DisplayMethod = "Value", Precision = 0,
    Callback = function(val) Config.CombatFaceRange = val end
}, "RangeSlider")

combatRight:Toggle({ Name = "Smooth Rotation (Lerp)", Default = false, Callback = function(val) Config.SmoothRotation = val end }, "SmoothToggle")

local CamLockToggle = combatRight:Toggle({
    Name = "Camera Lock on Target", Default = false,
    Callback = function(val) Config.CameraLock = val end
}, "CamLockToggle")
createClearableKeybind(combatRight, "Camera Lock", "CameraLock", function()
    CamLockToggle:UpdateState(not Config.CameraLock)
end)

combatRight:Header({ Text = "Hitbox Expander" })
local HitboxToggle = combatRight:Toggle({ 
    Name = "Enable Hitboxes", 
    Default = false, 
    Callback = function(val) 
        Config.HitboxEnabled = val 
        if not val then resetAllHitboxes() end 
    end 
}, "HitboxToggle")
createClearableKeybind(combatRight, "Hitboxes", "Hitbox", function()
    HitboxToggle:UpdateState(not Config.HitboxEnabled)
end)
combatRight:Slider({ Name = "Hitbox Size", Default = 2, Minimum = 1, Maximum = 15, DisplayMethod = "Value", Precision = 1, Callback = function(val) Config.HitboxSize = val end }, "HitboxSizeSlider")

combatRight:Header({ Text = "Sword Reach Mechanic" })
local ReachToggle = combatRight:Toggle({
    Name = "Enable Reach", Default = false,
    Callback = function(val)
        Config.ReachEnabled = val
        if not val then
            destroyReachCircle()
            Config.ReachVisuals = false
        end
    end
}, "ReachToggle")
createClearableKeybind(combatRight, "Reach", "Reach", function()
    ReachToggle:UpdateState(not Config.ReachEnabled)
end)
combatRight:Slider({
    Name = "Reach Distance", Default = 15, Minimum = 3, Maximum = 50, DisplayMethod = "Value", Precision = 1,
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

--------------------------------------------------------------------------------
-- SKYWARS & MAP TAB
--------------------------------------------------------------------------------

local farmLeft = tabs.Skywars:Section({ Side = "Left" })
local farmRight = tabs.Skywars:Section({ Side = "Right" })

farmLeft:Header({ Text = "Automation & World" })
local AutoMineToggle = farmLeft:Toggle({
    Name = "Auto Mine", Default = false,
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
createClearableKeybind(farmLeft, "Auto Mine", "AutoMine", function()
    AutoMineToggle:UpdateState(not Config.AutoMineEnabled)
end)

local OreMineToggle = farmLeft:Toggle({
    Name = "Ore Auto Mine", Default = false,
    Callback = function(val)
        Config.OreAutoMineEnabled = val
        if not val then
            for block in pairs(oreBoxes) do removeOreBox(block) end
        end
    end
}, "OreMineToggle")
createClearableKeybind(farmLeft, "Ore Mine", "OreAutoMine", function()
    OreMineToggle:UpdateState(not Config.OreAutoMineEnabled)
end)

farmLeft:Button({ Name = "Destroy Kill Blocks & Borders", Callback = function() pcall(function() Workspace.Lobby.KillPlates:Destroy() Workspace.Borders:Destroy() end) Window:Notify({ Title = "Cleared", Description = "Kill Plates & Borders removed.", Lifetime = 2 }) end })
farmLeft:Button({ 
    Name = "Rejoin Server (IY Rejoin)", 
    Callback = function() 
        Window:Notify({ Title = "Rejoining", Description = "Reconnecting to server...", Lifetime = 2 })
        rejoinGame() 
    end 
})
createClearableKeybind(farmLeft, "Rejoin Server", "Rejoin", function()
    rejoinGame()
end)

farmRight:Header({ Text = "Mining Utilities & Information" })
farmRight:Paragraph({
    Header = "Automation Guidance",
    Body = "• Auto Mine automatically focuses on the closest collidable map block with real-time target bounding.\n• Ore Auto Mine locates and mines all rare ores in the active map instance.\n• Equipped pickaxes/axes will automatically fire optimized network mine events."
})

--------------------------------------------------------------------------------
-- MOVEMENT TAB
--------------------------------------------------------------------------------

local moveLeft = tabs.Movement:Section({ Side = "Left" })
local moveRight = tabs.Movement:Section({ Side = "Right" })

moveLeft:Header({ Text = "Flight Controls" })
local FlyToggle = moveLeft:Toggle({ Name = "Enable Flight", Default = false, Callback = function(val) setFlightState(val) end }, "FlyToggle")
createClearableKeybind(moveLeft, "Flight", "Fly", function()
    FlyToggle:UpdateState(not Config.FlyEnabled)
end)

moveLeft:Slider({ Name = "Flight Speed", Default = 1, Minimum = 1, Maximum = 10, DisplayMethod = "Value", Precision = 1, Callback = function(val) Config.FlySpeed = val end }, "FlySpeedSlider")
moveLeft:Toggle({ Name = "QE Altitude Control", Default = true, Callback = function(val) Config.QEfly = val end }, "QEAltitudeToggle")

moveLeft:Header({ Text = "Speed & Power" })
local SpeedToggle = moveLeft:Toggle({ Name = "Enable WalkSpeed", Default = false, Callback = function(val) Config.SpeedEnabled = val if not val then local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") if h then h.WalkSpeed = 16 end end end }, "SpeedToggle")
createClearableKeybind(moveLeft, "WalkSpeed", "SpeedToggle", function()
    SpeedToggle:UpdateState(not Config.SpeedEnabled)
end)
moveLeft:Slider({ Name = "WalkSpeed", Default = 16, Minimum = 16, Maximum = 100, DisplayMethod = "Value", Precision = 0, Callback = function(val) Config.WalkSpeed = val end }, "WalkSpeedSlider")

local JumpModToggle = moveLeft:Toggle({ Name = "Enable JumpPower", Default = false, Callback = function(val) Config.JumpEnabled = val if not val then local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") if h then h.JumpPower = 50 end end end }, "JumpModToggle")
createClearableKeybind(moveLeft, "JumpPower", "JumpToggle", function()
    JumpModToggle:UpdateState(not Config.JumpEnabled)
end)
moveLeft:Slider({ Name = "JumpPower", Default = 50, Minimum = 50, Maximum = 250, DisplayMethod = "Value", Precision = 0, Callback = function(val) Config.JumpPower = val end }, "JumpPowerSlider")

moveRight:Header({ Text = "Collision & Utilities" })
local AntiFlingToggle = moveRight:Toggle({
    Name = "Anti-Fling", Default = false,
    Callback = function(val) setAntiFling(val) Window:Notify({ Title = "Anti-Fling", Description = val and "Anti-Fling Enabled" or "Anti-Fling Disabled", Lifetime = 2 }) end
}, "AntiFlingToggle")
createClearableKeybind(moveRight, "Anti-Fling", "AntiFling", function()
    AntiFlingToggle:UpdateState(not Config.AntiFlingEnabled)
end)

local NoclipToggle = moveRight:Toggle({ Name = "Noclip", Default = false, Callback = function(val) setNoclip(val) end }, "NoclipToggle")
createClearableKeybind(moveRight, "Noclip", "Noclip", function()
    NoclipToggle:UpdateState(not Config.Noclip)
end)

local InfJumpToggle = moveRight:Toggle({ Name = "Infinite Jump", Default = false, Callback = function(val) setInfiniteJump(val) end }, "InfJumpToggle")
createClearableKeybind(moveRight, "Infinite Jump", "InfiniteJump", function()
    InfJumpToggle:UpdateState(not Config.InfiniteJump)
end)

local CtrlTpToggle = moveRight:Toggle({ Name = "CTRL + Click TP", Default = false, Callback = function(val) toggleCtrlTP(val) end }, "CtrlTpToggle")
createClearableKeybind(moveRight, "CTRL+Click TP", "CtrlTP", function()
    CtrlTpToggle:UpdateState(not Config.CtrlTP)
end)

moveRight:Button({ Name = "Give TP Tool", Callback = function() giveTpTool() Window:Notify({ Title = "Inventory", Description = "TP Tool added to backpack!", Lifetime = 2.5 }) end })

local FlingToggle = moveRight:Toggle({ Name = "Fling Aura", Default = false, Callback = function(val) setFling(val) end }, "FlingToggle")
createClearableKeybind(moveRight, "Fling Aura", "Fling", function()
    FlingToggle:UpdateState(not Config.FlingEnabled)
end)

moveRight:Header({ Text = "Safe-TP Platform" })
SafeTPToggleObj = moveRight:Toggle({
    Name = "Safe-TP Platform",
    Default = false,
    Callback = function(val)
        toggleSafeTP(val)
        Window:Notify({
            Title = "Safe-TP Platform",
            Description = val and "Teleported to Safe Platform!" or "Returned to Previous Position.",
            Lifetime = 2
        })
    end
}, "SafeTPToggle")

createClearableKeybind(moveRight, "Safe-TP", "SafeTP", function()
    if SafeTPToggleObj then
        SafeTPToggleObj:UpdateState(not Config.SafeTPEnabled)
    else
        toggleSafeTP(not Config.SafeTPEnabled)
    end
end)

moveRight:Slider({
    Name = "Safe-TP Height",
    Default = 1500,
    Minimum = 200,
    Maximum = 5000,
    DisplayMethod = "Value",
    Precision = 0,
    Callback = function(val)
        Config.SafeTPHeight = val
    end
}, "SafeTPHeightSlider")

--------------------------------------------------------------------------------
-- TROLL & FUN TAB
--------------------------------------------------------------------------------

local trollLeft = tabs.Trolling:Section({ Side = "Left" })
local trollRight = tabs.Trolling:Section({ Side = "Right" })

trollLeft:Header({ Text = "Target Selector" })

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
            pcall(function()
                if typeof(PlayerDropdown.ClearOptions) == "function" and typeof(PlayerDropdown.InsertOptions) == "function" then
                    PlayerDropdown:ClearOptions()
                    PlayerDropdown:InsertOptions(updatedList)
                elseif typeof(PlayerDropdown.SetOptions) == "function" then
                    PlayerDropdown:SetOptions(updatedList)
                elseif typeof(PlayerDropdown.Refresh) == "function" then
                    PlayerDropdown:Refresh(updatedList)
                elseif typeof(PlayerDropdown.Update) == "function" then
                    PlayerDropdown:Update(updatedList)
                end
            end)
        end
        Window:Notify({ Title = "Players Refreshed", Description = "Found " .. tostring(#updatedList) .. " player(s).", Lifetime = 2 })
    end,
})

trollLeft:Header({ Text = "Target Trolls" })

local BangToggle = trollLeft:Toggle({
    Name = "Enable Bang", Default = false,
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
createClearableKeybind(trollLeft, "Bang Troll", "Bang", function()
    BangToggle:UpdateState(not bangLoop)
end)

trollLeft:Slider({
    Name = "Bang Speed", Default = 3, Minimum = 1, Maximum = 25, DisplayMethod = "Value", Precision = 1,
    Callback = function(val)
        Config.BangSpeed = val
        if bangAnimTrack then bangAnimTrack:AdjustSpeed(val) end
    end,
}, "BangSpeedSlider")

local CarpetToggle = trollLeft:Toggle({
    Name = "Enable Carpet", Default = false,
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
createClearableKeybind(trollLeft, "Carpet Troll", "Carpet", function()
    CarpetToggle:UpdateState(not carpetLoop)
end)

trollRight:Header({ Text = "External Script Loadstrings" })
trollRight:Button({ Name = "Universal Vehicle Fly", Callback = function() loadstring(game:HttpGet(('https://raw.githubusercontent.com/zachisfunny/Universal-Vehicle-Fly/main/Script'),true))() end })
trollRight:Button({ Name = "Universal Reach Script", Callback = function() loadstring(game:HttpGet(('https://raw.githubusercontent.com/zachisfunny/Universal-Reach/main/Reach%20Script'),true))() end })
trollRight:Button({ Name = "Attach To Back Script", Callback = function() loadstring(game:HttpGet(('https://raw.githubusercontent.com/zachisfunny/Attach-to-back-Script/main/Script'),true))() end })

--------------------------------------------------------------------------------
-- VISUALS TAB
--------------------------------------------------------------------------------

local visLeft = tabs.Visuals:Section({ Side = "Left" })
local visRight = tabs.Visuals:Section({ Side = "Right" })

visLeft:Header({ Text = "Enemy ESP" })
local ESPMasterToggle = visLeft:Toggle({ Name = "Master Visuals Switch", Default = false, Callback = function(val) Config.VisualsEnabled = val if not val then hideAllVisuals() end end }, "ESPMasterToggle")
createClearableKeybind(visLeft, "Visuals", "Visuals", function()
    ESPMasterToggle:UpdateState(not Config.VisualsEnabled)
end)
visLeft:Toggle({ Name = "Chams / Highlights", Default = true, Callback = function(val) Config.HighlightsEnabled = val end }, "ChamsToggle")
visLeft:Toggle({ Name = "Snapline Tracers", Default = true, Callback = function(val) Config.TracersEnabled = val end }, "TracersToggle")
visLeft:Toggle({ Name = "3D Floating Tags", Default = true, Callback = function(val) Config.TagsEnabled = val end }, "TagsToggle")

visRight:Header({ Text = "Minecraft Shaders" })
local ShaderToggle = visRight:Toggle({ Name = "Minecraft Graphics", Default = false, Callback = function(val) applyMinecraftGraphics(val) end }, "ShaderToggle")
createClearableKeybind(visRight, "Shaders", "Graphics", function()
    ShaderToggle:UpdateState(not Config.MinecraftGraphics)
end)

--------------------------------------------------------------------------------
-- SETTINGS TAB
--------------------------------------------------------------------------------

MacLib:SetFolder("SkywarsMaclibSuite")
tabs.Settings:InsertConfigSection("Left")

local sessionSec = tabs.Settings:Section({ Side = "Right" })
sessionSec:Header({ Text = "Session Control" })
sessionSec:Paragraph({
    Header = "Keybind Guide",
    Body = "• Click any Feature's Bind button, then press any keyboard key or mouse click (M1 through M5).\n• Press Backspace or Escape while listening to clear/remove the keybind.\n\n⚡ High-Ping Fast Bow automatically scales burst density with network latency.\n🎯 Silent Aim automatically highlights targets in red when a bow is equipped."
})
sessionSec:Button({ Name = "Unload Suite", Callback = function() if _G.SkywarsSuiteCleanup then _G.SkywarsSuiteCleanup() end end })
sessionSec:Button({
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

tabs.Combat:Select()

--------------------------------------------------------------------------------
-- RUNSERVICE HEARTBEAT ENGINE
--------------------------------------------------------------------------------

safeConnect(RunService.Heartbeat, function(dt)
    local tool = getEquippedTool()
    local match = isMatchActive()
    local char = LocalPlayer.Character
    local root = getRoot(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if tool and string.find(string.lower(tool.Name), "bow") then
        hookBowClientControl(tool)
    end

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
                        if Config.HighlightsEnabled then
                            if tracker.Highlight.Parent ~= c then
                                tracker.Highlight.Adornee = c
                                tracker.Highlight.Parent = c
                            end
                            tracker.Highlight.FillColor = Config.HighlightColor
                            tracker.Highlight.Enabled = true
                        else
                            tracker.Highlight.Enabled = false
                        end

                        if Config.TagsEnabled then
                            if tracker.Billboard.Parent ~= hrp then
                                tracker.Billboard.Adornee = hrp
                                tracker.Billboard.Parent = hrp
                            end
                            tracker.Label.Text = string.format("%s\n%d HP | %d studs", p.DisplayName, math.floor(h.Health), math.floor(dist))
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
                                    tracker.Tracer.Color = Config.TracerColor
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

            if Config.CameraLock then
                Camera.CameraType = Enum.CameraType.Scriptable
                Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, target.Position + Vector3.new(0, 1.5, 0))
            else
                if Camera.CameraType == Enum.CameraType.Scriptable then
                    Camera.CameraType = Enum.CameraType.Custom
                end
            end
        else
            hum.AutoRotate = true
            if Camera.CameraType == Enum.CameraType.Scriptable then
                Camera.CameraType = Enum.CameraType.Custom
            end
        end
    elseif hum and not hum.AutoRotate then
        hum.AutoRotate = true
        if Camera.CameraType == Enum.CameraType.Scriptable then
            Camera.CameraType = Enum.CameraType.Custom
        end
    end

    if not Config.ClickerEnabled or not match or not tool then
        clickAccumulator = 0
        return
    end

    if Config.HoldToClick and not isMouseDown then
        clickAccumulator = 0
        return
    end

    if Config.BypassDetection then
        resetToolRateLimits(tool)
    end

    local rate = Config.CPS
    local name = string.lower(tool.Name)
    if (string.find(name, "block") or string.find(name, "axe") or string.find(name, "pickaxe")) and Config.SmartRateLimit then
        rate = math.min(Config.CPS, Config.BlockMaxCPS)
    end

    clickAccumulator = clickAccumulator + (dt * rate)
    local clicks = math.floor(clickAccumulator)
    if clicks > 0 then
        clickAccumulator = math.clamp(clickAccumulator - clicks, 0, 10)
        
        task.spawn(function()
            for _ = 1, math.min(clicks, 250) do
                if not tool or not tool.Parent then break end
                performClick(tool)
            end
        end)
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
            if tool and string.find(string.lower(tool.Name), "bow") and Config.HighPingBowEnabled then
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

-- Prevent a stuck "held" state if the window loses focus while Ctrl is down
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
            -- Cache the aim point so the __index hook stays trivial (and only bows are ever redirected,
            -- not block-placing / pickaxe tools that also read Mouse.Hit).
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


-- Install the metamethod hook ONCE per game session; re-executing the suite only swaps the state table
-- (stacking a new hook on every reload caused heavy __index overhead and stale closures).
if not getgenv().__SkywarsAimHooked then
    getgenv().__SkywarsAimHooked = true
    local oldIndex
    oldIndex = hookmetamethod(game, "__index", function(self, key)
        -- Only spoof Mouse.Hit, and only while the Heartbeat loop has a valid cached target
        -- (bow equipped, alive, Ctrl not held). Never do any work/property reads in here.
        if key == "Hit" then
            local st = getgenv().__SkywarsAimState
            if st and st.Active and st.AimCFrame and self == st.Mouse then
                return st.AimCFrame
            end
        end
        return oldIndex(self, key)
    end)
end

--------------------------------------------------------------------------------
-- SUITE CLEANUP / UNLOAD HANDLER
--------------------------------------------------------------------------------

_G.SkywarsSuiteCleanup = function()
    Config.AutoMineEnabled = false
    Config.OreAutoMineEnabled = false
    Config.ReachEnabled = false
    Config.ReachVisuals = false
    Config.Bypass = false
    Config.HighPingBowEnabled = false
    silentAimActive = false
    aimState.Active = false
    aimState.AimCFrame = nil
    pcall(function() targetHighlight:Destroy() end)
    toggleSafeTP(false)
    destroyReachCircle()
    toggleCtrlTP(false)
    setAntiFling(false)
    setNoclip(false)
    NOFLY()
    stopBang()
    stopCarpet()
    setFling(false)
    hideAllVisuals()
    resetAllHitboxes()
    if directVisualBox then pcall(function() directVisualBox:Destroy() end) end
    for block in pairs(oreBoxes) do removeOreBox(block) end
    if hankiCleanerThread then
        pcall(function() task.cancel(hankiCleanerThread) end)
        hankiCleanerThread = nil
    end
    if fpsSteppedConn then
        pcall(function() fpsSteppedConn:Disconnect() end)
        fpsSteppedConn = nil
    end
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(connections)
    pcall(function() Window:Unload() end)
    pcall(function()
        if mobileGui then mobileGui:Destroy() end
    end)
    _G.SkywarsSuiteCleanup = nil
    print("[Maclib] Fully unloaded all modules and UI.")
end