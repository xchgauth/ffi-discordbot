local ffi = require("ffi")
local discord = require("src.ffi.concord")
local config = require("src.config")
local commands = require("src.commands")
local slashcmds = require("src.slashcmds")

local client = discord.init(config.token)
local guild_id = tonumber(os.getenv("GUILD_ID")) or 0

discord.add_intents(client, discord.INTENTS.GUILDS)
discord.add_intents(client, discord.INTENTS.GUILD_MESSAGES)
discord.add_intents(client, discord.INTENTS.MESSAGE_CONTENT)
discord.add_intents(client, discord.INTENTS.DIRECT_MESSAGES)

local function on_ready(bot_client, event)
    local user = event.user
    if user ~= nil and user.username ~= nil then
        print(string.format("bot ready: %s", ffi.string(user.username)))
    else
        print("bot ready!")
    end
    
    if guild_id > 0 then
        slashcmds.register(discord, bot_client, guild_id)
        print("slash commands registered")
    end
end

local function on_message(bot_client, message)
    if message == nil then return end
    if message.author == nil then return end
    if message.author.bot then return end
    if message.content == nil then return end
    
    local ok, content = pcall(ffi.string, message.content)
    if not ok then return end
    
    if content:sub(1, #config.prefix) == config.prefix then
        local cmdname = content:sub(#config.prefix + 1):match("^%S+")
        if cmdname then
            local args = content:sub(#config.prefix + #cmdname + 2)
            commands.handle(discord, bot_client, message, cmdname, args)
        end
    end
end

local function on_interaction(bot_client, interaction)
    if interaction == nil then return end
    if interaction.type == 2 then
        slashcmds.handle(discord, bot_client, interaction)
    end
end

local ready_callback = ffi.cast("void(*)(struct discord*, const struct discord_ready*)", on_ready)
local message_callback = ffi.cast("void(*)(struct discord*, const struct discord_message*)", on_message)
local interaction_callback = ffi.cast("void(*)(struct discord*, const struct discord_interaction*)", on_interaction)

discord.on_ready(client, ready_callback)
discord.on_message(client, message_callback)
discord.on_interaction(client, interaction_callback)

print("starting bot...")

local callbacks = {ready_callback, message_callback, interaction_callback}

discord.run(client)
discord.cleanup(client)
