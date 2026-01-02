# ffi discord bot

a minimal discord bot using luajit ffi bindings to concord c library

## installation

```bash
bash scripts/install.sh
export DISCORD_TOKEN=your_token_here
export GUILD_ID=your_guild_id_here
luajit main.lua
```

the install script downloads only essential files from concord dev branch and compiles them

## how it works

- **luajit** - lua runtime with jit compilation
- **ffi** - foreign function interface to call c code from lua
- **concord** - c library for discord api (we call it via ffi)
- **our code** - pure lua using ffi bindings

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

## vps deployment

see `scripts/setup.txt` for full vps setup instructions
