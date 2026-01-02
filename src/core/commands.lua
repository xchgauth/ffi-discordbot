local ffi = require("ffi")

local floor, format, clock, concat = math.floor, string.format, os.clock, table.concat
local collectgarbage, pairs, pcall, tostring = collectgarbage, pairs, pcall, tostring
local gsub, sub, match = string.gsub, string.sub, string.match

local commands = {}
local registry = {}
local start_time = clock()
local PREFIX = "!"

local function send(discord, client, msg, content)
    discord.send_message(client, msg.channel_id, content)
end

local function get_mem()
    collectgarbage("collect")
    return collectgarbage("count")
end

local function fmt_bytes(kb)
    return kb >= 1024 and format("%.2f MB", kb / 1024) or format("%.1f KB", kb)
end

local function fmt_time(s)
    local d, h, m = floor(s / 86400), floor(s % 86400 / 3600), floor(s % 3600 / 60)
    return d > 0 and format("%dd %dh %dm", d, h, m)
        or h > 0 and format("%dh %dm %ds", h, m, floor(s % 60))
        or m > 0 and format("%dm %.1fs", m, s % 60)
        or format("%.2fs", s)
end

local function timed(fn)
    local t = clock()
    fn()
    return (clock() - t) * 1000
end

local function bar(val, max, width)
    local filled = floor((val / max) * width)
    return string.rep("\226\150\136", filled) .. string.rep("\226\150\145", width - filled)
end

registry.ping = function(discord, client, msg)
    local t = clock()
    send(discord, client, msg, "pong!")
    print(format("[ping] %.2fms", (clock() - t) * 1000))
end

registry.echo = function(discord, client, msg, args)
    if #args == 0 then return end
    if sub(args, 1, 1) == PREFIX then return end
    local sanitized = gsub(args, "@", "@ ")
    sanitized = gsub(sanitized, "<@!?%d+>", "[mention]")
    sanitized = gsub(sanitized, "<@&%d+>", "[role]")
    sanitized = gsub(sanitized, "@everyone", "[everyone]")
    sanitized = gsub(sanitized, "@here", "[here]")
    send(discord, client, msg, sanitized)
end

registry.help = function(discord, client, msg)
    local names = {}
    for k in pairs(registry) do names[#names + 1] = "!" .. k end
    table.sort(names)
    send(discord, client, msg, concat(names, "  "))
end

registry.info = function(discord, client, msg)
    send(discord, client, msg, concat({
        "**dcbot** - discord bot",
        "",
        "**runtime:** luajit 2.1",
        "**library:** ffi binding to c99",
    }, "\n"))
end

registry.mem = function(discord, client, msg)
    local kb = get_mem()
    local mb = kb / 1024
    local w = 20

    send(discord, client, msg, concat({
        "**memory usage comparison**",
        "```",
        format("%-12s %s %6.2f MB", "this bot", bar(mb, 150, w), mb),
        format("%-12s %s %6.1f MB", "discord.go", bar(15, 150, w), 15),
        format("%-12s %s %6.1f MB", "discordpy", bar(60, 150, w), 60),
        format("%-12s %s %6.1f MB", "discordjs", bar(100, 150, w), 100),
        format("%-12s %s %6.1f MB", "discordjda", bar(150, 150, w), 150),
        "```"
    }, "\n"))
end

registry.bench = function(discord, client, msg)
    local r_loop = timed(function()
        local x = 0
        for i = 1, 1e6 do x = x + i end
    end)

    local r_alloc = timed(function()
        local t = {}
        for i = 1, 1e5 do t[i] = { i } end
    end)

    local r_str = timed(function()
        for i = 1, 1e4 do local _ = tostring(i) end
    end)

    local r_hash = timed(function()
        local t = {}
        for i = 1, 1e5 do t["k" .. i] = i end
    end)

    send(discord, client, msg, concat({
        "**benchmark results**",
        "```",
        format("1M iterations:    %7.2f ms", r_loop),
        format("100k allocations: %7.2f ms", r_alloc),
        format("10k strings:      %7.2f ms", r_str),
        format("100k hash ops:    %7.2f ms", r_hash),
        "```",
        format("*mem after: %s*", fmt_bytes(get_mem()))
    }, "\n"))
end

registry.uptime = function(discord, client, msg)
    send(discord, client, msg, format("**uptime:** %s", fmt_time(clock() - start_time)))
end

registry.gc = function(discord, client, msg)
    local before = collectgarbage("count")
    collectgarbage("collect")
    local after = collectgarbage("count")
    send(discord, client, msg, format("**gc:** freed %s (%s -> %s)", fmt_bytes(before - after), fmt_bytes(before), fmt_bytes(after)))
end

registry.stats = function(discord, client, msg)
    local n = 0
    for _ in pairs(registry) do n = n + 1 end

    send(discord, client, msg, concat({
        "**bot stats**",
        "",
        format("**memory:** %s", fmt_bytes(get_mem())),
        format("**uptime:** %s", fmt_time(clock() - start_time)),
        format("**commands:** %d", n),
        format("**runtime:** %s", jit and jit.version or "luajit"),
        format("**os:** %s", jit and jit.os or ffi.os)
    }, "\n"))
end

function commands.handle(discord, client, msg, name, args)
    local fn = registry[name]
    if not fn then return end
    local ok, err = pcall(fn, discord, client, msg, args)
    if not ok then io.stderr:write(format("[%s] %s\n", name, err)) end
end

commands.list = registry

return commands
