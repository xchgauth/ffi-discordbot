local ffi = require("ffi")
local discord = require("src.ffi.concord")
local config = require("src.config")
local commands = require("src.commands")
local slashcmds = require("src.slashcmds")

local client = discord.init(config.token)
local guild_id = tonumber(os.getenv("GUILD_ID")) or 0

local function on_ready(bot_client, event)
    local app = event.application
    print(string.format("bot ready: %s (%llu)", app.name, tonumber(app.id)))
    
    if guild_id > 0 then
        slashcmds.register(discord, bot_client, guild_id)
        print("slash commands registered")
    end
end

local function on_message(bot_client, message)
    if message.author.bot then return end
    
    local content = ffi.string(message.content)
    
    if content:sub(1, #config.prefix) == config.prefix then
        local cmdname = content:sub(#config.prefix + 1):match("^%S+")
        local args = content:sub(#config.prefix + #cmdname + 2)
        
        commands.handle(discord, bot_client, message, cmdname, args)
    end
end

local function on_interaction(bot_client, interaction)
    if interaction.type == 2 then
        slashcmds.handle(discord, bot_client, interaction)
    end
end

local ready_callback = ffi.cast("void(*)(discord*, const struct discord_ready*)", on_ready)
local message_callback = ffi.cast("void(*)(discord*, const struct discord_message*)", on_message)
local interaction_callback = ffi.cast("void(*)(discord*, const struct discord_interaction*)", on_interaction)

discord.on_ready(client, ready_callback)
discord.on_message(client, message_callback)
discord.on_interaction(client, interaction_callback)

print("starting bot...")
discord.run(client)
discord.cleanup(client)
