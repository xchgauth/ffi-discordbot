# ffi discord bot

a minimal discord bot using luajit ffi bindings to concord c library

## structure

```
dcbot/
├── main.lua              # entry point
├── install.sh            # installs concord from github
├── src/
│   ├── bot.lua           # main bot logic
│   ├── config.lua        # configuration
│   ├── commands.lua      # command handlers
│   └── ffi/
│       └── concord.lua   # ffi bindings to concord c library
└── lib/                  # auto-generated (not in git)
```

## how it works

- **luajit** - lua runtime with jit compilation
- **ffi** - foreign function interface to call c code from lua
- **concord** - c library for discord api (called via ffi)
- **our code** - pure lua using ffi bindings

## installation

```bash
bash install.sh
export DISCORD_TOKEN=your_token_here
export GUILD_ID=your_guild_id_here
luajit main.lua
```

the install script downloads only essential files from concord dev branch and compiles them

## commands

**text commands (prefix: !)**
- `!ping` - pong
- `!echo <text>` - echo back
- `!help` - list commands
- `!info` - bot info

**slash commands**
- `/ping` - test bot response
- `/info` - bot information
- `/help` - list all commands
