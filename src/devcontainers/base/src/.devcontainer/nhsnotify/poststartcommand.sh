#!/bin/bash

echo "reload shell"
source ~/.zshrc
echo "reloaded shell"

echo "running make config"
make config
echo "make config complete"

/welcome.sh