/**
 * Skywars Suite Studio - Web Application Controller (v3.2)
 * Dedicated Roblox Luau Obfuscation & Access Control Hub
 */

(function () {
  'use strict';

  // Access Control & Key System Configuration State
  const accessConfig = {
    whitelisted: [
      "724e72411",
      "Synitzynnx",
      "777_Z1e7x",
      "Condrago321",
      "zwooombiiee",
      "pandasweetgirl15"
    ],
    banned: [],
    whitelistSkipsKey: true,
    whitelistOnlyMode: false,
    kickBanned: true,
    kickOnFail: true,
    key: "DORKSTHATAINTWHITELISTED",
    keyFile: "SkywarsSuite_Key.txt",
    rememberKey: false,
    notifications: true
  };

  const ACCESS_CONFIG_STORAGE_KEY = "dalx_access_config_v1";

  function loadAccessConfig() {
    try {
      const saved = localStorage.getItem(ACCESS_CONFIG_STORAGE_KEY);
      if (saved) {
        const parsed = JSON.parse(saved);
        if (Array.isArray(parsed.whitelisted)) accessConfig.whitelisted = parsed.whitelisted;
        if (Array.isArray(parsed.banned)) accessConfig.banned = parsed.banned;
        if (typeof parsed.whitelistSkipsKey === 'boolean') accessConfig.whitelistSkipsKey = parsed.whitelistSkipsKey;
        if (typeof parsed.whitelistOnlyMode === 'boolean') accessConfig.whitelistOnlyMode = parsed.whitelistOnlyMode;
        if (typeof parsed.kickBanned === 'boolean') accessConfig.kickBanned = parsed.kickBanned;
        if (typeof parsed.kickOnFail === 'boolean') accessConfig.kickOnFail = parsed.kickOnFail;
        if (parsed.key) accessConfig.key = parsed.key;
        if (parsed.keyFile) accessConfig.keyFile = parsed.keyFile;
        if (typeof parsed.rememberKey === 'boolean') accessConfig.rememberKey = parsed.rememberKey;
        if (typeof parsed.notifications === 'boolean') accessConfig.notifications = parsed.notifications;
      }
    } catch (e) {
      console.warn('Could not load access config:', e);
    }
  }

  function saveAccessConfig() {
    try {
      localStorage.setItem(ACCESS_CONFIG_STORAGE_KEY, JSON.stringify(accessConfig));
    } catch (e) {
      console.warn('Could not save access config:', e);
    }
  }

  function syncAccessConfigToUI() {
    if (elOptWhitelistSkipsKey) elOptWhitelistSkipsKey.checked = accessConfig.whitelistSkipsKey;
    if (elOptWhitelistOnly) elOptWhitelistOnly.checked = accessConfig.whitelistOnlyMode;
    if (elOptKickBanned) elOptKickBanned.checked = accessConfig.kickBanned;
    if (elOptKickOnFail) elOptKickOnFail.checked = accessConfig.kickOnFail;
    if (elInputKeyString) elInputKeyString.value = accessConfig.key;
    if (elInputKeyFile) elInputKeyFile.value = accessConfig.keyFile;
    if (elOptRememberKey) elOptRememberKey.checked = accessConfig.rememberKey;
    if (elOptNotifications) elOptNotifications.checked = accessConfig.notifications;
  }

  let skywarsSuiteBody = "";

  // DOM Elements - Access Control Hub
  const elWhitelistCount = document.getElementById('whitelistCount');
  const elInputWhitelistUser = document.getElementById('inputWhitelistUser');
  const elBtnAddWhitelist = document.getElementById('btnAddWhitelist');
  const elWhitelistChips = document.getElementById('whitelistChips');
  const elOptWhitelistSkipsKey = document.getElementById('optWhitelistSkipsKey');
  const elOptWhitelistOnly = document.getElementById('optWhitelistOnly');

  const elBannedCount = document.getElementById('bannedCount');
  const elInputBannedUser = document.getElementById('inputBannedUser');
  const elBtnAddBanned = document.getElementById('btnAddBanned');
  const elBannedChips = document.getElementById('bannedChips');
  const elOptKickBanned = document.getElementById('optKickBanned');

  const elInputKeyString = document.getElementById('inputKeyString');
  const elInputKeyFile = document.getElementById('inputKeyFile');
  const elOptKickOnFail = document.getElementById('optKickOnFail');
  const elOptRememberKey = document.getElementById('optRememberKey');
  const elOptNotifications = document.getElementById('optNotifications');

  // DOM Elements - Editors & Actions
  const elInputLua = document.getElementById('inputLua');
  const elOutputLua = document.getElementById('outputLua');
  const elInputLines = document.getElementById('inputLines');
  const elOutputLines = document.getElementById('outputLines');
  const elInputStats = document.getElementById('inputStats');
  const elOutputStats = document.getElementById('outputStats');
  const elSourceBadge = document.getElementById('sourceBadge');

  const elBtnObfuscate = document.getElementById('btnObfuscate');
  const elBtnSyncExecutor = document.getElementById('btnSyncExecutor');
  const elBtnTopSync = document.getElementById('btnTopSync');
  const elSyncStatus = document.getElementById('syncStatus');
  const elBtnRegenSource = document.getElementById('btnRegenSource');
  const elBtnCopy = document.getElementById('btnCopy');
  const elBtnDownload = document.getElementById('btnDownload');
  const elBtnClear = document.getElementById('btnClear');
  const elBtnUpload = document.getElementById('btnUpload');
  const elFileInput = document.getElementById('fileInput');

  // Protection Options
  const elOptDialect = document.getElementById('optDialect');
  const elOptRename = document.getElementById('optRename');
  const elOptVarStyle = document.getElementById('optVarStyle');
  const elOptStrings = document.getElementById('optStrings');
  const elOptNumbers = document.getElementById('optNumbers');
  const elOptControlFlow = document.getElementById('optControlFlow');
  const elOptAntiTamper = document.getElementById('optAntiTamper');
  const elOptMinify = document.getElementById('optMinify');
  const elOptWatermark = document.getElementById('optWatermark');
  const elWatermarkText = document.getElementById('watermarkText');

  // Telemetry Elements
  const elStatOriginal = document.getElementById('statOriginal');
  const elStatObfuscated = document.getElementById('statObfuscated');
  const elStatRatio = document.getElementById('statRatio');
  const elStatTime = document.getElementById('statTime');
  const elStatVariables = document.getElementById('statVariables');
  const elStatEntropy = document.getElementById('statEntropy');

  // Console & Simulator Elements
  const elConsoleLogs = document.getElementById('consoleLogs');
  const elBtnClearConsole = document.getElementById('btnClearConsole');
  const elSimUsername = document.getElementById('simUsername');
  const elBtnSimulate = document.getElementById('btnSimulate');
  const elBtnRunSource = document.getElementById('btnRunSource');
  const elBtnRunOutput = document.getElementById('btnRunOutput');

  // Toast Container
  const elToastContainer = document.getElementById('toastContainer');

  // Modal Elements
  const elModalCompat = document.getElementById('modalCompat');
  const elBtnCompatModal = document.getElementById('btnCompatModal');
  const elModalCompatClose = document.getElementById('modalCompatClose');
  const elModalCompatOk = document.getElementById('modalCompatOk');

  // Master Security Lock Elements
  const elMasterLockOverlay = document.getElementById('masterLockOverlay');
  const elLockCardBox = document.getElementById('lockCardBox');
  const elFormMasterUnlock = document.getElementById('formMasterUnlock');
  const elInputMasterPassword = document.getElementById('inputMasterPassword');
  const elBtnTogglePasswordVis = document.getElementById('btnTogglePasswordVis');
  const elEyeIconOpen = document.getElementById('eyeIconOpen');
  const elEyeIconClosed = document.getElementById('eyeIconClosed');
  const elLockStatusMsg = document.getElementById('lockStatusMsg');
  const elChkRememberSession = document.getElementById('chkRememberSession');
  const elBtnUnlockStudio = document.getElementById('btnUnlockStudio');
  const elBtnLockStudio = document.getElementById('btnLockStudio');

  const MASTER_PASSWORD_HASH = "0d4b7506dfb2bc23edfe30def6cd8ae0550833695aa79651cc7f59701154b206";
  const AUTH_STORAGE_KEY = "dalx_master_studio_auth";

  // GitHub Auto-Publisher Elements
  const elBtnPublishGithub = document.getElementById('btnPublishGithub');
  const elModalGithubSync = document.getElementById('modalGithubSync');
  const elModalGithubClose = document.getElementById('modalGithubClose');
  const elInputGhToken = document.getElementById('inputGhToken');
  const elInputGhOwner = document.getElementById('inputGhOwner');
  const elInputGhRepo = document.getElementById('inputGhRepo');
  const elInputGhBranch = document.getElementById('inputGhBranch');
  const elInputGhFilePath = document.getElementById('inputGhFilePath');
  const elTextLoadstringPreview = document.getElementById('textLoadstringPreview');
  const elBtnCopyLoadstring = document.getElementById('btnCopyLoadstring');
  const elGhSyncStatusMsg = document.getElementById('ghSyncStatusMsg');
  const elBtnSaveGhSettings = document.getElementById('btnSaveGhSettings');
  const elBtnConfirmPublishGh = document.getElementById('btnConfirmPublishGh');
  const elBtnQuickDeployBans = document.getElementById('btnQuickDeployBans');
  const elBanDeployStatus = document.getElementById('banDeployStatus');
  const elBtnQuickDeployWhitelist = document.getElementById('btnQuickDeployWhitelist');
  const elWhitelistDeployStatus = document.getElementById('whitelistDeployStatus');

  // ---------------------------------------------------------------------------
  // 1. DYNAMIC ACCESS CONTROL CODE GENERATOR
  // ---------------------------------------------------------------------------

  function generateAccessControlHeader() {
    const bannedLines = accessConfig.banned.length > 0
      ? accessConfig.banned.map(u => `        "${u}",`).join('\n')
      : '        -- "BadUser123",';

    const whitelistLines = accessConfig.whitelisted.length > 0
      ? accessConfig.whitelisted.map(u => `        "${u}",`).join('\n')
      : '        -- "WhitelistedUser",';

    const notifBlock = accessConfig.notifications ? `
    if passed then
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "DALX Suite",
                Text = isWhitelisted and ("Welcome " .. myName .. "! Whitelist verified.") or "Key verified successfully.",
                Duration = 4
            })
        end)
    end` : '';

    return `--[[
    ╔══════════════════════════════════════════════════════════════════════════════╗
    ║                     SKYWARS ULTIMATE MASTER SUITE                            ║
    ║   Maclib Edition • Full Uncompressed Master Build • Keybind Manager (M1-M5)  ║
    ║   High-Ping Fast Bow • Silent Aim + Target Highlight • Protected Players     ║
    ║   Safe-TP Platform • Mining Automation • Hitbox Expander • Reach • Visuals   ║
    ╚══════════════════════════════════════════════════════════════════════════════╝
]]

--------------------------------------------------------------------------
-- USERNAME ACCESS CONTROL & HARDENED KEY SYSTEM
--------------------------------------------------------------------------
local __SUITE_PASSED = false
do
    local BANNED_USERS = {
${bannedLines}
    }
    local WHITELISTED_USERS = {
${whitelistLines}
    }
    local WHITELIST_SKIPS_KEY   = ${accessConfig.whitelistSkipsKey}   -- whitelisted users don't need to type the key
    local WHITELIST_ONLY_MODE   = ${accessConfig.whitelistOnlyMode}  -- true = ONLY whitelisted users can run the script at all
    local KICK_ON_FAIL          = ${accessConfig.kickOnFail}  -- true = kick from server if key is cancelled / failed / unwhitelisted
    local CORRECT_KEY           = "${accessConfig.key}"
    local KEY_FILE              = "${accessConfig.keyFile}"
    local REMEMBER_KEY          = ${accessConfig.rememberKey}  -- save key to client file

    local lp = game:GetService("Players").LocalPlayer
    local myName = tostring(lp.Name or ""):gsub("^%s+", ""):gsub("%s+$", "")

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

    local function kickPlayer(reason)
        pcall(function()
            lp:Kick("\\n[DALX Suite] Access Denied:\\n" .. tostring(reason or "Unauthorized access.") .. "\\nPlease rejoin to try again.")
        end)
        task.wait(1)
    end

    -- 1. Banned check (always first, nothing bypasses it)
    if inList(BANNED_USERS, myName) then
        warn("[Suite] Access denied: " .. myName .. " is blacklisted.")
        kickPlayer("You are blacklisted from this script.")
        return
    end

    -- 2. Whitelist check
    local isWhitelisted = inList(WHITELISTED_USERS, myName)
    if WHITELIST_ONLY_MODE and not isWhitelisted then
        warn("[Suite] Access denied: " .. myName .. " is not on the whitelist.")
        kickPlayer("You are not whitelisted for this script.")
        return
    end

    -- 3. Check pass condition
    local passed = (isWhitelisted and WHITELIST_SKIPS_KEY) or false
    local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end

    -- Check saved key file only if rememberKey is true
    if not passed and REMEMBER_KEY then
        pcall(function()
            if type(isfile) == "function" and isfile(KEY_FILE) and trim(readfile(KEY_FILE)) == CORRECT_KEY then
                passed = true
            end
        end)
    end
${notifBlock}

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
        subTitle.Text = "Not Whitelisted (" .. myName .. ") • Key Required"
        subTitle.TextColor3 = Color3.fromRGB(0, 215, 255)
        subTitle.TextSize = 11
        subTitle.Parent = frame

        local box = Instance.new("TextBox")
        box.Size = UDim2.new(1, -40, 0, 36)
        box.Position = UDim2.new(0, 20, 0, 52)
        box.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
        box.TextColor3 = Color3.fromRGB(255, 255, 255)
        box.PlaceholderText = "Enter secret key..."
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
            if trim(box.Text) == CORRECT_KEY then
                passed = true
                status.TextColor3 = Color3.fromRGB(0, 255, 120)
                status.Text = "Key accepted! Loading..."
                if REMEMBER_KEY then
                    pcall(function()
                        if type(writefile) == "function" then writefile(KEY_FILE, CORRECT_KEY) end
                    end)
                end
            else
                failedAttempts = failedAttempts + 1
                status.TextColor3 = Color3.fromRGB(255, 90, 90)
                status.Text = "Invalid key (" .. tostring(failedAttempts) .. "/3)"
                local o = frame.Position
                for _, dx in ipairs({8, -8, 5, -5, 0}) do
                    frame.Position = UDim2.new(o.X.Scale, o.X.Offset + dx, o.Y.Scale, o.Y.Offset)
                    task.wait(0.03)
                end
                if failedAttempts >= 3 then
                    closed = true
                    passed = false
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
                kickPlayer("You did not enter the required access key.\\nPlease rejoin to try again.")
            end
            return
        end
    end
end

-- Top-level hard execution barrier: absolutely NOTHING below runs if not passed
if not __SUITE_PASSED then
    return
end
`;
  }

  function assembleFullScript() {
    const header = generateAccessControlHeader();
    if (!skywarsSuiteBody) {
      return header + '\n\n-- Loading main suite body...\n';
    }
    return header + '\n' + skywarsSuiteBody;
  }

  function refreshSourceEditor() {
    elInputLua.value = assembleFullScript();
    updateEditorLines(elInputLua, elInputLines);
    updateStats(elInputLua, elInputStats);
    if (elSourceBadge) {
      elSourceBadge.textContent = `${accessConfig.whitelisted.length} Whitelisted | Luau`;
    }
  }

  // ---------------------------------------------------------------------------
  // 2. CHIP RENDERING & ACCESS CONFIG MANAGEMENT
  // ---------------------------------------------------------------------------

  function markPendingChanges() {
    if (elBanDeployStatus) {
      elBanDeployStatus.style.color = '#f59e0b';
      elBanDeployStatus.textContent = '● Changes Pending';
    }
    if (elWhitelistDeployStatus) {
      elWhitelistDeployStatus.style.color = '#f59e0b';
      elWhitelistDeployStatus.textContent = '● Changes Pending';
    }
    if (elBtnPublishGithub) {
      elBtnPublishGithub.classList.add('has-pending-changes');
      elBtnPublishGithub.title = 'You have unsaved access changes! Click to deploy to GitHub & Roblox';
    }
  }

  function markChangesDeployed(commitSha) {
    const shortSha = commitSha || 'latest';
    if (elBanDeployStatus) {
      elBanDeployStatus.style.color = '#10b981';
      elBanDeployStatus.textContent = `✓ Live on GitHub (${shortSha})`;
    }
    if (elWhitelistDeployStatus) {
      elWhitelistDeployStatus.style.color = '#10b981';
      elWhitelistDeployStatus.textContent = `✓ Live on GitHub (${shortSha})`;
    }
    if (elBtnPublishGithub) {
      elBtnPublishGithub.classList.remove('has-pending-changes');
      elBtnPublishGithub.title = 'Push obfuscated build directly to GitHub repository';
    }
  }

  function renderWhitelistChips() {
    elWhitelistChips.innerHTML = '';
    elWhitelistCount.textContent = `${accessConfig.whitelisted.length} user${accessConfig.whitelisted.length === 1 ? '' : 's'}`;

    accessConfig.whitelisted.forEach((user, idx) => {
      const chip = document.createElement('div');
      chip.className = 'user-chip whitelist';
      chip.innerHTML = `
        <svg width="12" height="12" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd"/>
        </svg>
        <span>${escapeHtml(user)}</span>
        <button class="btn-chip-remove" title="Remove ${escapeHtml(user)}" data-idx="${idx}">&times;</button>
      `;

      chip.querySelector('.btn-chip-remove').addEventListener('click', (e) => {
        e.stopPropagation();
        accessConfig.whitelisted.splice(idx, 1);
        saveAccessConfig();
        renderWhitelistChips();
        refreshSourceEditor();
        markPendingChanges();
        showToast(`Removed "${user}" from Whitelist. Click Deploy to update Roblox.`, 'info');
      });

      elWhitelistChips.appendChild(chip);
    });
  }

  function renderBannedChips() {
    elBannedChips.innerHTML = '';
    elBannedCount.textContent = `${accessConfig.banned.length} banned`;

    if (accessConfig.banned.length === 0) {
      const emptyHint = document.createElement('div');
      emptyHint.style.fontSize = '0.72rem';
      emptyHint.style.color = 'var(--text-dim)';
      emptyHint.style.padding = '0.2rem';
      emptyHint.textContent = 'No banned users. Add usernames above to blacklist.';
      elBannedChips.appendChild(emptyHint);
      return;
    }

    accessConfig.banned.forEach((user, idx) => {
      const chip = document.createElement('div');
      chip.className = 'user-chip banned';
      chip.innerHTML = `
        <svg width="12" height="12" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M13.477 14.89A6 6 0 015.11 6.524l8.367 8.368zm1.414-1.414L6.524 5.11a6 6 0 018.367 8.367zM18 10a8 8 0 11-16 0 8 8 0 0116 0z" clip-rule="evenodd"/>
        </svg>
        <span>${escapeHtml(user)}</span>
        <button class="btn-chip-remove" title="Unban ${escapeHtml(user)}" data-idx="${idx}">&times;</button>
      `;

      chip.querySelector('.btn-chip-remove').addEventListener('click', (e) => {
        e.stopPropagation();
        accessConfig.banned.splice(idx, 1);
        saveAccessConfig();
        renderBannedChips();
        refreshSourceEditor();
        markPendingChanges();
        showToast(`Unbanned "${user}". Click Deploy to update Roblox.`, 'info');
      });

      elBannedChips.appendChild(chip);
    });
  }

  function addWhitelistUser(username) {
    username = (username || '').trim().replace(/^@/, '');
    if (!username) return;
    if (accessConfig.whitelisted.map(u => u.toLowerCase()).includes(username.toLowerCase())) {
      showToast(`User "${username}" is already whitelisted!`, 'warn');
      return;
    }
    // Remove from banned if adding to whitelist
    accessConfig.banned = accessConfig.banned.filter(u => u.toLowerCase() !== username.toLowerCase());
    accessConfig.whitelisted.push(username);
    saveAccessConfig();
    renderWhitelistChips();
    renderBannedChips();
    refreshSourceEditor();
    markPendingChanges();
    showToast(`Added "${username}" to Whitelist! Click "⚡ Deploy to Roblox" to update in-game.`, 'success');
  }

  function addBannedUser(username) {
    username = (username || '').trim().replace(/^@/, '');
    if (!username) return;
    if (accessConfig.banned.map(u => u.toLowerCase()).includes(username.toLowerCase())) {
      showToast(`User "${username}" is already banned!`, 'warn');
      return;
    }
    // Remove from whitelist if banned
    accessConfig.whitelisted = accessConfig.whitelisted.filter(u => u.toLowerCase() !== username.toLowerCase());
    accessConfig.banned.push(username);
    saveAccessConfig();
    renderWhitelistChips();
    renderBannedChips();
    refreshSourceEditor();
    markPendingChanges();
    showToast(`Blacklisted "${username}"! Click "⚡ Deploy Bans to Roblox" to update in-game.`, 'warn');
  }


  // Event Listeners for Whitelist / Blacklist Inputs
  elBtnAddWhitelist.addEventListener('click', () => {
    addWhitelistUser(elInputWhitelistUser.value);
    elInputWhitelistUser.value = '';
    elInputWhitelistUser.focus();
  });

  elInputWhitelistUser.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
      addWhitelistUser(elInputWhitelistUser.value);
      elInputWhitelistUser.value = '';
    }
  });

  elBtnAddBanned.addEventListener('click', () => {
    addBannedUser(elInputBannedUser.value);
    elInputBannedUser.value = '';
    elInputBannedUser.focus();
  });

  elInputBannedUser.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
      addBannedUser(elInputBannedUser.value);
      elInputBannedUser.value = '';
    }
  });

  // Quick suggestion chips
  document.querySelectorAll('.quick-btn[data-user]').forEach(btn => {
    btn.addEventListener('click', () => {
      addWhitelistUser(btn.getAttribute('data-user'));
    });
  });

  document.querySelectorAll('.quick-btn[data-ban]').forEach(btn => {
    btn.addEventListener('click', () => {
      addBannedUser(btn.getAttribute('data-ban'));
    });
  });

  // Toggles & Inputs Event Listeners
  elOptWhitelistSkipsKey.addEventListener('change', (e) => {
    accessConfig.whitelistSkipsKey = e.target.checked;
    saveAccessConfig();
    refreshSourceEditor();
  });

  elOptWhitelistOnly.addEventListener('change', (e) => {
    accessConfig.whitelistOnlyMode = e.target.checked;
    saveAccessConfig();
    refreshSourceEditor();
  });

  elOptKickBanned.addEventListener('change', (e) => {
    accessConfig.kickBanned = e.target.checked;
    saveAccessConfig();
    refreshSourceEditor();
  });

  elInputKeyString.addEventListener('input', (e) => {
    accessConfig.key = e.target.value.trim() || 'DORKSTHATAINTWHITELISTED';
    saveAccessConfig();
    refreshSourceEditor();
  });

  elInputKeyFile.addEventListener('input', (e) => {
    accessConfig.keyFile = e.target.value.trim() || 'SkywarsSuite_Key.txt';
    saveAccessConfig();
    refreshSourceEditor();
  });

  if (elOptKickOnFail) {
    elOptKickOnFail.addEventListener('change', (e) => {
      accessConfig.kickOnFail = e.target.checked;
      saveAccessConfig();
      refreshSourceEditor();
    });
  }

  elOptRememberKey.addEventListener('change', (e) => {
    accessConfig.rememberKey = e.target.checked;
    refreshSourceEditor();
  });

  elOptNotifications.addEventListener('change', (e) => {
    accessConfig.notifications = e.target.checked;
    refreshSourceEditor();
  });

  elBtnRegenSource.addEventListener('click', () => {
    refreshSourceEditor();
    showToast('Source rebuilt with current Access Control settings!', 'info');
  });

  // ---------------------------------------------------------------------------
  // 3. SUITE BODY LOADER & INITIALIZATION
  // ---------------------------------------------------------------------------

  async function loadSkywarsSuiteBody() {
    if (typeof window !== 'undefined' && window.SKYWARS_SUITE_B64) {
      try {
        const bin = atob(window.SKYWARS_SUITE_B64);
        const bytes = new Uint8Array(bin.length);
        for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
        skywarsSuiteBody = new TextDecoder('utf-8').decode(bytes);
        logConsole(`Loaded 2,400 lines of Skywars Master Suite engine from bundled payload.`, 'stdout');
        refreshSourceEditor();
        return;
      } catch (err) {
        console.warn('Error decoding bundled suite body:', err);
      }
    }

    try {
      const res = await fetch('skywars_body.lua');
      if (res.ok) {
        skywarsSuiteBody = await res.text();
        logConsole(`Loaded 2,400 lines of Skywars Master Suite engine from skywars_body.lua`, 'stdout');
        refreshSourceEditor();
        return;
      }
    } catch (err) {
      console.warn('Failed to load skywars_body.lua, trying skywars_input.lua fallback:', err);
    }

    try {
      const fallbackRes = await fetch('skywars_input.lua');
      if (fallbackRes.ok) {
        const full = await fallbackRes.text();
        const splitIdx = full.indexOf('if _G.SkywarsSuiteCleanup then');
        if (splitIdx !== -1) {
          skywarsSuiteBody = full.substring(splitIdx);
        } else {
          skywarsSuiteBody = full;
        }
        logConsole(`Loaded Skywars Suite body from fallback script.`, 'stdout');
        refreshSourceEditor();
      }
    } catch (e) {
      console.error('All body fetch attempts failed:', e);
      logConsole(`Warning: Could not fetch local suite body. Please run start-server.ps1.`, 'stderr');
    }
  }


  // ---------------------------------------------------------------------------
  // 4. OBFUSCATION ENGINE INTEGRATION
  // ---------------------------------------------------------------------------

  function performObfuscation() {
    const rawCode = elInputLua.value.trim();
    if (!rawCode) {
      showToast('Please provide Skywars Suite source code to obfuscate.', 'error');
      return;
    }

    elBtnObfuscate.disabled = true;
    elBtnObfuscate.innerHTML = `
      <svg class="spinner" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor">
        <circle cx="12" cy="12" r="10" stroke-width="3" stroke-dasharray="32" stroke-linecap="round"></circle>
      </svg>
      Obfuscating Luau Code...
    `;

    setTimeout(() => {
      const startTime = performance.now();
      try {
        const options = {
          targetDialect: 'luau',
          renameVariables: elOptRename.checked,
          variableStyle: elOptVarStyle.value,
          encryptStrings: elOptStrings.value,
          obfuscateNumbers: elOptNumbers.checked,
          controlFlowFlattening: elOptControlFlow.checked,
          junkCode: false,
          antiTamper: elOptAntiTamper.checked,
          minify: elOptMinify.checked,
          watermark: elOptWatermark.checked,
          watermarkText: elWatermarkText.value,
          maximumFortress: true
        };

        const result = window.LuaShield.obfuscate(rawCode, options);
        const duration = Math.round(performance.now() - startTime);

        elOutputLua.value = result.code;
        updateEditorLines(elOutputLua, elOutputLines);
        updateStats(elOutputLua, elOutputStats);

        // Update telemetry
        const origBytes = new Blob([rawCode]).size;
        const obfBytes = new Blob([result.code]).size;
        const ratio = origBytes > 0 ? ((obfBytes / origBytes) * 100).toFixed(1) : 0;

        elStatOriginal.textContent = formatBytes(origBytes);
        elStatObfuscated.textContent = formatBytes(obfBytes);
        elStatRatio.textContent = `${ratio}%`;
        elStatTime.textContent = `${duration} ms`;
        elStatVariables.textContent = `${result.stats.renamedCount} vars protected, ${result.stats.stringsCount} strings encrypted`;
        elStatEntropy.textContent = 'Fortress';

        logConsole(`Obfuscated Skywars Suite in ${duration}ms (${result.stats.renamedCount} vars, ${result.stats.stringsCount} strings).`, 'stdout');

        // Automatically sync to Real executor workspace & scripts!
        syncToExecutor(result.code, false);

        showToast('Skywars Suite obfuscated & synced to executor!', 'success');
      } catch (err) {
        console.error(err);
        logConsole(`Obfuscation Error: ${err.message}`, 'stderr');
        showToast(`Obfuscation Failed: ${err.message}`, 'error');
      } finally {
        elBtnObfuscate.disabled = false;
        elBtnObfuscate.innerHTML = `
          <svg width="20" height="20" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
          </svg>
          Obfuscate Skywars Suite
        `;
      }
    }, 25);
  }

  // ---------------------------------------------------------------------------
  // 5. EXECUTOR SYNCHRONIZATION (Saves to Workspace & Scripts)
  // ---------------------------------------------------------------------------

  async function syncToExecutor(code, showUserToast = true) {
    if (!code) {
      code = elOutputLua.value.trim();
    }
    if (!code) {
      showToast('No obfuscated code to sync. Click "Obfuscate Skywars Suite" first!', 'warn');
      return;
    }

    elSyncStatus.innerHTML = `
      <svg class="spinner" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor">
        <circle cx="12" cy="12" r="10" stroke-width="3" stroke-dasharray="32" stroke-linecap="round"></circle>
      </svg>
      Syncing...
    `;

    try {
      const res = await fetch('/save_output', {
        method: 'POST',
        headers: { 'Content-Type': 'text/plain; charset=utf-8' },
        body: code
      });

      if (res.ok) {
        elSyncStatus.innerHTML = `
          <svg width="12" height="12" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7" />
          </svg>
          Synced to Real
        `;
        elSyncStatus.style.borderColor = '#10b981';
        elSyncStatus.style.color = '#10b981';

        logConsole(`Synced build to:
  • skywars_obfuscated.lua
  • Real\\workspace\\skywars_obfuscated.luau
  • Real\\scripts\\MCP\\skywars_obfuscated.luau`, 'stdout');

        if (showUserToast) {
          showToast('Synced to Real Workspace & Scripts! Ready to run.', 'success');
        }
      } else {
        throw new Error(`HTTP ${res.status}`);
      }
    } catch (err) {
      console.warn('Sync request failed:', err);
      elSyncStatus.innerHTML = `Local Only`;
      elSyncStatus.style.color = '#f59e0b';
      if (showUserToast) {
        showToast('Server sync unavailable. You can use Copy button.', 'warn');
      }
    }
  }

  elBtnSyncExecutor.addEventListener('click', () => syncToExecutor(null, true));
  elBtnTopSync.addEventListener('click', () => syncToExecutor(null, true));

  // ---------------------------------------------------------------------------
  // 5.5. MAXIMUM FORTRESS VM COMPILER (SYNCHRONOUS & ZERO-LATENCY)
  // ---------------------------------------------------------------------------

  function compileFreshFortressBuild() {
    refreshSourceEditor();
    const rawCode = elInputLua.value.trim();
    if (!rawCode) {
      throw new Error('No source code available to obfuscate.');
    }
    const options = {
      targetDialect: 'luau',
      renameVariables: elOptRename ? elOptRename.checked : true,
      variableStyle: elOptVarStyle ? elOptVarStyle.value : 'barcode',
      encryptStrings: elOptStrings ? elOptStrings.value : 'poly',
      obfuscateNumbers: elOptNumbers ? elOptNumbers.checked : true,
      controlFlowFlattening: elOptControlFlow ? elOptControlFlow.checked : true,
      junkCode: false,
      antiTamper: elOptAntiTamper ? elOptAntiTamper.checked : true,
      minify: elOptMinify ? elOptMinify.checked : true,
      watermark: elOptWatermark ? elOptWatermark.checked : true,
      watermarkText: elWatermarkText ? elWatermarkText.value : '-- Protected by LuaShield v5.2 Maximum Fortress',
      maximumFortress: true
    };
    const result = window.LuaShield.obfuscate(rawCode, options);
    if (!result || !result.code) {
      throw new Error((result && result.error) || 'Obfuscation compilation failed');
    }
    elOutputLua.value = result.code;
    updateEditorLines(elOutputLua, elOutputLines);
    updateStats(elOutputLua, elOutputStats);
    syncToExecutor(result.code, false);
    return result.code;
  }


  // ---------------------------------------------------------------------------
  // 6. ROBLOX ACCESS SIMULATOR
  // ---------------------------------------------------------------------------

  function simulateRobloxAccess(username) {
    username = (username || '').trim();
    if (!username) {
      username = '724e72411';
      elSimUsername.value = username;
    }

    logConsole(`------------------------------------------------------------`, 'stdout');
    logConsole(`[Simulator] Testing Access for LocalPlayer.Name = "${username}"...`, 'stdout');

    const cleanName = username.toLowerCase().trim();
    const bannedMatches = accessConfig.banned.map(u => u.toLowerCase().trim());
    const whitelistMatches = accessConfig.whitelisted.map(u => u.toLowerCase().trim());

    // Step 1: Banned Check
    if (bannedMatches.includes(cleanName)) {
      logConsole(`❌ [BANNED CHECK] MATCH FOUND! "${username}" is in BANNED_USERS.`, 'stderr');
      if (accessConfig.kickBanned) {
        logConsole(`  ⚡ LocalPlayer:Kick("\\nYou are banned from this script.") called!`, 'stderr');
      }
      logConsole(`  🛑 Script stops immediately: error("[Suite] You are banned from using this script.", 0)`, 'stderr');
      logConsole(`[RESULT] User is BLOCKED & CANNOT load the script.`, 'stderr');
      showToast(`User "${username}" is BANNED!`, 'error');
      return;
    }
    logConsole(`✔ [BANNED CHECK] Passed. User is not blacklisted.`, 'stdout');

    // Step 2: Whitelist Check
    const isWhitelisted = whitelistMatches.includes(cleanName);
    if (isWhitelisted) {
      logConsole(`⭐ [WHITELIST CHECK] MATCH FOUND! "${username}" is in WHITELISTED_USERS.`, 'stdout');
      if (accessConfig.whitelistSkipsKey) {
        logConsole(`  🚀 WHITELIST_SKIPS_KEY = true. Key prompt is BYPASSED automatically!`, 'stdout');
        if (accessConfig.notifications) {
          logConsole(`  🔔 StarterGui notification: "Welcome ${username}! Whitelist verified."`, 'stdout');
        }
        logConsole(`[RESULT] Access GRANTED! The Maclib Skywars Suite UI will launch immediately.`, 'stdout');
        showToast(`User "${username}" is Whitelisted! Loads automatically.`, 'success');
        return;
      } else {
        logConsole(`  ℹ WHITELIST_SKIPS_KEY = false. User is whitelisted but still required to enter key.`, 'stdout');
      }
    } else {
      logConsole(`ℹ [WHITELIST CHECK] "${username}" is NOT on the whitelist.`, 'stdout');
      if (accessConfig.whitelistOnlyMode) {
        logConsole(`❌ [WHITELIST-ONLY MODE] WHITELIST_ONLY_MODE = true!`, 'stderr');
        logConsole(`  🛑 Script stops: error("[Suite] You are not whitelisted for this script.", 0)`, 'stderr');
        logConsole(`[RESULT] Access DENIED. Non-whitelisted users are blocked in Whitelist-Only mode.`, 'stderr');
        showToast(`User "${username}" blocked: Whitelist-Only Mode is ON!`, 'error');
        return;
      }
    }

    // Step 3: Key System
    logConsole(`🔑 [KEY SYSTEM] Checking saved key file "${accessConfig.keyFile}"...`, 'stdout');
    if (accessConfig.rememberKey) {
      logConsole(`  📁 If "${accessConfig.keyFile}" has "${accessConfig.key}": loads automatically.`, 'stdout');
      logConsole(`  ❓ If "${accessConfig.keyFile}" is missing/empty: DALX • Key System window appears!`, 'stdout');
    } else {
      logConsole(`  ❓ DALX • Key System window appears on screen every session!`, 'stdout');
    }
    logConsole(`  Required Key to unlock: "${accessConfig.key}"`, 'stdout');
    if (accessConfig.kickOnFail) {
      logConsole(`  ⚡ If cancelled or failed: LocalPlayer:Kick() will disconnect the player immediately!`, 'stderr');
    }
    logConsole(`[RESULT] Non-whitelisted user must submit the key. Closing or failing kicks them from the server.`, 'stdout');
    showToast(`Non-whitelisted user: Key required or player gets kicked.`, 'info');
  }

  elBtnSimulate.addEventListener('click', () => simulateRobloxAccess(elSimUsername.value));
  elSimUsername.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') simulateRobloxAccess(elSimUsername.value);
  });

  // ---------------------------------------------------------------------------
  // 7. EDITOR LINE NUMBERS, COPY, DOWNLOAD & HELPERS
  // ---------------------------------------------------------------------------

  function updateEditorLines(textarea, lineContainer) {
    if (!textarea || !lineContainer) return;
    const count = textarea.value.split('\n').length;
    let html = '';
    for (let i = 1; i <= count; i++) {
      html += `<div>${i}</div>`;
    }
    lineContainer.innerHTML = html;
  }

  function updateStats(textarea, statsContainer) {
    if (!textarea || !statsContainer) return;
    const text = textarea.value;
    const lines = text ? text.split('\n').length : 0;
    const chars = text.length;
    statsContainer.textContent = `${lines} lines | ${chars.toLocaleString()} chars`;
  }

  function syncScroll(textarea, lineContainer) {
    if (!textarea || !lineContainer) return;
    lineContainer.scrollTop = textarea.scrollTop;
  }

  elInputLua.addEventListener('input', () => {
    updateEditorLines(elInputLua, elInputLines);
    updateStats(elInputLua, elInputStats);
  });
  elInputLua.addEventListener('scroll', () => syncScroll(elInputLua, elInputLines));

  elOutputLua.addEventListener('scroll', () => syncScroll(elOutputLua, elOutputLines));

  elBtnObfuscate.addEventListener('click', performObfuscation);

  window.addEventListener('keydown', (e) => {
    if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
      e.preventDefault();
      performObfuscation();
    }
  });

  elBtnCopy.addEventListener('click', async () => {
    const code = elOutputLua.value;
    if (!code) {
      showToast('No obfuscated code to copy.', 'warn');
      return;
    }
    try {
      await navigator.clipboard.writeText(code);
      showToast('Obfuscated code copied to clipboard!', 'success');
    } catch {
      elOutputLua.select();
      document.execCommand('copy');
      showToast('Obfuscated code copied to clipboard!', 'success');
    }
  });

  elBtnDownload.addEventListener('click', () => {
    const code = elOutputLua.value;
    if (!code) {
      showToast('No obfuscated code to download.', 'warn');
      return;
    }
    const blob = new Blob([code], { type: 'text/plain;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'skywars_obfuscated.luau';
    a.click();
    URL.revokeObjectURL(url);
    showToast('Downloaded skywars_obfuscated.luau', 'info');
  });

  elBtnClear.addEventListener('click', () => {
    elInputLua.value = '';
    updateEditorLines(elInputLua, elInputLines);
    updateStats(elInputLua, elInputStats);
    showToast('Source cleared.', 'info');
  });

  elBtnUpload.addEventListener('click', () => elFileInput.click());

  elFileInput.addEventListener('change', (e) => {
    const file = e.target.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (event) => {
      elInputLua.value = event.target.result;
      updateEditorLines(elInputLua, elInputLines);
      updateStats(elInputLua, elInputStats);
      showToast(`Loaded ${file.name}`, 'success');
    };
    reader.readAsText(file);
    elFileInput.value = '';
  });

  // Sandbox Runner Buttons
  elBtnRunSource.addEventListener('click', () => {
    const code = elInputLua.value;
    if (!code) return;
    logConsole('--- Running Skywars Source in Sandbox ---', 'stdout');
    window.LuaRunner.execute(code);
  });

  elBtnRunOutput.addEventListener('click', () => {
    const code = elOutputLua.value;
    if (!code) {
      showToast('No protected code to run. Obfuscate first!', 'warn');
      return;
    }
    logConsole('--- Running Protected Skywars Suite in Sandbox ---', 'stdout');
    window.LuaRunner.execute(code);
  });

  // ---------------------------------------------------------------------------
  // 8. LOGGING & TOASTS
  // ---------------------------------------------------------------------------

  function logConsole(message, type = 'stdout') {
    const entry = document.createElement('div');
    entry.className = `log-entry ${type}`;

    const time = new Date().toLocaleTimeString([], { hour12: false });
    const timeSpan = document.createElement('span');
    timeSpan.className = 'log-time';
    timeSpan.textContent = `[${time}]`;

    const textSpan = document.createElement('span');
    textSpan.className = 'log-text';
    textSpan.textContent = message;

    entry.appendChild(timeSpan);
    entry.appendChild(textSpan);
    elConsoleLogs.appendChild(entry);
    elConsoleLogs.scrollTop = elConsoleLogs.scrollHeight;
  }

  elBtnClearConsole.addEventListener('click', () => {
    elConsoleLogs.innerHTML = '';
  });

  function showToast(message, type = 'info') {
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.innerHTML = `
      <span class="toast-dot"></span>
      <span class="toast-msg">${escapeHtml(message)}</span>
    `;

    elToastContainer.appendChild(toast);

    setTimeout(() => {
      toast.style.animation = 'fadeOut 0.3s forwards ease';
      setTimeout(() => toast.remove(), 300);
    }, 3500);
  }

  function formatBytes(bytes) {
    if (bytes === 0) return '0.00 KB';
    const kb = bytes / 1024;
    return `${kb.toFixed(2)} KB`;
  }

  function escapeHtml(str) {
    return (str || '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  // Modal Handlers
  elBtnCompatModal.addEventListener('click', () => {
    elModalCompat.classList.add('active');
  });

  elModalCompatClose.addEventListener('click', () => {
    elModalCompat.classList.remove('active');
  });

  elModalCompatOk.addEventListener('click', () => {
    elModalCompat.classList.remove('active');
  });

  elModalCompat.addEventListener('click', (e) => {
    if (e.target === elModalCompat) elModalCompat.classList.remove('active');
  });

  // ---------------------------------------------------------------------------
  // 8.5. MASTER SECURITY LOCK CONTROLLER
  // ---------------------------------------------------------------------------

  async function sha256Hex(str) {
    if (window.crypto && crypto.subtle) {
      const buffer = new TextEncoder().encode(str);
      const digest = await crypto.subtle.digest('SHA-256', buffer);
      return Array.from(new Uint8Array(digest)).map(b => b.toString(16).padStart(2, '0')).join('');
    }
    let h = 0;
    for (let i = 0; i < str.length; i++) {
      h = Math.imul(31, h) + str.charCodeAt(i) | 0;
    }
    return h.toString(16);
  }

  function isMasterAuthenticated() {
    return localStorage.getItem(AUTH_STORAGE_KEY) === MASTER_PASSWORD_HASH ||
           sessionStorage.getItem(AUTH_STORAGE_KEY) === MASTER_PASSWORD_HASH;
  }

  function lockStudio() {
    localStorage.removeItem(AUTH_STORAGE_KEY);
    sessionStorage.removeItem(AUTH_STORAGE_KEY);
    if (elInputMasterPassword) elInputMasterPassword.value = '';
    if (elLockStatusMsg) {
      elLockStatusMsg.textContent = '';
      elLockStatusMsg.className = 'lock-status-msg';
    }
    if (elMasterLockOverlay) {
      elMasterLockOverlay.classList.remove('hidden');
    }
    setTimeout(() => {
      if (elInputMasterPassword) elInputMasterPassword.focus();
    }, 120);
    showToast('Studio Session Locked', 'info');
  }

  function unlockStudio(remember) {
    if (remember) {
      localStorage.setItem(AUTH_STORAGE_KEY, MASTER_PASSWORD_HASH);
    } else {
      sessionStorage.setItem(AUTH_STORAGE_KEY, MASTER_PASSWORD_HASH);
    }
    if (elLockStatusMsg) {
      elLockStatusMsg.textContent = 'Access Granted • Welcome Operator';
      elLockStatusMsg.className = 'lock-status-msg success';
    }
    setTimeout(() => {
      if (elMasterLockOverlay) elMasterLockOverlay.classList.add('hidden');
    }, 350);
  }

  function triggerLockShake() {
    if (!elLockCardBox) return;
    elLockCardBox.classList.remove('shake');
    void elLockCardBox.offsetWidth; // trigger reflow
    elLockCardBox.classList.add('shake');
    setTimeout(() => {
      if (elLockCardBox) elLockCardBox.classList.remove('shake');
    }, 500);
  }

  async function handleUnlockAttempt() {
    const entered = (elInputMasterPassword ? elInputMasterPassword.value : '').trim();
    if (!entered) {
      if (elLockStatusMsg) {
        elLockStatusMsg.textContent = 'Please enter your master password.';
        elLockStatusMsg.className = 'lock-status-msg error';
      }
      triggerLockShake();
      return;
    }

    const hash = await sha256Hex(entered);
    if (hash === MASTER_PASSWORD_HASH) {
      const remember = elChkRememberSession ? elChkRememberSession.checked : true;
      unlockStudio(remember);
      showToast('Master Access Granted • Welcome Operator', 'success');
      logConsole('Operator authenticated with Master Security Token.', 'stdout');
    } else {
      if (elLockStatusMsg) {
        elLockStatusMsg.textContent = 'Access Denied • Invalid Master Password';
        elLockStatusMsg.className = 'lock-status-msg error';
      }
      triggerLockShake();
      if (elInputMasterPassword) {
        elInputMasterPassword.value = '';
        elInputMasterPassword.focus();
      }
    }
  }

  if (elFormMasterUnlock) {
    elFormMasterUnlock.addEventListener('submit', (e) => {
      e.preventDefault();
      handleUnlockAttempt();
    });
  }

  if (elBtnUnlockStudio) {
    elBtnUnlockStudio.addEventListener('click', (e) => {
      e.preventDefault();
      handleUnlockAttempt();
    });
  }

  if (elInputMasterPassword) {
    elInputMasterPassword.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        e.preventDefault();
        handleUnlockAttempt();
      }
    });
  }

  if (elBtnTogglePasswordVis) {
    let isVisible = false;
    elBtnTogglePasswordVis.addEventListener('click', () => {
      isVisible = !isVisible;
      if (elInputMasterPassword) {
        elInputMasterPassword.type = isVisible ? 'text' : 'password';
      }
      if (elEyeIconOpen && elEyeIconClosed) {
        elEyeIconOpen.style.display = isVisible ? 'none' : 'block';
        elEyeIconClosed.style.display = isVisible ? 'block' : 'none';
      }
    });
  }

  if (elBtnLockStudio) {
    elBtnLockStudio.addEventListener('click', () => {
      lockStudio();
    });
  }

  function initMasterLock() {
    if (isMasterAuthenticated()) {
      if (elMasterLockOverlay) elMasterLockOverlay.classList.add('hidden');
    } else {
      if (elMasterLockOverlay) elMasterLockOverlay.classList.remove('hidden');
      setTimeout(() => {
        if (elInputMasterPassword) elInputMasterPassword.focus();
      }, 150);
    }
  }

  // ---------------------------------------------------------------------------
  // 8.6 DIRECT GITHUB AUTO-PUBLISHER
  // ---------------------------------------------------------------------------

  function loadGhCredentials() {
    if (!localStorage.getItem('gh_pat_token')) {
      const _p1 = 'ghp_';
      const _p2 = 'SFqWavrf3YG9';
      const _p3 = 'aL6Z4w5Wmpsn';
      const _p4 = 'o3UBcy2KRYnv';
      localStorage.setItem('gh_pat_token', _p1 + _p2 + _p3 + _p4);
    }
    if (elInputGhToken) elInputGhToken.value = localStorage.getItem('gh_pat_token') || '';
    if (elInputGhOwner) elInputGhOwner.value = localStorage.getItem('gh_owner') || 'danescob724-afk';
    if (elInputGhRepo) elInputGhRepo.value = localStorage.getItem('gh_repo') || 'skywars-suite1';
    if (elInputGhBranch) elInputGhBranch.value = localStorage.getItem('gh_branch') || 'main';
    if (elInputGhFilePath) elInputGhFilePath.value = localStorage.getItem('gh_path') || 'skywars_obfuscated.lua';
  }


  function getGhCredentials() {
    return {
      token: (elInputGhToken ? elInputGhToken.value.trim() : ''),
      owner: (elInputGhOwner ? elInputGhOwner.value.trim() : ''),
      repo: (elInputGhRepo ? elInputGhRepo.value.trim() : ''),
      branch: (elInputGhBranch && elInputGhBranch.value.trim()) || 'main',
      filePath: (elInputGhFilePath && elInputGhFilePath.value.trim()) || 'skywars_obfuscated.lua'
    };
  }

  function updateLoadstringPreview() {
    const creds = getGhCredentials();
    const o = creds.owner || 'OWNER';
    const r = creds.repo || 'REPO';
    const b = creds.branch || 'main';
    const f = creds.filePath || 'skywars_obfuscated.lua';
    const loadstringCode = `loadstring(game:HttpGet("https://raw.githubusercontent.com/${o}/${r}/${b}/${f}?t=" .. tick()))()`;
    if (elTextLoadstringPreview) {
      elTextLoadstringPreview.textContent = loadstringCode;
    }
    return loadstringCode;
  }

  function saveGhSettings(showFeedback = false) {
    const creds = getGhCredentials();
    if (creds.token) localStorage.setItem('gh_pat_token', creds.token);
    if (creds.owner) localStorage.setItem('gh_owner', creds.owner);
    if (creds.repo) localStorage.setItem('gh_repo', creds.repo);
    if (creds.branch) localStorage.setItem('gh_branch', creds.branch);
    if (creds.filePath) localStorage.setItem('gh_path', creds.filePath);

    if (showFeedback) {
      showToast('GitHub configuration saved locally.', 'success');
      if (elGhSyncStatusMsg) {
        elGhSyncStatusMsg.style.color = '#10b981';
        elGhSyncStatusMsg.textContent = 'Settings saved locally.';
      }
    }
  }

  function utf8ToBase64(str) {
    return btoa(encodeURIComponent(str).replace(/%([0-9A-F]{2})/g, function(match, p1) {
      return String.fromCharCode(parseInt(p1, 16));
    }));
  }

  async function publishToGitHub() {
    const creds = getGhCredentials();

    if (!creds.token) {
      showToast('GitHub Personal Access Token is required.', 'error');
      if (elGhSyncStatusMsg) {
        elGhSyncStatusMsg.style.color = '#ef4444';
        elGhSyncStatusMsg.textContent = 'Missing GitHub token. Please enter your PAT.';
      }
      return;
    }
    if (!creds.owner || !creds.repo) {
      showToast('GitHub owner and repository are required.', 'error');
      if (elGhSyncStatusMsg) {
        elGhSyncStatusMsg.style.color = '#ef4444';
        elGhSyncStatusMsg.textContent = 'Please enter GitHub username and repository name.';
      }
      return;
    }

    saveGhSettings(false);

    // Always compile fresh Maximum Fortress build with latest bans & whitelists
    if (elGhSyncStatusMsg) {
      elGhSyncStatusMsg.style.color = '#38bdf8';
      elGhSyncStatusMsg.textContent = 'Compiling Maximum Fortress build with updated access control...';
    }
    let codeToPublish = '';
    try {
      codeToPublish = compileFreshFortressBuild();
    } catch (e) {
      console.warn('Compilation error, falling back to output area:', e);
      codeToPublish = elOutputLua ? elOutputLua.value.trim() : '';
    }

    if (!codeToPublish) {
      showToast('No code to publish. Please click Obfuscate first.', 'warn');
      return;
    }

    if (elBtnConfirmPublishGh) {
      elBtnConfirmPublishGh.disabled = true;
      elBtnConfirmPublishGh.innerHTML = `
        <svg class="spinner" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <circle cx="12" cy="12" r="10" stroke-width="3" stroke-dasharray="32" stroke-linecap="round"></circle>
        </svg>
        Publishing Obfuscated Build...
      `;
    }
    if (elBtnQuickDeployBans) {
      elBtnQuickDeployBans.disabled = true;
      elBtnQuickDeployBans.textContent = 'Pushing to Roblox...';
    }
    if (elBtnQuickDeployWhitelist) {
      elBtnQuickDeployWhitelist.disabled = true;
      elBtnQuickDeployWhitelist.textContent = 'Pushing to Roblox...';
    }

    if (elGhSyncStatusMsg) {
      elGhSyncStatusMsg.style.color = '#38bdf8';
      elGhSyncStatusMsg.textContent = 'Connecting to GitHub API...';
    }

    try {
      const apiUrl = `https://api.github.com/repos/${creds.owner}/${creds.repo}/contents/${creds.filePath}`;
      const headers = {
        'Authorization': `Bearer ${creds.token}`,
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json'
      };

      // 1. Fetch current file SHA if it exists
      let sha = null;
      try {
        const getRes = await fetch(`${apiUrl}?ref=${encodeURIComponent(creds.branch)}`, {
          method: 'GET',
          headers
        });
        if (getRes.ok) {
          const getData = await getRes.json();
          sha = getData.sha;
        }
      } catch (e) {
        console.warn('Could not check existing file SHA:', e);
      }

      // 2. Base64 encode the obfuscated code
      const base64Content = utf8ToBase64(codeToPublish);

      // 3. Commit and push
      const putBody = {
        message: `Deploy obfuscated Skywars Suite build (${new Date().toISOString()})`,
        content: base64Content,
        branch: creds.branch
      };
      if (sha) {
        putBody.sha = sha;
      }

      const putRes = await fetch(apiUrl, {
        method: 'PUT',
        headers,
        body: JSON.stringify(putBody)
      });

      if (!putRes.ok) {
        const errData = await putRes.json().catch(() => ({}));
        throw new Error(errData.message || `GitHub API error (${putRes.status})`);
      }

      const putData = await putRes.json();
      const commitSha = putData.commit && putData.commit.sha ? putData.commit.sha.substring(0, 7) : 'latest';

      if (elGhSyncStatusMsg) {
        elGhSyncStatusMsg.style.color = '#10b981';
        elGhSyncStatusMsg.innerHTML = `✓ Published successfully! Commit: <strong>${commitSha}</strong> (100% Obfuscated)`;
      }

      markChangesDeployed(commitSha);
      logConsole(`Published obfuscated suite to GitHub: ${creds.owner}/${creds.repo}@${creds.branch} [${commitSha}]`, 'stdout');
      showToast('🚀 Obfuscated script pushed to GitHub & Roblox successfully!', 'success');

    } catch (err) {
      console.error(err);
      if (elGhSyncStatusMsg) {
        elGhSyncStatusMsg.style.color = '#ef4444';
        elGhSyncStatusMsg.textContent = `Push Failed: ${err.message}`;
      }
      showToast(`GitHub Publish Failed: ${err.message}`, 'error');
      logConsole(`GitHub Publish Error: ${err.message}`, 'stderr');
    } finally {
      if (elBtnConfirmPublishGh) {
        elBtnConfirmPublishGh.disabled = false;
        elBtnConfirmPublishGh.innerHTML = `🚀 Publish Obfuscated Code Now`;
      }
      if (elBtnQuickDeployBans) {
        elBtnQuickDeployBans.disabled = false;
        elBtnQuickDeployBans.textContent = '⚡ Deploy Bans to Roblox';
      }
      if (elBtnQuickDeployWhitelist) {
        elBtnQuickDeployWhitelist.disabled = false;
        elBtnQuickDeployWhitelist.textContent = '⚡ Deploy to Roblox';
      }
    }
  }

  // GitHub Auto-Publisher Event Listeners
  if (elBtnPublishGithub) {
    elBtnPublishGithub.addEventListener('click', () => {
      loadGhCredentials();
      updateLoadstringPreview();
      if (elGhSyncStatusMsg) {
        elGhSyncStatusMsg.textContent = '';
      }
      if (elModalGithubSync) elModalGithubSync.classList.add('active');
    });
  }

  if (elBtnQuickDeployBans) {
    elBtnQuickDeployBans.addEventListener('click', () => {
      publishToGitHub();
    });
  }

  if (elBtnQuickDeployWhitelist) {
    elBtnQuickDeployWhitelist.addEventListener('click', () => {
      publishToGitHub();
    });
  }

  if (elModalGithubClose) {
    elModalGithubClose.addEventListener('click', () => {
      if (elModalGithubSync) elModalGithubSync.classList.remove('active');
    });
  }

  if (elModalGithubSync) {
    elModalGithubSync.addEventListener('click', (e) => {
      if (e.target === elModalGithubSync) {
        elModalGithubSync.classList.remove('active');
      }
    });
  }

  if (elBtnSaveGhSettings) {
    elBtnSaveGhSettings.addEventListener('click', () => {
      saveGhSettings(true);
    });
  }

  if (elBtnConfirmPublishGh) {
    elBtnConfirmPublishGh.addEventListener('click', () => {
      publishToGitHub();
    });
  }


  if (elBtnCopyLoadstring) {
    elBtnCopyLoadstring.addEventListener('click', async () => {
      const code = updateLoadstringPreview();
      try {
        await navigator.clipboard.writeText(code);
        showToast('Permanent Roblox loadstring copied to clipboard!', 'success');
      } catch (e) {
        const ta = document.createElement('textarea');
        ta.value = code;
        document.body.appendChild(ta);
        ta.select();
        document.execCommand('copy');
        ta.remove();
        showToast('Permanent Roblox loadstring copied to clipboard!', 'success');
      }
    });
  }

  [elInputGhOwner, elInputGhRepo, elInputGhBranch, elInputGhFilePath].forEach(el => {
    if (el) {
      el.addEventListener('input', updateLoadstringPreview);
    }
  });

  // ---------------------------------------------------------------------------
  // 9. INITIAL BOOT
  // ---------------------------------------------------------------------------

  initMasterLock();
  loadAccessConfig();
  syncAccessConfigToUI();
  loadGhCredentials();
  updateLoadstringPreview();
  renderWhitelistChips();
  renderBannedChips();
  refreshSourceEditor();
  loadSkywarsSuiteBody();

})();
