#!/bin/bash
SHARE_DIR="/usr/local/share/nhsnotify"

add_asdf_to_path(){
    echo "adding asdf to path"
    export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
    echo "added asdf to path"
}

echo "Starting NHS Notify feature installation script"


echo "Share dir is $SHARE_DIR"
mkdir -p $SHARE_DIR
cp -r ./scripts $SHARE_DIR

echo "Setup share dir, contents:"
pwd $SHARE_DIR
ls -la $SHARE_DIR

echo "Configuring APT packages"
. $SHARE_DIR/scripts/configure-apt.sh
echo "APT packages configured"

echo "go is at $(which go)"
echo 'install asdf via go'
go install github.com/asdf-vm/asdf/cmd/asdf@v0.18.0


add_asdf_to_path



echo "Finished NHS Notify feature installation script"