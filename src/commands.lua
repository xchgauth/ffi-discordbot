local commands = {}

commands.list = {
    ping = function(discord, client, msg)
        discord.send_message(client, msg.channel_id, "pong!")
    end,
    
    echo = function(discord, client, msg, args)
        if #args > 0 then
            discord.send_message(client, msg.channel_id, args)
        end
    end,
    
    help = function(discord, client, msg)
        local cmdlist = {}
        for name in pairs(commands.list) do
            table.insert(cmdlist, name)
        end
        table.sort(cmdlist)
        discord.send_message(client, msg.channel_id, "commands: !" .. table.concat(cmdlist, " !"))
    end,
    
    info = function(discord, client, msg)
        local info = "luajit discord bot | ffi + concord"
        discord.send_message(client, msg.channel_id, info)
    end
}

function commands.handle(discord, client, msg, cmdname, args)
    local handler = commands.list[cmdname]
    if handler then
        local success, error = pcall(handler, discord, client, msg, args)
        if not success then
            print("error in command " .. cmdname .. ": " .. tostring(error))
        end
    end
end

return commands
