#!/bin/bash

echo "make config variable is set to: ${MAKECONFIG}"
make_config="${MAKECONFIG:-true}"
if [ "${make_config}" != "true" ]; then
    echo "Skipping make config script as per configuration"
    exit 0
fi

echo "running make config"
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
make config
echo "make config complete"