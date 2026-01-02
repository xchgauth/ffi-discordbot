local ffi = require("ffi")
local config = require("src.config")

ffi.cdef[[
typedef uint64_t u64snowflake;
typedef uint64_t u64unix_ms;
typedef uint64_t u64bitmask;

typedef struct discord discord;

struct discord_user {
    u64snowflake id;
    char *username;
    char *discriminator;
    char *global_name;
    char *avatar;
    char *avatar_decoration;
    bool bot;
    bool system;
    bool mfa_enabled;
    char *banner;
    int accent_color;
    char *locale;
    bool verified;
    char *email;
    u64bitmask flags;
    int premium_type;
    u64bitmask public_flags;
};

struct discord_application {
    u64snowflake id;
    char *name;
    char *icon;
    char *description;
    char **rpc_origins;
    bool bot_public;
    bool bot_require_code_grant;
    char *terms_of_service_url;
    char *privacy_policy_url;
    struct discord_user *owner;
    char *verify_key;
    void *team;
    u64snowflake guild_id;
    u64snowflake primary_sku_id;
    char *slug;
    char *cover_image;
    u64bitmask flags;
    char **tags;
    void *install_params;
    char *custom_install_url;
};

struct discord_ready {
    int v;
    struct discord_user *user;
    void *guilds;
    char *session_id;
    char *resume_gateway_url;
    int *shard;
    struct discord_application *application;
};

struct discord_message {
    u64snowflake id;
    u64snowflake channel_id;
    u64snowflake guild_id;
    struct discord_user *author;
    void *member;
    char *content;
    u64unix_ms timestamp;
    u64unix_ms edited_timestamp;
    bool tts;
    bool mention_everyone;
    void *mentions;
    void *mention_roles;
    void *mention_channels;
    void *attachments;
    void *embeds;
    void *reactions;
    char *nonce;
    bool pinned;
    u64snowflake webhook_id;
    int type;
    void *activity;
    struct discord_application *application;
    u64snowflake application_id;
    void *message_reference;
    u64bitmask flags;
    void *referenced_message;
    void *interaction;
    void *thread;
    void *components;
    void *sticker_items;
    void *stickers;
    int position;
    void *role_subscription_data;
    void *resolved;
};

struct discord_interaction {
    u64snowflake id;
    u64snowflake application_id;
    int type;
    void *data;
    u64snowflake guild_id;
    u64snowflake channel_id;
    void *member;
    struct discord_user *user;
    char *token;
    int version;
    void *message;
    char *app_permissions;
    char *locale;
    char *guild_locale;
};

struct discord_create_message {
    char *content;
    char *nonce;
    bool tts;
    void *embeds;
    void *allowed_mentions;
    void *message_reference;
    void *components;
    void *sticker_ids;
    void *attachments;
    u64bitmask flags;
};

struct discord_interaction_response {
    int type;
    void *data;
};

struct discord_interaction_callback_data {
    bool tts;
    char *content;
    void *embeds;
    void *allowed_mentions;
    u64bitmask flags;
    void *components;
    void *attachments;
};

struct discord_create_guild_application_command {
    char *name;
    void *name_localizations;
    char *description;
    void *description_localizations;
    void *options;
    char *default_member_permissions;
    bool dm_permission;
    bool default_permission;
    bool nsfw;
    int type;
};

struct discord_interaction_data {
    u64snowflake id;
    char *name;
    int type;
    void *resolved;
    void *options;
    u64snowflake guild_id;
    u64snowflake target_id;
};

discord* discord_init(const char *token);
void discord_cleanup(discord *client);
void discord_run(discord *client);

void discord_set_on_ready(struct discord *client, void (*callback)(struct discord *client, const struct discord_ready *event));
void discord_set_on_message_create(struct discord *client, void (*callback)(struct discord *client, const struct discord_message *event));
void discord_set_on_interaction_create(struct discord *client, void (*callback)(struct discord *client, const struct discord_interaction *event));

void discord_create_message(struct discord *client, u64snowflake channel_id, struct discord_create_message *params, void *ret);
void discord_create_interaction_response(struct discord *client, u64snowflake interaction_id, const char *interaction_token, struct discord_interaction_response *params, void *ret);
void discord_create_guild_application_command(struct discord *client, u64snowflake guild_id, struct discord_create_guild_application_command *params, void *ret);
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
    local content_buf = ffi.new("char[?]", #content + 1, content)
    msg.content = content_buf
    concord.discord_create_message(client, channel_id, msg, nil)
end

function discord.reply_interaction(client, interaction_id, token, content)
    local response = ffi.new("struct discord_interaction_response")
    local data = ffi.new("struct discord_interaction_callback_data")
    local content_buf = ffi.new("char[?]", #content + 1, content)
    data.content = content_buf
    response.type = 4
    response.data = data
    concord.discord_create_interaction_response(client, interaction_id, token, response, nil)
end

function discord.create_slash_command(client, guild_id, name, description)
    local cmd = ffi.new("struct discord_create_guild_application_command")
    local name_buf = ffi.new("char[?]", #name + 1, name)
    local desc_buf = ffi.new("char[?]", #description + 1, description)
    cmd.name = name_buf
    cmd.description = desc_buf
    cmd.type = 1
    concord.discord_create_guild_application_command(client, guild_id, cmd, nil)
end

return discord
