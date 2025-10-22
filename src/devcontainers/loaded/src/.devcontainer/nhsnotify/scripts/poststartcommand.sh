#!/bin/bash

echo "running make config"
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
make config
echo "make config complete"

/usr/local/share/nhsnotify/scripts/welcome.sh