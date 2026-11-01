/**
 * DALX MASTER SUITE - DISCORD 2-WAY REMOTE CONTROL BOT (v3.4)
 * 
 * Provides both Slash Commands (/) and Chat Prefix Commands (!) to manage 
 * in-game whitelists, blacklists, access keys, modes, and the emergency 
 * kill switch remotely via GitHub Cloud Sync API.
 */

require('dotenv').config();
const { 
  Client, 
  GatewayIntentBits, 
  REST, 
  Routes, 
  SlashCommandBuilder, 
  EmbedBuilder, 
  PermissionFlagsBits 
} = require('discord.js');

const TOKEN = process.env.DISCORD_BOT_TOKEN;
const CLIENT_ID = process.env.CLIENT_ID;
const GUILD_ID = process.env.GUILD_ID || null;
const PREFIX = process.env.PREFIX || '!';
const GITHUB_TOKEN = process.env.GITHUB_TOKEN;
const GITHUB_OWNER = process.env.GITHUB_OWNER || 'Liojayalx';
const GITHUB_REPO = process.env.GITHUB_REPO || 'skywars-suite1';
const GITHUB_BRANCH = process.env.GITHUB_BRANCH || 'main';
const GITHUB_CONFIG_PATH = process.env.GITHUB_CONFIG_PATH || 'access_config.json';
const ALLOWED_USERS = (process.env.ALLOWED_USER_IDS || '').split(',').map(s => s.trim()).filter(Boolean);

if (!TOKEN || !CLIENT_ID) {
  console.warn('[Warning] DISCORD_BOT_TOKEN and CLIENT_ID are not yet filled in .env.');
  console.warn('[Notice] Please configure discord_bot/.env with your Discord bot credentials.');
}

// -----------------------------------------------------------------------------
// GITHUB CLOUD CONFIG API HELPERS
// -----------------------------------------------------------------------------

async function getLiveConfig() {
  const url = `https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/contents/${GITHUB_CONFIG_PATH}?ref=${encodeURIComponent(GITHUB_BRANCH)}&_t=${Date.now()}`;
  const res = await fetch(url, {
    headers: {
      'Authorization': `Bearer ${GITHUB_TOKEN}`,
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'SkywarsSuiteBot'
    }
  });

  if (!res.ok) {
    throw new Error(`Failed to fetch cloud config from GitHub (HTTP ${res.status})`);
  }

  const data = await res.json();
  const contentStr = Buffer.from(data.content, 'base64').toString('utf-8');
  const config = JSON.parse(contentStr);
  return { config, sha: data.sha };
}

async function updateLiveConfig(newConfig, sha, commitMessage) {
  const url = `https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/contents/${GITHUB_CONFIG_PATH}`;
  newConfig.lastUpdated = new Date().toISOString();
  const contentBase64 = Buffer.from(JSON.stringify(newConfig, null, 2), 'utf-8').toString('base64');

  const res = await fetch(url, {
    method: 'PUT',
    headers: {
      'Authorization': `Bearer ${GITHUB_TOKEN}`,
      'Accept': 'application/vnd.github.v3+json',
      'Content-Type': 'application/json',
      'User-Agent': 'SkywarsSuiteBot'
    },
    body: JSON.stringify({
      message: commitMessage || `Remote Discord Bot Sync (${new Date().toLocaleTimeString()})`,
      content: contentBase64,
      branch: GITHUB_BRANCH,
      sha: sha
    })
  });

  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.message || `Failed to update GitHub cloud config (HTTP ${res.status})`);
  }

  const result = await res.json();
  return result.commit && result.commit.sha ? result.commit.sha.substring(0, 7) : 'live';
}

function isAuthorized(user, member) {
  if (ALLOWED_USERS.length > 0) {
    return ALLOWED_USERS.includes(user.id);
  }
  if (member && member.permissions) {
    return member.permissions.has(PermissionFlagsBits.Administrator);
  }
  return false;
}

function getLoadstringCode() {
  return `loadstring(game:HttpGet("https://raw.githubusercontent.com/${GITHUB_OWNER}/${GITHUB_REPO}/${GITHUB_BRANCH}/skywars_obfuscated.lua?t=" .. tick()))()`;
}

// -----------------------------------------------------------------------------
// SLASH COMMAND DEFINITIONS
// -----------------------------------------------------------------------------

const commands = [
  new SlashCommandBuilder()
    .setName('whitelist')
    .setDescription('Manage the Skywars Suite live Roblox player whitelist')
    .addSubcommand(sub =>
      sub.setName('add')
        .setDescription('Add a Roblox player to the live cloud whitelist')
        .addStringOption(opt => opt.setName('username').setDescription('Roblox exact username').setRequired(true))
    )
    .addSubcommand(sub =>
      sub.setName('remove')
        .setDescription('Remove a player from the live cloud whitelist')
        .addStringOption(opt => opt.setName('username').setDescription('Roblox exact username').setRequired(true))
    )
    .addSubcommand(sub =>
      sub.setName('list')
        .setDescription('Display all currently whitelisted players')
    ),

  new SlashCommandBuilder()
    .setName('ban')
    .setDescription('Manage blacklisted Roblox players who will be instantly kicked')
    .addSubcommand(sub =>
      sub.setName('add')
        .setDescription('Add a Roblox player to the live blacklist')
        .addStringOption(opt => opt.setName('username').setDescription('Roblox exact username').setRequired(true))
    )
    .addSubcommand(sub =>
      sub.setName('remove')
        .setDescription('Remove a player from the blacklist')
        .addStringOption(opt => opt.setName('username').setDescription('Roblox exact username').setRequired(true))
    )
    .addSubcommand(sub =>
      sub.setName('list')
        .setDescription('Display all currently blacklisted players')
    ),

  new SlashCommandBuilder()
    .setName('killswitch')
    .setDescription('Emergency Remote Kill Switch control')
    .addSubcommand(sub =>
      sub.setName('status')
        .setDescription('Check current Kill Switch status')
    )
    .addSubcommand(sub =>
      sub.setName('arm')
        .setDescription('ARM the kill switch: Immediately block all in-game executions')
        .addStringOption(opt => opt.setName('reason').setDescription('Reason displayed to kicked players').setRequired(false))
    )
    .addSubcommand(sub =>
      sub.setName('disarm')
        .setDescription('DISARM the kill switch: Resume normal script executions')
    ),

  new SlashCommandBuilder()
    .setName('key')
    .setDescription('View or update the in-game DALX access key')
    .addSubcommand(sub =>
      sub.setName('view')
        .setDescription('View the current live access key')
    )
    .addSubcommand(sub =>
      sub.setName('set')
        .setDescription('Set a new live access key')
        .addStringOption(opt => opt.setName('new_key').setDescription('The new access key').setRequired(true))
    ),

  new SlashCommandBuilder()
    .setName('config')
    .setDescription('Configure suite operational modes')
    .addSubcommand(sub =>
      sub.setName('view')
        .setDescription('View all active protection settings')
    )
    .addSubcommand(sub =>
      sub.setName('whitelist-only')
        .setDescription('Toggle Whitelist-Only mode (strictly whitelist only, no key option)')
        .addBooleanOption(opt => opt.setName('enabled').setDescription('Enable or disable').setRequired(true))
    )
    .addSubcommand(sub =>
      sub.setName('skips-key')
        .setDescription('Toggle whether whitelisted players skip entering the key')
        .addBooleanOption(opt => opt.setName('enabled').setDescription('Enable or disable').setRequired(true))
    )
    .addSubcommand(sub =>
      sub.setName('kick-on-fail')
        .setDescription('Toggle whether non-whitelisted users who fail/cancel the key get kicked')
        .addBooleanOption(opt => opt.setName('enabled').setDescription('Enable or disable').setRequired(true))
    ),

  new SlashCommandBuilder()
    .setName('loadstring')
    .setDescription('Get the 1-click Roblox loadstring for executor execution'),

  new SlashCommandBuilder()
    .setName('status')
    .setDescription('Check live Cloud Suite status, whitelists, bans, and key'),

  new SlashCommandBuilder()
    .setName('help')
    .setDescription('Display documentation for all bot commands')
];

// -----------------------------------------------------------------------------
// BOT INITIALIZATION
// -----------------------------------------------------------------------------

const client = new Client({ 
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent
  ] 
});

client.once('ready', async () => {
  console.log(`[Bot Online] Logged in as ${client.user.tag}`);
  
  if (TOKEN && CLIENT_ID) {
    const rest = new REST({ version: '10' }).setToken(TOKEN);
    try {
      if (GUILD_ID) {
        console.log(`[Slash Commands] Registering guild (/) commands to guild ID ${GUILD_ID}...`);
        await rest.put(
          Routes.applicationGuildCommands(CLIENT_ID, GUILD_ID),
          { body: commands.map(c => c.toJSON()) }
        );
        console.log('[Slash Commands] Successfully registered instant guild commands.');
      } else {
        console.log('[Slash Commands] Registering global application (/) commands...');
        await rest.put(
          Routes.applicationCommands(CLIENT_ID),
          { body: commands.map(c => c.toJSON()) }
        );
        console.log('[Slash Commands] Successfully registered global commands.');
      }
    } catch (err) {
      console.error('[Slash Commands Error]', err);
    }
  }
});

// -----------------------------------------------------------------------------
// COMMAND HANDLER LOGIC (SHARED BETWEEN SLASH & PREFIX)
// -----------------------------------------------------------------------------

async function handleWhitelistAction({ sub, username, user }) {
  const { config, sha } = await getLiveConfig();
  config.whitelisted = config.whitelisted || [];

  if (sub === 'list') {
    return {
      embeds: [
        new EmbedBuilder()
          .setTitle('⭐ Skywars Suite • Live Whitelist')
          .setColor(0x00f0ff)
          .setDescription(config.whitelisted.length > 0 
            ? config.whitelisted.map((u, i) => `**${i + 1}.** \`${u}\``).join('\n')
            : '*No players currently whitelisted.*')
          .addFields(
            { name: 'Total Whitelisted', value: `${config.whitelisted.length} players`, inline: true },
            { name: 'Whitelist-Only Mode', value: config.whitelistOnlyMode ? '🔒 Enabled' : '🔓 Disabled', inline: true }
          )
          .setFooter({ text: 'DALX Cloud Access Engine • 1s Live Sync' })
          .setTimestamp()
      ]
    };
  }

  if (sub === 'add') {
    if (!username) throw new Error('Please specify a Roblox username: `whitelist add <username>`');
    if (config.whitelisted.some(u => u.toLowerCase() === username.toLowerCase())) {
      return { content: `⚠️ **${username}** is already whitelisted!` };
    }
    config.whitelisted.push(username);
    // Remove from blacklist if present
    config.banned = (config.banned || []).filter(u => u.toLowerCase() !== username.toLowerCase());
    const commit = await updateLiveConfig(config, sha, `Discord: Whitelist add ${username}`);

    return {
      embeds: [
        new EmbedBuilder()
          .setTitle('✅ Player Whitelisted Successfully')
          .setColor(0x10b981)
          .setDescription(`Player **${username}** has been added to the live cloud whitelist.`)
          .addFields(
            { name: 'Player', value: `\`${username}\``, inline: true },
            { name: 'Cloud Commit', value: `\`${commit}\``, inline: true },
            { name: 'Authorized By', value: `<@${user.id}>`, inline: true }
          )
          .setFooter({ text: 'Active in-game within 1-2 seconds!' })
          .setTimestamp()
      ]
    };
  }

  if (sub === 'remove') {
    if (!username) throw new Error('Please specify a Roblox username: `whitelist remove <username>`');
    const initialLen = config.whitelisted.length;
    config.whitelisted = config.whitelisted.filter(u => u.toLowerCase() !== username.toLowerCase());
    if (config.whitelisted.length === initialLen) {
      return { content: `⚠️ **${username}** was not found in the whitelist.` };
    }
    const commit = await updateLiveConfig(config, sha, `Discord: Whitelist remove ${username}`);

    return {
      embeds: [
        new EmbedBuilder()
          .setTitle('🗑️ Player Removed from Whitelist')
          .setColor(0xf59e0b)
          .setDescription(`Player **${username}** has been removed from the live cloud whitelist.`)
          .addFields(
            { name: 'Player', value: `\`${username}\``, inline: true },
            { name: 'Cloud Commit', value: `\`${commit}\``, inline: true }
          )
          .setTimestamp()
      ]
    };
  }
}

async function handleBanAction({ sub, username, user }) {
  const { config, sha } = await getLiveConfig();
  config.banned = config.banned || [];

  if (sub === 'list') {
    return {
      embeds: [
        new EmbedBuilder()
          .setTitle('🚫 Skywars Suite • Blacklisted Users')
          .setColor(0xef4444)
          .setDescription(config.banned.length > 0
            ? config.banned.map((u, i) => `**${i + 1}.** \`${u}\``).join('\n')
            : '*No players currently blacklisted.*')
          .setFooter({ text: 'Blacklisted users are kicked immediately on boot' })
          .setTimestamp()
      ]
    };
  }

  if (sub === 'add') {
    if (!username) throw new Error('Please specify a Roblox username: `ban add <username>`');
    if (config.banned.some(u => u.toLowerCase() === username.toLowerCase())) {
      return { content: `⚠️ **${username}** is already blacklisted!` };
    }
    config.banned.push(username);
    // Remove from whitelist if present
    config.whitelisted = (config.whitelisted || []).filter(u => u.toLowerCase() !== username.toLowerCase());
    const commit = await updateLiveConfig(config, sha, `Discord: Blacklist add ${username}`);

    return {
      embeds: [
        new EmbedBuilder()
          .setTitle('🔨 Player Blacklisted')
          .setColor(0xef4444)
          .setDescription(`Player **${username}** has been blacklisted and will be kicked immediately upon running the script.`)
          .addFields(
            { name: 'Target', value: `\`${username}\``, inline: true },
            { name: 'Cloud Commit', value: `\`${commit}\``, inline: true },
            { name: 'Authorized By', value: `<@${user.id}>`, inline: true }
          )
          .setTimestamp()
      ]
    };
  }

  if (sub === 'remove') {
    if (!username) throw new Error('Please specify a Roblox username: `ban remove <username>`');
    const initialLen = config.banned.length;
    config.banned = config.banned.filter(u => u.toLowerCase() !== username.toLowerCase());
    if (config.banned.length === initialLen) {
      return { content: `⚠️ **${username}** was not found in the blacklist.` };
    }
    const commit = await updateLiveConfig(config, sha, `Discord: Blacklist remove ${username}`);

    return {
      embeds: [
        new EmbedBuilder()
          .setTitle('✅ Player Unbanned')
          .setColor(0x10b981)
          .setDescription(`Player **${username}** has been removed from the blacklist.`)
          .setTimestamp()
      ]
    };
  }
}

async function handleKillswitchAction({ sub, reason, user }) {
  const { config, sha } = await getLiveConfig();

  if (sub === 'status') {
    return {
      embeds: [
        new EmbedBuilder()
          .setTitle('🚨 Remote Kill Switch Status')
          .setColor(config.killSwitchArmed ? 0xef4444 : 0x10b981)
          .addFields(
            { name: 'State', value: config.killSwitchArmed ? '🔴 ARMED (ALL BLOCKED)' : '🟢 DISARMED (NORMAL)', inline: true },
            { name: 'Reason Displayed', value: config.killSwitchReason || 'N/A', inline: false },
            { name: 'Last Updated', value: config.lastUpdated || 'Unknown', inline: false }
          )
          .setTimestamp()
      ]
    };
  }

  if (sub === 'arm') {
    const finalReason = reason || '⚠️ Skywars Suite is temporarily offline for emergency maintenance.';
    config.killSwitchArmed = true;
    config.killSwitchReason = finalReason;
    const commit = await updateLiveConfig(config, sha, `Discord: Emergency Kill Switch ARMED`);

    return {
      embeds: [
        new EmbedBuilder()
          .setTitle('🚨 EMERGENCY KILL SWITCH ARMED')
          .setColor(0xef4444)
          .setDescription('**ALL in-game executions are now IMMEDIATELY BLOCKED.** Any player running the script will be disconnected.')
          .addFields(
            { name: 'Shutdown Reason', value: finalReason, inline: false },
            { name: 'Cloud Commit', value: `\`${commit}\``, inline: true },
            { name: 'Triggered By', value: `<@${user.id}>`, inline: true }
          )
          .setFooter({ text: 'Active in-game in 1-2 seconds!' })
          .setTimestamp()
      ]
    };
  }

  if (sub === 'disarm') {
    config.killSwitchArmed = false;
    const commit = await updateLiveConfig(config, sha, `Discord: Emergency Kill Switch DISARMED`);

    return {
      embeds: [
        new EmbedBuilder()
          .setTitle('🟢 Emergency Kill Switch Disarmed')
          .setColor(0x10b981)
          .setDescription('Normal script operations resumed. Authorized players can now run the suite normally.')
          .addFields(
            { name: 'Cloud Commit', value: `\`${commit}\``, inline: true },
            { name: 'Disarmed By', value: `<@${user.id}>`, inline: true }
          )
          .setTimestamp()
      ]
    };
  }
}

async function handleKeyAction({ sub, newKey, user }) {
  const { config, sha } = await getLiveConfig();

  if (sub === 'view' || !sub) {
    return {
      embeds: [
        new EmbedBuilder()
          .setTitle('🔑 In-Game DALX Access Key')
          .setColor(0xa855f7)
          .addFields(
            { name: 'Current Access Key', value: `\`${config.key || 'DORKSTHATAINTWHITELISTED'}\``, inline: false },
            { name: 'Key Storage File', value: `\`${config.keyFile || 'SkywarsSuite_Key.txt'}\``, inline: true },
            { name: 'Whitelist Skips Key', value: config.whitelistSkipsKey ? '✅ Yes' : '❌ No', inline: true }
          )
          .setFooter({ text: 'Set a new key anytime via /key set <new_key>' })
          .setTimestamp()
      ]
    };
  }

  if (sub === 'set') {
    if (!newKey) throw new Error('Please provide the new key string: `key set <new_key>`');
    config.key = newKey.trim();
    const commit = await updateLiveConfig(config, sha, `Discord: Key changed to ${newKey}`);

    return {
      embeds: [
        new EmbedBuilder()
          .setTitle('🔑 Access Key Updated')
          .setColor(0x10b981)
          .setDescription('The in-game verification key has been updated.')
          .addFields(
            { name: 'New Access Key', value: `\`${config.key}\``, inline: true },
            { name: 'Cloud Commit', value: `\`${commit}\``, inline: true },
            { name: 'Changed By', value: `<@${user.id}>`, inline: true }
          )
          .setFooter({ text: 'Live in-game immediately!' })
          .setTimestamp()
      ]
    };
  }
}

async function handleConfigAction({ sub, value, user }) {
  const { config, sha } = await getLiveConfig();

  if (sub === 'view' || !sub) {
    return {
      embeds: [
        new EmbedBuilder()
          .setTitle('⚙️ Suite Operating Mode Configuration')
          .setColor(0x38bdf8)
          .addFields(
            { name: 'Whitelist-Only Mode', value: config.whitelistOnlyMode ? '🔒 Enabled (No key entry allowed)' : '🔓 Disabled (Keys allowed)', inline: false },
            { name: 'Whitelist Skips Key', value: config.whitelistSkipsKey ? '✅ Enabled (Whitelisted bypass key prompt)' : '❌ Disabled', inline: false },
            { name: 'Kick On Fail', value: config.kickOnFail ? '🚪 Enabled (Kick on cancel/invalid key)' : '❌ Disabled', inline: false },
            { name: 'In-Game Notifications', value: config.notifications !== false ? '🔔 Enabled' : '🔕 Disabled', inline: false }
          )
          .setTimestamp()
      ]
    };
  }

  if (sub === 'whitelist-only') {
    config.whitelistOnlyMode = Boolean(value);
    const commit = await updateLiveConfig(config, sha, `Discord: Set whitelistOnlyMode=${config.whitelistOnlyMode}`);
    return {
      embeds: [
        new EmbedBuilder()
          .setTitle('🔒 Whitelist-Only Mode Updated')
          .setColor(config.whitelistOnlyMode ? 0xf59e0b : 0x10b981)
          .setDescription(`Whitelist-Only Mode is now **${config.whitelistOnlyMode ? 'ENABLED (Strict mode)' : 'DISABLED (Public with key)'}**.`)
          .addFields({ name: 'Cloud Commit', value: `\`${commit}\``, inline: true })
          .setTimestamp()
      ]
    };
  }

  if (sub === 'skips-key') {
    config.whitelistSkipsKey = Boolean(value);
    const commit = await updateLiveConfig(config, sha, `Discord: Set whitelistSkipsKey=${config.whitelistSkipsKey}`);
    return {
      embeds: [
        new EmbedBuilder()
          .setTitle('⚡ Whitelist Skips Key Updated')
          .setColor(0x10b981)
          .setDescription(`Whitelisted users skipping the key prompt is now **${config.whitelistSkipsKey ? 'ENABLED' : 'DISABLED'}**.`)
          .addFields({ name: 'Cloud Commit', value: `\`${commit}\``, inline: true })
          .setTimestamp()
      ]
    };
  }

  if (sub === 'kick-on-fail') {
    config.kickOnFail = Boolean(value);
    const commit = await updateLiveConfig(config, sha, `Discord: Set kickOnFail=${config.kickOnFail}`);
    return {
      embeds: [
        new EmbedBuilder()
          .setTitle('🚪 Kick On Fail Updated')
          .setColor(0x10b981)
          .setDescription(`Kick players on invalid key/cancel is now **${config.kickOnFail ? 'ENABLED' : 'DISABLED'}**.`)
          .addFields({ name: 'Cloud Commit', value: `\`${commit}\``, inline: true })
          .setTimestamp()
      ]
    };
  }
}

async function handleStatusAction() {
  const { config } = await getLiveConfig();
  return {
    embeds: [
      new EmbedBuilder()
        .setTitle('⚡ DALX Master Suite • Cloud System Status')
        .setColor(config.killSwitchArmed ? 0xef4444 : 0x00f0ff)
        .addFields(
          { name: 'Kill Switch', value: config.killSwitchArmed ? '🔴 ARMED' : '🟢 Disarmed', inline: true },
          { name: 'Whitelisted Players', value: `${(config.whitelisted || []).length} users`, inline: true },
          { name: 'Blacklisted Users', value: `${(config.banned || []).length} users`, inline: true },
          { name: 'Active Key', value: `\`${config.key || 'DORKSTHATAINTWHITELISTED'}\``, inline: true },
          { name: 'Whitelist-Only Mode', value: config.whitelistOnlyMode ? '🔒 Enabled' : '🔓 Disabled', inline: true },
          { name: 'Whitelist Skips Key', value: config.whitelistSkipsKey ? '⚡ Yes' : 'No', inline: true },
          { name: 'Last Cloud Sync', value: config.lastUpdated ? new Date(config.lastUpdated).toLocaleString() : 'Live', inline: false }
        )
        .setFooter({ text: 'Connected to GitHub Cloud API • v3.4' })
        .setTimestamp()
    ]
  };
}

function handleLoadstringAction() {
  const code = getLoadstringCode();
  return {
    embeds: [
      new EmbedBuilder()
        .setTitle('🚀 Official Skywars Suite Loadstring')
        .setColor(0x00f0ff)
        .setDescription('Paste this loadstring into any supported executor (Real, Wave, Electron, Synapse, etc.):')
        .addFields({
          name: 'Roblox Luau Loadstring',
          value: `\`\`\`lua\n${code}\n\`\`\``
        })
        .setFooter({ text: 'Includes automatic ?t= timestamp cache bypass' })
        .setTimestamp()
    ]
  };
}

function handleHelpAction() {
  return {
    embeds: [
      new EmbedBuilder()
        .setTitle('📖 Skywars Suite Discord Bot Commands')
        .setColor(0x00f0ff)
        .setDescription('You can use either **Slash Commands** (`/`) or **Prefix Commands** (`!`) in chat.')
        .addFields(
          { 
            name: '⭐ Whitelist Management', 
            value: '`/whitelist add <username>` or `!whitelist add <user>`\n`/whitelist remove <username>` or `!whitelist remove <user>`\n`/whitelist list` or `!whitelist list`' 
          },
          { 
            name: '🚫 Blacklist / Bans', 
            value: '`/ban add <username>` or `!ban add <user>`\n`/ban remove <username>` or `!ban remove <user>`\n`/ban list` or `!ban list`' 
          },
          { 
            name: '🚨 Emergency Kill Switch', 
            value: '`/killswitch arm [reason]` or `!killswitch arm [reason]`\n`/killswitch disarm` or `!killswitch disarm`\n`/killswitch status` or `!killswitch status`' 
          },
          { 
            name: '🔑 Access Key Manager', 
            value: '`/key view` or `!key`\n`/key set <new_key>` or `!key set <new_key>`' 
          },
          { 
            name: '⚙️ Mode Configuration', 
            value: '`/config view` or `!config`\n`/config whitelist-only <true|false>`\n`/config skips-key <true|false>`\n`/config kick-on-fail <true|false>`' 
          },
          { 
            name: '⚡ General & Quick Tools', 
            value: '`/status` or `!status` - System & cloud telemetry dashboard\n`/loadstring` or `!loadstring` - Instant executor script\n`/help` or `!help` - Display this command handbook' 
          }
        )
        .setFooter({ text: 'DALX Studio Remote Engine • 2-Way GitHub Cloud Sync' })
        .setTimestamp()
    ]
  };
}

// -----------------------------------------------------------------------------
// SLASH COMMAND INTERACTION LISTENER
// -----------------------------------------------------------------------------

client.on('interactionCreate', async (interaction) => {
  if (!interaction.isChatInputCommand()) return;

  if (!isAuthorized(interaction.user, interaction.member)) {
    return interaction.reply({
      content: '❌ **Access Denied**: You do not have operator authorization to execute suite remote commands.',
      ephemeral: true
    });
  }

  const { commandName } = interaction;
  await interaction.deferReply({ ephemeral: false });

  try {
    let response;
    if (commandName === 'whitelist') {
      const sub = interaction.options.getSubcommand();
      const username = interaction.options.getString('username');
      response = await handleWhitelistAction({ sub, username, user: interaction.user });
    } else if (commandName === 'ban') {
      const sub = interaction.options.getSubcommand();
      const username = interaction.options.getString('username');
      response = await handleBanAction({ sub, username, user: interaction.user });
    } else if (commandName === 'killswitch') {
      const sub = interaction.options.getSubcommand();
      const reason = interaction.options.getString('reason');
      response = await handleKillswitchAction({ sub, reason, user: interaction.user });
    } else if (commandName === 'key') {
      const sub = interaction.options.getSubcommand();
      const newKey = interaction.options.getString('new_key');
      response = await handleKeyAction({ sub, newKey, user: interaction.user });
    } else if (commandName === 'config') {
      const sub = interaction.options.getSubcommand();
      const value = interaction.options.getBoolean('enabled');
      response = await handleConfigAction({ sub, value, user: interaction.user });
    } else if (commandName === 'loadstring') {
      response = handleLoadstringAction();
    } else if (commandName === 'status') {
      response = await handleStatusAction();
    } else if (commandName === 'help') {
      response = handleHelpAction();
    }

    if (response) {
      await interaction.editReply(response);
    }
  } catch (err) {
    console.error('Slash Command Error:', err);
    await interaction.editReply({ content: `❌ **Operation Failed**: ${err.message}` });
  }
});

// -----------------------------------------------------------------------------
// PREFIX CHAT COMMAND LISTENER (!whitelist, !ban, !key, !status, etc.)
// -----------------------------------------------------------------------------

client.on('messageCreate', async (message) => {
  if (message.author.bot || !message.content.startsWith(PREFIX)) return;

  if (!isAuthorized(message.author, message.member)) {
    return message.reply('❌ **Access Denied**: You do not have operator authorization to run suite remote commands.');
  }

  const rawArgs = message.content.slice(PREFIX.length).trim().split(/\s+/);
  const cmd = rawArgs.shift()?.toLowerCase();
  if (!cmd) return;

  try {
    let response;

    if (cmd === 'whitelist' || cmd === 'wl') {
      const sub = rawArgs[0]?.toLowerCase() || 'list';
      const username = rawArgs[1];
      response = await handleWhitelistAction({ sub, username, user: message.author });
    } else if (cmd === 'ban' || cmd === 'blacklist') {
      const sub = rawArgs[0]?.toLowerCase() || 'list';
      const username = rawArgs[1];
      response = await handleBanAction({ sub, username, user: message.author });
    } else if (cmd === 'killswitch' || cmd === 'ks') {
      const sub = rawArgs[0]?.toLowerCase() || 'status';
      const reason = rawArgs.slice(1).join(' ');
      response = await handleKillswitchAction({ sub, reason, user: message.author });
    } else if (cmd === 'key') {
      const sub = rawArgs[0]?.toLowerCase() === 'set' ? 'set' : 'view';
      const newKey = sub === 'set' ? rawArgs.slice(1).join(' ') : null;
      response = await handleKeyAction({ sub, newKey, user: message.author });
    } else if (cmd === 'config' || cmd === 'cfg') {
      const sub = rawArgs[0]?.toLowerCase() || 'view';
      let value = null;
      if (rawArgs[1]) {
        value = ['true', '1', 'yes', 'on', 'enable'].includes(rawArgs[1].toLowerCase());
      }
      response = await handleConfigAction({ sub, value, user: message.author });
    } else if (cmd === 'status' || cmd === 'stats') {
      response = await handleStatusAction();
    } else if (cmd === 'loadstring' || cmd === 'script') {
      response = handleLoadstringAction();
    } else if (cmd === 'help' || cmd === 'commands') {
      response = handleHelpAction();
    }

    if (response) {
      await message.reply(response);
    }
  } catch (err) {
    console.error('Prefix Command Error:', err);
    await message.reply(`❌ **Operation Failed**: ${err.message}`);
  }
});

// -----------------------------------------------------------------------------
// START BOT CLIENT
// -----------------------------------------------------------------------------

if (TOKEN) {
  client.login(TOKEN).catch(err => {
    console.error('[Bot Login Error]', err.message);
  });
}
