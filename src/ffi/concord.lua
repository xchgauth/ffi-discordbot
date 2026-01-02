local ffi = require("ffi")
local config = require("src.config")

ffi.cdef[[
typedef struct discord discord;
typedef struct discord_ready discord_ready;
typedef struct discord_message discord_message;
typedef struct discord_interaction discord_interaction;
typedef struct discord_application discord_application;
typedef struct discord_user discord_user;

struct discord_ready {
    struct discord_application *application;
    struct discord_user *user;
};

struct discord_user {
    uint64_t id;
    char *username;
    char *discriminator;
    char *avatar;
    bool bot;
};

struct discord_application {
    uint64_t id;
    char *name;
};

struct discord_message {
    uint64_t id;
    uint64_t channel_id;
    uint64_t guild_id;
    struct discord_user *author;
    char *content;
};

struct discord_interaction {
    uint64_t id;
    int type;
    char *token;
    uint64_t guild_id;
    uint64_t channel_id;
    struct discord_user *user;
    void *data;
};

struct discord_interaction_response {
    int type;
    void *data;
};

struct discord_interaction_callback_data {
    char *content;
};

struct discord_create_message {
    char *content;
};

struct discord_create_guild_application_command {
    char *name;
    char *description;
    int type;
};

struct discord_interaction_data {
    char *name;
};

discord* discord_init(const char *token);
void discord_cleanup(discord *client);
void discord_run(discord *client);

void discord_set_on_ready(discord *client, void (*callback)(discord *client, const struct discord_ready *event));
void discord_set_on_message_create(discord *client, void (*callback)(discord *client, const struct discord_message *event));
void discord_set_on_interaction_create(discord *client, void (*callback)(discord *client, const struct discord_interaction *event));

void discord_create_message(discord *client, uint64_t channel_id, struct discord_create_message *params, void *ret);
void discord_create_interaction_response(discord *client, uint64_t interaction_id, const char *interaction_token, struct discord_interaction_response *params, void *ret);
void discord_create_guild_application_command(discord *client, uint64_t guild_id, struct discord_create_guild_application_command *params, void *ret);
]]

local libpath = config.libpath
local concord = ffi.load(libpath)

local discord = {}

function discord.init(token)
    return concord.discord_init(token)
end

function discord.cleanup(client)
    concord.discord_cleanup(client)
end

function discord.run(client)
    concord.discord_run(client)
end

function discord.on_ready(client, callback)
    concord.discord_set_on_ready(client, callback)
end

function discord.on_message(client, callback)
    concord.discord_set_on_message_create(client, callback)
end

function discord.on_interaction(client, callback)
    concord.discord_set_on_interaction_create(client, callback)
end

function discord.send_message(client, channel_id, content)
    local msg = ffi.new("struct discord_create_message")
    msg.content = content
    concord.discord_create_message(client, channel_id, msg, nil)
end

function discord.reply_interaction(client, interaction_id, token, content)
    local response = ffi.new("struct discord_interaction_response")
    local data = ffi.new("struct discord_interaction_callback_data")
    data.content = content
    response.type = 4
    response.data = data
    concord.discord_create_interaction_response(client, interaction_id, token, response, nil)
end

function discord.create_slash_command(client, guild_id, name, description)
    local cmd = ffi.new("struct discord_create_guild_application_command")
    cmd.name = name
    cmd.description = description
    cmd.type = 1
    concord.discord_create_guild_application_command(client, guild_id, cmd, nil)
end

return discord
