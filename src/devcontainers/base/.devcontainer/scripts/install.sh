#!/bin/bash

echo "Starting NHS Notify base container installation script"

echo "Configuring APT packages"
./configure-apt.sh
echo "APT packages configured"

echo "Finished NHS Notify base container installation script"
