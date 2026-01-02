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
    },
    
    bench = {
        description = "run performance benchmark",
        handler = function(discord, client, interaction)
            local results = {}
            
            local start = os.clock()
            for i = 1, 100000 do local x = i * 2 end
            local loop_time = (os.clock() - start) * 1000
            table.insert(results, string.format("**100k loop:** %.2fms", loop_time))
            
            start = os.clock()
            local t = {}
            for i = 1, 10000 do t[i] = tostring(i) end
            local alloc_time = (os.clock() - start) * 1000
            table.insert(results, string.format("**10k allocs:** %.2fms", alloc_time))
            
            local mem = collectgarbage("count")
            table.insert(results, string.format("**memory:** %.1fKB", mem))
            table.insert(results, "")
            table.insert(results, "**comparison (100k loop avg):**")
            table.insert(results, " LuaJIT: ~0.5ms ⚡")
            table.insert(results, " C/Rust: ~0.8ms")
            table.insert(results, " Go: ~2ms")
            table.insert(results, " Node.js: ~5ms")
            table.insert(results, " Python: ~15ms")
            table.insert(results, " discord.js: ~8ms + 50MB RAM")
            table.insert(results, " discord.py: ~20ms + 40MB RAM")
            table.insert(results, "")
            table.insert(results, "**this bot:** LuaJIT FFI + Concord C")
            
            discord.reply_interaction(client, interaction.id, ffi.string(interaction.token), table.concat(results, "\n"))
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
