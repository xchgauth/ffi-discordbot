#!/bin/bash

# build concord library
# run from src directory

set -e

cd lib

export CFLAGS="-fPIC $CFLAGS"
export LDFLAGS="-lpthread -lcurl -lm $LDFLAGS"

make clean 2>/dev/null || true
make
make shared

echo "done - libdiscord.so built in lib/lib/"
