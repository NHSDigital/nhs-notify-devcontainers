#!/bin/bash

SHARE_DIR="/usr/local/share/nhsnotify"
mkdir -p $SHARE_DIR
cp -r ./scripts $SHARE_DIR

. $SHARE_DIR/scripts/configure-apt.sh

echo "go is at $(which go)"
echo 'install asdf via go'
go install github.com/asdf-vm/asdf/cmd/asdf@v0.18.0
