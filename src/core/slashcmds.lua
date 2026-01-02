local ffi = require("ffi")

ffi.cdef[[
    typedef struct timespec {
        long tv_sec;
        long tv_nsec;
    } timespec;
    int clock_gettime(int clk_id, struct timespec *tp);
]]

local CLOCK_MONOTONIC = jit.os == "Linux" and 1 or 6

local function gettime()
    local ts = ffi.new("timespec")
    ffi.C.clock_gettime(CLOCK_MONOTONIC, ts)
    return tonumber(ts.tv_sec) + tonumber(ts.tv_nsec) / 1e9
end

local function measure_ping()
    local t1 = gettime()
    os.execute("curl -s -o /dev/null https://discord.com/api/v10/gateway")
    return (gettime() - t1) * 1000
end

local ffi_string, ffi_cast = ffi.string, ffi.cast
local pairs, pcall, format, concat = pairs, pcall, string.format, table.concat
local clock, collectgarbage = os.clock, collectgarbage

local slashcmds = {}

local function timed(fn)
    local t = clock()
    fn()
    return (clock() - t) * 1000
end

local function reply(discord, client, interaction, content)
    discord.reply_interaction(client, interaction.id, ffi_string(interaction.token), content)
end

slashcmds.list = {
    ping = {
        description = "test bot response",
        handler = function(discord, client, interaction)
            local ms = measure_ping()
            reply(discord, client, interaction, format("🏓 **pong!** `%.2fms` (REST)", ms))
            print(format("[ping] %.2fms", ms))
        end
    },

    info = {
        description = "bot information",
        handler = function(discord, client, interaction)
            reply(discord, client, interaction, concat({
                "**dcbot** - discord bot in luajit",
                "",
                "**runtime:** luajit 2.1 + ffi",
                "**library:** concord (c99)",
                "**source:** github.com/cogmasters/concord"
            }, "\n"))
        end
    },

    help = {
        description = "list all commands",
        handler = function(discord, client, interaction)
            local names = {}
            for k in pairs(slashcmds.list) do names[#names + 1] = "/" .. k end
            table.sort(names)
            reply(discord, client, interaction, "**commands:** " .. concat(names, "  "))
        end
    },

    bench = {
        description = "run performance benchmark",
        handler = function(discord, client, interaction)
            local r_loop = timed(function()
                local x = 0
                for i = 1, 1e6 do x = x + i end
            end)

            local r_alloc = timed(function()
                local t = {}
                for i = 1, 1e5 do t[i] = { i } end
            end)

            collectgarbage("collect")
            local mem = collectgarbage("count")

            reply(discord, client, interaction, concat({
                "**benchmark results**",
                "```",
                format("1M iterations:    %7.2f ms", r_loop),
                format("100k allocations: %7.2f ms", r_alloc),
                format("memory:           %7.1f KB", mem),
                "```",
                "**comparison (typical values):**",
                "```",
                "luajit     ~0.5ms   <2MB",
                "go         ~2ms    ~15MB",
                "node.js    ~5ms    ~50MB",
                "python     ~15ms   ~40MB",
                "```"
            }, "\n"))
        end
    },

    mem = {
        description = "memory usage",
        handler = function(discord, client, interaction)
            collectgarbage("collect")
            local kb = collectgarbage("count")
            reply(discord, client, interaction, format("**memory:** %.2f KB (%.2f MB)", kb, kb / 1024))
        end
    }
}

function slashcmds.register(discord, client, guild_id)
    for name, cmd in pairs(slashcmds.list) do
        print(format("[slash] registering /%s", name))
        discord.create_slash_command(client, guild_id, name, cmd.description)
    end
end

function slashcmds.handle(discord, client, interaction)
    if interaction.data == nil then return end

    local data = ffi_cast("struct discord_interaction_data*", interaction.data)
    if data == nil or data.name == nil then return end

    local ok, cmdname = pcall(ffi_string, data.name)
    if not ok then return end

    local cmd = slashcmds.list[cmdname]
    if not cmd or not cmd.handler then return end

    local success, err = pcall(cmd.handler, discord, client, interaction)
    if not success then
        io.stderr:write(format("[slash] %s: %s\n", cmdname, err))
    end
end

return slashcmds
