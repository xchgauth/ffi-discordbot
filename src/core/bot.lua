local ffi = require("ffi")
local discord = require("ffi.lib")
local config = require("config")
local commands = require("core.commands")
local slashcmds = require("core.slashcmds")

local ffi_string, ffi_cast = ffi.string, ffi.cast
local tonumber, print, format = tonumber, print, string.format
local sub, match = string.sub, string.match

local client = discord.init(config.token)
local guild_id = tonumber(os.getenv("GUILD_ID")) or 0
local prefix = config.prefix
local prefix_len = #prefix

local INTENTS = discord.INTENTS
discord.add_intents(client, INTENTS.GUILDS)
discord.add_intents(client, INTENTS.GUILD_MESSAGES)
discord.add_intents(client, INTENTS.MESSAGE_CONTENT)
discord.add_intents(client, INTENTS.DIRECT_MESSAGES)

local function on_ready(_, event)
    local user = event.user
    local name = user ~= nil and user.username ~= nil and ffi_string(user.username) or "unknown"
    print(format("[ready] logged in as %s", name))

    if guild_id > 0 then
        slashcmds.register(discord, client, guild_id)
        print("[ready] slash commands registered")
    end
end

local function on_message(_, msg)
    if msg == nil or msg.author == nil or msg.author.bot or msg.content == nil then return end

    local ok, content = pcall(ffi_string, msg.content)
    if not ok or sub(content, 1, prefix_len) ~= prefix then return end

    local cmdname = match(content, "^%S+", prefix_len + 1)
    if cmdname then
        commands.handle(discord, client, msg, cmdname, sub(content, prefix_len + #cmdname + 2))
    end
end

local function on_interaction(_, interaction)
    if interaction ~= nil and interaction.type == 2 then
        slashcmds.handle(discord, client, interaction)
    end
end

local cb_ready = ffi_cast("void(*)(struct discord*, const struct discord_ready*)", on_ready)
local cb_message = ffi_cast("void(*)(struct discord*, const struct discord_message*)", on_message)
local cb_interaction = ffi_cast("void(*)(struct discord*, const struct discord_interaction*)", on_interaction)

discord.on_ready(client, cb_ready)
discord.on_message(client, cb_message)
discord.on_interaction(client, cb_interaction)

local refs = { cb_ready, cb_message, cb_interaction }

print("[init] starting bot...")
discord.run(client)
discord.cleanup(client)
