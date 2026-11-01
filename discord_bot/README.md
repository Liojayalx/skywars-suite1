# 🤖 Skywars Suite Discord Remote Control Bot (v3.4)

A dedicated Discord bot allowing full remote administration of the **Skywars Ultimate Master Suite** directly from your Discord server.

Supports both **Slash Commands (`/`)** and **Chat Prefix Commands (`!`)** with real-time 2-way cloud synchronization to GitHub and Roblox. Changes take effect **in-game within 1–2 seconds**.

---

## ⚡ Command Reference

All commands can be invoked via Discord slash commands (`/command`) or regular text chat prefix (`!command`):

| Slash Command | Prefix Command | Description | Example |
| :--- | :--- | :--- | :--- |
| `/whitelist add <user>` | `!whitelist add <user>` | Add player to cloud whitelist | `/whitelist add Player1` |
| `/whitelist remove <user>` | `!whitelist remove <user>` | Remove player from whitelist | `/whitelist remove Player1` |
| `/whitelist list` | `!whitelist list` | View all whitelisted players | `/whitelist list` |
| `/ban add <user>` | `!ban add <user>` | Blacklist a player (kicked immediately) | `/ban add ToxicPlayer` |
| `/ban remove <user>` | `!ban remove <user>` | Unban a player from blacklist | `/ban remove ToxicPlayer` |
| `/ban list` | `!ban list` | View all blacklisted players | `/ban list` |
| `/killswitch arm [reason]` | `!killswitch arm [reason]` | **Emergency Shutdown**: Blocks all executions | `/killswitch arm Emergency maintenance` |
| `/killswitch disarm` | `!killswitch disarm` | Resume normal script operations | `/killswitch disarm` |
| `/killswitch status` | `!killswitch status` | Check if kill switch is armed | `/killswitch status` |
| `/key view` | `!key` | View current in-game access key | `/key view` |
| `/key set <new_key>` | `!key set <new_key>` | Change the live in-game key | `/key set MY_SECRET_KEY` |
| `/config view` | `!config` | View active suite configuration | `/config view` |
| `/config whitelist-only <true\|false>` | `!config whitelist-only true` | Toggle Whitelist-Only mode | `/config whitelist-only true` |
| `/config skips-key <true\|false>` | `!config skips-key true` | Toggle Whitelist Skips Key | `/config skips-key true` |
| `/config kick-on-fail <true\|false>` | `!config kick-on-fail true` | Toggle Kick on failed key | `/config kick-on-fail true` |
| `/loadstring` | `!loadstring` | Get 1-click executor loadstring | `/loadstring` |
| `/status` | `!status` | Telemetry & active settings dashboard | `/status` |
| `/help` | `!help` | Full bot commands handbook | `/help` |

---

## 🚀 Setup Instructions

### 1. Create a Discord Bot
1. Go to the [Discord Developer Portal](https://discord.com/developers/applications).
2. Click **New Application** → Name it `Skywars Suite Remote`.
3. Go to the **Bot** tab:
   - Click **Reset Token** and copy the bot token.
   - Under **Privileged Gateway Intents**, enable **Message Content Intent** (needed for `!` prefix commands) and **Server Members Intent**.
4. Go to **OAuth2 → URL Generator**:
   - Scopes: `bot`, `applications.commands`
   - Bot Permissions: `Send Messages`, `Embed Links`, `Read Messages/View Channels`, `Use Application Commands`
   - Copy the link and invite the bot to your Discord server.

### 2. Configure `.env`
In `discord_bot/`, copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
Fill in your credentials:
```env
DISCORD_BOT_TOKEN=your_copied_bot_token
CLIENT_ID=your_discord_application_id
GUILD_ID=your_discord_server_id (optional, for instant command sync)
PREFIX=!
ALLOWED_USER_IDS=your_discord_user_id (optional, defaults to Admins)
GITHUB_TOKEN=your_github_token_here
GITHUB_OWNER=Liojayalx
GITHUB_REPO=skywars-suite1
GITHUB_BRANCH=main
GITHUB_CONFIG_PATH=access_config.json
```

### 3. Install & Start
```bash
cd discord_bot
npm install
node bot.js
```
