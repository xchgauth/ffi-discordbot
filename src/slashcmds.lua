local ffi = require("ffi")

local slashcmds = {}

slashcmds.list = {
    ping = {
        description = "test bot response",
        handler = function(discord, client, interaction)
            discord.reply_interaction(client, interaction.id, ffi.string(interaction.token), "pong!")
        end
    },
    
    info = {
        description = "bot information",
        handler = function(discord, client, interaction)
            local info = "luajit discord bot | ffi + concord"
            discord.reply_interaction(client, interaction.id, ffi.string(interaction.token), info)
        end
    },
    
    help = {
        description = "list all commands",
        handler = function(discord, client, interaction)
            local cmdlist = {}
            for name in pairs(slashcmds.list) do
                table.insert(cmdlist, "/" .. name)
            end
            table.sort(cmdlist)
            discord.reply_interaction(client, interaction.id, ffi.string(interaction.token), "commands: " .. table.concat(cmdlist, " "))
        end
    }
}

function slashcmds.register(discord, client, guild_id)
    for name, cmd in pairs(slashcmds.list) do
        discord.create_slash_command(client, guild_id, name, cmd.description)
    end
end

function slashcmds.handle(discord, client, interaction)
    local data = ffi.cast("struct discord_interaction_data*", interaction.data)
    if not data then return end
    
    local cmdname = ffi.string(data.name)
    local cmd = slashcmds.list[cmdname]
    
    if cmd and cmd.handler then
        local success, error = pcall(cmd.handler, discord, client, interaction)
        if not success then
            print("error in slash command " .. cmdname .. ": " .. tostring(error))
        end
    end
end

return slashcmds
