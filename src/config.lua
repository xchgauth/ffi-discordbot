local config = {}

config.token = os.getenv("DISCORD_TOKEN") or error("DISCORD_TOKEN not set")
config.prefix = "!"
config.libpath = "./lib/libdiscord.so"

return config
