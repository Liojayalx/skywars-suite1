# 🛡️ Skywars Suite Studio (v3.2 Master Access Hub)

**Live Studio Web App**: [https://danescob724-afk.github.io/skywars-suite1/](https://danescob724-afk.github.io/skywars-suite1/)

**Skywars Suite Studio** is a dedicated web application and protection studio engineered specifically around the **Skywars Ultimate Master Suite** and Roblox Luau security.

It integrates a real-time **Access Control & Key System Manager**, dynamic source code synthesizer, and a specialized **Roblox Luau Obfuscator** with instant synchronization to your executor and GitHub repository.

---

## 🚀 Live Roblox Loadstring (Always Up-to-Date)

Run this permanent loadstring in any modern Roblox executor (Real, Wave, Synapse, Electron, etc.):

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/danescob724-afk/skywars-suite1/main/skywars_obfuscated.lua?t=" .. tick()))()
```

> **Automatic Cache-Bypass**: The `?t=" .. tick()` parameter guarantees that Roblox immediately fetches your latest ban list, whitelists, and Fortress VM build without waiting for GitHub CDN cache.

---

## ✨ Studio Capabilities

### 1. Roblox Username Whitelist Manager
- **Visual User Badges**: Add or remove Roblox usernames (`724e72411`, `Synitzynnx`, `777_Z1e7x`, `Condrago321`, `zwooombiiee`, `pandasweetgirl15`) with a single click.
- **`WHITELIST_SKIPS_KEY` Toggle**: Whitelisted players automatically bypass key entry and launch directly into the suite.
- **`WHITELIST_ONLY_MODE` Toggle**: Strict mode where only whitelisted accounts can execute the script at all; all others are rejected.

### 2. Blacklist / Banned Users Manager
- **Username Blacklist**: Prevent bad actors or compromised accounts from running the suite.
- **`KICK_BANNED` Toggle**: Automatically kicks blacklisted players from the game immediately.
- **Priority Execution**: Blacklist checks run before anything else; nothing bypasses a ban.
- **1-Click Deploy**: Click **⚡ Deploy Bans to Roblox** to immediately compile and push the updated ban list to GitHub.

### 3. DALX Key System Configuration
- **Custom Access Key**: Set any secret key string (defaults to `DORKSTHATAINTWHITELISTED`).
- **Saved Key File**: Configure client storage filename (defaults to `SkywarsSuite_Key.txt`).
- **Auto-Remember Key Toggle**: Auto-pass subsequent runs if the client already verified the key.
- **Roblox In-Game Banners**: Show native notifications on verify (`Welcome <Name>! Whitelist verified`).

### 4. Maximum Fortress v5.2 Obfuscation Engine
- **Stage 1 (AST Renaming)**: Barcode identifiers (`_Il1l_...`), hex number decomposition, decimal byte escaping.
- **Stage 2 (Autokey VM Matrix)**: Encrypted into 55 high-entropy VM chunks with rolling Autokey ciphers and ephemeral heap purging.
- **Anti-Tamper & Metamethod Shield**: Environment verification protecting all hook targets.

---

## 🌐 Web Studio Access

- **Online**: [https://danescob724-afk.github.io/skywars-suite1/](https://danescob724-afk.github.io/skywars-suite1/)
- **Localhost**: `http://127.0.0.1:8080/`
- **Master Password**: `De996477_`
