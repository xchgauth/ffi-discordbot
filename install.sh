#!/bin/bash

set -e

branch="dev"
base_url="https://raw.githubusercontent.com/Cogmasters/concord/$branch"

mkdir -p lib/core lib/gencodecs lib/include lib/src lib/lib

curl -sL "$base_url/Makefile" -o lib/Makefile
curl -sL "$base_url/config.json" -o lib/config.json

for file in carray.h cog-utils.h jsmn.h jsmn-find.h logconf.h threadpool.h websockets.h; do
    curl -sL "$base_url/core/$file" -o "lib/core/$file"
done

for file in api.pre.h api_channel.pre.h api_guild.pre.h api_user.pre.h discord-codecs.pre.h gateway-codecs.pre.h; do
    curl -sL "$base_url/gencodecs/$file" -o "lib/gencodecs/$file" 2>/dev/null || true
done

for file in concord-once.h discord-internal.h discord.h gateway.h types.h user-agent.h; do
    curl -sL "$base_url/include/$file" -o "lib/include/$file"
done

for file in discord-adapter.c discord-cache.c discord-client.c discord-core.c discord-gateway.c discord-loop.c discord-rest.c discord-timer.c discord-voice.c gateway.c io_poller.c websockets.c; do
    curl -sL "$base_url/src/$file" -o "lib/src/$file"
done

cd lib
make
cd ..
